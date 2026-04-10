#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_FILE="${ROOT_DIR}/state/p2.6-isolation-pilot.json"

python3 - "${OUT_FILE}" <<'PY'
import json
import os
import time
import urllib.request
import urllib.error

api_base = (os.environ.get("PAPERCLIP_API_BASE") or "http://127.0.0.1:3110/api").rstrip("/")
company_a_name = os.environ.get("PAPERCLIP_COMPANY_A", "Foreman")
company_b_name = os.environ.get("PAPERCLIP_COMPANY_B", "Foreman-Isolation-B")
company_a_id_override = os.environ.get("PAPERCLIP_COMPANY_A_ID", "").strip()
company_b_id_override = os.environ.get("PAPERCLIP_COMPANY_B_ID", "").strip()
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
            try:
                return json.loads(raw) if raw else {}
            except json.JSONDecodeError:
                raise SystemExit(f"ERROR: Paperclip API {method} {path} returned non-JSON response.")
    except urllib.error.HTTPError as exc:
        if exc.code in {401, 403} and not api_token:
            raise SystemExit("ERROR: Paperclip API requires auth. Set PAPERCLIP_API_TOKEN.")
        body = (exc.read() or b"").decode(errors="replace")
        raise SystemExit(f"ERROR: Paperclip API {method} {path} failed with HTTP {exc.code}: {body[:200]}")
    except urllib.error.URLError as exc:
        raise SystemExit(f"ERROR: Paperclip API {method} {path} connection failed: {exc.reason}")

def safe_delete(path: str):
    try:
        req("DELETE", path)
        return True
    except SystemExit:
        return False

companies = req("GET", "/companies")
if not isinstance(companies, list):
    raise SystemExit("ERROR: Paperclip API /companies did not return a list.")
company_items = [c for c in companies if isinstance(c, dict)]
company_a = next((c for c in company_items if c.get("id") == company_a_id_override), None) if company_a_id_override else None
if company_a_id_override and not company_a:
    raise SystemExit(f"ERROR: PAPERCLIP_COMPANY_A_ID '{company_a_id_override}' not found.")
if not company_a:
    company_a = next((c for c in company_items if c.get("name") == company_a_name), None)
if not company_a:
    raise SystemExit(f"ERROR: Company '{company_a_name}' not found.")
if not isinstance(company_a, dict) or not company_a.get("id"):
    raise SystemExit("ERROR: Company A resolution did not return a valid object with id.")

company_b = next((c for c in company_items if c.get("id") == company_b_id_override), None) if company_b_id_override else None
if company_b_id_override and not company_b:
    raise SystemExit(f"ERROR: PAPERCLIP_COMPANY_B_ID '{company_b_id_override}' not found.")
if not company_b:
    company_b = next((c for c in company_items if c.get("name") == company_b_name), None)
if not company_b:
    company_b = req("POST", "/companies", {"name": company_b_name})
if not isinstance(company_b, dict) or not company_b.get("id"):
    raise SystemExit("ERROR: Company B resolution did not return a valid object with id.")

marker_a = f"isolation-a-{int(time.time())}"
marker_b = f"isolation-b-{int(time.time())}"

issue_a = {}
issue_b = {}
cleanup_failures = []
pending_error = None
try:
    issue_a = req(
        "POST",
        f"/companies/{company_a['id']}/issues",
        {"title": marker_a, "description": "isolation test A", "status": "todo", "priority": "low"},
    )
    if not isinstance(issue_a, dict) or not issue_a.get("id"):
        raise SystemExit("ERROR: Company A issue creation returned invalid response.")
    issue_b = req(
        "POST",
        f"/companies/{company_b['id']}/issues",
        {"title": marker_b, "description": "isolation test B", "status": "todo", "priority": "low"},
    )
    if not isinstance(issue_b, dict) or not issue_b.get("id"):
        raise SystemExit("ERROR: Company B issue creation returned invalid response.")

    issues_a = req("GET", f"/companies/{company_a['id']}/issues")
    issues_b = req("GET", f"/companies/{company_b['id']}/issues")
    if not isinstance(issues_a, list) or not isinstance(issues_b, list):
        raise SystemExit("ERROR: Company issues response was not a list.")

    titles_a = {i.get("title") for i in issues_a if isinstance(i, dict)}
    titles_b = {i.get("title") for i in issues_b if isinstance(i, dict)}

    if marker_a not in titles_a:
        raise SystemExit("ERROR: Company A cannot see its own isolation marker.")
    if marker_b not in titles_b:
        raise SystemExit("ERROR: Company B cannot see its own isolation marker.")
    if marker_b in titles_a:
        raise SystemExit("ERROR: Company A can see company B marker (isolation breach).")
    if marker_a in titles_b:
        raise SystemExit("ERROR: Company B can see company A marker (isolation breach).")
except SystemExit as exc:
    pending_error = exc
finally:
    # Cleanup pilot issues to avoid accumulating test rows on repeated runs.
    if isinstance(issue_a, dict) and issue_a.get("id"):
        if not safe_delete(f"/issues/{issue_a['id']}"):
            cleanup_failures.append(f"/issues/{issue_a['id']}")
    if isinstance(issue_b, dict) and issue_b.get("id"):
        if not safe_delete(f"/issues/{issue_b['id']}"):
            cleanup_failures.append(f"/issues/{issue_b['id']}")

if cleanup_failures and pending_error is not None:
    raise SystemExit(
        f"{pending_error}. Cleanup also failed for {', '.join(cleanup_failures)}"
    )
if cleanup_failures:
    raise SystemExit(f"ERROR: Isolation cleanup failed for {', '.join(cleanup_failures)}")
if pending_error is not None:
    raise pending_error

payload = {
    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "api_base": api_base,
    "company_a": {"id": company_a["id"], "name": company_a["name"], "marker": marker_a, "issue_id": issue_a.get("id")},
    "company_b": {"id": company_b["id"], "name": company_b["name"], "marker": marker_b, "issue_id": issue_b.get("id")},
    "verification": {
        "a_sees_a": True,
        "b_sees_b": True,
        "a_sees_b": False,
        "b_sees_a": False,
    },
}

os.makedirs(os.path.dirname(out_file), exist_ok=True)
tmp = out_file + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")
os.replace(tmp, out_file)

print("ISOLATION_OK")
print(f"EVIDENCE: {out_file}")
PY
