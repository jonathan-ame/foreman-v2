#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
TEMPLATE_FILE="${ROOT_DIR}/config/openclaw.foreman.json5"
TARGET_INCLUDE="${HOME}/.openclaw/foreman.json5"

[[ -f "${ENV_FILE}" ]] || { echo "ERROR: Missing ${ENV_FILE}. Copy .env.example to .env first." >&2; exit 1; }
[[ -f "${TEMPLATE_FILE}" ]] || { echo "ERROR: Missing template ${TEMPLATE_FILE}." >&2; exit 1; }

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

for key in TOGETHER_API_KEY DASHSCOPE_US_KEY DASHSCOPE_SG_KEY; do
  [[ -n "${!key:-}" ]] || { echo "ERROR: Missing ${key} in .env" >&2; exit 1; }
done

mkdir -p "$(dirname "${TARGET_INCLUDE}")"

if [[ -f "${TARGET_INCLUDE}" ]]; then
  cp "${TARGET_INCLUDE}" "${TARGET_INCLUDE}.bak-$(date +%Y%m%d-%H%M%S)"
fi

python3 - "${TEMPLATE_FILE}" "${TARGET_INCLUDE}" <<'PY'
import os, re, sys
src, dst = sys.argv[1], sys.argv[2]
with open(src) as f:
    content = f.read()
def sub(match):
    var = match.group(1)
    val = os.environ.get(var, '')
    if not val:
        raise SystemExit(f"ERROR: template references ${{{var}}} but not set in env")
    return val
content = re.sub(r'\$\{([A-Z_][A-Z0-9_]*)\}', sub, content)
with open(dst, 'w') as f:
    f.write(content)
os.chmod(dst, 0o600)
PY

echo "Wrote ${TARGET_INCLUDE} (mode 600)"
echo "OpenClaw will pick up the new include on next gateway start or 'openclaw secrets reload'."
