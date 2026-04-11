#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
STATE_FILE="${ROOT_DIR}/state/pods.json"
MIGRATION_LOG="${ROOT_DIR}/state/migrations/2026-04-10-h100-to-a100-cutover.jsonl"
SKU_CHAIN=(
  "NVIDIA A100 PCIe"
  "NVIDIA RTX PRO 6000"
  "NVIDIA H100 PCIe"
  "NVIDIA A100 SXM"
  "NVIDIA H100 NVL"
  "NVIDIA H100 SXM"
  "NVIDIA H200"
)

mkdir -p "$(dirname "${MIGRATION_LOG}")"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "ERROR: Missing ${ENV_FILE}" >&2
  exit 1
fi
set -a
source "${ENV_FILE}"
set +a

if [[ -z "${RUNPOD_API_KEY:-}" ]]; then
  echo "ERROR: RUNPOD_API_KEY is required in ${ENV_FILE}" >&2
  exit 1
fi

if [[ ! -f "${STATE_FILE}" ]]; then
  echo "ERROR: Missing ${STATE_FILE}. Run provisioning first." >&2
  exit 1
fi

json_role_entry() {
  local role="$1"
  python3 - "${STATE_FILE}" "${role}" <<'PY'
import json, sys
path, role = sys.argv[1:3]
with open(path, "r", encoding="utf-8") as f:
    state = json.load(f)
pods = state.get("pods") or []
entry = next((p for p in pods if p.get("logical_name") == role), None)
if not entry:
    raise SystemExit(f"ERROR: role '{role}' not found in state/pods.json")
print(json.dumps(entry))
PY
}

fetch_pod_details() {
  local pod_id="$1"
  python3 - "${pod_id}" <<'PY'
import json, os, sys, urllib.request
pod_id = sys.argv[1]
key = os.environ["RUNPOD_API_KEY"]
req = urllib.request.Request(
    f"https://rest.runpod.io/v1/pods/{pod_id}?includeMachine=true",
    headers={"Authorization": f"Bearer {key}"},
)
with urllib.request.urlopen(req, timeout=60) as resp:
    print(resp.read().decode())
PY
}

provision_replacement() {
  local role="$1"
  local model_id="$2"
  local image_name="$3"
  local start_cmd_json="$4"
  local sku_chain_json="$5"
  python3 - "${role}" "${model_id}" "${image_name}" "${start_cmd_json}" "${sku_chain_json}" <<'PY'
import datetime as dt
import json
import os
import sys
import time
import urllib.error
import urllib.request

role, model_id, image_name, start_cmd_json, sku_chain_json = sys.argv[1:6]
start_cmd = json.loads(start_cmd_json)
sku_chain = json.loads(sku_chain_json)
api_key = os.environ["RUNPOD_API_KEY"]

REST = "https://rest.runpod.io/v1"
GQL = "https://api.runpod.io/graphql"

def api(method, url, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        method=method,
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            body = resp.read().decode()
            return resp.getcode(), (json.loads(body) if body else {})
    except urllib.error.HTTPError as exc:
        body = (exc.read() or b"").decode(errors="replace")
        parsed = {}
        try:
            parsed = json.loads(body) if body else {}
        except Exception:
            parsed = {"error": body}
        return exc.code, parsed

def gql(query):
    status, payload = api("POST", GQL, {"query": query})
    if status != 200:
        raise RuntimeError(f"GraphQL failed HTTP {status}: {payload}")
    if payload.get("errors"):
        raise RuntimeError(f"GraphQL errors: {payload['errors']}")
    return payload.get("data") or {}

def available_secure_sku(sku):
    query = f'''
query {{
  gpuTypes(input: {{id: "{sku}"}}) {{
    id
    secureCloud
    securePrice
  }}
}}
'''
    data = gql(query)
    rows = data.get("gpuTypes") or []
    if not rows:
        return None
    row = rows[0]
    if not row.get("secureCloud"):
        return None
    if row.get("securePrice") is None:
        return None
    return row

def wait_running(pod_id, timeout=900):
    deadline = time.time() + timeout
    while time.time() < deadline:
        status, pod = api("GET", f"{REST}/pods/{pod_id}?includeMachine=true")
        if status != 200:
            time.sleep(10)
            continue
        desired = str(pod.get("desiredStatus") or "").upper()
        if desired == "RUNNING":
            return pod
        if desired in {"FAILED", "TERMINATED", "EXITED"}:
            raise RuntimeError(f"Pod {pod_id} entered terminal state {desired}")
        time.sleep(10)
    raise RuntimeError(f"Pod {pod_id} did not reach RUNNING in time")

def health_check(pod_id):
    base = f"https://{pod_id}-8000.proxy.runpod.net/v1"
    status, models = api("GET", f"{base}/models")
    if status != 200:
        raise RuntimeError(f"/models HTTP {status}")
    model_ids = [m.get("id") for m in (models.get("data") or []) if isinstance(m, dict)]
    if model_id not in model_ids:
        raise RuntimeError(f"Expected model {model_id} not in /models")
    if role == "embedding":
        status, emb = api("POST", f"{base}/embeddings", {"model": model_id, "input": "migration health check"})
        if status != 200:
            raise RuntimeError(f"/embeddings HTTP {status}")
        data = emb.get("data") or []
        if not data or not isinstance(data[0], dict) or not isinstance(data[0].get("embedding"), list):
            raise RuntimeError("Embedding payload invalid")
    else:
        status, chat = api("POST", f"{base}/chat/completions", {
            "model": model_id,
            "messages": [{"role": "user", "content": "Reply with OK"}],
            "max_tokens": 32
        })
        if status != 200:
            raise RuntimeError(f"/chat/completions HTTP {status}")
        choices = chat.get("choices") or []
        if not choices:
            raise RuntimeError("chat response missing choices")
    return base

mode_a_deadline = time.time() + (15 * 60)
mode_e_deadline = time.time() + (5 * 60)
idx = 0
while True:
    sku = sku_chain[idx]
    sku_row = available_secure_sku(sku)
    if not sku_row:
        idx = (idx + 1) % len(sku_chain)
        if idx == 0 and time.time() > mode_a_deadline:
            raise RuntimeError(f"Mode A timeout for {role}: no secure SKU in chain")
        if idx == 0:
            time.sleep(60)
        continue
    payload = {
        "name": f"foreman-v2-{role}-cutover-{dt.datetime.utcnow().strftime('%Y%m%d%H%M%S')}",
        "computeType": "GPU",
        "cloudType": "SECURE",
        "imageName": image_name,
        "gpuTypeIds": [sku_row["id"]],
        "gpuCount": 1,
        "containerDiskInGb": 80,
        "volumeInGb": 50,
        "volumeMountPath": "/workspace",
        "ports": ["8000/http"],
        "interruptible": False,
        "env": {},
        "dockerStartCmd": start_cmd,
        "dataCenterPriority": "availability",
        "gpuTypePriority": "custom",
    }
    status, created = api("POST", f"{REST}/pods", payload)
    if status in (200, 201) and isinstance(created, dict) and created.get("id"):
        pod_id = created["id"]
        running = wait_running(pod_id)
        base_url = health_check(pod_id)
        machine = running.get("machine") or {}
        out = {
            "pod_id": pod_id,
            "base_url": base_url,
            "gpu_type": machine.get("gpuTypeId") or sku_row["id"],
            "hourly_rate": float(sku_row.get("securePrice") or 0.0),
            "region": machine.get("dataCenterId") or machine.get("location") or "unknown",
            "selected_sku": sku_row["id"],
        }
        print(json.dumps(out))
        raise SystemExit(0)
    payload_text = json.dumps(created).lower()
    is_mode_e = status in {429, 500, 502, 503, 504, 0} or "timeout" in payload_text
    is_mode_a = any(n in payload_text for n in (
        "no gpu available", "out of capacity", "insufficient capacity",
        "not enough gpu", "currently unavailable", "no instances", "stock"
    ))
    if is_mode_e:
        if time.time() > mode_e_deadline:
            raise RuntimeError(f"Mode E timeout for {role}: {created}")
        time.sleep(60)
        continue
    if is_mode_a:
        idx = (idx + 1) % len(sku_chain)
        if idx == 0:
            if time.time() > mode_a_deadline:
                raise RuntimeError(f"Mode A timeout for {role}: {created}")
            time.sleep(60)
        continue
    raise RuntimeError(f"Provision failed for {role}: HTTP {status} payload={created}")
PY
}

delete_pod() {
  local pod_id="$1"
  python3 - "${pod_id}" <<'PY'
import os, sys, urllib.request, urllib.error
pod_id = sys.argv[1]
key = os.environ["RUNPOD_API_KEY"]
req = urllib.request.Request(
    f"https://rest.runpod.io/v1/pods/{pod_id}",
    headers={"Authorization": f"Bearer {key}"},
    method="DELETE",
)
try:
    with urllib.request.urlopen(req, timeout=60):
        pass
except urllib.error.HTTPError as exc:
    if exc.code != 404:
        raise
PY
}

update_role_state() {
  local role="$1"
  local new_entry_json="$2"
  python3 - "${STATE_FILE}" "${role}" "${new_entry_json}" <<'PY'
import json, sys
path, role, entry_json = sys.argv[1:4]
new_entry = json.loads(entry_json)
with open(path, "r", encoding="utf-8") as f:
    state = json.load(f)
pods = state.get("pods") or []
replaced = False
for idx, pod in enumerate(pods):
    if pod.get("logical_name") == role:
        pods[idx] = new_entry
        replaced = True
        break
if not replaced:
    raise SystemExit(f"ERROR: role {role} missing in state/pods.json")
state["pods"] = pods
tmp = path + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(state, f, indent=2)
    f.write("\n")
import os
os.replace(tmp, path)
PY
}

restore_role_state() {
  local role="$1"
  local old_entry_json="$2"
  update_role_state "${role}" "${old_entry_json}"
}

gateway_smoke_for_role() {
  local runtime_role="$1"
  if [[ "${runtime_role}" == "executor" ]]; then
    local out
    out="$(openclaw agent --session-id "cutover-executor-$(date +%s)" -m "Reply with exactly CUTOVER_OK and nothing else." 2>&1 || true)"
    [[ "${out}" == *"CUTOVER_OK"* ]]
  else
    local out
    out="$(PAPERCLIP_ROLE="${runtime_role}" "${ROOT_DIR}/scripts/paperclip-role-dispatch.sh" 2>&1 || true)"
    [[ "${out}" == *"HEARTBEAT_OK:${runtime_role}"* ]]
  fi
}

echo "Starting sequential cutover: executor -> planner -> coder(reviewer)"

for item in "executor:executor" "planner:planner" "coder:reviewer"; do
  label="${item%%:*}"
  role="${item##*:}"
  echo "==== Migrating ${label} (runtime role ${role}) ===="

  old_entry_json="$(json_role_entry "${role}")"
  old_pod_id="$(python3 - <<'PY' "${old_entry_json}"
import json, sys
entry = json.loads(sys.argv[1])
print(entry["pod_id"])
PY
)"

  pod_json="$(fetch_pod_details "${old_pod_id}")"
  old_image="$(python3 - <<'PY' "${pod_json}"
import json, sys
pod = json.loads(sys.argv[1])
print(pod.get("imageName") or "vllm/vllm-openai:latest")
PY
)"
  old_cmd_json="$(python3 - <<'PY' "${pod_json}"
import json, sys
pod = json.loads(sys.argv[1])
print(json.dumps(pod.get("dockerStartCmd") or []))
PY
)"
  model_id="$(python3 - <<'PY' "${old_entry_json}"
import json, sys
entry = json.loads(sys.argv[1])
print(entry["model_id"])
PY
)"

  echo "Provisioning replacement for ${role}..."
  sku_chain_json="$(python3 - <<'PY' "${SKU_CHAIN[@]}"
import json, sys
print(json.dumps(sys.argv[1:]))
PY
)"
  new_entry_json="$(provision_replacement "${role}" "${model_id}" "${old_image}" "${old_cmd_json}" "${sku_chain_json}")"

  echo "Applying atomic endpoint swap for ${role}..."
  merged_entry_json="$(python3 - <<'PY' "${old_entry_json}" "${new_entry_json}"
import datetime as dt
import json, sys
old_entry = json.loads(sys.argv[1])
new_entry = json.loads(sys.argv[2])
merged = dict(old_entry)
merged.update({
    "pod_id": new_entry["pod_id"],
    "base_url": new_entry["base_url"],
    "proxy_url": new_entry["base_url"],
    "gpu_type": new_entry["gpu_type"],
    "hourly_rate": new_entry["hourly_rate"],
    "region": new_entry["region"],
    "status": "healthy",
    "provisioned_at": dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
})
print(json.dumps(merged))
PY
)"
  update_role_state "${role}" "${merged_entry_json}"

  "${ROOT_DIR}/scripts/configure.sh"
  openclaw gateway restart
  sleep 60

  echo "Running gateway smoke for ${role}..."
  if ! gateway_smoke_for_role "${role}"; then
    echo "ERROR: Gateway smoke failed for ${role}. Rolling back."
    restore_role_state "${role}" "${old_entry_json}"
    "${ROOT_DIR}/scripts/configure.sh"
    openclaw gateway restart
    new_pod_id="$(python3 - <<'PY' "${new_entry_json}"
import json, sys
print(json.loads(sys.argv[1])["pod_id"])
PY
)"
    delete_pod "${new_pod_id}"
    exit 1
  fi

  new_pod_id="$(python3 - <<'PY' "${new_entry_json}"
import json, sys
print(json.loads(sys.argv[1])["pod_id"])
PY
)"
  echo "Gateway smoke passed; tearing down old pod ${old_pod_id}..."
  delete_pod "${old_pod_id}"

  python3 - <<'PY' "${MIGRATION_LOG}" "${label}" "${role}" "${old_pod_id}" "${new_entry_json}"
import datetime as dt
import json, sys
path, label, role, old_pod_id, new_entry_json = sys.argv[1:6]
new_entry = json.loads(new_entry_json)
row = {
    "ts": dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
    "label": label,
    "role": role,
    "old_pod_id": old_pod_id,
    "new_pod_id": new_entry["pod_id"],
    "selected_sku": new_entry.get("selected_sku"),
    "new_gpu_type": new_entry.get("gpu_type"),
}
with open(path, "a", encoding="utf-8") as f:
    f.write(json.dumps(row) + "\n")
PY

  echo "Role ${role} migrated successfully."
done

echo "Cutover completed for executor, planner, coder(reviewer)."
