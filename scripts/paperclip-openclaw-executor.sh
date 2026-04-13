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


def preflight_executor_openclaw_endpoint(issue_id: str, identifier: str) -> None:
    """
    Probe executor vLLM /models from ~/.openclaw/openclaw.json before invoking `openclaw agent`.
    On failure, PATCH issue to blocked with diagnostics and exit 1.
    """
    cfg_path = Path.home() / ".openclaw" / "openclaw.json"
    diag_prefix = f"OpenClawWorker endpoint preflight failed for `{identifier}`."
    if not cfg_path.is_file():
        patch_issue(
            issue_id,
            status="blocked",
            comment=(
                f"{diag_prefix}\n\n"
                f"Missing OpenClaw config file: {cfg_path}\n"
                "Run ./scripts/configure.sh after provisioning pods."
            ),
        )
        print("HEARTBEAT_FAIL:executor (missing openclaw.json)")
        raise SystemExit(1)
    def extract_executor_regex(text: str) -> tuple[str, str]:
        m = re.search(
            r"executor\s*:\s*\{[^}]*baseUrl\s*:\s*\"([^\"]+)\"[^}]*apiKey\s*:\s*\"([^\"]*)\"",
            text,
            flags=re.S,
        )
        if not m:
            return "", ""
        return m.group(1).strip().rstrip("/"), (m.group(2) or "").strip()

    max_attempts = 5
    backoff_seconds = 0.25
    base_url = ""
    cfg_api_key = ""
    attempt_diagnostics: list[dict[str, str]] = []

    for attempt in range(1, max_attempts + 1):
        try:
            cfg, raw_cfg = read_openclaw_config_once_atomic(cfg_path)
        except Exception as exc:
            attempt_diagnostics.append(
                {
                    "attempt": str(attempt),
                    "status": "parse_error",
                    "detail": str(exc)[:220],
                }
            )
            if attempt < max_attempts:
                time.sleep(backoff_seconds)
            continue

        models_block = cfg.get("models") if isinstance(cfg.get("models"), dict) else {}
        providers = models_block.get("providers") if isinstance(models_block.get("providers"), dict) else {}
        ex = providers.get("executor") if isinstance(providers.get("executor"), dict) else {}
        candidate_base = str(ex.get("baseUrl") or "").strip().rstrip("/")
        candidate_key = str(ex.get("apiKey") or "").strip()
        if not candidate_base or not candidate_key:
            br, kr = extract_executor_regex(raw_cfg)
            candidate_base = candidate_base or br
            candidate_key = candidate_key or kr

        if candidate_base:
            base_url = candidate_base
            cfg_api_key = candidate_key
            attempt_diagnostics.append(
                {
                    "attempt": str(attempt),
                    "status": "parsed_ok",
                    "detail": "baseUrl found",
                }
            )
            break

        attempt_diagnostics.append(
            {
                "attempt": str(attempt),
                "status": "parsed_missing_baseurl",
                "detail": "executor block present but baseUrl unresolved",
            }
        )
        if attempt < max_attempts:
            time.sleep(backoff_seconds)

    parse_errors = sum(1 for d in attempt_diagnostics if d["status"] == "parse_error")
    missing_base = sum(1 for d in attempt_diagnostics if d["status"] == "parsed_missing_baseurl")
    env_key = (os.environ.get("RUNPOD_API_KEY") or "").strip()
    api_key = cfg_api_key or env_key
    expected_model = "Qwen/Qwen2.5-32B-Instruct"
    if not base_url:
        patch_issue(
            issue_id,
            status="blocked",
            comment=(
                f"{diag_prefix}\n\n"
                "models.providers.executor.baseUrl is missing in ~/.openclaw/openclaw.json.\n"
                f"Attempts: {max_attempts}; parse_failures={parse_errors}; parsed_missing_baseUrl={missing_base}."
            ),
        )
        print("HEARTBEAT_FAIL:executor (no executor baseUrl)")
        raise SystemExit(1)
    if not api_key:
        patch_issue(
            issue_id,
            status="blocked",
            comment=(
                f"{diag_prefix}\n\n"
                "No API key for executor probe: set models.providers.executor.apiKey in openclaw.json "
                "or export RUNPOD_API_KEY in the adapter environment."
            ),
        )
        print("HEARTBEAT_FAIL:executor (no api key for probe)")
        raise SystemExit(1)

    models_url = f"{base_url}/models"
    print(
        f"[executor] preflight_models_probe url={models_url} expected_model={expected_model}",
        flush=True,
    )
    try:
        req_http = urllib.request.Request(
            models_url,
            headers={
                "Authorization": f"Bearer {api_key}",
                "Accept": "application/json",
                "User-Agent": "foreman-v2/paperclip-openclaw-executor (1.0)",
            },
            method="GET",
        )
        with urllib.request.urlopen(req_http, timeout=45) as resp:
            code = resp.getcode()
            body = resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as exc:
        body = (exc.read() or b"").decode("utf-8", errors="replace")
        patch_issue(
            issue_id,
            status="blocked",
            comment=(
                f"{diag_prefix}\n\n"
                f"GET {models_url} => HTTP {exc.code}\n"
                f"Body (truncated): {body[:1200]}"
            ),
        )
        print("HEARTBEAT_FAIL:executor (executor /models http error)")
        raise SystemExit(1)
    except Exception as exc:
        patch_issue(
            issue_id,
            status="blocked",
            comment=(
                f"{diag_prefix}\n\n"
                f"GET {models_url} unreachable or error: {exc}"
            ),
        )
        print("HEARTBEAT_FAIL:executor (executor /models unreachable)")
        raise SystemExit(1)

    if code < 200 or code >= 300:
        patch_issue(
            issue_id,
            status="blocked",
            comment=(
                f"{diag_prefix}\n\n"
                f"GET {models_url} => HTTP {code}\n"
                f"Body (truncated): {body[:1200]}"
            ),
        )
        print("HEARTBEAT_FAIL:executor (executor /models non-2xx)")
        raise SystemExit(1)

    try:
        payload = json.loads(body) if body else {}
    except json.JSONDecodeError as exc:
        patch_issue(
            issue_id,
            status="blocked",
            comment=f"{diag_prefix}\n\nExecutor /models returned non-JSON: {exc}",
        )
        print("HEARTBEAT_FAIL:executor (executor /models non-json)")
        raise SystemExit(1)

    if isinstance(payload, dict) and payload.get("error") is not None:
        patch_issue(
            issue_id,
            status="blocked",
            comment=f"{diag_prefix}\n\nExecutor /models error field: {payload.get('error')}",
        )
        print("HEARTBEAT_FAIL:executor (executor /models error payload)")
        raise SystemExit(1)

    model_rows = payload.get("data") if isinstance(payload.get("data"), list) else []
    model_ids = [m.get("id") for m in model_rows if isinstance(m, dict)]
    print(
        f"[executor] preflight_models_probe_ok status={code} models_count={len(model_ids)}",
        flush=True,
    )
    if expected_model not in model_ids:
        patch_issue(
            issue_id,
            status="blocked",
            comment=(
                f"{diag_prefix}\n\n"
                f"Expected model {expected_model!r} not listed by executor /models. "
                f"Got ids (sample): {', '.join(str(x) for x in model_ids[:12] if x)}"
            ),
        )
        print("HEARTBEAT_FAIL:executor (executor model mismatch)")
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

preflight_executor_openclaw_endpoint(TASK_ID, identifier)

oc_timeout = resolve_openclaw_subprocess_timeout_sec()
agent_notes = ""
agent_ok = False

def run_openclaw_attempt(prompt: str, current_session_id: str, local_mode: bool = False) -> tuple[bool, str]:
    print(
        f"[executor] openclaw_attempt_start mode={'local' if local_mode else 'default'} "
        f"session_id={current_session_id}",
        flush=True,
    )
    try:
        cmd = ["openclaw", "agent", "--session-id", current_session_id, "-m", prompt]
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

    if agent_proc.returncode != 0:
        stderr = (agent_proc.stderr or "").strip()
        print(
            f"[executor] openclaw_attempt_nonzero_exit code={agent_proc.returncode} "
            f"stderr_excerpt={stderr[:180]}",
            flush=True,
        )
        return False, f"OpenClaw agent exited with code {agent_proc.returncode}. stderr: {stderr[:400]}"

    output = (agent_proc.stdout or "").strip()
    print(f"[executor] openclaw_attempt_completed stdout_chars={len(output)}", flush=True)
    if not output:
        return False, "OpenClaw returned empty output."
    if is_openclaw_llm_outcome_failure(output):
        return False, f"OpenClaw returned failure-like output. Raw output preview: {output[:300]}"
    if not is_substantive_deliverable(output):
        return False, f"OpenClaw returned non-substantive output. Raw output preview: {output[:300]}"
    return True, output

# Attempt 1: standard issue prompt.
agent_ok, agent_notes = run_openclaw_attempt(exec_prompt, session_id)

# Attempt 2: stricter prompt on non-substantive outcome.
if not agent_ok:
    retry_prompt = (
        exec_prompt
        + "\n\nIMPORTANT: Your response must be a project-specific markdown deliverable grounded in the repository context. "
          "Do not return status words like 'completed' or any compaction notice. "
          "Include concrete findings and actions specific to this issue."
    )
    retry_session_id = make_valid_session_id(COMPANY_ID, AGENT_ID, TASK_ID, f"{session_suffix}-retry")
    retry_ok, retry_notes = run_openclaw_attempt(retry_prompt, retry_session_id, local_mode=True)
    if retry_ok:
        agent_ok = True
        agent_notes = retry_notes
    else:
        agent_notes = (
            f"{agent_notes}\n\nSecond attempt also failed non-substantively.\n"
            f"{retry_notes}"
        )

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
print("HEARTBEAT_FAIL:executor")
raise SystemExit(1)
PY
