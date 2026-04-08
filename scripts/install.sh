#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

min_major=22
min_minor=16

if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: Node.js is required (need 24.x or >=22.16)." >&2
  exit 1
fi

node_version_raw="$(node --version)"
node_version="${node_version_raw#v}"
major="${node_version%%.*}"
rest="${node_version#*.}"
minor="${rest%%.*}"

if [[ "${major}" -lt "${min_major}" ]] || { [[ "${major}" -eq "${min_major}" ]] && [[ "${minor}" -lt "${min_minor}" ]]; }; then
  echo "ERROR: Unsupported Node version ${node_version_raw}. Need Node 24.x or >=22.16." >&2
  exit 1
fi

echo "Installing OpenClaw globally..."
npm install -g --loglevel=error openclaw@latest

echo "Attempting daemon onboarding..."
onboard_help="$(openclaw onboard --help 2>&1 || true)"
if [[ "${onboard_help}" == *"--yes"* ]]; then
  if openclaw onboard --install-daemon --yes; then
    echo "OpenClaw onboarding completed non-interactively."
  else
    echo "WARNING: Non-interactive onboarding failed." >&2
    echo "Run this manually: openclaw onboard --install-daemon" >&2
  fi
else
  echo "OpenClaw onboarding appears interactive on this version."
  echo "Run this manually in your terminal: openclaw onboard --install-daemon"
fi

echo
echo "Next step:"
echo "  cd \"${ROOT_DIR}\" && ./scripts/configure.sh"
