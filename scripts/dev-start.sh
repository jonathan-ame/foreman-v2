#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend"
ENV_FILE="${ROOT_DIR}/.env"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

echo "=== Foreman v2 Development Environment ==="
echo

if ! command -v pnpm &>/dev/null; then
  echo "Error: pnpm is required. Install with: npm install -g pnpm"
  exit 1
fi

echo "Installing dependencies..."
cd "${BACKEND_DIR}" && pnpm install --frozen-lockfile 2>/dev/null

echo "Building web frontend..."
cd "${BACKEND_DIR}" && pnpm --dir web install --frozen-lockfile 2>/dev/null
pnpm --dir web build

echo
echo "Checking Paperclip connection..."
PAPERCLIP_URL="${PAPERCLIP_API_BASE:-http://localhost:3100}"
if curl -sf "${PAPERCLIP_URL}/api/health" >/dev/null 2>&1; then
  echo "Paperclip is running at ${PAPERCLIP_URL}"
else
  echo "Warning: Paperclip not reachable at ${PAPERCLIP_URL}"
  echo "Start Paperclip first: npx paperclipai onboard --yes && npx paperclipai start"
fi

echo
echo "Checking database connection..."
if [[ -z "${SUPABASE_URL:-}" ]]; then
  echo "Warning: SUPABASE_URL not set. Check .env configuration."
fi

echo
echo "Starting backend server on port ${PORT:-8080}..."
echo "Press Ctrl+C to stop."
echo

cd "${BACKEND_DIR}" && pnpm run dev