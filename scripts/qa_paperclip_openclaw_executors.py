#!/usr/bin/env python3
"""
Extensive QA: Paperclip + foreman-v2 process executors (CEO + OpenClawWorker).

Exercises:
  - Static validation (bash -n, Python AST for embedded scripts)
  - E2E: create CEO issue -> CEO heartbeat -> child delegated -> worker completes
  - Optional worker-only issue

Requires local Paperclip on PAPERCLIP_API_BASE (default http://127.0.0.1:3125).
OpenClaw gateway should be up for meaningful worker/CEO outcomes.

Exit 0 iff all critical checks pass (strict: child done + worker comment).
"""
from __future__ import annotations

import ast
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = REPO_ROOT / "scripts"
CHIEF = SCRIPTS / "paperclip-chief-executor.sh"
WORKER = SCRIPTS / "paperclip-openclaw-executor.sh"

API_BASE = os.environ.get("PAPERCLIP_API_BASE", "http://127.0.0.1:3125").rstrip("/")
API = f"{API_BASE}/api"
COMPANY_ID = os.environ.get(
    "FOREMAN_QA_COMPANY_ID", "5d1780c4-7574-4632-a97d-a9917b1f2fc0"
)
CEO_ID = os.environ.get(
    "FOREMAN_QA_CEO_ID", "a81ff4a7-5d8b-4a0f-a610-5fcf4cc8a5af"
)
WORKER_ID = os.environ.get(
    "FOREMAN_QA_WORKER_ID", "df87e879-826e-47e8-a6d1-354f5e4735d4"
)

E2E_RUNS = int(os.environ.get("FOREMAN_QA_E2E_RUNS", "4"))
# CEO runs `openclaw agent` for planning; cold runs can exceed 7m — default matches patience for extensive QA.
CEO_HB_TIMEOUT = int(os.environ.get("FOREMAN_QA_CEO_HEARTBEAT_SEC", "720"))
WORKER_HB_TIMEOUT = int(os.environ.get("FOREMAN_QA_WORKER_HEARTBEAT_SEC", "360"))
CHILD_WAIT_SEC = int(os.environ.get("FOREMAN_QA_CHILD_WAIT_SEC", "300"))


def http_code(url: str) -> str:
    try:
        req = urllib.request.Request(url, method="GET")
        with urllib.request.urlopen(req, timeout=5) as r:
            return str(r.status)
    except Exception:
        return "000"


def api(method: str, path: str, payload: dict | None = None) -> dict | list:
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(
        f"{API}{path}",
        data=data,
        headers={"Content-Type": "application/json", "Accept": "application/json"},
        method=method,
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        body = resp.read().decode()
        return json.loads(body) if body else {}


def run_heartbeat(agent_id: str, label: str, timeout_sec: int) -> tuple[int, str]:
    cmd = [
        "npx",
        "--yes",
        "paperclipai@2026.403.0",
        "heartbeat",
        "run",
        "--agent-id",
        agent_id,
        "--api-base",
        API_BASE,
    ]
    try:
        p = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout_sec,
        )
        tail = ((p.stdout or "") + "\n" + (p.stderr or ""))[-1200:]
        return p.returncode, tail
    except subprocess.TimeoutExpired:
        return -1, f"TIMEOUT after {timeout_sec}s"


def wait_for_child(parent_id: str, timeout_sec: int) -> dict | None:
    deadline = time.time() + timeout_sec
    while time.time() < deadline:
        issues = api("GET", f"/companies/{COMPANY_ID}/issues?limit=100")
        items = issues.get("items", issues) if isinstance(issues, dict) else issues
        if not isinstance(items, list):
            time.sleep(2)
            continue
        for it in items:
            if it.get("parentId") == parent_id:
                return it
        time.sleep(3)
    return None


def wait_child_terminal(child_id: str, timeout_sec: int) -> dict:
    deadline = time.time() + timeout_sec
    while time.time() < deadline:
        issue = api("GET", f"/issues/{child_id}")
        st = (issue.get("status") or "").strip()
        if st in ("done", "blocked", "cancelled"):
            return issue
        time.sleep(4)
    return api("GET", f"/issues/{child_id}")


def has_worker_comment(child_id: str) -> bool:
    data = api("GET", f"/issues/{child_id}/comments")
    items = data if isinstance(data, list) else data.get("items", [])
    for c in items:
        body = c.get("body") or ""
        if "OpenClawWorker execution update" in body or "Deliverable" in body:
            return True
    return False


def static_checks() -> list[tuple[str, bool, str]]:
    results: list[tuple[str, bool, str]] = []
    for path, label in [(CHIEF, "chief bash"), (WORKER, "worker bash")]:
        r = subprocess.run(["bash", "-n", str(path)], capture_output=True, text=True)
        ok = r.returncode == 0
        results.append((label + " bash -n", ok, (r.stderr or "")[:200]))

    for path, label in [(CHIEF, "chief py"), (WORKER, "worker py")]:
        text = path.read_text(encoding="utf-8")
        m = re.search(r"python3 - <<'PY'\n(.+?)\nPY", text, re.DOTALL)
        if not m:
            results.append((label + " extract PY", False, "no heredoc"))
            continue
        try:
            ast.parse(m.group(1))
            results.append((label + " ast.parse", True, ""))
        except SyntaxError as e:
            results.append((label + " ast.parse", False, str(e)))
    return results


@dataclass
class E2EResult:
    run: int
    parent_ident: str = ""
    child_ident: str = ""
    parent_status: str = ""
    child_status: str = ""
    worker_comment: bool = False
    ceo_exit: int = -99
    notes: str = ""

    @property
    def strict_pass(self) -> bool:
        return (
            self.child_status == "done"
            and self.worker_comment
            and self.parent_status == "in_review"
            and self.ceo_exit == 0
        )


def main() -> int:
    report: list[str] = []
    report.append("=== Foreman Paperclip/OpenClaw executor QA ===")
    report.append(f"Time (UTC): {datetime.now(timezone.utc).isoformat()}")
    report.append(f"API: {API_BASE}  Paperclip:{http_code(API_BASE + '/')}  OpenClaw:{http_code('http://127.0.0.1:18789/')}")
    report.append("")

    report.append("--- Static checks ---")
    static_ok = True
    for name, ok, detail in static_checks():
        static_ok = static_ok and ok
        report.append(f"  [{'PASS' if ok else 'FAIL'}] {name} {detail}")
    report.append("")

    if not static_ok:
        report.append("CRITICAL: static checks failed.")
        print("\n".join(report))
        return 1

    e2e_results: list[E2EResult] = []
    for n in range(1, E2E_RUNS + 1):
        ts = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
        title = f"[EXT-QA E2E {n}/{E2E_RUNS}] {ts}"
        report.append(f"--- E2E run {n}/{E2E_RUNS}: {title} ---")
        er = E2EResult(run=n)

        try:
            created = api(
                "POST",
                f"/companies/{COMPANY_ID}/issues",
                {
                    "title": title,
                    "description": "Extensive QA: short delegation smoke; worker should deliver notes or block with cause.",
                    "assigneeAgentId": CEO_ID,
                    "status": "todo",
                    "priority": "medium",
                },
            )
        except urllib.error.HTTPError as e:
            er.notes = f"create issue HTTP {e.code}"
            e2e_results.append(er)
            report.append(f"  FAIL create: {er.notes}")
            continue

        parent_id = created.get("id", "")
        er.parent_ident = created.get("identifier") or parent_id[:8]

        er.ceo_exit, tail = run_heartbeat(CEO_ID, "CEO", CEO_HB_TIMEOUT)
        report.append(f"  CEO heartbeat exit={er.ceo_exit}")

        child = wait_for_child(parent_id, 45)
        if not child:
            er.notes = "no child issue after CEO run"
            e2e_results.append(er)
            report.append(f"  FAIL: {er.notes}")
            continue

        child_id = child.get("id")
        er.child_ident = child.get("identifier") or str(child_id)[:8]

        if (child.get("status") or "") == "todo":
            report.append("  Child still todo; invoking worker heartbeat (fallback)")
            wx, _ = run_heartbeat(WORKER_ID, "Worker", WORKER_HB_TIMEOUT)
            report.append(f"  Worker fallback exit={wx}")

        final = wait_child_terminal(child_id, CHILD_WAIT_SEC)
        er.child_status = (final.get("status") or "").strip()
        er.worker_comment = has_worker_comment(child_id)

        parent = api("GET", f"/issues/{parent_id}")
        er.parent_status = (parent.get("status") or "").strip()

        report.append(
            f"  parent={er.parent_ident} status={er.parent_status}  "
            f"child={er.child_ident} status={er.child_status}  "
            f"worker_comment={er.worker_comment}  strict_pass={er.strict_pass}"
        )
        if er.child_status == "blocked":
            report.append("  (child blocked — acceptable if OpenClaw failed; not strict pass)")
        e2e_results.append(er)

    report.append("")
    report.append("--- Summary ---")
    strict_passes = sum(1 for r in e2e_results if r.strict_pass)
    report.append(f"  E2E strict pass: {strict_passes}/{len(e2e_results)}")
    report.append(f"  Static: {'PASS' if static_ok else 'FAIL'}")

    all_strict = static_ok and len(e2e_results) == E2E_RUNS and all(
        r.strict_pass for r in e2e_results
    )
    report.append(f"  OVERALL: {'PASS' if all_strict else 'FAIL (see above)'}")

    out_path = REPO_ROOT / "state" / "qa-executors-last-run.txt"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    text = "\n".join(report)
    out_path.write_text(text, encoding="utf-8")
    print(text)
    print(f"\nWrote {out_path}")
    return 0 if all_strict else 1


if __name__ == "__main__":
    sys.exit(main())
