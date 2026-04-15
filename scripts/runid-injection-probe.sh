#!/usr/bin/env bash
set -euo pipefail

# RunID injection environment probe
# Validates that PAPERCLIP_RUN_ID is properly injected into the environment

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${ROOT_DIR}/state"
PROBE_FILE="${STATE_DIR}/runid-injection-probe-latest.json"
HISTORY_FILE="${STATE_DIR}/runid-injection-probe-history.jsonl"
HEALTH_FILE="${STATE_DIR}/runid-injection-probe-health.txt"

python3 - "${PROBE_FILE}" "${HISTORY_FILE}" "${HEALTH_FILE}" <<'PY'
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

probe_path = Path(sys.argv[1])
history_path = Path(sys.argv[2])
health_path = Path(sys.argv[3])

now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

# Check for required environment variables
run_id = os.environ.get("PAPERCLIP_RUN_ID")
company_id = os.environ.get("PAPERCLIP_COMPANY_ID")
agent_id = os.environ.get("PAPERCLIP_AGENT_ID")
api_key = os.environ.get("PAPERCLIP_API_KEY")
api_url = os.environ.get("PAPERCLIP_API_URL")

def check_var(name, value):
    if not value or not value.strip():
        return f"missing", f"{name} environment variable is not set"
    return "present", f"{name} is present"

run_id_status, run_id_detail = check_var("PAPERCLIP_RUN_ID", run_id)
company_id_status, company_id_detail = check_var("PAPERCLIP_COMPANY_ID", company_id)
agent_id_status, agent_id_detail = check_var("PAPERCLIP_AGENT_ID", agent_id)
api_key_status, api_key_detail = check_var("PAPERCLIP_API_KEY", api_key)
api_url_status, api_url_detail = check_var("PAPERCLIP_API_URL", api_url)

# Overall status
if (run_id_status == "present" and 
    company_id_status == "present" and 
    agent_id_status == "present" and 
    api_key_status == "present" and 
    api_url_status == "present"):
    overall_status = "ok"
    overall_detail = "All required Paperclip environment variables are present"
else:
    overall_status = "incomplete"
    overall_detail = "Missing one or more required Paperclip environment variables"

record = {
    "timestamp": now,
    "probe": "runid_injection",
    "status": overall_status,
    "detail": overall_detail,
    "variables": {
        "PAPERCLIP_RUN_ID": {
            "status": run_id_status,
            "detail": run_id_detail,
            "value": run_id[:8] + "..." if run_id and len(run_id) > 8 else run_id
        },
        "PAPERCLIP_COMPANY_ID": {
            "status": company_id_status,
            "detail": company_id_detail,
            "value": company_id[:8] + "..." if company_id and len(company_id) > 8 else company_id
        },
        "PAPERCLIP_AGENT_ID": {
            "status": agent_id_status,
            "detail": agent_id_detail,
            "value": agent_id[:8] + "..." if agent_id and len(agent_id) > 8 else agent_id
        },
        "PAPERCLIP_API_KEY": {
            "status": api_key_status,
            "detail": api_key_detail,
            "value": "present" if api_key else "missing"
        },
        "PAPERCLIP_API_URL": {
            "status": api_url_status,
            "detail": api_url_detail,
            "value": api_url[:50] + "..." if api_url and len(api_url) > 50 else api_url
        }
    }
}

# Write results
probe_path.parent.mkdir(parents=True, exist_ok=True)
history_path.parent.mkdir(parents=True, exist_ok=True)
health_path.parent.mkdir(parents=True, exist_ok=True)

tmp = probe_path.with_suffix(".json.tmp")
tmp.write_text(json.dumps(record, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
tmp.replace(probe_path)

with history_path.open("a", encoding="utf-8") as fh:
    fh.write(json.dumps(record, ensure_ascii=True) + "\n")

health_line = (
    f"{record['timestamp']} status={record['status']} "
    f"run_id={run_id_status} company_id={company_id_status} "
    f"agent_id={agent_id_status} api_key={api_key_status} api_url={api_url_status}"
)
health_path.write_text(health_line + "\n", encoding="utf-8")
print(health_line)

if overall_status != "ok":
    raise SystemExit(1)
PY