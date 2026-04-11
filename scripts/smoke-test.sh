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
REVIEWER_BASE_URL=""
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

required = ("executor", "planner", "embedding", "reviewer")
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
    reviewer) REVIEWER_BASE_URL="${base_url}" ;;
    *)
      echo "ERROR: Unexpected role '${role}' while parsing ${STATE_FILE}." >&2
      exit 1
      ;;
  esac
done < "${pod_lines_file}"
rm -f "${pod_lines_file}"

if [[ -z "${EXECUTOR_BASE_URL}" || -z "${PLANNER_BASE_URL}" || -z "${EMBEDDING_BASE_URL}" || -z "${REVIEWER_BASE_URL}" ]]; then
  echo "ERROR: Failed to extract required endpoint URLs from ${STATE_FILE}." >&2
  exit 1
fi

fail_count=0

echo "Checking gateway status..."
if ! openclaw gateway status >/dev/null; then
  echo "WARN: OpenClaw gateway status probe returned non-zero; continuing with direct endpoint smoke checks." >&2
fi

echo "Executor direct endpoint test..."
executor_out="$(mktemp)"
executor_code="$(
curl -sS -o "${executor_out}" -w "%{http_code}" \
  -H "Authorization: Bearer ${RUNPOD_API_KEY:-}" \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen/Qwen2.5-32B-Instruct","messages":[{"role":"user","content":"What is 2+2? Reply in one short sentence."}],"max_tokens":48}' \
  "${EXECUTOR_BASE_URL%/}/chat/completions"
)"
if [[ "${executor_code}" -lt 200 || "${executor_code}" -ge 300 ]]; then
  echo "ERROR: Executor endpoint failed with HTTP ${executor_code}" >&2
  python3 - "${executor_out}" <<'PY'
from pathlib import Path
print(Path(__import__("sys").argv[1]).read_text(encoding="utf-8"))
PY
  fail_count=$((fail_count + 1))
elif ! python3 - "${executor_out}" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    payload = json.load(f)
choices = payload.get("choices") or []
content = ""
if choices and isinstance(choices[0], dict):
    msg = choices[0].get("message") or {}
    if isinstance(msg, dict):
        content = str(msg.get("content") or "")
if not content.strip():
    raise SystemExit("ERROR: Executor returned empty content.")
if not any(ch.isalpha() for ch in content):
    raise SystemExit(f"ERROR: Executor response is non-linguistic. Got: {content[:200]!r}")
PY
then
  fail_count=$((fail_count + 1))
else
  echo "Executor test passed."
fi
rm -f "${executor_out}"

echo "Planner direct endpoint test..."
planner_out="$(mktemp)"
planner_code="$(
curl -sS -o "${planner_out}" -w "%{http_code}" \
  -H "Authorization: Bearer ${RUNPOD_API_KEY:-}" \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek-ai/DeepSeek-R1-Distill-Qwen-32B","messages":[{"role":"user","content":"Give a 3-step reasoning plan for brewing tea, with numbered steps only."}],"max_tokens":128}' \
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
if not any(ch.isalpha() for ch in content):
    raise SystemExit(f"ERROR: Planner response is non-linguistic. Got: {content[:200]!r}")

if not re.search(
    r"(?:\b1[\.\)]\s|\bstep\s*1\s*:|\bfirst\b|\bthen\b|\bnext\b|\bfinally\b)",
    content,
    flags=re.IGNORECASE,
):
    raise SystemExit(
        "ERROR: Planner response missing expected planning structure keywords/format. "
        f"Got content: {content[:200]!r}"
    )
PY
then
  fail_count=$((fail_count + 1))
else
  echo "Planner test passed."
fi
rm -f "${planner_out}"

echo "Reviewer direct endpoint test..."
reviewer_out="$(mktemp)"
reviewer_code="$(
curl -sS -o "${reviewer_out}" -w "%{http_code}" \
  -H "Authorization: Bearer ${RUNPOD_API_KEY:-}" \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen/Qwen2.5-Coder-32B-Instruct","messages":[{"role":"user","content":"Review this code and list exactly 2 concrete bugs:\\n```python\\ndef add(a,b):\\n    return a-b\\n```"}],"max_tokens":128}' \
  "${REVIEWER_BASE_URL%/}/chat/completions"
)"
if [[ "${reviewer_code}" -lt 200 || "${reviewer_code}" -ge 300 ]]; then
  echo "ERROR: Reviewer endpoint failed with HTTP ${reviewer_code}" >&2
  python3 - "${reviewer_out}" <<'PY'
from pathlib import Path
print(Path(__import__("sys").argv[1]).read_text(encoding="utf-8"))
PY
  fail_count=$((fail_count + 1))
elif ! python3 - "${reviewer_out}" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    payload = json.load(f)

if isinstance(payload, dict):
    if payload.get("error") is not None:
        raise SystemExit(f"ERROR: Reviewer returned error payload: {payload.get('error')}")
    if payload.get("errors"):
        raise SystemExit(f"ERROR: Reviewer returned errors payload: {payload.get('errors')}")

content = ""
choices = payload.get("choices") or []
if choices and isinstance(choices[0], dict):
    msg = choices[0].get("message") or {}
    if isinstance(msg, dict):
        content = str(msg.get("content") or "")

if not content.strip():
    raise SystemExit("ERROR: Reviewer returned empty content.")
if not any(ch.isalpha() for ch in content):
    raise SystemExit(f"ERROR: Reviewer response is non-linguistic. Got: {content[:200]!r}")
PY
then
  fail_count=$((fail_count + 1))
else
  echo "Reviewer test passed."
fi
rm -f "${reviewer_out}"

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
  echo "Smoke test failed: ${fail_count} check(s) failed (executor/planner/reviewer/embedding/gateway)." >&2
  exit 1
fi

echo "Smoke test passed: executor, planner, reviewer, and embedding checks succeeded."
