#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

python3 - "${ROOT_DIR}" <<'PY'
import json
import subprocess
import time
import uuid
from pathlib import Path
import sys

ROOT_DIR = Path(sys.argv[1]).resolve()
HELPER_DIR = ROOT_DIR / "scripts" / "lib"
if str(HELPER_DIR) not in sys.path:
    sys.path.insert(0, str(HELPER_DIR))

from tool_call_recorder import (
    append_tool_call_records,
    collect_tool_calls_from_transcript_window,
    resolve_session_file_for_agent,
)


def run_openclaw(session_id: str, message: str) -> tuple[int, str, str, int, int]:
    cmd = ["openclaw", "agent", "--agent", "main", "--session-id", session_id, "--json", "-m", message]
    started_ms = int(time.time() * 1000)
    proc = subprocess.run(cmd, capture_output=True, text=True, cwd=str(ROOT_DIR), check=False)
    finished_ms = int(time.time() * 1000)
    return proc.returncode, proc.stdout or "", proc.stderr or "", started_ms, finished_ms


run_id = f"phase2-tool-gate-{int(time.time())}-{uuid.uuid4().hex[:6]}"
run_logs_dir = ROOT_DIR / "state" / "run-logs" / run_id
run_logs_dir.mkdir(parents=True, exist_ok=True)
tool_log_path = run_logs_dir / "tool-calls.jsonl"
if tool_log_path.exists():
    tool_log_path.unlink()

positive_message = (
    "Use exactly these tools in order: "
    "(1) write file state/phase2-gate-note.txt with content PHASE2_GATE_NOTE, "
    "(2) read state/phase2-gate-note.txt, "
    "(3) exec command 'echo PHASE2_EXEC_OK'. "
    "Then reply with exactly PHASE2_GATE_DONE."
)
negative_message = (
    "Use exec with command: bash -lc 'echo PHASE2_FAIL_STDERR 1>&2; exit 7'. "
    "Then reply with exactly PHASE2_NEGATIVE_DONE."
)

positive_session = f"phase2-gate-positive-{uuid.uuid4().hex[:8]}"
negative_session = f"phase2-gate-negative-{uuid.uuid4().hex[:8]}"

pos_code, pos_out, pos_err, pos_start, pos_end = run_openclaw(positive_session, positive_message)
session_file = resolve_session_file_for_agent(Path.home() / ".openclaw", "main")
if session_file is None:
    raise SystemExit("FAIL: could not resolve OpenClaw main session transcript file")
pos_records = collect_tool_calls_from_transcript_window(
    session_file,
    run_id=run_id,
    step_id="phase2_gate_positive",
    started_ms=pos_start,
    finished_ms=pos_end,
)
append_tool_call_records(run_logs_dir, pos_records)

neg_code, neg_out, neg_err, neg_start, neg_end = run_openclaw(negative_session, negative_message)
neg_records = collect_tool_calls_from_transcript_window(
    session_file,
    run_id=run_id,
    step_id="phase2_gate_negative",
    started_ms=neg_start,
    finished_ms=neg_end,
)
append_tool_call_records(run_logs_dir, neg_records)

all_records = []
for line in tool_log_path.read_text(encoding="utf-8").splitlines():
    if line.strip():
        all_records.append(json.loads(line))

positive_tools = {r.get("tool_name") for r in all_records if r.get("step_id") == "phase2_gate_positive"}
required_tools = {"write", "read", "exec"}
if not required_tools.issubset(positive_tools):
    raise SystemExit(
        f"FAIL: positive run did not capture required tools. have={sorted(positive_tools)} need={sorted(required_tools)}"
    )

negative_exec = [
    r for r in all_records
    if r.get("step_id") == "phase2_gate_negative" and r.get("tool_name") == "exec"
]
if not negative_exec:
    raise SystemExit("FAIL: negative run missing exec record")
neg = negative_exec[0]
if int(neg.get("exit_code") or 0) == 0 and not (neg.get("stderr") or ""):
    raise SystemExit("FAIL: negative exec record did not capture failure state")

summary = {
    "run_id": run_id,
    "tool_log_path": str(tool_log_path),
    "positive_invocation": {
        "session_id": positive_session,
        "message": positive_message,
        "exit_code": pos_code,
        "stdout": pos_out,
        "stderr": pos_err,
        "records_captured": len(pos_records),
    },
    "negative_invocation": {
        "session_id": negative_session,
        "message": negative_message,
        "exit_code": neg_code,
        "stdout": neg_out,
        "stderr": neg_err,
        "records_captured": len(neg_records),
    },
    "required_tools_present": sorted(positive_tools),
    "negative_exec_record": neg,
}
(run_logs_dir / "phase2-gate-summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
print(f"RUN_ID={run_id}")
print(f"TOOL_LOG={tool_log_path}")
print("PASS")
PY
