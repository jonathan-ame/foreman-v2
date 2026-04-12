#!/usr/bin/env bash
set -euo pipefail

CHECK_PODS=0
STRICT_PODS=0
for _arg in "$@"; do
  case "${_arg}" in
    --check-pods) CHECK_PODS=1 ;;
    --strict) STRICT_PODS=1 ;;
    *)
      echo "ERROR: Unknown argument: ${_arg}" >&2
      echo "Usage: $0 [--check-pods] [--strict]" >&2
      exit 1
      ;;
  esac
done

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

validate_json5_config() {
  local source_file="$1"
  node - "${source_file}" <<'JS'
const fs = require("node:fs");
const path = require("node:path");
const { createRequire } = require("node:module");

const sourceFile = process.argv[2];
const sourceText = fs.readFileSync(sourceFile, "utf-8");

const attempted = [];
function tryLoadJson5(req, label) {
  try {
    return {
      mod: req("json5"),
      resolvedPath: req.resolve("json5"),
      label,
    };
  } catch (err) {
    attempted.push(`${label}: ${String(err)}`);
    return null;
  }
}

let loaded = tryLoadJson5(require, "global-require");
if (!loaded) {
  const anchors = [
    "/opt/homebrew/lib/node_modules/openclaw/package.json",
    "/opt/homebrew/lib/node_modules/openclaw/node_modules/json5/package.json",
  ];
  for (const anchor of anchors) {
    try {
      const anchoredRequire = createRequire(anchor);
      loaded = tryLoadJson5(anchoredRequire, anchor);
      if (loaded) break;
    } catch (err) {
      attempted.push(`${anchor}: ${String(err)}`);
    }
  }
}

if (!loaded) {
  console.error(`ERROR: Could not resolve JSON5 parser for validation of ${sourceFile}`);
  for (const line of attempted) {
    console.error(`  - ${line}`);
  }
  process.exit(1);
}

try {
  loaded.mod.parse(sourceText);
} catch (err) {
  const message = err instanceof Error ? err.message : String(err);
  console.error(`ERROR: JSON5 parse validation failed for ${sourceFile}: ${message}`);
  process.exit(1);
}

console.log(`Validated JSON5 parse for ${sourceFile} using ${loaded.resolvedPath}`);
JS
}

reset_openclaw_config_baseline_state() {
  local target_config_path="$1"
  local resolved_config_path
  resolved_config_path="$(
    python3 - "${target_config_path}" <<'PY'
import os
import sys
print(os.path.realpath(sys.argv[1]))
PY
  )"

  local config_health_path="${OPENCLAW_HOME}/logs/config-health.json"
  if [[ -f "${config_health_path}" ]]; then
    if ! command -v jq >/dev/null 2>&1; then
      echo "ERROR: jq is required to edit ${config_health_path} baseline state." >&2
      exit 1
    fi
    if jq -e . "${config_health_path}" >/dev/null 2>&1; then
      if jq -e --arg cfg "${resolved_config_path}" '.entries | type == "object" and has($cfg)' "${config_health_path}" >/dev/null 2>&1; then
        local tmp_health
        tmp_health="$(mktemp)"
        if jq --arg cfg "${resolved_config_path}" '
          if (.entries | type) == "object"
          then .entries |= with_entries(select(.key != $cfg))
          else .
          end
        ' "${config_health_path}" > "${tmp_health}"; then
          mv "${tmp_health}" "${config_health_path}"
          echo "Removed stale config-health baseline entry for ${resolved_config_path}"
        else
          rm -f "${tmp_health}"
          echo "NOTICE: Failed updating ${config_health_path}; continuing without baseline entry removal." >&2
        fi
      else
        echo "NOTICE: No config-health baseline entry found for ${resolved_config_path}; nothing to remove."
      fi
    else
      echo "NOTICE: Could not parse ${config_health_path}; continuing without baseline entry removal." >&2
    fi
  fi

  local backup_fallback_path="${resolved_config_path}.bak"
  if [[ -f "${backup_fallback_path}" ]]; then
    local moved_backup_path
    moved_backup_path="${backup_fallback_path}.pre-configure-$(date +%Y%m%d-%H%M%S)"
    mv "${backup_fallback_path}" "${moved_backup_path}"
    echo "Moved baseline fallback backup to ${moved_backup_path}"
  fi
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
REVIEWER_BASE_URL=""

pod_lines_file="$(mktemp)"
python3 - "${STATE_FILE}" > "${pod_lines_file}" <<'PY'
import json
import re
import sys
from urllib.parse import urlparse

path = sys.argv[1]
expected_roles = {
    "embedding": "Qwen/Qwen3-Embedding-8B",
    "executor": "Qwen/Qwen2.5-32B-Instruct",
    "planner": "deepseek-ai/DeepSeek-R1-Distill-Qwen-32B",
    "reviewer": "Qwen/Qwen2.5-Coder-32B-Instruct",
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

if len(by_role) != 4:
    raise SystemExit("ERROR: state/pods.json must contain exactly four roles (executor, planner, embedding, reviewer).")

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
    reviewer) REVIEWER_BASE_URL="${base_url}" ;;
    *)
      echo "ERROR: Unexpected role '${role}' while parsing ${STATE_FILE}." >&2
      exit 1
      ;;
  esac
done < "${pod_lines_file}"
rm -f "${pod_lines_file}"

if [[ -z "${EXECUTOR_BASE_URL}" || -z "${PLANNER_BASE_URL}" || -z "${EMBEDDING_BASE_URL}" || -z "${REVIEWER_BASE_URL}" ]]; then
  echo "ERROR: Failed to extract all required base URLs from ${STATE_FILE}." >&2
  exit 1
fi
export EXECUTOR_BASE_URL PLANNER_BASE_URL EMBEDDING_BASE_URL REVIEWER_BASE_URL

mkdir -p "${OPENCLAW_HOME}"

if [[ -f "${TARGET_CONFIG}" ]]; then
  backup_path="${TARGET_CONFIG}.bak-$(date +%Y%m%d-%H%M%S)"
  cp "${TARGET_CONFIG}" "${backup_path}"
  echo "Backed up existing config to ${backup_path}"
fi

tmp_rendered="$(mktemp)"
python3 - "${TEMPLATE_FILE}" "${tmp_rendered}" <<'PY'
import os
import sys

template_path = sys.argv[1]
output_path = sys.argv[2]

with open(template_path, "r", encoding="utf-8") as f:
    data = f.read()

rendered = data
rendered = rendered.replace("__EXECUTOR_BASE_URL__", os.environ["EXECUTOR_BASE_URL"])  # type: ignore[name-defined]
rendered = rendered.replace("__PLANNER_BASE_URL__", os.environ["PLANNER_BASE_URL"])  # type: ignore[name-defined]
rendered = rendered.replace("__EMBEDDING_BASE_URL__", os.environ["EMBEDDING_BASE_URL"])  # type: ignore[name-defined]
rendered = rendered.replace("__REVIEWER_BASE_URL__", os.environ["REVIEWER_BASE_URL"])  # type: ignore[name-defined]

with open(output_path, "w", encoding="utf-8") as f:
    f.write(rendered)
PY
reset_openclaw_config_baseline_state "${TARGET_CONFIG}"
mv "${tmp_rendered}" "${TARGET_CONFIG}"
write_config_checksum "${TARGET_CONFIG}"
validate_json5_config "${TARGET_CONFIG}"

openclaw_env_tmp="$(mktemp)"
cat > "${openclaw_env_tmp}" <<EOF
RUNPOD_API_KEY=${RUNPOD_API_KEY}
EXECUTOR_BASE_URL=${EXECUTOR_BASE_URL}
PLANNER_BASE_URL=${PLANNER_BASE_URL}
EMBEDDING_BASE_URL=${EMBEDDING_BASE_URL}
REVIEWER_BASE_URL=${REVIEWER_BASE_URL}
EOF
chmod 600 "${openclaw_env_tmp}"
mv "${openclaw_env_tmp}" "${OPENCLAW_ENV_FILE}"

echo "Wrote ${TARGET_CONFIG}"
echo "Wrote ${OPENCLAW_ENV_FILE}"
echo "Wrote ${CHECKSUM_FILE}"

check_err() {
  if [[ "${STRICT_PODS}" -eq 1 ]]; then
    echo "ERROR: $*" >&2
    exit 1
  fi
  echo "WARNING: $*" >&2
}

json_error_check() {
  local role="$1"
  local body_file="$2"
  if ! python3 - "${role}" "${body_file}" <<'PY'
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
  then
    return 1
  fi
  return 0
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
      check_err "${role} check failed calling ${models_url}"
      rm -f "${out_file}" "${chat_out}"
      return 1
    }

  if [[ "${code}" -lt 200 || "${code}" -ge 300 ]]; then
    cat "${out_file}" >&2
    check_err "${role} /models returned HTTP ${code}"
    rm -f "${out_file}" "${chat_out}"
    return 1
  fi
  if ! json_error_check "${role}" "${out_file}"; then
    check_err "${role} /models JSON validation failed"
    rm -f "${out_file}" "${chat_out}"
    return 1
  fi

  if ! python3 - "${out_file}" "${expected_model}" "${role}" <<'PY'
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
  then
    check_err "${role} /models response missing expected model ${expected_model}"
    rm -f "${out_file}" "${chat_out}"
    return 1
  fi

  local chat_code
  chat_code="$(curl -sS -o "${chat_out}" -w "%{http_code}" \
    -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"${expected_model}\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with PONG\"}],\"max_tokens\":16}" \
    "${chat_url}")" || {
      check_err "${role} chat probe failed calling ${chat_url}"
      rm -f "${out_file}" "${chat_out}"
      return 1
    }

  if [[ "${chat_code}" -lt 200 || "${chat_code}" -ge 300 ]]; then
    cat "${chat_out}" >&2
    check_err "${role} /chat/completions returned HTTP ${chat_code}"
    rm -f "${out_file}" "${chat_out}"
    return 1
  fi
  if ! json_error_check "${role}" "${chat_out}"; then
    check_err "${role} chat JSON validation failed"
    rm -f "${out_file}" "${chat_out}"
    return 1
  fi

  if ! python3 - "${chat_out}" "${role}" <<'PY'
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
  then
    check_err "${role} chat probe returned unusable assistant content"
    rm -f "${out_file}" "${chat_out}"
    return 1
  fi

  rm -f "${out_file}" "${chat_out}"
  return 0
}

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
      check_err "${role} check failed calling ${models_url}"
      rm -f "${out_file}"
      return 1
    }
  if [[ "${code}" -lt 200 || "${code}" -ge 300 ]]; then
    cat "${out_file}" >&2
    check_err "${role} /models returned HTTP ${code}"
    rm -f "${out_file}"
    return 1
  fi
  if ! json_error_check "${role}" "${out_file}"; then
    check_err "${role} /models JSON validation failed"
    rm -f "${out_file}"
    return 1
  fi
  if ! python3 - "${out_file}" "${expected_model}" "${role}" <<'PY'
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
  then
    check_err "${role} /models response missing expected model ${expected_model}"
    rm -f "${out_file}"
    return 1
  fi
  rm -f "${out_file}"
  return 0
}

run_embedding_endpoint_probe() {
  local embed_probe_out
  embed_probe_out="$(mktemp)"
  local embed_probe_code
  embed_probe_code="$(
curl -sS -o "${embed_probe_out}" -w "%{http_code}" \
  -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen/Qwen3-Embedding-8B","input":"foreman-v2 embedding health probe"}' \
  "${EMBEDDING_BASE_URL%/}/embeddings"
)" || {
    check_err "embedding /embeddings curl failed"
    rm -f "${embed_probe_out}"
    return 1
  }

  if [[ "${embed_probe_code}" -lt 200 || "${embed_probe_code}" -ge 300 ]]; then
    cat "${embed_probe_out}" >&2
    check_err "embedding /embeddings probe failed with HTTP ${embed_probe_code}"
    rm -f "${embed_probe_out}"
    return 1
  fi
  if ! json_error_check "embedding" "${embed_probe_out}"; then
    check_err "embedding /embeddings JSON validation failed"
    rm -f "${embed_probe_out}"
    return 1
  fi
  if ! python3 - "${embed_probe_out}" <<'PY'
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
  then
    check_err "embedding /embeddings probe returned invalid vector payload"
    rm -f "${embed_probe_out}"
    return 1
  fi
  rm -f "${embed_probe_out}"
  return 0
}

if [[ "${CHECK_PODS}" -eq 1 ]]; then
  POD_PROBE_FAILURES=0
  check_models_and_chat "executor" "${EXECUTOR_BASE_URL}" "Qwen/Qwen2.5-32B-Instruct" || POD_PROBE_FAILURES=$((POD_PROBE_FAILURES + 1))
  check_models_and_chat "planner" "${PLANNER_BASE_URL}" "deepseek-ai/DeepSeek-R1-Distill-Qwen-32B" || POD_PROBE_FAILURES=$((POD_PROBE_FAILURES + 1))
  check_models_and_chat "reviewer" "${REVIEWER_BASE_URL}" "Qwen/Qwen2.5-Coder-32B-Instruct" || POD_PROBE_FAILURES=$((POD_PROBE_FAILURES + 1))
  check_models_only "embedding" "${EMBEDDING_BASE_URL}" "Qwen/Qwen3-Embedding-8B" || POD_PROBE_FAILURES=$((POD_PROBE_FAILURES + 1))
  run_embedding_endpoint_probe || POD_PROBE_FAILURES=$((POD_PROBE_FAILURES + 1))
  if [[ "${POD_PROBE_FAILURES}" -gt 0 ]]; then
    if [[ "${STRICT_PODS}" -eq 1 ]]; then
      echo "ERROR: One or more RunPod endpoint probes failed (strict mode)." >&2
      exit 1
    fi
    echo "WARNING: RunPod endpoint verification finished with ${POD_PROBE_FAILURES} failing probe(s); continuing (non-strict)." >&2
  else
    echo "RunPod endpoint verification passed for executor, planner, reviewer, and embedding."
  fi
else
  echo "Skipping RunPod HTTP endpoint probes (pass --check-pods; add --strict to fail on probe errors)."
fi

if [[ "${STRICT_PODS}" -eq 1 && "${CHECK_PODS}" -eq 0 ]]; then
  echo "WARNING: --strict without --check-pods has no effect." >&2
fi
