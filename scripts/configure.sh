#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
TEMPLATE_FILE="${ROOT_DIR}/config/openclaw.foreman.json"
STATE_FILE="${ROOT_DIR}/state/pods.json"
CHECKSUM_FILE="${ROOT_DIR}/state/openclaw-config-checksum.txt"
OPENCLAW_HOME="${HOME}/.openclaw"
TARGET_CONFIG="${OPENCLAW_HOME}/openclaw.json"
OPENCLAW_ENV_FILE="${OPENCLAW_HOME}/.env"

write_config_checksum() {
  local source_file="$1"
  mkdir -p "$(dirname "${CHECKSUM_FILE}")"
  python3 - "${source_file}" "${CHECKSUM_FILE}" <<'PY'
import hashlib
import pathlib
import sys

source = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
digest = hashlib.sha256(source.read_bytes()).hexdigest()
target.write_text(digest + "\n", encoding="utf-8")
PY
}

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "ERROR: Missing ${ENV_FILE}. Copy .env.example to .env first." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

required_vars=(
  "RUNPOD_API_KEY"
)

for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "ERROR: Required env var ${var_name} is missing or empty in ${ENV_FILE}." >&2
    exit 1
  fi
done

if [[ ! -f "${STATE_FILE}" ]]; then
  echo "ERROR: Missing ${STATE_FILE}. Run ./scripts/provision.sh first." >&2
  exit 1
fi

EXECUTOR_BASE_URL=""
PLANNER_BASE_URL=""
EMBEDDING_BASE_URL=""

pod_lines_file="$(mktemp)"
python3 - "${STATE_FILE}" > "${pod_lines_file}" <<'PY'
import json
import re
import sys
from urllib.parse import urlparse

path = sys.argv[1]
expected_roles = {
    "embedding": "Qwen/Qwen3-Embedding-8B",
    "executor": "Qwen/Qwen3-14B-AWQ",
    "planner": "Qwen/Qwen3-30B-A3B-Instruct-2507",
}

try:
    with open(path, "r", encoding="utf-8") as f:
        payload = json.load(f)
except FileNotFoundError:
    raise SystemExit(f"ERROR: Missing state file: {path}")
except json.JSONDecodeError as exc:
    raise SystemExit(f"ERROR: Malformed JSON in {path}: {exc}")
except Exception as exc:
    raise SystemExit(f"ERROR: Failed reading {path}: {exc}")

if not isinstance(payload, dict):
    raise SystemExit("ERROR: state/pods.json root must be an object.")

pods = payload.get("pods")
if not isinstance(pods, list):
    raise SystemExit("ERROR: state/pods.json must contain a list at key 'pods'.")

by_role = {}
allowed_roles = set(expected_roles.keys())
for idx, pod in enumerate(pods):
    if not isinstance(pod, dict):
        raise SystemExit(f"ERROR: state/pods.json pods[{idx}] is not an object.")
    role = str(pod.get("logical_name") or "").strip()
    if not role:
        raise SystemExit(f"ERROR: state/pods.json pods[{idx}] missing logical_name.")
    if role not in allowed_roles:
        raise SystemExit(f"ERROR: Unexpected role '{role}' in state/pods.json.")
    if role in by_role:
        raise SystemExit(f"ERROR: Duplicate role '{role}' in state/pods.json.")
    by_role[role] = pod

missing = [r for r in expected_roles if r not in by_role]
if missing:
    raise SystemExit("ERROR: state/pods.json is missing roles: " + ", ".join(missing))

if len(by_role) != 3:
    raise SystemExit("ERROR: state/pods.json must contain exactly three roles (executor, planner, embedding).")

url_pattern = re.compile(r"^https://[^/]+(?:/v1)?/?$")
for role, model in expected_roles.items():
    pod = by_role[role]
    base = str(pod.get("base_url") or "").strip()
    configured_model = str(pod.get("model_id") or "").strip()
    status = str(pod.get("status") or "").strip().lower()
    if not base:
        raise SystemExit(f"ERROR: Missing base_url for {role} in state/pods.json")
    parsed = urlparse(base)
    if parsed.scheme != "https" or not parsed.netloc:
        raise SystemExit(f"ERROR: Invalid base_url for {role}: {base}")
    if not url_pattern.match(base):
        raise SystemExit(
            f"ERROR: Unexpected base_url format for {role}: {base}. "
            "Expected https://<host>/v1"
        )
    if configured_model != model:
        raise SystemExit(
            f"ERROR: Model mismatch for {role}. Expected {model}, got {configured_model or '<empty>'}."
        )
    if status not in {"running", "healthy"}:
        raise SystemExit(
            f"ERROR: Role {role} is not ready in state/pods.json (status={status or '<empty>'})."
        )
    print(f"{role}\t{base}")
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
  echo "ERROR: Failed to extract all required base URLs from ${STATE_FILE}." >&2
  exit 1
fi
export EXECUTOR_BASE_URL PLANNER_BASE_URL EMBEDDING_BASE_URL

mkdir -p "${OPENCLAW_HOME}"

if [[ -f "${TARGET_CONFIG}" ]]; then
  backup_path="${TARGET_CONFIG}.bak-$(date +%Y%m%d-%H%M%S)"
  cp "${TARGET_CONFIG}" "${backup_path}"
  echo "Backed up existing config to ${backup_path}"
fi

tmp_rendered="$(mktemp)"
python3 - "${TEMPLATE_FILE}" "${tmp_rendered}" <<'PY'
import os
import re
import sys

template_path = sys.argv[1]
output_path = sys.argv[2]

with open(template_path, "r", encoding="utf-8") as f:
    data = f.read()

pattern = re.compile(r"\$\{([A-Z_][A-Z0-9_]*)\}")

def replace(match: re.Match[str]) -> str:
    key = match.group(1)
    value = os.environ.get(key)
    if not value:
        raise RuntimeError(f"Missing required env var for template substitution: {key}")
    return value

rendered = pattern.sub(replace, data)

with open(output_path, "w", encoding="utf-8") as f:
    f.write(rendered)
PY

python3 - "${tmp_rendered}" "${TARGET_CONFIG}" <<'PY'
import os
import sys

src = sys.argv[1]
dst = sys.argv[2]

with open(src, "r", encoding="utf-8") as f:
    data = f.read()

data = data.replace("__EXECUTOR_BASE_URL__", os.environ["EXECUTOR_BASE_URL"])  # type: ignore[name-defined]
data = data.replace("__PLANNER_BASE_URL__", os.environ["PLANNER_BASE_URL"])  # type: ignore[name-defined]
data = data.replace("__EMBEDDING_BASE_URL__", os.environ["EMBEDDING_BASE_URL"])  # type: ignore[name-defined]

with open(dst, "w", encoding="utf-8") as f:
    f.write(data)
PY
rm -f "${tmp_rendered}"
write_config_checksum "${TARGET_CONFIG}"

openclaw_env_tmp="$(mktemp)"
cat > "${openclaw_env_tmp}" <<EOF
RUNPOD_API_KEY=${RUNPOD_API_KEY}
EXECUTOR_BASE_URL=${EXECUTOR_BASE_URL}
PLANNER_BASE_URL=${PLANNER_BASE_URL}
EMBEDDING_BASE_URL=${EMBEDDING_BASE_URL}
EOF
chmod 600 "${openclaw_env_tmp}"
mv "${openclaw_env_tmp}" "${OPENCLAW_ENV_FILE}"

echo "Wrote ${TARGET_CONFIG}"
echo "Wrote ${OPENCLAW_ENV_FILE}"
echo "Wrote ${CHECKSUM_FILE}"

json_error_check() {
  local role="$1"
  local body_file="$2"
  python3 - "${role}" "${body_file}" <<'PY'
import json
import sys

role = sys.argv[1]
body = sys.argv[2]
try:
    with open(body, "r", encoding="utf-8") as f:
        payload = json.load(f)
except json.JSONDecodeError as exc:
    raise SystemExit(f"ERROR: {role} endpoint returned non-JSON body: {exc}")

if isinstance(payload, dict):
    if payload.get("error") is not None:
        raise SystemExit(f"ERROR: {role} endpoint returned error payload: {payload.get('error')}")
    errs = payload.get("errors")
    if errs:
        raise SystemExit(f"ERROR: {role} endpoint returned errors payload: {errs}")
PY
}

check_models_and_chat() {
  local role="$1"
  local base_url="$2"
  local expected_model="$3"
  local models_url="${base_url%/}/models"
  local chat_url="${base_url%/}/chat/completions"
  local out_file
  out_file="$(mktemp)"
  local chat_out
  chat_out="$(mktemp)"

  local code
  code="$(curl -sS -o "${out_file}" -w "%{http_code}" \
    -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
    -H "Content-Type: application/json" \
    "${models_url}")" || {
      echo "ERROR: ${role} check failed calling ${models_url}" >&2
      rm -f "${out_file}"
      exit 1
    }

  if [[ "${code}" -lt 200 || "${code}" -ge 300 ]]; then
    echo "ERROR: ${role} /models returned HTTP ${code}" >&2
    cat "${out_file}" >&2
    rm -f "${out_file}"
    exit 1
  fi
  json_error_check "${role}" "${out_file}"

  python3 - "${out_file}" "${expected_model}" "${role}" <<'PY'
import json
import sys

payload_path = sys.argv[1]
expected = sys.argv[2]
role = sys.argv[3]

with open(payload_path, "r", encoding="utf-8") as f:
    payload = json.load(f)

models = payload.get("data") or []
model_ids = [m.get("id") for m in models if isinstance(m, dict)]
if expected not in model_ids:
    raise SystemExit(
        f"ERROR: {role} expected model {expected} not found. Got: "
        + ", ".join([m for m in model_ids if m])
    )
PY

  local chat_code
  chat_code="$(curl -sS -o "${chat_out}" -w "%{http_code}" \
    -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"${expected_model}\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with PONG\"}],\"max_tokens\":16}" \
    "${chat_url}")" || {
      echo "ERROR: ${role} chat probe failed calling ${chat_url}" >&2
      rm -f "${out_file}" "${chat_out}"
      exit 1
    }

  if [[ "${chat_code}" -lt 200 || "${chat_code}" -ge 300 ]]; then
    echo "ERROR: ${role} /chat/completions returned HTTP ${chat_code}" >&2
    cat "${chat_out}" >&2
    rm -f "${out_file}" "${chat_out}"
    exit 1
  fi
  json_error_check "${role}" "${chat_out}"

  python3 - "${chat_out}" "${role}" <<'PY'
import json
import sys

path = sys.argv[1]
role = sys.argv[2]
with open(path, "r", encoding="utf-8") as f:
    payload = json.load(f)

choices = payload.get("choices")
if not isinstance(choices, list) or not choices:
    raise SystemExit(f"ERROR: {role} chat probe missing choices in response.")
msg = choices[0].get("message") if isinstance(choices[0], dict) else None
content = msg.get("content") if isinstance(msg, dict) else None
if not isinstance(content, str) or not content.strip():
    raise SystemExit(f"ERROR: {role} chat probe returned empty content.")
PY

  rm -f "${out_file}" "${chat_out}"
}

check_models_and_chat "executor" "${EXECUTOR_BASE_URL}" "Qwen/Qwen3-14B-AWQ"
check_models_and_chat "planner" "${PLANNER_BASE_URL}" "Qwen/Qwen3-30B-A3B-Instruct-2507"

check_models_only() {
  local role="$1"
  local base_url="$2"
  local expected_model="$3"
  local models_url="${base_url%/}/models"
  local out_file
  out_file="$(mktemp)"
  local code
  code="$(curl -sS -o "${out_file}" -w "%{http_code}" \
    -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
    -H "Content-Type: application/json" \
    "${models_url}")" || {
      echo "ERROR: ${role} check failed calling ${models_url}" >&2
      rm -f "${out_file}"
      exit 1
    }
  if [[ "${code}" -lt 200 || "${code}" -ge 300 ]]; then
    echo "ERROR: ${role} /models returned HTTP ${code}" >&2
    cat "${out_file}" >&2
    rm -f "${out_file}"
    exit 1
  fi
  json_error_check "${role}" "${out_file}"
  python3 - "${out_file}" "${expected_model}" "${role}" <<'PY'
import json
import sys

payload_path = sys.argv[1]
expected = sys.argv[2]
role = sys.argv[3]
with open(payload_path, "r", encoding="utf-8") as f:
    payload = json.load(f)
models = payload.get("data") or []
model_ids = [m.get("id") for m in models if isinstance(m, dict)]
if expected not in model_ids:
    raise SystemExit(
        f"ERROR: {role} expected model {expected} not found. Got: "
        + ", ".join([m for m in model_ids if m])
    )
PY
  rm -f "${out_file}"
}

check_models_only "embedding" "${EMBEDDING_BASE_URL}" "Qwen/Qwen3-Embedding-8B"

embed_probe_out="$(mktemp)"
embed_probe_code="$(
curl -sS -o "${embed_probe_out}" -w "%{http_code}" \
  -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen/Qwen3-Embedding-8B","input":"foreman-v2 embedding health probe"}' \
  "${EMBEDDING_BASE_URL%/}/embeddings"
)"

if [[ "${embed_probe_code}" -lt 200 || "${embed_probe_code}" -ge 300 ]]; then
  echo "ERROR: embedding /embeddings probe failed with HTTP ${embed_probe_code}" >&2
  cat "${embed_probe_out}" >&2
  rm -f "${embed_probe_out}"
  exit 1
fi
json_error_check "embedding" "${embed_probe_out}"
python3 - "${embed_probe_out}" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    payload = json.load(f)

data = payload.get("data")
if not isinstance(data, list) or not data:
    raise SystemExit("ERROR: embedding probe missing data array.")
embedding = data[0].get("embedding") if isinstance(data[0], dict) else None
if not isinstance(embedding, list) or not embedding:
    raise SystemExit("ERROR: embedding probe returned empty embedding vector.")
PY
rm -f "${embed_probe_out}"

echo "RunPod endpoint verification passed for executor, planner, and embedding."
