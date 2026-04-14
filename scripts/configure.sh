#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
TEMPLATE_FILE="${ROOT_DIR}/config/openclaw.foreman.json"
OPENCLAW_HOME="${HOME}/.openclaw"
TARGET_CONFIG="${OPENCLAW_HOME}/openclaw.json"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "ERROR: Missing ${ENV_FILE}. Copy .env.example to .env first." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

if [[ ! -f "${TEMPLATE_FILE}" ]]; then
  echo "ERROR: Missing template ${TEMPLATE_FILE}." >&2
  exit 1
fi

mkdir -p "${OPENCLAW_HOME}"

if [[ -f "${TARGET_CONFIG}" ]]; then
  backup_path="${TARGET_CONFIG}.bak-$(date +%Y%m%d-%H%M%S)"
  cp "${TARGET_CONFIG}" "${backup_path}"
  echo "Backed up existing config to ${backup_path}"
fi

cp "${TEMPLATE_FILE}" "${TARGET_CONFIG}"

node - "${TARGET_CONFIG}" <<'JS'
const fs = require("node:fs");
const path = process.argv[2];
const { createRequire } = require("node:module");
const text = fs.readFileSync(path, "utf-8");
const req = createRequire(process.cwd() + "/");
let json5;
try {
  json5 = req("json5");
} catch (_) {
  const fallback = createRequire("/opt/homebrew/lib/node_modules/openclaw/package.json");
  json5 = fallback("json5");
}
json5.parse(text);
JS

echo "Wrote ${TARGET_CONFIG}"
echo "Configuration uses Together AI planner + DashScope two-region workers."
