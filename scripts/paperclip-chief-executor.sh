#!/usr/bin/env bash
set -euo pipefail

# ChiefOfStaff issue executor:
# - checks out assigned task
# - drafts an execution/delegation plan via OpenClaw
# - delegates to OpenClawWorker
# - writes a visible Paperclip comment + status update

python3 - <<'PY'
import json
import os
import re
import subprocess
import sys
import uuid
from pathlib import Path
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
    # Strict origin match first (scheme + hostname + port).
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

    # Local-only fallback: accept loopback credentials only if exactly one token exists.
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


def infer_repo_root() -> str:
    def validate_repo_root(raw_root: str) -> str:
        repo = Path(raw_root).expanduser().resolve()
        required = [
            repo / "scripts" / "paperclip-chief-executor.sh",
            repo / "scripts" / "paperclip-openclaw-executor.sh",
        ]
        if not all(p.exists() for p in required):
            raise RuntimeError(f"Invalid repo root for runtime scripts: {repo}")
        allowed_roots_raw = (
            (os.environ.get("FOREMAN_ALLOWED_REPO_ROOTS") or "").strip()
            or (os.environ.get("FOREMAN_REPO_ROOT") or "").strip()
        )
        if allowed_roots_raw:
            allowed_roots = [
                Path(part).expanduser().resolve()
                for part in allowed_roots_raw.split(":")
                if part.strip()
            ]
            if not any(
                str(repo) == str(allowed) or str(repo).startswith(f"{allowed}{os.sep}")
                for allowed in allowed_roots
            ):
                raise RuntimeError(f"Repo root {repo} is outside FOREMAN_ALLOWED_REPO_ROOTS")
        return str(repo)

    resolved = (os.environ.get("PAPERCLIP_RESOLVED_COMMAND") or "").strip()
    if resolved:
        p = Path(resolved).resolve()
        # .../foreman-v2/scripts/paperclip-chief-executor.sh -> .../foreman-v2
        if p.parent.name == "scripts":
            return validate_repo_root(str(p.parent.parent))
    # Fallback to current process cwd.
    return validate_repo_root(os.getcwd())


def build_worker_adapter_cfg(chief_agent: dict) -> tuple[str, dict]:
    adapter_type = (chief_agent.get("adapterType") or "").strip()
    adapter_cfg = chief_agent.get("adapterConfig") if isinstance(chief_agent.get("adapterConfig"), dict) else {}
    if not adapter_type or not isinstance(adapter_cfg, dict):
        raise RuntimeError("ChiefOfStaff adapter configuration is invalid; cannot hire OpenClawWorker.")

    chief_env = adapter_cfg.get("env") if isinstance(adapter_cfg.get("env"), dict) else {}
    worker_env = {}
    # Keep runtime role explicit; copy only explicitly safe optional OpenClaw vars.
    worker_env["PAPERCLIP_ROLE"] = {"type": "plain", "value": "executor"}
    for key in ("OPENCLAW_BASE_URL", "OPENCLAW_BEARER_TOKEN", "OPENCLAW_GATEWAY_TOKEN"):
        value = chief_env.get(key)
        if isinstance(value, dict) and value.get("type") == "plain":
            worker_env[key] = value

    repo_root = infer_repo_root()
    worker_command = str(Path(repo_root) / "scripts" / "paperclip-openclaw-executor.sh")
    worker_cfg = {
        "command": worker_command,
        "cwd": repo_root,
        "env": worker_env,
        "timeoutSec": int(adapter_cfg.get("timeoutSec") or 300),
    }
    if isinstance(adapter_cfg.get("graceSec"), int):
        worker_cfg["graceSec"] = int(adapter_cfg["graceSec"])
    return adapter_type, worker_cfg


if not TASK_ID:
    # Fallback for manual/invoke runs that do not pass explicit task context.
    assignments = req(
        "GET",
        f"/companies/{COMPANY_ID}/issues?assigneeAgentId={AGENT_ID}&status=todo,in_progress,blocked&limit=20&offset=0",
    )
    items = assignments.get("items", []) if isinstance(assignments, dict) else assignments
    if isinstance(items, list) and items:
        # Prefer in_progress first, then todo, then blocked.
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

# Idempotency guard: if this task already has child issues delegated by a previous
# run, skip re-delegation entirely.
all_issues = req("GET", f"/companies/{COMPANY_ID}/issues")
all_items = all_issues.get("items", []) if isinstance(all_issues, dict) else all_issues
existing_children = [
    i for i in (all_items if isinstance(all_items, list) else [])
    if i.get("parentId") == TASK_ID
]
if existing_children:
    pending = [c for c in existing_children if c.get("status") not in ("done", "cancelled")]
    done = [c for c in existing_children if c.get("status") == "done"]
    if pending:
        print(f"HEARTBEAT_OK:executor (task {TASK_ID} already has {len(pending)} pending child issue(s); skipping re-delegation)")
        raise SystemExit(0)
    if done and not pending:
        patch_issue(TASK_ID, status="done", comment=(
            f"All {len(done)} delegated sub-task(s) completed. Marking parent done."
        ))
        print(f"HEARTBEAT_OK:executor (all children done; closed parent {TASK_ID})")
        raise SystemExit(0)

if task_status == "in_progress":
    # Already checked out from a prior heartbeat — continue work.
    pass
elif task_status in ("todo", "backlog", "blocked"):
    checkout_issue(TASK_ID, AGENT_ID)
else:
    print(f"HEARTBEAT_OK:executor (task {TASK_ID} in state '{task_status}', nothing to do)")
    raise SystemExit(0)

title = (issue.get("title") or "").strip()
description = (issue.get("description") or "").strip()
priority = (issue.get("priority") or "medium").strip()
project_id = issue.get("projectId")
goal_id = issue.get("goalId")
identifier = (issue.get("identifier") or TASK_ID).strip()

prompt = (
    "You have OpenClaw tools/skills available in this runtime. "
    "Do not claim tools are unavailable unless you actually attempted a command/tool "
    "and include the exact failing command and error.\n\n"
    "Do not suggest npm package installation for @openclaw/* skills. "
    "Use existing OpenClaw skills and project code analysis only.\n\n"
)

skills_text = ""
ready_skills: list[str] = []
skills_proc = subprocess.run(
    ["openclaw", "skills", "list"],
    capture_output=True,
    text=True,
    timeout=60,
    check=False,
)
if skills_proc.returncode == 0:
    skills_text = skills_proc.stdout or ""
    for line in skills_text.splitlines():
        if "✓ ready" not in line:
            continue
        cols = [part.strip() for part in line.split("│")]
        if len(cols) >= 3:
            name = cols[2]
            if name:
                ready_skills.append(name)
skills_hint = ", ".join(ready_skills[:20]) if ready_skills else "unknown"

prompt += (
    "You are ChiefOfStaff. Produce an execution-ready delegation plan for the task below.\n\n"
    f"Issue: {identifier} - {title}\n"
    f"Wake reason: {WAKE_REASON or 'unknown'}\n\n"
    f"Verified ready OpenClaw skills: {skills_hint}\n\n"
    "Task details:\n"
    f"{description}\n\n"
    "Return:\n"
    "1) Short understanding (3 bullets)\n"
    "2) Concrete execution steps (5-10 bullets)\n"
    "3) Success criteria checklist\n"
    "4) First implementation action to start immediately\n"
)

session_id = f"{COMPANY_ID}-{AGENT_ID}-{TASK_ID}-{RUN_ID or uuid.uuid4().hex[:8]}"
plan_error_note = ""


def _fallback_plan(error_note: str) -> str:
    details = f" (degraded mode: {error_note})" if error_note else ""
    return (
        "1) Short understanding\n"
        "- The issue asks for an actionable GTM/launch-readiness plan based on current product and copy gaps.\n"
        "- The workflow should produce a delegated execution lane under OpenClawWorker.\n"
        f"- This draft is generated in fallback mode{details}.\n\n"
        "2) Concrete execution steps\n"
        "- Inventory product capabilities and map to launch requirements.\n"
        "- Audit site copy for positioning, ICP clarity, and conversion friction.\n"
        "- Build a prioritized gap list (Critical/High/Medium) with owners.\n"
        "- Define launch milestones and acceptance criteria.\n"
        "- Delegate implementation evidence gathering to OpenClawWorker.\n\n"
        "3) Success criteria checklist\n"
        "- Gap inventory complete and prioritized.\n"
        "- Milestones and owners assigned.\n"
        "- Delegated execution sub-issue created and running.\n"
        "- Parent issue updated with clear next actions.\n\n"
        "4) First implementation action\n"
        "- Create child execution issue for OpenClawWorker and start evidence collection."
    )


def _generate_plan_text(prompt_text: str, sid: str) -> tuple[str, str]:
    last_error = ""
    for _attempt in range(2):
        try:
            proc = subprocess.run(
                ["openclaw", "agent", "--session-id", sid, "-m", prompt_text],
                capture_output=True,
                text=True,
                timeout=180,
                check=False,
            )
        except subprocess.TimeoutExpired:
            last_error = "openclaw agent timeout >180s"
            continue
        if proc.returncode == 0:
            out = (proc.stdout or "").strip()
            if out:
                return out, ""
            last_error = "openclaw agent returned empty output"
            continue
        stderr = (proc.stderr or "").strip()
        last_error = f"openclaw agent failed: {stderr[:180]}"
    return _fallback_plan(last_error), last_error


plan_text, plan_error_note = _generate_plan_text(prompt, session_id)

# Guardrail: reject speculative "tool unavailable" statements unless they include
# concrete command/error evidence.
unsupported_hint = re.search(r"(unavailable|not available|cannot access)", plan_text, re.IGNORECASE)
has_evidence = re.search(r"(error|errno|failed|command:|stderr|http\\s+\\d{3})", plan_text, re.IGNORECASE)
if unsupported_hint and not has_evidence:
    retry_prompt = (
        prompt
        + "\nIMPORTANT: Your previous draft included an unsupported availability claim "
          "without command/error evidence. Regenerate the plan with no speculative "
          "tool availability statements. Use only verified observations."
    )
    retry_proc = subprocess.run(
        ["openclaw", "agent", "--session-id", session_id, "-m", retry_prompt],
        capture_output=True,
        text=True,
        timeout=180,
        check=False,
    )
    if retry_proc.returncode == 0 and (retry_proc.stdout or "").strip():
        plan_text = retry_proc.stdout.strip()

# Safety filter: block stale/hallucinated package-install guidance that is not
# relevant to issue execution output.
bad_markers = ("@openclaw/skill-runner", "@openclaw/clawhub", "not available on npm")
if any(marker in plan_text for marker in bad_markers):
    plan_text = (
        "1) Short understanding\n"
        "- The task requests a launch-readiness gap analysis across product, technical, and commercial dimensions.\n"
        "- We need a baseline scorecard plus a prioritized closure roadmap.\n"
        "- Work should be delegated for deeper implementation evidence.\n\n"
        "2) Concrete execution steps\n"
        "- Inventory current features and map against expected launch requirements.\n"
        "- Run technical quality checks (tests, reliability risks, security gaps, scalability risks).\n"
        "- Evaluate UX/commercial readiness (onboarding friction, positioning clarity, conversion blockers).\n"
        "- Group findings into Critical / High / Medium gaps with owner and effort.\n"
        "- Produce a closure plan with milestone sequencing and acceptance criteria.\n\n"
        "3) Success criteria checklist\n"
        "- Baseline scorecard produced with explicit criteria.\n"
        "- All identified gaps mapped to owners and target milestones.\n"
        "- Prioritized execution backlog created with measurable completion signals.\n"
        "- Parent issue contains progress summary and delegation links.\n\n"
        "4) First implementation action\n"
        "- Delegate detailed technical gap extraction to OpenClawWorker and begin evidence collection in sub-issues."
    )

agents = req("GET", f"/companies/{COMPANY_ID}/agents")
if isinstance(agents, dict):
    agents = agents.get("items", [])
worker = next((a for a in agents if a.get("name") == "OpenClawWorker"), None)
hired_worker = False

if not worker:
    chief = req("GET", f"/agents/{AGENT_ID}")
    adapter_type, adapter_cfg = build_worker_adapter_cfg(chief)
    hire_payload = {
        "name": "OpenClawWorker",
        "role": "engineer",
        "title": "OpenClaw Runtime Worker",
        "reportsTo": AGENT_ID,
        "capabilities": "Role-dispatched runtime worker via OpenClaw executor path.",
        "adapterType": adapter_type,
        "adapterConfig": adapter_cfg,
    }
    created_worker = req("POST", f"/companies/{COMPANY_ID}/agents", hire_payload)
    if not isinstance(created_worker, dict) or not created_worker.get("id"):
        raise RuntimeError("Failed to hire OpenClawWorker during CEO delegation flow.")
    worker = created_worker
    hired_worker = True
else:
    chief = req("GET", f"/agents/{AGENT_ID}")
    adapter_type, adapter_cfg = build_worker_adapter_cfg(chief)
    worker_payload = {
        "name": worker.get("name") or "OpenClawWorker",
        "role": worker.get("role") or "engineer",
        "title": worker.get("title") or "OpenClaw Runtime Worker",
        "reportsTo": worker.get("reportsTo") or AGENT_ID,
        "capabilities": worker.get("capabilities") or "Role-dispatched runtime worker via OpenClaw executor path.",
        "status": worker.get("status") or "idle",
        "adapterType": adapter_type,
        "adapterConfig": adapter_cfg,
    }
    try:
        refreshed_worker = req("PATCH", f"/agents/{worker['id']}", worker_payload)
        if isinstance(refreshed_worker, dict) and refreshed_worker.get("id"):
            worker = refreshed_worker
    except Exception:
        # Non-fatal: continue with existing worker config if patch is rejected.
        pass

child_issue_id = None
if worker and worker.get("id"):
    child_payload = {
        "title": f"[Execution] {title}",
        "description": (
            f"Delegated from {identifier}.\n\n"
            "ChiefOfStaff delegation plan:\n\n"
            f"{plan_text[:2000]}\n"
        ),
        "assigneeAgentId": worker["id"],
        "parentId": TASK_ID,
        "status": "todo",
        "priority": priority,
    }
    if project_id:
        child_payload["projectId"] = project_id
    if goal_id:
        child_payload["goalId"] = goal_id
    child = req("POST", f"/companies/{COMPANY_ID}/issues", child_payload)
    child_issue_id = child.get("id")
    if child_issue_id and worker.get("id"):
        try:
            req("POST", f"/agents/{worker['id']}/heartbeat/invoke", {})
            invoked_worker = True
        except Exception:
            invoked_worker = False
    else:
        invoked_worker = False

summary = plan_text[:5000]
comment_lines = [
    f"ChiefOfStaff heartbeat processed `{identifier}`.",
    "",
    "- Checked out task and prepared delegation plan via OpenClaw.",
]
if plan_error_note:
    comment_lines.append(f"- OpenClaw planner degraded to fallback plan due to runtime error: `{plan_error_note}`.")
if child_issue_id:
    comment_lines.append(f"- Delegated implementation to OpenClawWorker in sub-issue `{child_issue_id}`.")
    if hired_worker:
        comment_lines.append("- Hired OpenClawWorker dynamically in this run.")
    if invoked_worker:
        comment_lines.append("- Invoked OpenClawWorker heartbeat to begin execution.")
    else:
        comment_lines.append("- Worker heartbeat invoke failed; Paperclip schedule will pick it up.")
else:
    comment_lines.append("- OpenClawWorker not found; posting plan here for manual assignment.")
comment_lines.extend(
    [
        "",
        "### Plan",
        summary,
    ]
)
patch_issue(TASK_ID, status="in_review", comment="\n".join(comment_lines))
print("HEARTBEAT_OK:executor")
PY
