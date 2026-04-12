#!/usr/bin/env bash
# Shared helpers for OpenClaw config reads/hashes.

set -euo pipefail

OPENCLAW_HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_HELPER_PY="${OPENCLAW_HELPERS_DIR}/openclaw_config_helper.py"

openclaw_scoped_hash() {
  local config_path="$1"
  python3 - "${OPENCLAW_HELPER_PY}" "${config_path}" <<'PY'
import importlib.util
import pathlib
import sys

helper_path = pathlib.Path(sys.argv[1])
config_path = pathlib.Path(sys.argv[2]).expanduser()

spec = importlib.util.spec_from_file_location("openclaw_config_helper", helper_path)
if spec is None or spec.loader is None:
    raise SystemExit(f"Unable to load helper module: {helper_path}")
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

print(mod.scoped_hash_for_file(config_path))
PY
}
