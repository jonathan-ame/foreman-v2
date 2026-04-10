#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE_FILE="${ROOT_DIR}/state/p2.5-pilot-run.json"

bash "${ROOT_DIR}/scripts/paperclip-scheduler-pilot.sh"

python3 - "${EVIDENCE_FILE}" <<'PY'
import json
import os
import sys

path = os.path.abspath(sys.argv[1])
if not os.path.exists(path):
    raise SystemExit(f"ERROR: Missing pilot evidence file: {path}")

with open(path, "r", encoding="utf-8") as f:
    payload = json.load(f)

run = payload.get("run") or {}
if run.get("status") != "succeeded":
    raise SystemExit(f"ERROR: Pilot status is not succeeded: {run.get('status')}")

stdout_excerpt = str(run.get("stdout_excerpt") or "")
if "HEARTBEAT_OK" not in stdout_excerpt:
    raise SystemExit("ERROR: Pilot output missing HEARTBEAT_OK marker.")

print(f"VALIDATION_OK run={run.get('id')}")
print(f"EVIDENCE: {path}")
PY
