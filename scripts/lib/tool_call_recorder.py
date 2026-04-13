#!/usr/bin/env python3
"""Tool-call recording utilities for OpenClaw transcript interception."""

from __future__ import annotations

import datetime as dt
import json
from pathlib import Path
from typing import Any


def _iso_from_ms(epoch_ms: int | None) -> str | None:
    if epoch_ms is None:
        return None
    return dt.datetime.fromtimestamp(epoch_ms / 1000, tz=dt.timezone.utc).isoformat()


def _to_int_ms(value: Any) -> int | None:
    try:
        if value is None:
            return None
        if isinstance(value, (int, float)):
            return int(value)
        return int(str(value).strip())
    except Exception:
        return None


def _extract_text_content(content: Any) -> str:
    if not isinstance(content, list):
        return ""
    parts: list[str] = []
    for item in content:
        if not isinstance(item, dict):
            continue
        if item.get("type") == "text":
            text = item.get("text")
            if text is not None:
                parts.append(str(text))
    return "\n".join(parts).strip()


def resolve_session_file_for_agent(openclaw_home: Path, agent_id: str) -> Path | None:
    sessions_dir = openclaw_home / "agents" / agent_id / "sessions"
    store_path = sessions_dir / "sessions.json"
    if not store_path.is_file():
        return None
    try:
        store = json.loads(store_path.read_text(encoding="utf-8"))
    except Exception:
        return None
    if not isinstance(store, dict):
        return None
    entry = store.get(f"agent:{agent_id}:main")
    if not isinstance(entry, dict):
        return None
    session_id = str(entry.get("sessionId") or "").strip()
    if not session_id:
        return None
    session_file = sessions_dir / f"{session_id}.jsonl"
    return session_file if session_file.is_file() else None


def collect_tool_calls_from_transcript_window(
    session_file: Path,
    *,
    run_id: str,
    step_id: str,
    started_ms: int,
    finished_ms: int,
    window_slack_ms: int = 2_000,
) -> list[dict[str, Any]]:
    if not session_file.is_file():
        return []

    min_ts = started_ms - max(0, window_slack_ms)
    max_ts = finished_ms + max(0, window_slack_ms)

    calls: dict[str, dict[str, Any]] = {}
    results: dict[str, list[dict[str, Any]]] = {}

    with session_file.open("r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            if not isinstance(event, dict) or event.get("type") != "message":
                continue
            msg = event.get("message")
            if not isinstance(msg, dict):
                continue
            msg_ts = _to_int_ms(msg.get("timestamp"))
            if msg_ts is None or msg_ts < min_ts or msg_ts > max_ts:
                continue
            role = str(msg.get("role") or "")
            if role == "assistant":
                content = msg.get("content")
                if not isinstance(content, list):
                    continue
                for part in content:
                    if not isinstance(part, dict) or part.get("type") != "toolCall":
                        continue
                    tool_call_id = str(part.get("id") or "").strip()
                    tool_name = str(part.get("name") or "").strip()
                    if not tool_call_id or not tool_name:
                        continue
                    calls[tool_call_id] = {
                        "tool_call_id": tool_call_id,
                        "tool_name": tool_name,
                        "args": part.get("arguments"),
                        "started_ms": msg_ts,
                    }
            elif role == "toolResult":
                tool_call_id = str(msg.get("toolCallId") or "").strip()
                if not tool_call_id:
                    continue
                results.setdefault(tool_call_id, []).append(
                    {
                        "timestamp_ms": msg_ts,
                        "tool_name": str(msg.get("toolName") or "").strip(),
                        "is_error": bool(msg.get("isError")),
                        "details": msg.get("details"),
                        "content_text": _extract_text_content(msg.get("content")),
                    }
                )

    records: list[dict[str, Any]] = []
    for tool_call_id, call in sorted(calls.items(), key=lambda item: item[1]["started_ms"]):
        result_rows = sorted(results.get(tool_call_id, []), key=lambda row: row["timestamp_ms"])
        result = result_rows[0] if result_rows else None

        exit_code = None
        stdout = ""
        stderr = ""
        success = False
        finished_at_ms = None

        if result is not None:
            finished_at_ms = _to_int_ms(result.get("timestamp_ms"))
            details = result.get("details")
            is_error = bool(result.get("is_error"))
            details_status = ""
            content_text = str(result.get("content_text") or "")
            if isinstance(details, dict):
                details_status = str(details.get("status") or "").strip().lower()
                if details.get("exitCode") is not None:
                    try:
                        exit_code = int(details.get("exitCode"))
                    except Exception:
                        exit_code = None
                if details.get("stdout") is not None:
                    stdout = str(details.get("stdout"))
                elif details.get("aggregated") is not None:
                    stdout = str(details.get("aggregated"))
                if details.get("stderr") is not None:
                    stderr = str(details.get("stderr"))
                if details_status == "error" and not stderr:
                    stderr = content_text
            if not stdout and content_text and not is_error:
                stdout = content_text
            if not stderr and content_text and is_error:
                stderr = content_text
            success = (not is_error) and (details_status != "error") and (exit_code in (None, 0))

        records.append(
            {
                "run_id": run_id,
                "step_id": step_id,
                "evidence_id": f"{step_id}:{tool_call_id}",
                "source": "openclaw_tool",
                "tool_call_id": tool_call_id,
                "tool_name": call["tool_name"],
                "args": call.get("args"),
                "started_at": _iso_from_ms(call.get("started_ms")),
                "finished_at": _iso_from_ms(finished_at_ms),
                "exit_code": exit_code,
                "stdout": stdout,
                "stderr": stderr,
                "success": success,
            }
        )
    return records


def append_tool_call_records(run_logs_dir: Path, records: list[dict[str, Any]]) -> Path:
    run_logs_dir.mkdir(parents=True, exist_ok=True)
    out_path = run_logs_dir / "tool-calls.jsonl"
    with out_path.open("a", encoding="utf-8") as fh:
        for record in records:
            fh.write(json.dumps(record, ensure_ascii=True) + "\n")
    return out_path
