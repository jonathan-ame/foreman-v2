#!/usr/bin/env python3
"""Shared OpenClaw config utilities for foreman-v2 scripts."""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import tempfile
import time
from pathlib import Path
from typing import Any

JSON5_PATH_CANDIDATES = (
    "/opt/homebrew/lib/node_modules/openclaw/node_modules/json5/lib/index.js",
    "/opt/homebrew/lib/node_modules/openclaw/node_modules/json5/dist/index.js",
    "/opt/homebrew/lib/node_modules/openclaw/node_modules/json5/package.json",
)


def _resolve_json5_module_path() -> str:
    for candidate in JSON5_PATH_CANDIDATES:
        p = Path(candidate)
        if p.is_file():
            # For package.json candidate, require package root.
            if p.name == "package.json":
                return str(p.parent)
            return str(p)
    raise RuntimeError(
        "Unable to resolve OpenClaw json5 module path from known locations."
    )


def _parse_with_node_json5(raw_text: str) -> dict[str, Any]:
    json5_module = _resolve_json5_module_path()
    node_script = r"""
const fs = require("fs");
const input = fs.readFileSync(0, "utf8");
const json5Path = process.argv[1];
const JSON5 = require(json5Path);
const parsed = JSON5.parse(input);
process.stdout.write(JSON.stringify(parsed));
"""
    proc = subprocess.run(
        ["node", "-e", node_script, json5_module],
        input=raw_text,
        text=True,
        capture_output=True,
        check=False,
    )
    if proc.returncode != 0:
        stderr = (proc.stderr or "").strip()
        raise RuntimeError(f"Node JSON5 parse failed: {stderr[:400]}")
    try:
        parsed = json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Node JSON5 output decode failed: {exc}") from exc
    if not isinstance(parsed, dict):
        raise RuntimeError("OpenClaw config root is not an object.")
    return parsed


def parse_openclaw_config_text(raw_text: str) -> dict[str, Any]:
    try:
        parsed = json.loads(raw_text)
    except json.JSONDecodeError:
        parsed = _parse_with_node_json5(raw_text)
    if not isinstance(parsed, dict):
        raise RuntimeError("OpenClaw config root is not an object.")
    return parsed


def read_openclaw_config_once_atomic(config_path: str | Path) -> tuple[dict[str, Any], str]:
    path = Path(config_path).expanduser()
    if not path.is_file():
        raise FileNotFoundError(f"OpenClaw config not found: {path}")

    tmp_path: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            prefix="openclaw-config-read-",
            suffix=".jsonc",
            dir=str(path.parent),
            delete=False,
        ) as tmp:
            tmp_path = tmp.name
        shutil.copy2(path, tmp_path)
        raw = Path(tmp_path).read_text(encoding="utf-8")
        parsed = parse_openclaw_config_text(raw)
        return parsed, raw
    finally:
        if tmp_path:
            try:
                os.unlink(tmp_path)
            except OSError:
                pass


def read_openclaw_config_atomic(
    config_path: str | Path,
    attempts: int = 5,
    delay_seconds: float = 0.25,
) -> tuple[dict[str, Any], str]:
    if attempts < 1:
        raise ValueError("attempts must be >= 1")
    last_exc: Exception | None = None
    for idx in range(1, attempts + 1):
        try:
            return read_openclaw_config_once_atomic(config_path)
        except Exception as exc:  # noqa: BLE001
            last_exc = exc
            if idx < attempts:
                time.sleep(delay_seconds)
    raise RuntimeError(
        f"Failed to atomically read+parse OpenClaw config after {attempts} attempts: {last_exc}"
    )


def canonical_scoped_json(config_obj: dict[str, Any]) -> str:
    scoped: dict[str, Any] = {}
    if isinstance(config_obj.get("models"), dict):
        scoped["models"] = config_obj["models"]
    if isinstance(config_obj.get("agents"), dict):
        scoped["agents"] = config_obj["agents"]
    return json.dumps(scoped, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def scoped_config_hash(config_obj: dict[str, Any]) -> str:
    serialized = canonical_scoped_json(config_obj)
    return hashlib.sha256(serialized.encode("utf-8")).hexdigest()


def scoped_hash_for_file(
    config_path: str | Path,
    attempts: int = 5,
    delay_seconds: float = 0.25,
) -> str:
    cfg, _ = read_openclaw_config_atomic(
        config_path=config_path,
        attempts=attempts,
        delay_seconds=delay_seconds,
    )
    return scoped_config_hash(cfg)
