#!/usr/bin/env bash
set -euo pipefail

# OpenClawWorker issue executor:
# - picks assigned actionable issue (Paperclip heartbeat protocol)
# - checks out the issue (single attempt; 409 => exit per docs)
# - runs one `openclaw agent` call bounded by adapter timeoutSec
# - on success => done + comment; on failure => blocked + comment (no custom retry loops)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export FOREMAN_ROOT_DIR="${ROOT_DIR}"

python3 - <<'PY'
import json
import os
import re
import subprocess
import sys
import time
import uuid
from pathlib import Path
import urllib.error
import urllib.request

ROOT_DIR = Path(os.environ.get("FOREMAN_ROOT_DIR", "")).resolve()
HELPER_DIR = ROOT_DIR / "scripts" / "lib"
if str(HELPER_DIR) not in sys.path:
    sys.path.insert(0, str(HELPER_DIR))

from openclaw_config_helper import read_openclaw_config_once_atomic
from tool_call_recorder import (
    append_tool_call_records,
    collect_tool_calls_from_transcript_window,
    resolve_session_file_for_agent,
)


def _normalize_api_base(raw: str) -> str:
    if not raw:
        raise SystemExit("ERROR: PAPERCLIP_API_URL must be set by the adapter environment.")
    raw = raw.rstrip("/")
    return raw if raw.endswith("/api") else f"{raw}/api"


API_BASE = _normalize_api_base(os.environ.get("PAPERCLIP_API_URL", ""))
COMPANY_ID = (os.environ.get("PAPERCLIP_COMPANY_ID") or "").strip()
AGENT_ID = (os.environ.get("PAPERCLIP_AGENT_ID") or "").strip()
TASK_ID = (os.environ.get("PAPERCLIP_TASK_ID") or "").strip()
RUN_ID = (os.environ.get("PAPERCLIP_RUN_ID") or "").strip()
WAKE_REASON = (os.environ.get("PAPERCLIP_WAKE_REASON") or "").strip()
API_KEY = (os.environ.get("PAPERCLIP_API_KEY") or "").strip()

if not API_KEY:
    raise SystemExit(
        "ERROR: PAPERCLIP_API_KEY is required. Heartbeats must use Paperclip-injected run JWT; "
        "static/user token fallback is disabled."
    )
if not COMPANY_ID or not AGENT_ID:
    raise SystemExit("ERROR: PAPERCLIP_COMPANY_ID and PAPERCLIP_AGENT_ID are required.")
print(
    f"[executor] env_probe agent_id={AGENT_ID} run_id={(RUN_ID or '<missing>')} "
    f"wake_reason={(WAKE_REASON or 'unknown')} task_id={(TASK_ID or 'none')}",
    flush=True,
)


def _resolve_run_id_from_heartbeat_runs() -> str:
    if RUN_ID:
        return RUN_ID
    list_path = f"/companies/{COMPANY_ID}/heartbeat-runs?limit=40&offset=0"
    request = urllib.request.Request(
        f"{API_BASE}{list_path}",
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        method="GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as resp:
            body = resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        detail = (exc.read() or b"").decode("utf-8", errors="replace")
        raise SystemExit(
            "ERROR: PAPERCLIP_RUN_ID missing and fallback run-id lookup failed: "
            f"HTTP {exc.code} GET {list_path}: {detail[:220]}"
        )
    except Exception as exc:
        raise SystemExit(
            "ERROR: PAPERCLIP_RUN_ID missing and fallback run-id lookup transport failed: "
            f"{exc}"
        )
    rows = json.loads(body) if body else []
    if not isinstance(rows, list):
        raise SystemExit("ERROR: PAPERCLIP_RUN_ID missing and heartbeat-runs response was not a list.")
    running = [r for r in rows if isinstance(r, dict) and r.get("status") == "running" and r.get("agentId") == AGENT_ID]
    if TASK_ID:
        task_scoped = []
        for r in running:
            snap = r.get("contextSnapshot") if isinstance(r.get("contextSnapshot"), dict) else {}
            if (snap.get("taskId") or snap.get("issueId") or "").strip() == TASK_ID:
                task_scoped.append(r)
        running = task_scoped
    if len(running) != 1:
        raise SystemExit(
            "ERROR: PAPERCLIP_RUN_ID missing and could not derive a unique running heartbeat run id "
            f"(candidates={len(running)} task_scope={'yes' if TASK_ID else 'no'})."
        )
    derived = (running[0].get("id") or "").strip()
    if not derived:
        raise SystemExit("ERROR: Derived heartbeat run id was empty.")
    print(f"[executor] derived_run_id_from_api run_id={derived}", flush=True)
    return derived


RUN_ID = _resolve_run_id_from_heartbeat_runs()
print(f"[executor] heartbeat bootstrap run_id={RUN_ID}", flush=True)
RUN_LOGS_DIR = ROOT_DIR / "state" / "run-logs" / RUN_ID
OPENCLAW_AGENT_ID = (
    os.environ.get("FOREMAN_OPENCLAW_AGENT_ID")
    or os.environ.get("FOREMAN_CEO_OPENCLAW_AGENT_ID")
    or "main"
).strip() or "main"


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
        "agent couldn't generate a response",
    )
    if any(n in t for n in needles):
        return True
    # Short shrift: tiny stdout that only signals failure
    if len(t) < 120 and ("timed out" in t or "rate limit" in t or "unauthorized" in t):
        return True
    return False


def is_substantive_deliverable(text: str) -> bool:
    """
    Guard against false-success runs where OpenClaw returns trivial status words
    (e.g., "completed") that are not a real issue deliverable.
    """
    t = (text or "").strip()
    if not t:
        return False
    tl = t.lower()
    trivial_exact = {
        "done",
        "completed",
        "complete",
        "ok",
        "success",
        "succeeded",
        "finished",
    }
    if tl in trivial_exact:
        return False
    non_substantive_markers = (
        "[compaction-safeguard]",
        "no reply from agent",
        "no real conversation messages to summarize",
        "writing compaction boundary",
    )
    if any(marker in tl for marker in non_substantive_markers):
        return False
    # Very short outputs are almost always non-deliverables in this workflow.
    if len(t) < 120:
        return False
    # Prefer multi-structure responses: markdown sections, bullets, or 2+ lines.
    if "\n" not in t and "###" not in t and "-" not in t:
        return False
    return True


def strip_reasoning_think_blocks(text: str) -> str:
    """
    Remove DeepSeek-style <think>...</think> traces from user-facing output.
    Handles nested blocks and unterminated trailing <think> sections.
    """
    src = text or ""
    out: list[str] = []
    i = 0
    depth = 0
    open_tag = "<think>"
    close_tag = "</think>"
    olen = len(open_tag)
    clen = len(close_tag)
    n = len(src)
    while i < n:
        if src.startswith(open_tag, i):
            depth += 1
            i += olen
            continue
        if src.startswith(close_tag, i):
            if depth > 0:
                depth -= 1
            i += clen
            continue
        if depth == 0:
            out.append(src[i])
        i += 1
    return "".join(out).strip()


def _test_strip_reasoning_think_blocks() -> None:
    fixture_nested = (
        "Alpha<think>internal A <think>nested B</think> still internal</think>Omega"
    )
    got_nested = strip_reasoning_think_blocks(fixture_nested)
    assert got_nested == "AlphaOmega", f"nested strip failed: {got_nested!r}"

    fixture_unterminated = "Visible<think>hidden forever"
    got_unterminated = strip_reasoning_think_blocks(fixture_unterminated)
    assert got_unterminated == "Visible", f"unterminated strip failed: {got_unterminated!r}"

    fixture_none = "No reasoning trace here."
    got_none = strip_reasoning_think_blocks(fixture_none)
    assert got_none == fixture_none, f"no-think strip changed text: {got_none!r}"


if (os.environ.get("FOREMAN_RUN_STRIP_THINK_TESTS") or "").strip() == "1":
    _test_strip_reasoning_think_blocks()
    print("[executor] strip_reasoning_think_blocks_tests=pass", flush=True)


def make_valid_session_id(company_id: str, agent_id: str, task_id: str, run_id: str) -> str:
    """
    OpenClaw gateway rejects overly long/invalid session ids.
    Keep to a compact, predictable ASCII slug.
    """
    def _slug(s: str, n: int = 8) -> str:
        cleaned = re.sub(r"[^a-zA-Z0-9]", "", (s or ""))
        return (cleaned[:n] or "x").lower()

    ts = int(time.time())
    rid = _slug(run_id, 6)
    return f"pc-{_slug(company_id)}-{_slug(agent_id)}-{_slug(task_id)}-{rid}-{ts}"


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


def preflight_openclaw_executor_config(issue_id: str, identifier: str) -> None:
    """
    Validate that OpenClaw executor provider metadata exists before running `openclaw agent`.
    """
    cfg_path = Path.home() / ".openclaw" / "openclaw.json"
    diag_prefix = f"OpenClawWorker configuration preflight failed for `{identifier}`."
    if not cfg_path.is_file():
        patch_issue(
            issue_id,
            status="blocked",
            comment=(
                f"{diag_prefix}\n\n"
                f"Missing OpenClaw config file: {cfg_path}\n"
                "Run ./scripts/configure.sh before invoking the CEO executor."
            ),
        )
        print("HEARTBEAT_FAIL:executor (missing openclaw.json)")
        raise SystemExit(1)

    try:
        cfg, _ = read_openclaw_config_once_atomic(cfg_path)
    except Exception as exc:
        patch_issue(
            issue_id,
            status="blocked",
            comment=f"{diag_prefix}\n\nCould not parse OpenClaw config: {exc}",
        )
        print("HEARTBEAT_FAIL:executor (invalid openclaw.json)")
        raise SystemExit(1)

    providers = (((cfg.get("models") or {}).get("providers") or {}))
    executor_provider = providers.get("executor") if isinstance(providers.get("executor"), dict) else {}
    base_url = str(executor_provider.get("baseUrl") or "").strip()
    api_key = str(executor_provider.get("apiKey") or "").strip()
    model_rows = executor_provider.get("models") if isinstance(executor_provider.get("models"), list) else []
    model_ids = [m.get("id") for m in model_rows if isinstance(m, dict)]

    if not base_url or not api_key:
        patch_issue(
            issue_id,
            status="blocked",
            comment=(
                f"{diag_prefix}\n\n"
                "OpenClaw executor provider must include non-empty baseUrl and apiKey fields."
            ),
        )
        print("HEARTBEAT_FAIL:executor (executor provider missing baseUrl/apiKey)")
        raise SystemExit(1)
    if not model_ids:
        patch_issue(
            issue_id,
            status="blocked",
            comment=f"{diag_prefix}\n\nOpenClaw executor provider must define at least one model id.",
        )
        print("HEARTBEAT_FAIL:executor (executor provider missing models)")
        raise SystemExit(1)


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
        if not body:
            continue

        # local-board comments do not reliably preserve agent/user authorship in this environment.
        # Filter out our own structured execution updates so reruns don't ingest prior agent output.
        normalized = body.lower()
        if (
            normalized.startswith("openclawworker execution update for `")
            or normalized.startswith("openclawworker could not complete `")
            or "### deliverable / execution notes" in normalized
        ):
            continue

        author_agent = c.get("authorAgentId") or c.get("agentId") or ""
        if author_agent and author_agent == AGENT_ID:
            continue
        user_comments.append(body)
    if not user_comments:
        return ""
    combined = "\n---\n".join(user_comments[:3])
    return combined[:2000]


def detect_local_repo_context() -> str:
    """
    Provide concrete local-repo context so the agent can analyze code from disk
    instead of treating GitHub URL availability as a blocker.
    """
    candidates = [
        Path("/Users/jonathanborgia/foreman-git/foreman-v2"),
        Path("/Users/jonathanborgia/foreman-git/foreman"),
    ]
    for path in candidates:
        if not (path / ".git").exists():
            continue
        try:
            head = subprocess.run(
                ["git", "-C", str(path), "rev-parse", "--short", "HEAD"],
                capture_output=True,
                text=True,
                timeout=10,
                check=False,
            ).stdout.strip()
            branch = subprocess.run(
                ["git", "-C", str(path), "branch", "--show-current"],
                capture_output=True,
                text=True,
                timeout=10,
                check=False,
            ).stdout.strip()
            return (
                "Local repository is available and must be used for analysis.\n"
                f"- local_path: {path}\n"
                f"- branch: {branch or 'unknown'}\n"
                f"- head: {head or 'unknown'}\n"
                "Do not treat GitHub URL accessibility as a blocker when local_path is present."
            )
        except Exception:
            continue
    return (
        "No local repository path was detected. If GitHub URL access fails, report the specific command/error."
    )


def req(method: str, path: str, payload=None):
    mutating = method in {"POST", "PATCH", "PUT", "DELETE"}
    if mutating and not RUN_ID:
        raise RuntimeError(f"Mutating request {method} {path} requires PAPERCLIP_RUN_ID.")
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    if mutating:
        headers["X-Paperclip-Run-Id"] = RUN_ID
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(f"{API_BASE}{path}", data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=60) as resp:
            body = resp.read().decode("utf-8")
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as exc:
        body = (exc.read() or b"").decode("utf-8", errors="replace")
        print(
            f"[executor] paperclip_http_error method={method} path={path} "
            f"status={exc.code} body_excerpt={body[:180]}",
            flush=True,
        )
        raise RuntimeError(f"HTTP {exc.code} {method} {path}: {body[:300]}")


def patch_issue(issue_id: str, status: str | None = None, comment: str | None = None):
    payload = {}
    if status:
        payload["status"] = status
    if comment:
        payload["comment"] = comment
    if payload:
        req("PATCH", f"/issues/{issue_id}", payload)


def post_comment(issue_id: str, body: str) -> str | None:
    """Post a comment on an issue and return its id when available."""
    try:
        result = req("POST", f"/issues/{issue_id}/comments", {"body": body})
    except Exception as exc:
        print(f"[executor] comment_post_failed issue_id={issue_id} error={exc}", flush=True)
        return None
    comment_id = ""
    if isinstance(result, dict):
        comment_id = (
            str(result.get("id") or result.get("commentId") or result.get("comment_id") or "").strip()
        )
    print(f"[executor] comment_posted issue_id={issue_id} comment_id={(comment_id or 'none')}", flush=True)
    return comment_id or None


def checkout_issue(task_id: str):
    """
    Paperclip task workflow requires checkout before work.
    This atomically claims ownership and binds checkoutRunId for this run.
    """
    print(f"[executor] checkout_issue task_id={task_id}", flush=True)
    req(
        "POST",
        f"/issues/{task_id}/checkout",
        {
            "agentId": AGENT_ID,
            "expectedStatuses": ["todo", "backlog", "blocked"],
        },
    )


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

if task_status in ("todo", "backlog", "blocked", "in_progress"):
    try:
        checkout_issue(TASK_ID)
    except Exception as exc:
        if "HTTP 409" in str(exc):
            print(f"HEARTBEAT_OK:executor (checkout conflict on {TASK_ID})")
            raise SystemExit(0)
        raise
else:
    print(f"HEARTBEAT_OK:executor (task {TASK_ID} in state '{task_status}', nothing to do)")
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
repo_context = detect_local_repo_context()

exec_prompt = (
    "You are OpenClawWorker. Execute this delegated issue and produce a concrete deliverable in markdown.\n\n"
    f"Issue: {identifier} - {title}\n"
    f"Description: {description_compact}\n"
    f"\n## Repository access context\n{repo_context}\n"
    f"{comment_block}\n"
    "Return markdown with:\n"
    "1) Deliverable (the actual output the operator asked for — plans, copy, checklist, etc.)\n"
    "2) What you validated in repo/context\n"
    "3) Remaining risks or follow-ups (if any)\n"
    "Be concise but complete. Do not refuse solely for length; prioritize usefulness.\n"
    "Do not include package-install speculation."
)
session_suffix = RUN_ID or f"hb-{int(time.time())}-{uuid.uuid4().hex[:8]}"
session_id = make_valid_session_id(COMPANY_ID, AGENT_ID, TASK_ID, session_suffix)

preflight_openclaw_executor_config(TASK_ID, identifier)

oc_timeout = resolve_openclaw_subprocess_timeout_sec()
agent_notes = ""
agent_ok = False

def run_openclaw_attempt(
    prompt: str,
    current_session_id: str,
    *,
    step_id: str,
    local_mode: bool = False,
) -> tuple[bool, str]:
    print(
        f"[executor] openclaw_attempt_start mode={'local' if local_mode else 'default'} "
        f"agent_id={OPENCLAW_AGENT_ID} session_id={current_session_id}",
        flush=True,
    )
    started_ms = int(time.time() * 1000)
    try:
        cmd = ["openclaw", "agent", "--agent", OPENCLAW_AGENT_ID, "--session-id", current_session_id, "-m", prompt]
        if local_mode:
            cmd.insert(2, "--local")
        agent_proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=oc_timeout,
            check=False,
        )
    except subprocess.TimeoutExpired:
        print("[executor] openclaw_attempt_timeout", flush=True)
        return False, f"OpenClaw agent timed out (>{oc_timeout}s; adapter budget aligns with Paperclip process timeout)."
    finished_ms = int(time.time() * 1000)

    session_file = resolve_session_file_for_agent(Path.home() / ".openclaw", OPENCLAW_AGENT_ID)
    if session_file is not None:
        records = collect_tool_calls_from_transcript_window(
            session_file,
            run_id=RUN_ID,
            step_id=step_id,
            started_ms=started_ms,
            finished_ms=finished_ms,
        )
        if records:
            out_path = append_tool_call_records(RUN_LOGS_DIR, records)
            print(
                f"[executor] tool_call_records_written count={len(records)} path={out_path}",
                flush=True,
            )

    if agent_proc.returncode != 0:
        stderr = (agent_proc.stderr or "").strip()
        print(
            f"[executor] openclaw_attempt_nonzero_exit code={agent_proc.returncode} "
            f"stderr_excerpt={stderr[:180]}",
            flush=True,
        )
        return False, f"OpenClaw agent exited with code {agent_proc.returncode}. stderr: {stderr[:400]}"

    output = (agent_proc.stdout or "").strip()
    output = strip_reasoning_think_blocks(output)
    print(f"[executor] openclaw_attempt_completed stdout_chars={len(output)}", flush=True)
    if not output:
        return False, "OpenClaw returned empty output."
    if is_openclaw_llm_outcome_failure(output):
        return False, f"OpenClaw returned failure-like output. Raw output preview: {output[:300]}"
    if not is_substantive_deliverable(output):
        return False, f"OpenClaw returned non-substantive output. Raw output preview: {output[:300]}"
    return True, output

# Attempt 1: standard issue prompt.
agent_ok, agent_notes = run_openclaw_attempt(
    exec_prompt,
    session_id,
    step_id="single_path_primary",
)

# Attempt 2: stricter prompt on non-substantive outcome.
if not agent_ok:
    retry_prompt = (
        exec_prompt
        + "\n\nIMPORTANT: Your response must be a project-specific markdown deliverable grounded in the repository context. "
          "Do not return status words like 'completed' or any compaction notice. "
          "Include concrete findings and actions specific to this issue."
    )
    retry_session_id = make_valid_session_id(COMPANY_ID, AGENT_ID, TASK_ID, f"{session_suffix}-retry")
    retry_ok, retry_notes = run_openclaw_attempt(
        retry_prompt,
        retry_session_id,
        step_id="single_path_retry_local",
        local_mode=True,
    )
    if retry_ok:
        agent_ok = True
        agent_notes = retry_notes
    else:
        agent_notes = (
            f"{agent_notes}\n\nSecond attempt also failed non-substantively.\n"
            f"{retry_notes}"
        )

if agent_ok:
    comment_body = (
        f"OpenClawWorker execution update for `{identifier}`.\n\n"
        "### Deliverable / execution notes\n"
        f"{agent_notes[:6000]}"
    )
    comment_id = post_comment(TASK_ID, comment_body)
    if comment_id:
        patch_issue(TASK_ID, status="done", comment=f"completed; results posted in comment {comment_id}")
    else:
        patch_issue(TASK_ID, status="done", comment=comment_body)
    print("HEARTBEAT_OK:executor")
    raise SystemExit(0)

# Paperclip task workflow: use `blocked` when progress cannot be made (docs: Issues API / task workflow).
blocked_comment = (
    f"OpenClawWorker could not complete `{identifier}` in this heartbeat.\n\n"
    f"{agent_notes}\n\n"
    "Narrow the task, fix OpenClaw/gateway availability, or re-run manually after adjusting scope."
)
post_comment(TASK_ID, blocked_comment)
patch_issue(
    TASK_ID,
    status="blocked",
    comment=blocked_comment,
)
print("HEARTBEAT_FAIL:executor")
raise SystemExit(1)
PY
