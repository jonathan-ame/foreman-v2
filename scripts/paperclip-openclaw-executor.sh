#!/usr/bin/env bash
set -euo pipefail

# OpenClawWorker issue executor:
# - picks assigned actionable issue (Paperclip heartbeat protocol)
# - checks out the issue (single attempt; 409 => exit per docs)
# - runs one `openclaw agent` call bounded by adapter timeoutSec
# - on success => done + comment; on failure => blocked + comment (no custom retry loops)

python3 - <<'PY'
import json
import os
import re
import subprocess
import time
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
WAKE_REASON = (os.environ.get("PAPERCLIP_WAKE_REASON") or "").strip()


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


def fetch_agent_adapter_timeout_sec() -> int:
    """Match OpenClaw subprocess budget to Paperclip process adapter timeoutSec."""
    try:
        me = req("GET", "/agents/me")
        cfg = me.get("adapterConfig") if isinstance(me.get("adapterConfig"), dict) else {}
        raw = int(cfg.get("timeoutSec") or 300)
        return max(120, min(raw, 3600))
    except Exception:
        return 300


def is_openclaw_llm_outcome_failure(text: str) -> bool:
    """
    OpenClaw `openclaw agent` often exits 0 while printing a *user-facing failure line*
    (see openclaw dist/errors-DVZmaL5J.js formatAssistantErrorText). Treat those as not delivered.
    """
    t = (text or "").strip().lower()
    if not t:
        return True
    needles = (
        "llm request timed out",
        "llm request rate limited",
        "llm request unauthorized",
        "llm request failed",
        "llm request rejected:",
        "context overflow:",
        "llm request failed: provider returned an invalid streaming response",
        "message ordering conflict",
        "session history looks corrupted",
    )
    if any(n in t for n in needles):
        return True
    # Short shrift: tiny stdout that only signals failure
    if len(t) < 120 and ("timed out" in t or "rate limit" in t or "unauthorized" in t):
        return True
    return False


def resolve_openclaw_subprocess_timeout_sec() -> int:
    """
    Inner `openclaw agent` must finish before the adapter kills the whole process.
    Reserve ~25s for Paperclip API calls and Python overhead.
    """
    adapter_sec = fetch_agent_adapter_timeout_sec()
    inner = adapter_sec - 25
    override = (os.environ.get("FOREMAN_OPENCLAW_AGENT_TIMEOUT_SEC") or "").strip()
    if override.isdigit():
        inner = int(override)
    return max(90, min(inner, adapter_sec - 10))


def wait_for_wake_issue_ready(initial_task_id: str, max_wait_sec: int = 20) -> str:
    """
    Comment/reopen wakes can race the DB: issue may not yet be todo+assigned when the process starts.
    Poll until the wake task is actionable for this agent. If the issue stays terminal after
    the deadline, return it anyway — the main status-check block will handle reopening.
    """
    if not initial_task_id:
        return ""
    deadline = time.time() + max_wait_sec
    while time.time() < deadline:
        try:
            issue = req("GET", f"/issues/{initial_task_id}")
        except Exception:
            time.sleep(1)
            continue
        if issue.get("assigneeAgentId") != AGENT_ID:
            time.sleep(1)
            continue
        st = (issue.get("status") or "").strip()
        if st in ("todo", "backlog", "blocked", "in_progress"):
            return initial_task_id
        time.sleep(1)
    return initial_task_id


def fetch_latest_user_comments(issue_id: str, limit: int = 5) -> str:
    """Fetch recent comments on an issue to include user follow-up context in the prompt."""
    try:
        resp = req("GET", f"/issues/{issue_id}/comments?limit={limit}&offset=0")
        items = resp if isinstance(resp, list) else resp.get("items", [])
    except Exception:
        return ""
    user_comments = []
    for c in items:
        body = (c.get("body") or c.get("comment") or c.get("content") or "").strip()
        author_agent = c.get("authorAgentId") or c.get("agentId") or ""
        if author_agent and author_agent == AGENT_ID:
            continue
        if body:
            user_comments.append(body)
    if not user_comments:
        return ""
    combined = "\n---\n".join(user_comments[:3])
    return combined[:2000]


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


def claim_issue(task_id: str):
    """
    Transition issue to in_progress. Uses direct PATCH instead of the checkout endpoint
    because checkout retains a stale executionRunId from prior runs, permanently blocking
    re-checkout of any previously-worked issue (409 conflict even when the issue is todo).
    """
    req("PATCH", f"/issues/{task_id}", {"status": "in_progress"})


wake_task = TASK_ID
if wake_task and (WAKE_REASON or "").strip():
    wake_task = wait_for_wake_issue_ready(wake_task)
TASK_ID = wake_task or TASK_ID

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
    pass
elif task_status in ("todo", "backlog", "blocked", "done", "cancelled", "in_review"):
    try:
        claim_issue(TASK_ID)
    except Exception:
        print(f"HEARTBEAT_OK:executor (could not claim task {TASK_ID} from '{task_status}')")
        raise SystemExit(0)
else:
    print(f"HEARTBEAT_OK:executor (task {TASK_ID} in terminal state '{task_status}')")
    raise SystemExit(0)

identifier = (issue.get("identifier") or TASK_ID).strip()
title = (issue.get("title") or "").strip()
description = (issue.get("description") or "").strip()
description_compact = re.sub(r"\s+", " ", description)[:1200]

user_comments = fetch_latest_user_comments(TASK_ID)
comment_block = ""
if user_comments:
    comment_block = (
        "\n\n## Recent user comments (address these specifically):\n"
        f"{user_comments}\n"
    )

exec_prompt = (
    "You are OpenClawWorker. Execute this delegated issue and produce a concrete deliverable in markdown.\n\n"
    f"Issue: {identifier} - {title}\n"
    f"Description: {description_compact}\n"
    f"{comment_block}\n"
    "Return markdown with:\n"
    "1) Deliverable (the actual output the operator asked for — plans, copy, checklist, etc.)\n"
    "2) What you validated in repo/context\n"
    "3) Remaining risks or follow-ups (if any)\n"
    "Be concise but complete. Do not refuse solely for length; prioritize usefulness.\n"
    "Do not include package-install speculation."
)
session_id = f"{COMPANY_ID}-{AGENT_ID}-{TASK_ID}-{RUN_ID}" if RUN_ID else f"{COMPANY_ID}-{AGENT_ID}-{TASK_ID}"

oc_timeout = resolve_openclaw_subprocess_timeout_sec()
agent_notes = ""
agent_ok = False
try:
    agent_proc = subprocess.run(
        ["openclaw", "agent", "--session-id", session_id, "-m", exec_prompt],
        capture_output=True,
        text=True,
        timeout=oc_timeout,
        check=False,
    )
    if agent_proc.returncode == 0:
        agent_notes = (agent_proc.stdout or "").strip()
        agent_ok = bool(agent_notes) and not is_openclaw_llm_outcome_failure(agent_notes)
    else:
        stderr = (agent_proc.stderr or "").strip()
        agent_notes = f"OpenClaw agent exited with code {agent_proc.returncode}. stderr: {stderr[:400]}"
except subprocess.TimeoutExpired:
    agent_notes = f"OpenClaw agent timed out (>{oc_timeout}s; adapter budget aligns with Paperclip process timeout)."

if agent_ok:
    comment = (
        f"OpenClawWorker execution update for `{identifier}`.\n\n"
        "### Deliverable / execution notes\n"
        f"{agent_notes[:6000]}"
    )
    patch_issue(TASK_ID, status="done", comment=comment)
    print("HEARTBEAT_OK:executor")
    raise SystemExit(0)

# Paperclip task workflow: use `blocked` when progress cannot be made (docs: Issues API / task workflow).
patch_issue(
    TASK_ID,
    status="blocked",
    comment=(
        f"OpenClawWorker could not complete `{identifier}` in this heartbeat.\n\n"
        f"{agent_notes}\n\n"
        "Narrow the task, fix OpenClaw/gateway availability, or re-run manually after adjusting scope."
    ),
)
print("HEARTBEAT_OK:executor")
PY
