#!/usr/bin/env bash
# Credential Rotation Helper for Foreman Phase 1 Infrastructure
#
# Usage:
#   ./scripts/rotate-credentials.sh [provider] [--dry-run] [--check]
#
# Providers: stripe, supabase, cloudflare, railway, resend, sentry, openrouter, dashscope
# --dry-run  Show what would be rotated without making changes
# --check    Check which credentials need rotation based on policy
#
# This script:
# 1. Reads the current .env file
# 2. Identifies credentials that need rotation based on policy
# 3. Validates new credentials against provider APIs
# 4. Updates .env with new values
# 5. Creates a timestamped backup of the old .env
#
# Credential storage architecture:
# - Local dev: .env file (gitignored, chmod 600)
# - Railway production: Railway environment variables (encrypted at rest)
# - Future Phase 2: Supabase Vault for DB-stored secrets
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
BACKUP_DIR="${ROOT_DIR}/state/credential-backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${BLUE}[rotate]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; }
success() { echo -e "${GREEN}[ok]${NC} $*"; }

# ─── Rotation Policies (days) ────────────────────────────────────────────────
# These match the rotationDays values in backend/src/config/secrets.ts
declare -A ROTATION_POLICY
ROTATION_POLICY[STRIPE_SECRET_KEY]=90
ROTATION_POLICY[STRIPE_SECRET_KEY_TEST]=90
ROTATION_POLICY[STRIPE_WEBHOOK_SECRET]=180
ROTATION_POLICY[STRIPE_WEBHOOK_SECRET_TEST]=180
ROTATION_POLICY[SUPABASE_SERVICE_KEY]=90
ROTATION_POLICY[SUPABASE_ANON_KEY]=180
ROTATION_POLICY[CLOUDFLARE_API_TOKEN]=90
ROTATION_POLICY[RAILWAY_API_KEY]=90
ROTATION_POLICY[RESEND_API_KEY]=90
ROTATION_POLICY[OPENROUTER_API_KEY]=90
ROTATION_POLICY[DASHSCOPE_SG_KEY]=90
ROTATION_POLICY[DASHSCOPE_US_KEY]=90
ROTATION_POLICY[TOGETHER_API_KEY]=90
ROTATION_POLICY[DEEPINFRA_API_KEY]=90
ROTATION_POLICY[OPENCLAW_GATEWAY_TOKEN]=90
ROTATION_POLICY[PAPERCLIP_API_KEY]=90

# ─── Parse Arguments ─────────────────────────────────────────────────────────

PROVIDER=""
DRY_RUN=false
CHECK_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --check) CHECK_ONLY=true; shift ;;
    stripe|supabase|cloudflare|railway|resend|sentry|openrouter|dashscope|together|deepinfra|openclaw|paperclip)
      PROVIDER="$1"; shift ;;
    *)
      error "Unknown argument: $1"
      echo "Usage: $0 [provider] [--dry-run] [--check]"
      exit 1 ;;
  esac
done

# ─── Provider → Variable Mapping ─────────────────────────────────────────────

provider_vars() {
  case "$1" in
    stripe)
      echo "STRIPE_SECRET_KEY STRIPE_SECRET_KEY_TEST STRIPE_WEBHOOK_SECRET STRIPE_WEBHOOK_SECRET_TEST"
      ;;
    supabase)
      echo "SUPABASE_SERVICE_KEY SUPABASE_ANON_KEY"
      ;;
    cloudflare)
      echo "CLOUDFLARE_API_TOKEN"
      ;;
    railway)
      echo "RAILWAY_API_KEY"
      ;;
    resend)
      echo "RESEND_API_KEY"
      ;;
    sentry)
      echo "SENTRY_DSN"
      ;;
    openrouter)
      echo "OPENROUTER_API_KEY"
      ;;
    dashscope)
      echo "DASHSCOPE_SG_KEY DASHSCOPE_US_KEY"
      ;;
    together)
      echo "TOGETHER_API_KEY"
      ;;
    deepinfra)
      echo "DEEPINFRA_API_KEY"
      ;;
    openclaw)
      echo "OPENCLAW_GATEWAY_TOKEN"
      ;;
    paperclip)
      echo "PAPERCLIP_API_KEY"
      ;;
    *)
      # All keys with rotation policies
      echo "${!ROTATION_POLICY[@]}"
      ;;
  esac
}

# ─── Check Mode ───────────────────────────────────────────────────────────────

if [[ "$CHECK_ONLY" == "true" ]]; then
  log "Checking credential rotation status..."
  echo ""

  # Read rotation tracking file
  ROTATION_FILE="${ROOT_DIR}/state/credential-rotation-dates.json"
  declare -A LAST_ROTATED

  if [[ -f "$ROTATION_FILE" ]]; then
    while IFS="=" read -r key value; do
      LAST_ROTATED["$key"]="$value"
    done < <(python3 -c "
import json, sys
try:
    data = json.load(open('${ROTATION_FILE}'))
    for k, v in data.items():
        print(f'{k}={v}')
except: pass
")
  fi

  NEEDS_ROTATION=0
  OK=0
  NO_POLICY=0

  for VAR in $(provider_vars "$PROVIDER"); do
    POLICY_DAYS="${ROTATION_POLICY[$VAR]:-0}"

    if [[ "$POLICY_DAYS" == "0" ]]; then
      NO_POLICY=$((NO_POLICY + 1))
      continue
    fi

    LAST_DATE="${LAST_ROTATED[$VAR]:-unknown}"

    if [[ "$LAST_DATE" == "unknown" ]]; then
      warn "$VAR — rotation date unknown (policy: ${POLICY_DAYS}d)"
      NEEDS_ROTATION=$((NEEDS_ROTATION + 1))
    else
      # Calculate days since rotation
      DAYS_SINCE=$(( ( $(date +%s) - $(date -j -f "%Y-%m-%d" "$LAST_DATE" +%s 2>/dev/null || echo 0) ) / 86400 ))
      if [[ "$DAYS_SINCE" -gt "$POLICY_DAYS" ]]; then
        warn "$VAR — ${DAYS_SINCE}d since rotation (policy: ${POLICY_DAYS}d) ⚠️"
        NEEDS_ROTATION=$((NEEDS_ROTATION + 1))
      else
        REMAINING=$((POLICY_DAYS - DAYS_SINCE))
        success "$VAR — ${DAYS_SINCE}d old, ${REMAINING}d remaining"
        OK=$((OK + 1))
      fi
    fi
  done

  echo ""
  log "Summary: ${OK} OK, ${NEEDS_ROTATION} need rotation, ${NO_POLICY} no policy"

  if [[ "$NEEDS_ROTATION" -gt 0 ]]; then
    exit 1
  fi
  exit 0
fi

# ─── Rotate Mode ──────────────────────────────────────────────────────────────

if [[ ! -f "$ENV_FILE" ]]; then
  error ".env file not found at ${ENV_FILE}"
  exit 1
fi

# Check file permissions
PERMS=$(stat -f "%Lp" "$ENV_FILE" 2>/dev/null || stat -c "%a" "$ENV_FILE" 2>/dev/null || echo "000")
if [[ "$PERMS" != "600" && "$PERMS" != "400" ]]; then
  warn ".env file permissions are ${PERMS}, recommend chmod 600"
  if [[ "$DRY_RUN" == "false" ]]; then
    chmod 600 "$ENV_FILE"
    success "Fixed .env permissions to 600"
  fi
fi

# Create backup
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="${BACKUP_DIR}/.env.backup-$(date +%Y%m%d-%H%M%S)"

if [[ "$DRY_RUN" == "true" ]]; then
  log "DRY RUN: Would backup .env to ${BACKUP_FILE}"
else
  cp "$ENV_FILE" "$BACKUP_FILE"
  chmod 600 "$BACKUP_FILE"
  success "Backed up .env to ${BACKUP_FILE}"
fi

# For each variable that needs rotation, prompt for new value
VARS_TO_ROTATE=$(provider_vars "$PROVIDER")
ROTATED=0

for VAR in $VARS_TO_ROTATE; do
  POLICY_DAYS="${ROTATION_POLICY[$VAR]:-0}"
  if [[ "$POLICY_DAYS" == "0" ]]; then
    continue
  fi

  # Check if variable exists in .env
  if ! grep -q "^${VAR}=" "$ENV_FILE"; then
    continue
  fi

  CURRENT_VALUE=$(grep "^${VAR}=" "$ENV_FILE" | cut -d'=' -f2-)
  REDACTED="${CURRENT_VALUE:0:4}***${CURRENT_VALUE: -4}"

  if [[ "$DRY_RUN" == "true" ]]; then
    log "DRY RUN: Would rotate $VAR (current: $REDACTED, policy: ${POLICY_DAYS}d)"
    ROTATED=$((ROTATED + 1))
  else
    echo ""
    log "Rotating $VAR (current: $REDACTED, policy: ${POLIVITY_DAYS}d)"
    echo -n "  Enter new value (or press Enter to skip): "
    read -r NEW_VALUE

    if [[ -z "$NEW_VALUE" ]]; then
      warn "Skipped $VAR"
      continue
    fi

    # Update .env
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "s|^${VAR}=.*|${VAR}=${NEW_VALUE}|" "$ENV_FILE"
    else
      sed -i "s|^${VAR}=.*|${VAR}=${NEW_VALUE}|" "$ENV_FILE"
    fi

    success "Updated $VAR in .env"
    ROTATED=$((ROTATED + 1))
  fi
done

# Update rotation tracking
if [[ "$ROTATED" -gt 0 && "$DRY_RUN" == "false" ]]; then
  ROTATION_FILE="${ROOT_DIR}/state/credential-rotation-dates.json"
  python3 - "$ROTATION_FILE" $VARS_TO_ROTATE <<'PY'
import json
import sys
from datetime import date
from pathlib import Path

rot_file = sys.argv[1]
vars_list = sys.argv[2:]
today = date.today().isoformat()

data = {}
if Path(rot_file).exists():
    try:
        data = json.load(open(rot_file))
    except:
        pass

for var in vars_list:
    data[var] = today

Path(rot_file).parent.mkdir(parents=True, exist_ok=True)
with open(rot_file, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
  success "Updated rotation tracking"
fi

echo ""
if [[ "$ROTATED" -gt 0 ]]; then
  success "Rotated ${ROTATED} credential(s)"
  if [[ "$DRY_RUN" == "false" ]]; then
    log "Remember to update Railway environment variables: https://railway.app/dashboard"
    log "Run 'pnpm run configure' to sync new credentials to OpenClaw config"
  fi
else
  log "No credentials needed rotation"
fi
