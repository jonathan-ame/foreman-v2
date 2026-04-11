#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
EVIDENCE_FILE="${ROOT_DIR}/state/p2.2-role-verifier.json"

python3 - "${EVIDENCE_FILE}" <<'PY'
import json
import os
import time
import urllib.request
import urllib.error
from pathlib import Path

api_base = os.environ.get("PAPERCLIP_API_BASE", "http://127.0.0.1:3110/api").rstrip("/")
company_name = os.environ.get("PAPERCLIP_COMPANY_NAME", "Foreman")
api_token = os.environ.get("PAPERCLIP_API_TOKEN", "").strip()
targets_env = os.environ.get("PAPERCLIP_VERIFY_TARGETS", "").strip()
if targets_env:
    try:
        loaded = json.loads(targets_env)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"ERROR: PAPERCLIP_VERIFY_TARGETS is not valid JSON: {exc}")
    if not isinstance(loaded, list):
        raise SystemExit("ERROR: PAPERCLIP_VERIFY_TARGETS must be a JSON array.")
    targets = []
    for item in loaded:
        if not isinstance(item, dict) or not isinstance(item.get("agent"), str) or not isinstance(item.get("marker"), str):
            raise SystemExit("ERROR: PAPERCLIP_VERIFY_TARGETS entries must be objects with 'agent' and 'marker'.")
        targets.append((item["agent"], item["marker"]))
else:
    targets = [
        ("CEO", "HEARTBEAT_OK:executor"),
        ("OpenClawWorker", "HEARTBEAT_OK:planner"),
        ("EmbeddingWorker", "HEARTBEAT_OK:embedding"),
        ("ReviewerWorker", "HEARTBEAT_OK:reviewer"),
    ]
evidence_path = Path(os.path.abspath(__import__("sys").argv[1]))
evidence_path.parent.mkdir(parents=True, exist_ok=True)

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
            raise SystemExit(
                "ERROR: Paperclip API requires auth. Set PAPERCLIP_API_TOKEN for verifier requests."
            )
        body = (exc.read() or b"").decode(errors="replace")
        raise SystemExit(f"ERROR: Paperclip API {method} {path} failed with HTTP {exc.code}: {body[:200]}")

companies = req("GET", "/companies")
company = next((c for c in companies if c.get("name") == company_name), None)
if not company:
    raise SystemExit(f"ERROR: Company '{company_name}' not found at {api_base}.")
company_id = company["id"]

agents = req("GET", f"/companies/{company_id}/agents")
agent_by_name = {a.get("name"): a for a in agents}

results = []
for name, marker in targets:
    agent = agent_by_name.get(name)
    if not agent:
        raise SystemExit(f"ERROR: Required agent '{name}' not found.")
    run = req("POST", f"/agents/{agent['id']}/heartbeat/invoke", {})
    run_id = run["id"]
    final = None
    for _ in range(60):
        cur = req("GET", f"/heartbeat-runs/{run_id}")
        if cur.get("status") in {"succeeded", "failed", "cancelled"}:
            final = cur
            break
        time.sleep(2)
    if not final:
        raise SystemExit(f"ERROR: Timed out waiting for run {run_id} ({name}).")
    status = final.get("status")
    stdout = str(final.get("stdoutExcerpt") or "")
    if status != "succeeded":
        raise SystemExit(f"ERROR: {name} run failed ({run_id}): {final.get('error')}")
    if marker not in stdout:
        raise SystemExit(f"ERROR: {name} run {run_id} missing marker '{marker}'.")
    results.append(
        {
            "agent_name": name,
            "agent_id": agent["id"],
            "expected_marker": marker,
            "run_id": run_id,
            "status": status,
            "stdout_excerpt": stdout[:500],
        }
    )

payload = {
    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "api_base": api_base,
    "company": {"id": company_id, "name": company_name},
    "results": results,
}

tmp_path = evidence_path.with_suffix(evidence_path.suffix + ".tmp")
with open(tmp_path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")
os.replace(tmp_path, evidence_path)

for item in results:
    print(f"{item['agent_name']}: {item['status']} ({item['run_id']})")
print(f"EVIDENCE: {evidence_path}")
PY
