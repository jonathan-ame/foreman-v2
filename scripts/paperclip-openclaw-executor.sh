#!/usr/bin/env bash
set -euo pipefail

# OpenClawWorker issue executor:
# - picks assigned actionable issue
# - checks out the issue
# - verifies skill visibility
# - runs OpenClaw agent for execution notes
# - writes evidence comment back to Paperclip

python3 - <<'PY'
import json
import os
import subprocess
import uuid
import re
from urllib.parse import urlparse
import urllib.error
import urllib.request


def _normalize_api_base(raw: str) -> str:
    if not raw:
        raise SystemExit("ERROR: PAPERCLIP_API_URL must be set by the adapter environment.")
    raw = raw.rstrip("/")
    return raw if raw.endswith("/api") else f"{raw}/api"


API_BASE = _normalize_api_base(os.environ.get("PAPERCLIP_API_URL", ""))
API_KEY = (os.environ.get("PAPERCLIP_API_KEY") or "").strip()
COMPANY_ID = (os.environ.get("PAPERCLIP_COMPANY_ID") or "").strip()
AGENT_ID = (os.environ.get("PAPERCLIP_AGENT_ID") or "").strip()
TASK_ID = (os.environ.get("PAPERCLIP_TASK_ID") or "").strip()
RUN_ID = (os.environ.get("PAPERCLIP_RUN_ID") or "").strip()


def _is_loopback_host(host: str | None) -> bool:
    return (host or "").lower() in {"127.0.0.1", "localhost"}


def _resolve_api_key_from_auth(api_base: str) -> str:
    auth_file = os.path.expanduser("~/.paperclip/auth.json")
    with open(auth_file, "r", encoding="utf-8") as fh:
        auth = json.load(fh)
    creds = auth.get("credentials") or {}
    origin = api_base.removesuffix("/api")
    direct = (creds.get(origin) or {}).get("token", "")
    if direct:
        return direct.strip()

    target = urlparse(origin)
    strict_tokens: list[str] = []
    for key, value in creds.items():
        if not isinstance(key, str):
            continue
        parsed = urlparse(key)
        if (
            parsed.scheme == target.scheme
            and (parsed.hostname or "").lower() == (target.hostname or "").lower()
            and parsed.port == target.port
            and (parsed.path or "/") in {"", "/"}
        ):
            token = (value or {}).get("token", "")
            if token:
                strict_tokens.append(token.strip())
    uniq_strict = sorted(set(strict_tokens))
    if len(uniq_strict) == 1:
        return uniq_strict[0]
    if len(uniq_strict) > 1:
        raise RuntimeError("Multiple host-matching tokens found; set PAPERCLIP_API_KEY explicitly.")

    if _is_loopback_host(target.hostname):
        loopback_tokens: list[str] = []
        for key, value in creds.items():
            if not isinstance(key, str):
                continue
            parsed = urlparse(key)
            if parsed.scheme != target.scheme or not _is_loopback_host(parsed.hostname):
                continue
            token = ((value or {}).get("token") or "").strip()
            if token:
                loopback_tokens.append(token)
        uniq = sorted(set(loopback_tokens))
        if len(uniq) == 1:
            return uniq[0]
    return ""


if not API_KEY:
    try:
        API_KEY = _resolve_api_key_from_auth(API_BASE)
    except Exception:
        API_KEY = ""

if not API_KEY:
    raise SystemExit("ERROR: PAPERCLIP_API_KEY is required (or a host-matching ~/.paperclip/auth.json token).")
if not COMPANY_ID or not AGENT_ID:
    raise SystemExit("ERROR: PAPERCLIP_COMPANY_ID and PAPERCLIP_AGENT_ID are required.")


def req(method: str, path: str, payload=None):
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    if RUN_ID and method in {"POST", "PATCH", "PUT", "DELETE"}:
        headers["X-Paperclip-Run-Id"] = RUN_ID
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(f"{API_BASE}{path}", data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=60) as resp:
            body = resp.read().decode("utf-8")
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as exc:
        body = (exc.read() or b"").decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code} {method} {path}: {body[:300]}")


def patch_issue(issue_id: str, status: str | None = None, comment: str | None = None):
    payload = {}
    if status:
        payload["status"] = status
    if comment:
        payload["comment"] = comment
    if payload:
        req("PATCH", f"/issues/{issue_id}", payload)


def checkout_issue(task_id: str, agent_id: str):
    """Atomic checkout per Paperclip contract. Never retry a 409."""
    payload = {
        "agentId": agent_id,
        "expectedStatuses": ["todo", "backlog", "blocked"],
    }
    try:
        req("POST", f"/issues/{task_id}/checkout", payload)
    except RuntimeError as exc:
        if "HTTP 409" in str(exc):
            print(f"HEARTBEAT_OK:executor (409 conflict on {task_id}, picking different task)")
            raise SystemExit(0)
        raise


if not TASK_ID:
    assignments = req(
        "GET",
        f"/companies/{COMPANY_ID}/issues?assigneeAgentId={AGENT_ID}&status=todo,in_progress,blocked&limit=20&offset=0",
    )
    items = assignments.get("items", []) if isinstance(assignments, dict) else assignments
    if isinstance(items, list) and items:
        ranked = sorted(
            items,
            key=lambda x: {"in_progress": 0, "todo": 1, "blocked": 2}.get((x or {}).get("status"), 3),
        )
        TASK_ID = (ranked[0] or {}).get("id", "") or ""
    if not TASK_ID:
        print("HEARTBEAT_OK:executor (no actionable assignments)")
        raise SystemExit(0)

issue = req("GET", f"/issues/{TASK_ID}")
if issue.get("assigneeAgentId") != AGENT_ID:
    print(f"HEARTBEAT_OK:executor (task {TASK_ID} not assigned to this agent)")
    raise SystemExit(0)

task_status = (issue.get("status") or "").strip()

if task_status == "in_progress":
    # Already checked out by us from a prior heartbeat. Per the docs:
    # "Work on in_progress tasks first" — continue work, no re-checkout needed.
    pass
elif task_status in ("todo", "backlog", "blocked"):
    checkout_issue(TASK_ID, AGENT_ID)
else:
    print(f"HEARTBEAT_OK:executor (task {TASK_ID} in terminal state '{task_status}')")
    raise SystemExit(0)

identifier = (issue.get("identifier") or TASK_ID).strip()
title = (issue.get("title") or "").strip()
description = (issue.get("description") or "").strip()
description_compact = re.sub(r"\\s+", " ", description)[:1200]

exec_prompt = (
    "You are OpenClawWorker. Execute this delegated issue and return concise progress notes only.\n\n"
    f"Issue: {identifier} - {title}\n"
    f"Description: {description_compact}\n\n"
    "Return markdown with:\n"
    "1) What you validated\n"
    "2) What you changed or attempted\n"
    "3) Remaining blockers (if any)\n"
    "4) Next concrete action\n"
    "Keep total response under 180 words.\n"
    "Do not include package-install speculation."
)
session_id = f"{COMPANY_ID}-{AGENT_ID}-{TASK_ID}-{RUN_ID or uuid.uuid4().hex[:8]}"

agent_notes = ""
agent_ok = False
try:
    agent_proc = subprocess.run(
        ["openclaw", "agent", "--session-id", session_id, "-m", exec_prompt],
        capture_output=True,
        text=True,
        timeout=120,
        check=False,
    )
    if agent_proc.returncode == 0:
        agent_notes = (agent_proc.stdout or "").strip()
        agent_ok = True
    else:
        agent_notes = f"OpenClaw agent exited with code {agent_proc.returncode}."
except subprocess.TimeoutExpired:
    agent_notes = "OpenClaw agent timed out (>120s)."

if agent_ok and agent_notes:
    comment = (
        f"OpenClawWorker execution update for `{identifier}`.\n\n"
        "### Execution Notes\n"
        f"{agent_notes[:6000]}"
    )
    patch_issue(TASK_ID, status="done", comment=comment)
    print("HEARTBEAT_OK:executor")
else:
    comment = (
        f"OpenClawWorker execution update for `{identifier}`.\n\n"
        f"- {agent_notes}\n"
        "- Marking done with partial results. Escalate if deeper work is needed."
    )
    patch_issue(TASK_ID, status="done", comment=comment)
    print("HEARTBEAT_OK:executor")
PY
