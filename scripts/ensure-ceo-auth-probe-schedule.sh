#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - <<'PY'
import json
import os
import urllib.error
import urllib.request
from pathlib import Path


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

supabase_url = (env.get("SUPABASE_PROJECT_URL") or "").strip().rstrip("/")
supabase_key = (env.get("SUPABASE_SERVICE_ROLE") or "").strip()
if not supabase_url or not supabase_key:
    raise SystemExit("ERROR: SUPABASE_PROJECT_URL and SUPABASE_SERVICE_ROLE are required.")

schedule_name = "ceo-agent-auth-probe-daily"
workspace_slug = "foreman"
agent_id = "a81ff4a7-5d8b-4a0f-a610-5fcf4cc8a5af"

instruction = (
    "Run the local command `./scripts/ceo-agent-auth-probe.sh` from repo root. "
    "If it fails, classify one of: auth_401, paperclip_api_5xx, network_timeout, wrong_agent_id. "
    "Then summarize the latest status from state/ceo-agent-auth-probe-latest.json."
)
payload = [
    {
        "workspace_slug": workspace_slug,
        "agent_id": agent_id,
        "schedule_name": schedule_name,
        "cron_expression": "17 9 * * *",
        "timezone": "UTC",
        "instruction_template": instruction,
        "skip_if_pending": True,
        "is_active": True,
    }
]
headers = {
    "Authorization": f"Bearer {supabase_key}",
    "apikey": supabase_key,
    "Content-Type": "application/json",
    "Accept": "application/json",
}

select_url = (
    f"{supabase_url}/rest/v1/agent_schedules"
    "?select=id,workspace_slug,agent_id,schedule_name,cron_expression,timezone,is_active"
    f"&workspace_slug=eq.{workspace_slug}"
    f"&agent_id=eq.{agent_id}"
    f"&schedule_name=eq.{schedule_name}"
    "&limit=1"
)
select_req = urllib.request.Request(select_url, headers=headers, method="GET")
try:
    with urllib.request.urlopen(select_req, timeout=60) as resp:
        selected = json.loads(resp.read().decode("utf-8") or "[]")
except urllib.error.HTTPError as exc:
    detail = (exc.read() or b"").decode("utf-8", errors="replace")
    raise SystemExit(f"ERROR: schedule lookup failed HTTP {exc.code}: {detail[:500]}")

if isinstance(selected, list) and selected:
    schedule_id = (selected[0].get("id") or "").strip()
    if not schedule_id:
        raise SystemExit("ERROR: existing schedule row missing id.")
    patch_url = f"{supabase_url}/rest/v1/agent_schedules?id=eq.{schedule_id}"
    patch_req = urllib.request.Request(
        patch_url,
        data=json.dumps(payload[0]).encode("utf-8"),
        headers={**headers, "Prefer": "return=representation"},
        method="PATCH",
    )
    try:
        with urllib.request.urlopen(patch_req, timeout=60) as resp:
            rows = json.loads(resp.read().decode("utf-8") or "[]")
    except urllib.error.HTTPError as exc:
        detail = (exc.read() or b"").decode("utf-8", errors="replace")
        raise SystemExit(f"ERROR: schedule patch failed HTTP {exc.code}: {detail[:500]}")
else:
    post_url = f"{supabase_url}/rest/v1/agent_schedules"
    post_req = urllib.request.Request(
        post_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={**headers, "Prefer": "return=representation"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(post_req, timeout=60) as resp:
            rows = json.loads(resp.read().decode("utf-8") or "[]")
    except urllib.error.HTTPError as exc:
        detail = (exc.read() or b"").decode("utf-8", errors="replace")
        raise SystemExit(f"ERROR: schedule create failed HTTP {exc.code}: {detail[:500]}")

if not isinstance(rows, list) or not rows:
    raise SystemExit("ERROR: schedule upsert returned no rows.")
row = rows[0] if isinstance(rows[0], dict) else {}
print(
    json.dumps(
        {
            "workspace_slug": row.get("workspace_slug"),
            "agent_id": row.get("agent_id"),
            "schedule_name": row.get("schedule_name"),
            "cron_expression": row.get("cron_expression"),
            "timezone": row.get("timezone"),
            "is_active": row.get("is_active"),
        },
        ensure_ascii=True,
    )
)
PY
