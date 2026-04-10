#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
STATE_FILE="${ROOT_DIR}/state/pods.json"
ENV_FILE="${ROOT_DIR}/.env"

if [[ ! -f "${STATE_FILE}" ]]; then
  echo "ERROR: Missing ${STATE_FILE}. Run ./scripts/provision.sh first." >&2
  exit 1
fi

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

if [[ -z "${RUNPOD_API_KEY:-}" ]]; then
  echo "ERROR: RUNPOD_API_KEY is required in ${ENV_FILE}." >&2
  exit 1
fi

EXECUTOR_BASE_URL=""
PLANNER_BASE_URL=""
EMBEDDING_BASE_URL=""
pod_lines_file="$(mktemp)"
python3 - "${STATE_FILE}" > "${pod_lines_file}" <<'PY'
import json
import sys
from urllib.parse import urlparse

try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        payload = json.load(f)
except json.JSONDecodeError as exc:
    raise SystemExit(f"ERROR: Malformed JSON in state/pods.json: {exc}")
except Exception as exc:
    raise SystemExit(f"ERROR: Failed to read state/pods.json: {exc}")

if not isinstance(payload, dict):
    raise SystemExit("ERROR: state/pods.json root must be an object.")
pods = payload.get("pods")
if not isinstance(pods, list):
    raise SystemExit("ERROR: state/pods.json must contain a list at key 'pods'.")

required = ("executor", "planner", "embedding")
by_role = {}
for idx, pod in enumerate(pods):
    if not isinstance(pod, dict):
        raise SystemExit(f"ERROR: state/pods.json pods[{idx}] is not an object.")
    role = str(pod.get("logical_name") or "").strip()
    if role in required:
        if role in by_role:
            raise SystemExit(f"ERROR: Duplicate role {role} in state/pods.json.")
        by_role[role] = pod
    elif role:
        raise SystemExit(f"ERROR: Unexpected role {role} in state/pods.json.")
    else:
        raise SystemExit(f"ERROR: state/pods.json pods[{idx}] missing logical_name.")

for role in required:
    if role not in by_role:
        raise SystemExit(f"ERROR: Missing {role} in state/pods.json")
    base_url = str(by_role[role].get("base_url") or "").strip()
    if not base_url:
        raise SystemExit(f"ERROR: Missing base_url for {role} in state/pods.json")
    parsed = urlparse(base_url)
    if parsed.scheme != "https" or not parsed.netloc:
        raise SystemExit(f"ERROR: Invalid base_url for {role}: {base_url}")
    print(f"{role}\t{base_url}")
PY

while IFS=$'\t' read -r role base_url; do
  case "${role}" in
    executor) EXECUTOR_BASE_URL="${base_url}" ;;
    planner) PLANNER_BASE_URL="${base_url}" ;;
    embedding) EMBEDDING_BASE_URL="${base_url}" ;;
    *)
      echo "ERROR: Unexpected role '${role}' while parsing ${STATE_FILE}." >&2
      exit 1
      ;;
  esac
done < "${pod_lines_file}"
rm -f "${pod_lines_file}"

if [[ -z "${EXECUTOR_BASE_URL}" || -z "${PLANNER_BASE_URL}" || -z "${EMBEDDING_BASE_URL}" ]]; then
  echo "ERROR: Failed to extract required endpoint URLs from ${STATE_FILE}." >&2
  exit 1
fi

fail_count=0

echo "Checking gateway status..."
if ! openclaw gateway status >/dev/null; then
  echo "ERROR: OpenClaw gateway is not healthy or not running." >&2
  fail_count=$((fail_count + 1))
fi

prompt="Reply with the exact string PONG and nothing else"
tmp_output="$(mktemp)"

echo "Sending smoke-test prompt via OpenClaw CLI..."
if ! openclaw agent \
  --session-id "foreman-v2-smoke" \
  --message "${prompt}" \
  --json > "${tmp_output}"; then
  echo "ERROR: openclaw agent command failed." >&2
  fail_count=$((fail_count + 1))
elif python3 - "${tmp_output}" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    payload = json.load(f)

def extract_candidates(value):
    out = []
    if isinstance(value, dict):
        for k, v in value.items():
            if k in {"content", "text"} and isinstance(v, str):
                out.append(v)
            out.extend(extract_candidates(v))
    elif isinstance(value, list):
        for item in value:
            out.extend(extract_candidates(item))
    return out

candidates = [c.strip() for c in extract_candidates(payload) if isinstance(c, str)]
if not candidates:
    raise SystemExit("ERROR: Executor response missing content/text fields.")

if "PONG" not in candidates:
    preview = " | ".join(candidates[:3])
    raise SystemExit(
        "ERROR: Executor expected exact 'PONG' in response content. Got: "
        + (preview or "<empty>")
    )
PY
then
  echo "Executor test passed: exact PONG found in response content."
else
  echo "ERROR: Executor smoke assertion failed." >&2
  python3 - "${tmp_output}" <<'PY'
from pathlib import Path
print(Path(__import__("sys").argv[1]).read_text(encoding="utf-8"))
PY
  fail_count=$((fail_count + 1))
fi
rm -f "${tmp_output}"

echo "Planner direct endpoint test..."
planner_out="$(mktemp)"
planner_code="$(
curl -sS -o "${planner_out}" -w "%{http_code}" \
  -H "Authorization: Bearer ${RUNPOD_API_KEY:-}" \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen/Qwen3-30B-A3B-Instruct-2507","messages":[{"role":"user","content":"Give a 3-step reasoning plan for brewing tea, with numbered steps only."}]}' \
  "${PLANNER_BASE_URL%/}/chat/completions"
)"
if [[ "${planner_code}" -lt 200 || "${planner_code}" -ge 300 ]]; then
  echo "ERROR: Planner endpoint failed with HTTP ${planner_code}" >&2
  python3 - "${planner_out}" <<'PY'
from pathlib import Path
print(Path(__import__("sys").argv[1]).read_text(encoding="utf-8"))
PY
  fail_count=$((fail_count + 1))
elif ! python3 - "${planner_out}" <<'PY'
import json
import re
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    payload = json.load(f)

if isinstance(payload, dict):
    if payload.get("error") is not None:
        raise SystemExit(f"ERROR: Planner returned error payload: {payload.get('error')}")
    if payload.get("errors"):
        raise SystemExit(f"ERROR: Planner returned errors payload: {payload.get('errors')}")

content = ""
choices = payload.get("choices") or []
if choices and isinstance(choices[0], dict):
    msg = choices[0].get("message") or {}
    if isinstance(msg, dict):
        content = str(msg.get("content") or "")

if not content.strip():
    raise SystemExit("ERROR: Planner returned empty content.")

if not re.search(r"\b1[\.\)]\s", content):
    raise SystemExit(
        "ERROR: Planner response missing expected numbered reasoning structure. "
        f"Got content: {content[:200]!r}"
    )
PY
then
  fail_count=$((fail_count + 1))
else
  echo "Planner test passed."
fi
rm -f "${planner_out}"

echo "Embedding endpoint test..."
embed_out="$(mktemp)"
embed_code="$(
curl -sS -o "${embed_out}" -w "%{http_code}" \
  -H "Authorization: Bearer ${RUNPOD_API_KEY:-}" \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen/Qwen3-Embedding-8B","input":"foreman v2 embedding smoke test"}' \
  "${EMBEDDING_BASE_URL%/}/embeddings"
)"
if [[ "${embed_code}" -lt 200 || "${embed_code}" -ge 300 ]]; then
  echo "ERROR: Embedding endpoint failed with HTTP ${embed_code}" >&2
  python3 - "${embed_out}" <<'PY'
from pathlib import Path
print(Path(__import__("sys").argv[1]).read_text(encoding="utf-8"))
PY
  fail_count=$((fail_count + 1))
elif ! python3 - "${embed_out}" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    payload = json.load(f)

if isinstance(payload, dict):
    if payload.get("error") is not None:
        raise SystemExit(f"ERROR: Embedding returned error payload: {payload.get('error')}")
    if payload.get("errors"):
        raise SystemExit(f"ERROR: Embedding returned errors payload: {payload.get('errors')}")

data = payload.get("data") or []
if not data or not isinstance(data[0], dict):
    raise SystemExit("ERROR: Embedding response missing data[0].")

vec = data[0].get("embedding")
if not isinstance(vec, list) or not vec:
    raise SystemExit("ERROR: Embedding vector is empty.")
if len(vec) <= 1:
    raise SystemExit(f"ERROR: Embedding vector dimension too small: {len(vec)}")
if not all(isinstance(x, (int, float)) for x in vec[:32]):
    raise SystemExit("ERROR: Embedding vector contains non-numeric values.")
PY
then
  fail_count=$((fail_count + 1))
else
  echo "Embedding test passed."
fi
rm -f "${embed_out}"

if [[ "${fail_count}" -gt 0 ]]; then
  echo "Smoke test failed: ${fail_count} check(s) failed (executor/planner/embedding/gateway)." >&2
  exit 1
fi

echo "Smoke test passed: executor, planner, and embedding checks succeeded."
