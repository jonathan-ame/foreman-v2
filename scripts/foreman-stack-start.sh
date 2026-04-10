#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DATA_DIR_ROOT="/Users/jonathanborgia/tmp-paperclip-ceo-reset/data"
DATA_INSTANCE="ceo-baseline"
LOG_DIR="/tmp/foreman"
PAPERCLIP_STDOUT="${LOG_DIR}/paperclip-stdout.log"
PAPERCLIP_STDERR="${LOG_DIR}/paperclip-stderr.log"

mkdir -p "${LOG_DIR}"

wait_for_http() {
  local url="$1"
  local timeout_seconds="$2"
  local label="$3"
  local started_at
  started_at="$(date +%s)"

  while true; do
    local code
    code="$(curl -sS -o /dev/null -w "%{http_code}" "${url}" || true)"
    if [[ -n "${code}" && "${code}" != "000" ]]; then
      echo "${label} is reachable at ${url} (HTTP ${code})."
      return 0
    fi

    local now
    now="$(date +%s)"
    if (( now - started_at >= timeout_seconds )); then
      echo "ERROR: ${label} did not become reachable at ${url} within ${timeout_seconds}s." >&2
      return 1
    fi
    sleep 1
  done
}

echo "Running OpenClaw configuration refresh..."
"${ROOT_DIR}/scripts/configure.sh"

echo "Restarting OpenClaw gateway..."
openclaw gateway restart

wait_for_http "http://127.0.0.1:18789" 10 "OpenClaw gateway"

if lsof -tiTCP:3125 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Paperclip already listening on :3125, skipping restart."
else
  echo "Starting Paperclip server..."
  nohup npx --yes paperclipai@2026.403.0 run -d "${DATA_DIR_ROOT}" -i "${DATA_INSTANCE}" >>"${PAPERCLIP_STDOUT}" 2>>"${PAPERCLIP_STDERR}" &
fi

wait_for_http "http://127.0.0.1:3125" 15 "Paperclip server"

echo "Foreman stack startup checks passed."
