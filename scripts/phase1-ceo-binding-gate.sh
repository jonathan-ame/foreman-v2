#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
EVIDENCE_PATH="${ROOT_DIR}/state/phase1-ceo-binding-gate.json"
OPENCLAW_CFG="${HOME}/.openclaw/openclaw.json"

mkdir -p "${ROOT_DIR}/state"

python3 - "${EVIDENCE_PATH}" "${OPENCLAW_CFG}" <<'PY'
import json
import re
import subprocess
import sys
import time
from pathlib import Path

evidence_path = Path(sys.argv[1])
cfg_path = Path(sys.argv[2])
openclaw_home = Path.home() / ".openclaw"


def strip_reasoning_think_blocks(text: str) -> str:
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


def normalize_terminal_line(text: str) -> str:
    compact = "\n".join([ln.strip() for ln in (text or "").splitlines() if ln.strip()])
    # If model emits verbose prose, we still want the final terminal marker line.
    for line in reversed(compact.splitlines()):
        if line.strip():
            return line.strip()
    return ""


def strip_no_reply_trailer(text: str) -> str:
    lines = [ln for ln in (text or "").splitlines()]
    while lines and lines[-1].strip().upper() == "NO_REPLY":
        lines.pop()
    return "\n".join(lines).strip()


def reset_agent_sessions(agent: str) -> None:
    sessions_dir = openclaw_home / "agents" / agent / "sessions"
    if not sessions_dir.is_dir():
        return
    for child in sessions_dir.iterdir():
        if child.is_file() and child.suffix == ".jsonl":
            try:
                child.unlink()
            except OSError:
                pass


def run_plain(agent: str) -> str:
    session_id = f"phase1-gate-{agent}-plain-{int(time.time() * 1000)}"
    cmd = [
        "openclaw",
        "agent",
        "--agent",
        agent,
        "--session-id",
        session_id,
        "-m",
        "reply with exactly HEARTBEAT_OK and nothing else",
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    return (proc.stdout or "").strip() if proc.returncode == 0 else ((proc.stdout or "") + "\n" + (proc.stderr or "")).strip()


def run_json(agent: str) -> dict:
    session_id = f"phase1-gate-{agent}-json-{int(time.time() * 1000)}"
    cmd = [
        "openclaw",
        "agent",
        "--agent",
        agent,
        "--session-id",
        session_id,
        "--json",
        "-m",
        "reply with exactly HEARTBEAT_OK and nothing else",
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    try:
        return json.loads(proc.stdout or "{}")
    except json.JSONDecodeError:
        return {"_parse_error": True, "_raw": (proc.stdout or "") + (proc.stderr or "")}


def load_config(path: Path) -> dict:
    raw = path.read_text(encoding="utf-8")
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        parser_path = "/opt/homebrew/lib/node_modules/openclaw/node_modules/json5/lib/index.js"
        node_cmd = [
            "node",
            "-e",
            (
                "const fs=require('fs');"
                f"const JSON5=require('{parser_path}');"
                "const raw=fs.readFileSync(process.argv[1],'utf8');"
                "const cfg=JSON5.parse(raw);"
                "process.stdout.write(JSON.stringify(cfg));"
            ),
            str(path),
        ]
        proc = subprocess.run(node_cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            raise RuntimeError(f"JSON5 parse failed: {proc.stderr.strip()}")
        return json.loads(proc.stdout or "{}")


cfg = load_config(cfg_path)
providers = (((cfg.get("models") or {}).get("providers")) or {})

agent_to_provider = {
    "ceo-planner": "planner",
    "ceo-executor": "executor",
    "ceo-reviewer": "reviewer",
}

results = {}
failed = []

for agent in ("ceo-planner", "ceo-executor", "ceo-reviewer"):
    reset_agent_sessions(agent)
    raw = run_plain(agent)
    stripped = strip_reasoning_think_blocks(raw)
    stripped_no_reply = strip_no_reply_trailer(stripped)
    terminal_line = normalize_terminal_line(stripped)
    terminal_line_no_reply = normalize_terminal_line(stripped_no_reply)
    meta = run_json(agent)

    provider = agent_to_provider[agent]
    provider_cfg = providers.get(provider) or {}
    model_cfgs = provider_cfg.get("models") or []
    provider_model = model_cfgs[0].get("id") if model_cfgs else ""
    base_url = str(provider_cfg.get("baseUrl") or "").strip()

    overflow = "context overflow" in raw.lower() or "context overflow" in stripped.lower()

    # Planner is a reasoning model: probe may contain reasoning prelude.
    # Gate checks planner by terminal marker, not exact full-text equality.
    if agent == "ceo-planner":
        passed = (not overflow) and terminal_line_no_reply.endswith("HEARTBEAT_OK")
    else:
        passed = (not overflow) and terminal_line == "HEARTBEAT_OK"

    if not passed:
        failed.append(agent)

    results[agent] = {
        "provider": provider,
        "provider_model": provider_model,
        "provider_base_url": base_url,
        "raw_output": raw,
        "post_strip_output": stripped,
        "post_strip_output_no_reply": stripped_no_reply,
        "terminal_line": terminal_line,
        "terminal_line_no_reply": terminal_line_no_reply,
        "overflow_detected": overflow,
        "json_meta": meta.get("result", {}).get("meta", {}),
        "passed": passed,
    }

payload = {
    "phase": "phase1-ceo-binding-gate",
    "results": results,
    "all_passed": len(failed) == 0,
    "failed_agents": failed,
}
evidence_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"EVIDENCE: {evidence_path}")
if failed:
    print("FAILED: " + ", ".join(failed))
    raise SystemExit(1)
print("PASS")
PY
