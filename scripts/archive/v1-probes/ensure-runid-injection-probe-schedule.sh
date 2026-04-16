#!/usr/bin/env bash
set -euo pipefail

# Ensure runid-injection-probe.sh runs periodically via cron
# Patterned after ensure-ceo-auth-probe-schedule.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROBE_SCRIPT="${SCRIPT_DIR}/scripts/runid-injection-probe.sh"
SCHEDULE="*/5 * * * *"  # Every 5 minutes
CRON_JOB="${SCHEDULE} ${PROBE_SCRIPT} 2>&1 | logger -t runid-injection-probe"
CRON_FILE="/tmp/runid-injection-probe-cron"

if [[ ! -f "${PROBE_SCRIPT}" ]]; then
  echo "ERROR: Missing probe script ${PROBE_SCRIPT}" >&2
  exit 1
fi

# Create temporary cron file
echo "${CRON_JOB}" > "${CRON_FILE}"

# Install cron job if not already present
if ! crontab -l | grep -q "runid-injection-probe"; then
  echo "Installing runid-injection-probe cron job"
  if crontab -l 2>/dev/null | cat - "${CRON_FILE}" | crontab -; then
    echo "✓ Installed runid-injection-probe cron job"
  else
    echo "✗ Failed to install cron job" >&2
    exit 1
  fi
else
  echo "✓ runid-injection-probe cron job already installed"
fi

rm -f "${CRON_FILE}"
echo "RunID injection probe scheduling configured"