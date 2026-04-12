#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_FILE="${HOME}/.openclaw/openclaw.json"
CHECKSUM_FILE="${ROOT_DIR}/state/openclaw-config-checksum.txt"
LAST_RESTORE_FILE="${ROOT_DIR}/state/openclaw-config-last-restore.txt"
CONFIGURE_SCRIPT="${ROOT_DIR}/scripts/configure.sh"
HELPER_SCRIPT="${ROOT_DIR}/scripts/lib/openclaw-config-helpers.sh"
LOG_DIR="/tmp/foreman"
LOG_FILE="${LOG_DIR}/stack-health.log"
PAPERCLIP_LABEL="ai.foreman.paperclip"
PAPERCLIP_PLIST="/Users/jonathanborgia/Library/LaunchAgents/${PAPERCLIP_LABEL}.plist"
RESTORE_RATE_LIMIT_SECONDS=900

export PATH="/Users/jonathanborgia/.nvm/versions/node/v24.14.1/bin:/Users/jonathanborgia/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

mkdir -p "${LOG_DIR}"
mkdir -p "${ROOT_DIR}/state"

# shellcheck source=/dev/null
source "${HELPER_SCRIPT}"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "${LOG_FILE}"
}

http_is_reachable() {
  local url="$1"
  local code
  code="$(curl -sS -o /dev/null -w "%{http_code}" "${url}" || true)"
  [[ -n "${code}" && "${code}" != "000" ]]
}

wait_for_http() {
  local url="$1"
  local timeout_seconds="$2"
  local label="$3"
  local started_at
  started_at="$(date +%s)"

  while true; do
    if http_is_reachable "${url}"; then
      log "${label} is reachable at ${url}."
      return 0
    fi
    if (( "$(date +%s)" - started_at >= timeout_seconds )); then
      log "ERROR: ${label} did not become reachable at ${url} within ${timeout_seconds}s."
      return 1
    fi
    sleep 1
  done
}

config_has_providers() {
  python3 - "${CONFIG_FILE}" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
if not path.exists():
    raise SystemExit(1)

text = path.read_text(encoding="utf-8")
normalized = text.replace('"', "").replace("'", "")
required_snippets = [
    "models",
    "providers",
    "executor",
    "planner",
    "reviewer",
    "embedding",
    "baseUrl",
]
for snippet in required_snippets:
    if snippet not in normalized:
        raise SystemExit(1)
if "__executor_base_url__" in normalized or "__planner_base_url__" in normalized or "__reviewer_base_url__" in normalized or "__embedding_base_url__" in normalized:
    raise SystemExit(1)
PY
}

current_config_scoped_hash() {
  openclaw_scoped_hash "${CONFIG_FILE}"
}

expected_config_scoped_hash() {
  if [[ ! -f "${CHECKSUM_FILE}" ]]; then
    return 1
  fi
  local raw
  raw="$(tr -d '[:space:]' < "${CHECKSUM_FILE}")"
  if [[ "${raw}" =~ ^scoped-v1:[0-9a-f]{64}$ ]]; then
    printf '%s\n' "${raw#scoped-v1:}"
    return 0
  fi
  if [[ "${raw}" =~ ^[0-9a-f]{64}$ ]]; then
    printf 'LEGACY_FULL_HASH\n'
    return 0
  fi
  return 1
}

write_scoped_checksum() {
  local scoped_hash="$1"
  printf 'scoped-v1:%s\n' "${scoped_hash}" > "${CHECKSUM_FILE}"
}

write_last_restore_timestamp() {
  date +%s > "${LAST_RESTORE_FILE}"
}

seconds_since_last_restore() {
  if [[ ! -f "${LAST_RESTORE_FILE}" ]]; then
    return 1
  fi
  local last now
  last="$(tr -d '[:space:]' < "${LAST_RESTORE_FILE}")"
  if [[ ! "${last}" =~ ^[0-9]+$ ]]; then
    return 1
  fi
  now="$(date +%s)"
  printf '%s\n' "$(( now - last ))"
}

restore_openclaw_config_if_needed() {
  local needs_restore="false"

  if [[ ! -f "${CONFIG_FILE}" ]]; then
    log "OpenClaw config missing at ${CONFIG_FILE}; restoring via configure.sh."
    needs_restore="true"
  elif ! config_has_providers; then
    log "OpenClaw config providers missing/invalid; restoring via configure.sh."
    needs_restore="true"
  else
    local expected_hash
    expected_hash="$(expected_config_scoped_hash || true)"
    local observed_hash
    observed_hash="$(current_config_scoped_hash)"

    if [[ -z "${expected_hash}" ]]; then
      write_scoped_checksum "${observed_hash}"
      write_last_restore_timestamp
      log "OpenClaw scoped checksum baseline missing; baseline regenerated."
      return
    fi

    if [[ "${expected_hash}" == "LEGACY_FULL_HASH" ]]; then
      write_scoped_checksum "${observed_hash}"
      write_last_restore_timestamp
      log "OpenClaw config checksum format migrated; baseline regenerated."
      return
    fi

    if [[ "${observed_hash}" != "${expected_hash}" ]]; then
      local since_last_restore
      since_last_restore="$(seconds_since_last_restore || true)"
      if [[ -n "${since_last_restore}" ]] && (( since_last_restore < RESTORE_RATE_LIMIT_SECONDS )); then
        log "DRIFT DETECTED but auto-restore suppressed (last restore ${since_last_restore} seconds ago, rate limit ${RESTORE_RATE_LIMIT_SECONDS}s). If this repeats, investigate what is mutating models/agents in ~/.openclaw/openclaw.json."
        return
      fi
      log "OpenClaw scoped checksum drift detected in models/agents; restoring via configure.sh."
      needs_restore="true"
    else
      if [[ ! -f "${LAST_RESTORE_FILE}" ]]; then
        write_last_restore_timestamp
      fi
      return 0
    fi
  fi

  if [[ "${needs_restore}" == "true" ]]; then
    "${CONFIGURE_SCRIPT}" >> "${LOG_FILE}" 2>&1
    write_last_restore_timestamp
    local refreshed_hash
    refreshed_hash="$(current_config_scoped_hash)"
    write_scoped_checksum "${refreshed_hash}"
    log "OpenClaw configuration refreshed."
  fi
}

ensure_paperclip_launch_agent_loaded() {
  local gui_uid
  gui_uid="$(id -u)"
  if ! launchctl print "gui/${gui_uid}/${PAPERCLIP_LABEL}" >/dev/null 2>&1; then
    log "Loading LaunchAgent ${PAPERCLIP_LABEL}."
    launchctl bootstrap "gui/${gui_uid}" "${PAPERCLIP_PLIST}" >> "${LOG_FILE}" 2>&1 || true
  fi
}

main() {
  restore_openclaw_config_if_needed

  if ! http_is_reachable "http://127.0.0.1:18789"; then
    log "OpenClaw gateway is down; restarting."
    restore_openclaw_config_if_needed
    openclaw gateway restart >> "${LOG_FILE}" 2>&1
    wait_for_http "http://127.0.0.1:18789" 10 "OpenClaw gateway" || true
  fi

  if ! http_is_reachable "http://127.0.0.1:3125"; then
    log "Paperclip is down; kickstarting LaunchAgent."
    ensure_paperclip_launch_agent_loaded
    launchctl kickstart -k "gui/$(id -u)/${PAPERCLIP_LABEL}" >> "${LOG_FILE}" 2>&1 || true
    wait_for_http "http://127.0.0.1:3125" 15 "Paperclip server" || true
  fi
}

main "$@"
