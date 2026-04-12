#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROUTING_FILE="${ROOT_DIR}/config/role-routing.json"
STATE_FILE="${ROOT_DIR}/state/pods.json"
OPENCLAW_CONFIG="${HOME}/.openclaw/openclaw.json"
ROLE="${PAPERCLIP_ROLE:-executor}"

temp_files=()
cleanup() {
  if [[ ${#temp_files[@]} -gt 0 ]]; then
    rm -f "${temp_files[@]}"
  fi
}
trap cleanup EXIT

if [[ ! -f "${ROUTING_FILE}" ]]; then
  echo "ERROR: Missing routing config ${ROUTING_FILE}" >&2
  exit 1
fi

if [[ ! -f "${STATE_FILE}" ]]; then
  echo "ERROR: Missing pod state ${STATE_FILE}" >&2
  exit 1
fi

if [[ ! -f "${OPENCLAW_CONFIG}" ]]; then
  echo "ERROR: Missing OpenClaw config ${OPENCLAW_CONFIG}" >&2
  exit 1
fi

resolved="$(
python3 - "${ROUTING_FILE}" "${STATE_FILE}" "${OPENCLAW_CONFIG}" "${ROLE}" "${ROOT_DIR}" <<'PY'
import json
import sys

routing_path, state_path, oc_path, role, root_dir = sys.argv[1:6]

from pathlib import Path

sys.path.insert(0, str(Path(root_dir) / "scripts" / "lib"))
from openclaw_config_helper import read_openclaw_config_atomic

with open(routing_path, "r", encoding="utf-8") as f:
    routing = json.load(f)
with open(state_path, "r", encoding="utf-8") as f:
    state = json.load(f)
oc, _ = read_openclaw_config_atomic(oc_path, attempts=5, delay_seconds=0.25)

roles = routing.get("roles") or {}
if role not in roles:
    raise SystemExit(f"ERROR: Unknown PAPERCLIP_ROLE '{role}'.")
role_cfg = roles[role]

pod_role = role_cfg.get("pod_role")
provider = role_cfg.get("provider")
model_id = role_cfg.get("model_id")
transport = role_cfg.get("transport")
if not all(isinstance(x, str) and x for x in [pod_role, provider, model_id, transport]):
    raise SystemExit(f"ERROR: Invalid routing config for role '{role}'.")

pods = state.get("pods") or []
pod = next((p for p in pods if isinstance(p, dict) and p.get("logical_name") == pod_role), None)
if not pod:
    raise SystemExit(f"ERROR: No pod found for role '{pod_role}' in state/pods.json.")
base_url = pod.get("base_url")
if not isinstance(base_url, str) or not base_url:
    raise SystemExit(f"ERROR: Missing base_url for role '{pod_role}'.")

providers = (((oc.get("models") or {}).get("providers") or {}))
provider_cfg = providers.get(provider) or {}
api_key = provider_cfg.get("apiKey")
if not isinstance(api_key, str) or not api_key:
    raise SystemExit(f"ERROR: Missing apiKey for provider '{provider}' in OpenClaw config.")

if any(("\t" in v) or ("\n" in v) or ("\r" in v) for v in [transport, model_id, base_url, api_key]):
    raise SystemExit("ERROR: Invalid routing metadata: control/tab characters not allowed.")

print("\t".join([transport, model_id, base_url, api_key]))
PY
)"

IFS=$'\t' read -r transport model_id base_url api_key <<< "${resolved}"

if [[ -z "${transport}" || -z "${model_id}" || -z "${base_url}" || -z "${api_key}" ]]; then
  echo "ERROR: Failed resolving routing metadata for role '${ROLE}'." >&2
  exit 1
fi

case "${transport}" in
  openclaw_agent)
    if [[ -z "${PAPERCLIP_COMPANY_ID:-}" || -z "${PAPERCLIP_AGENT_ID:-}" ]]; then
      echo "ERROR: PAPERCLIP_COMPANY_ID and PAPERCLIP_AGENT_ID are required for executor path." >&2
      exit 1
    fi
    session_id="${PAPERCLIP_COMPANY_ID}-${PAPERCLIP_AGENT_ID}"
    set +e
    output="$(openclaw agent --session-id "${session_id}" -m "Reply with exactly HEARTBEAT_OK and nothing else." 2>&1)"
    status=$?
    set -e
    if [[ ${status} -ne 0 ]]; then
      echo "ERROR: openclaw agent command failed." >&2
      exit "${status}"
    fi
    if [[ "${output}" == *"falling back to embedded"* ]] || [[ "${output}" == *"No reply from agent."* ]]; then
      echo "ERROR: OpenClaw gateway path failed; refusing silent fallback." >&2
      exit 1
    fi
    if [[ "${output}" != *"HEARTBEAT_OK"* ]]; then
      echo "ERROR: Unexpected OpenClaw response; expected HEARTBEAT_OK marker." >&2
      exit 1
    fi
    echo "HEARTBEAT_OK:${ROLE}"
    ;;
  openai_chat)
    python3 - "${base_url}" "${api_key}" "${model_id}" "${ROLE}" <<'PY'
import json
import sys
import urllib.request
import urllib.error

base_url, api_key, model_id, role = sys.argv[1:5]
payload = {
    "model": model_id,
    "messages": [{"role": "user", "content": "Reply with exactly HEARTBEAT_OK and nothing else."}],
    "max_tokens": 24,
}
req = urllib.request.Request(
    f"{base_url.rstrip('/')}/chat/completions",
    data=json.dumps(payload).encode(),
    headers={
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "User-Agent": "foreman-v2/1.0 role-dispatch",
    },
    method="POST",
)
try:
    with urllib.request.urlopen(req, timeout=60) as resp:
        if resp.getcode() < 200 or resp.getcode() >= 300:
            raise SystemExit(f"ERROR: {role} route failed with HTTP {resp.getcode()}.")
        out = json.loads(resp.read().decode())
except urllib.error.HTTPError as exc:
    raise SystemExit(f"ERROR: {role} route failed with HTTP {exc.code}.")

choices = out.get("choices") or []
if not choices or not isinstance(choices[0], dict):
    raise SystemExit(f"ERROR: {role} route response missing choices.")
msg = choices[0].get("message") or {}
content = (msg.get("content") if isinstance(msg, dict) else "") or ""
if "HEARTBEAT_OK" not in str(content):
    raise SystemExit(f"ERROR: {role} route returned unexpected content.")
PY
    echo "HEARTBEAT_OK:${ROLE}"
    ;;
  openai_embeddings)
    python3 - "${base_url}" "${api_key}" "${model_id}" <<'PY'
import json
import sys
import urllib.request
import urllib.error

base_url, api_key, model_id = sys.argv[1:4]
payload = {
    "model": model_id,
    "input": "foreman role dispatch embedding probe",
}
req = urllib.request.Request(
    f"{base_url.rstrip('/')}/embeddings",
    data=json.dumps(payload).encode(),
    headers={
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "User-Agent": "foreman-v2/1.0 role-dispatch",
    },
    method="POST",
)
try:
    with urllib.request.urlopen(req, timeout=60) as resp:
        if resp.getcode() < 200 or resp.getcode() >= 300:
            raise SystemExit(f"ERROR: embedding route failed with HTTP {resp.getcode()}.")
        out = json.loads(resp.read().decode())
except urllib.error.HTTPError as exc:
    raise SystemExit(f"ERROR: embedding route failed with HTTP {exc.code}.")

data = out.get("data") or []
if not data or not isinstance(data[0], dict):
    raise SystemExit("ERROR: embedding route response missing data.")
vec = data[0].get("embedding")
if not isinstance(vec, list) or len(vec) < 8:
    raise SystemExit("ERROR: embedding route returned invalid vector.")
PY
    echo "HEARTBEAT_OK:${ROLE}"
    ;;
  *)
    echo "ERROR: Unsupported transport '${transport}' for role '${ROLE}'." >&2
    exit 1
    ;;
esac
