#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROUTING_FILE="${ROOT_DIR}/config/role-routing.json"
STATE_FILE="${ROOT_DIR}/state/pods.json"
OPENCLAW_CONFIG="${HOME}/.openclaw/openclaw.json"
OUT_FILE="${ROOT_DIR}/state/p2.2-routing-consistency.json"

python3 - "${ROUTING_FILE}" "${STATE_FILE}" "${OPENCLAW_CONFIG}" "${OUT_FILE}" <<'PY'
import json
import sys
from pathlib import Path
from urllib.parse import urlparse

routing_path, state_path, oc_path, out_path = [Path(p) for p in sys.argv[1:5]]
for p in [routing_path, state_path, oc_path]:
    if not p.exists():
        raise SystemExit(f"ERROR: Missing required file: {p}")

routing = json.loads(routing_path.read_text(encoding="utf-8"))
state = json.loads(state_path.read_text(encoding="utf-8"))
oc = json.loads(oc_path.read_text(encoding="utf-8"))

roles = routing.get("roles") or {}
required_roles = {"executor", "planner", "embedding"}
if not required_roles.issubset(set(roles.keys())):
    raise SystemExit(
        "ERROR: role-routing must include executor/planner/embedding roles."
    )

pods = {p.get("logical_name"): p for p in state.get("pods", []) if isinstance(p, dict)}
providers = (((oc.get("models") or {}).get("providers") or {}))

report = {"checks": []}
def normalize_base(url: str) -> str:
    parsed = urlparse(url)
    path = parsed.path.rstrip("/")
    return f"{parsed.scheme}://{parsed.netloc}{path}"

for role in sorted(roles.keys()):
    rcfg = roles[role]
    provider_name = rcfg.get("provider")
    pod_role = rcfg.get("pod_role")
    model_id = rcfg.get("model_id")

    pod = pods.get(pod_role)
    if not pod:
        raise SystemExit(f"ERROR: Missing pod for role '{role}' (pod_role={pod_role})")
    provider = providers.get(provider_name) or {}
    p_base = provider.get("baseUrl")
    p_models = provider.get("models") or []
    provider_model_ids = [m.get("id") for m in p_models if isinstance(m, dict)]

    if pod.get("model_id") != model_id:
        raise SystemExit(
            f"ERROR: role '{role}' model mismatch with state/pods.json: "
            f"{model_id} != {pod.get('model_id')}"
        )
    if normalize_base(str(p_base or "")) != normalize_base(str(pod.get("base_url") or "")):
        raise SystemExit(
            f"ERROR: role '{role}' base URL mismatch between OpenClaw provider and state/pods.json"
        )
    if model_id not in provider_model_ids:
        raise SystemExit(
            f"ERROR: role '{role}' model {model_id} not present in OpenClaw provider '{provider_name}'"
        )

    report["checks"].append(
        {
            "role": role,
            "provider": provider_name,
            "model_id": model_id,
            "pod_id": pod.get("pod_id"),
            "base_url": pod.get("base_url"),
            "status": "ok",
        }
    )

out_path.parent.mkdir(parents=True, exist_ok=True)
tmp_path = out_path.with_suffix(out_path.suffix + ".tmp")
tmp_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
tmp_path.replace(out_path)
print(f"CONSISTENCY_OK {out_path}")
PY
