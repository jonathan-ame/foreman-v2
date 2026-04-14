#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROUTING_FILE="${ROOT_DIR}/config/role-routing.json"
OPENCLAW_CONFIG="${HOME}/.openclaw/openclaw.json"
OUT_FILE="${ROOT_DIR}/state/p2.2-routing-consistency.json"

python3 - "${ROUTING_FILE}" "${OPENCLAW_CONFIG}" "${OUT_FILE}" "${ROOT_DIR}" <<'PY'
import json
import sys
from pathlib import Path

routing_path, oc_path, out_path = [Path(p) for p in sys.argv[1:4]]
root_dir = Path(sys.argv[4])
sys.path.insert(0, str(root_dir / "scripts" / "lib"))
from openclaw_config_helper import read_openclaw_config_atomic

for p in [routing_path, oc_path]:
    if not p.exists():
        raise SystemExit(f"ERROR: Missing required file: {p}")

routing = json.loads(routing_path.read_text(encoding="utf-8"))
oc, _ = read_openclaw_config_atomic(oc_path, attempts=5, delay_seconds=0.25)

roles = routing.get("roles") or {}
required_roles = {"executor", "planner", "embedding", "reviewer"}
if not required_roles.issubset(set(roles.keys())):
    raise SystemExit("ERROR: role-routing must include executor/planner/embedding/reviewer roles.")

providers = (((oc.get("models") or {}).get("providers") or {}))

report = {"checks": []}
for role in sorted(roles.keys()):
    rcfg = roles[role]
    provider_name = rcfg.get("provider")
    model_id = rcfg.get("model_id")
    provider = providers.get(provider_name) or {}
    provider_base = provider.get("baseUrl")
    provider_models = provider.get("models") or []
    provider_model_ids = [m.get("id") for m in provider_models if isinstance(m, dict)]

    if not provider_base:
        raise SystemExit(f"ERROR: provider '{provider_name}' missing baseUrl in OpenClaw config.")
    if model_id not in provider_model_ids:
        raise SystemExit(
            f"ERROR: role '{role}' model {model_id} not present in OpenClaw provider '{provider_name}'"
        )

    report["checks"].append(
        {
            "role": role,
            "provider": provider_name,
            "model_id": model_id,
            "base_url": provider_base,
            "status": "ok",
        }
    )

out_path.parent.mkdir(parents=True, exist_ok=True)
tmp_path = out_path.with_suffix(out_path.suffix + ".tmp")
tmp_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
tmp_path.replace(out_path)
print(f"CONSISTENCY_OK {out_path}")
PY
