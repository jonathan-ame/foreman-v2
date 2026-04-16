#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${ROOT_DIR}/state"
LATEST_FILE="${STATE_DIR}/ceo-agent-auth-probe-latest.json"
HISTORY_FILE="${STATE_DIR}/ceo-agent-auth-probe-history.jsonl"
HEALTH_SIGNAL_FILE="${STATE_DIR}/ceo-agent-auth-probe-health.txt"

python3 - "${LATEST_FILE}" "${HISTORY_FILE}" "${HEALTH_SIGNAL_FILE}" <<'PY'
import json
import os
import re
import socket
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

latest_path = Path(sys.argv[1])
history_path = Path(sys.argv[2])
health_path = Path(sys.argv[3])


def load_env_file(path: Path) -> dict[str, str]:
    env: dict[str, str] = {}
    if not path.exists():
        return env
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        env[key] = value
    return env


env = dict(os.environ)
env.update(load_env_file(Path.cwd() / ".env"))

api_url = (env.get("PAPERCLIP_API_URL") or "").strip().rstrip("/")
if not api_url:
    raise SystemExit("ERROR: PAPERCLIP_API_URL must be set.")
if not api_url.endswith("/api"):
    api_url = f"{api_url}/api"

ceo_key = (env.get("PAPERCLIP_CEO_AGENT_API_KEY") or "").strip()
if not ceo_key:
    raise SystemExit("ERROR: PAPERCLIP_CEO_AGENT_API_KEY must be set.")

expected_id = "a81ff4a7-5d8b-4a0f-a610-5fcf4cc8a5af"
started = time.time()
now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
status_code: int | None = None
response_text = ""
probe_status = "unknown"
detail = ""

request = urllib.request.Request(
    f"{api_url}/agents/me",
    headers={
        "Authorization": f"Bearer {ceo_key}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    },
    method="GET",
)

try:
    with urllib.request.urlopen(request, timeout=20) as resp:
        status_code = int(resp.getcode())
        response_text = resp.read().decode("utf-8", errors="replace")
except urllib.error.HTTPError as exc:
    status_code = int(exc.code)
    response_text = (exc.read() or b"").decode("utf-8", errors="replace")
except (urllib.error.URLError, socket.timeout, TimeoutError) as exc:
    probe_status = "network_timeout"
    detail = f"network timeout/unreachable: {exc}"
except Exception as exc:  # noqa: BLE001 - explicit unknown transport bucket
    probe_status = "transport_error"
    detail = f"transport error: {exc}"
else:
    if status_code == 401:
        probe_status = "auth_401"
        detail = "agent key unauthorized/revoked/expired"
    elif status_code is not None and status_code >= 500:
        probe_status = "paperclip_api_5xx"
        detail = "paperclip api returned 5xx"
    elif status_code == 200:
        try:
            payload = json.loads(response_text) if response_text else {}
        except json.JSONDecodeError as exc:
            probe_status = "invalid_json"
            detail = f"/agents/me returned invalid JSON: {exc}"
        else:
            got_id = (payload.get("id") or "").strip() if isinstance(payload, dict) else ""
            if got_id != expected_id:
                probe_status = "wrong_agent_id"
                detail = f"/agents/me id mismatch expected={expected_id} got={got_id or '<empty>'}"
            else:
                probe_status = "ok"
                detail = "ceo key authenticated as expected agent id"
    else:
        probe_status = "unexpected_http_status"
        detail = f"unexpected status code {status_code}"

record = {
    "timestamp": now,
    "probe": "ceo_agents_me_auth",
    "expected_agent_id": expected_id,
    "status": probe_status,
    "detail": detail,
    "http_status": status_code,
    "duration_ms": int((time.time() - started) * 1000),
    "response_body_excerpt": re.sub(r"pcp_[A-Za-z0-9]+", "pcp_<redacted>", response_text)[:1200],
}

latest_path.parent.mkdir(parents=True, exist_ok=True)
history_path.parent.mkdir(parents=True, exist_ok=True)
health_path.parent.mkdir(parents=True, exist_ok=True)

tmp = latest_path.with_suffix(".json.tmp")
tmp.write_text(json.dumps(record, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
tmp.replace(latest_path)
with history_path.open("a", encoding="utf-8") as fh:
    fh.write(json.dumps(record, ensure_ascii=True) + "\n")

health_line = (
    f"{record['timestamp']} status={record['status']} http_status={record['http_status']} "
    f"expected_agent_id={expected_id} detail={record['detail']}"
)
health_path.write_text(health_line + "\n", encoding="utf-8")
print(health_line)

if probe_status != "ok":
    raise SystemExit(1)
PY
