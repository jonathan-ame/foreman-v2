#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_FILE="${ROOT_DIR}/state/p2.5-pilot-run.json"

python3 - "${OUT_FILE}" <<'PY'
import json
import os
import time
import urllib.request
import urllib.error

api_base = (os.environ.get("PAPERCLIP_API_BASE") or "http://127.0.0.1:3110/api").rstrip("/")
company_name = os.environ.get("PAPERCLIP_COMPANY_NAME", "Foreman")
target_agent_name = os.environ.get("PAPERCLIP_PILOT_AGENT", "ChiefOfStaff")
api_token = os.environ.get("PAPERCLIP_API_TOKEN", "").strip()
out_file = os.path.abspath(__import__("sys").argv[1])

def req(method: str, path: str, payload=None):
    data = None
    headers = {"Content-Type": "application/json"}
    if api_token:
        headers["Authorization"] = f"Bearer {api_token}"
    if payload is not None:
        data = json.dumps(payload).encode()
    request = urllib.request.Request(f"{api_base}{path}", data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=60) as resp:
            raw = resp.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        if exc.code in {401, 403} and not api_token:
            raise SystemExit("ERROR: Paperclip API requires auth. Set PAPERCLIP_API_TOKEN.")
        body = (exc.read() or b"").decode(errors="replace")
        raise SystemExit(f"ERROR: Paperclip API {method} {path} failed with HTTP {exc.code}: {body[:200]}")
    except urllib.error.URLError as exc:
        raise SystemExit(f"ERROR: Paperclip API {method} {path} connection failed: {exc.reason}")

companies = req("GET", "/companies")
company = next((c for c in companies if c.get("name") == company_name), None)
if not company:
    raise SystemExit(f"ERROR: Company '{company_name}' not found.")

agents = req("GET", f"/companies/{company['id']}/agents")
agent = next((a for a in agents if a.get("name") == target_agent_name), None)
if not agent:
    raise SystemExit(f"ERROR: Agent '{target_agent_name}' not found.")

run = req("POST", f"/agents/{agent['id']}/heartbeat/invoke", {})
run_id = run.get("id")
if not isinstance(run_id, str) or not run_id:
    raise SystemExit(f"ERROR: Unexpected heartbeat invoke response: {run!r}")
final = None
for _ in range(60):
    cur = req("GET", f"/heartbeat-runs/{run_id}")
    if cur.get("status") in {"succeeded", "failed", "cancelled"}:
        final = cur
        break
    time.sleep(2)

if not final:
    raise SystemExit(f"ERROR: Timed out waiting for run {run_id}.")

payload = {
    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "api_base": api_base,
    "company": {"id": company["id"], "name": company["name"]},
    "job_id": "p2.5-pilot-chief-of-staff-heartbeat",
    "agent": {"id": agent["id"], "name": agent["name"]},
    "run": {
        "id": run_id,
        "status": final.get("status"),
        "error": final.get("error"),
        "stdout_excerpt": (final.get("stdoutExcerpt") or "")[:2000],
        "stderr_excerpt": (final.get("stderrExcerpt") or "")[:1200],
    },
}
os.makedirs(os.path.dirname(out_file), exist_ok=True)
tmp = out_file + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")
os.replace(tmp, out_file)

if final.get("status") != "succeeded":
    raise SystemExit(f"ERROR: Pilot run failed ({run_id}): {final.get('error')}")

print(f"PILOT_OK run={run_id} agent={agent['name']}")
print(f"EVIDENCE: {out_file}")
PY
