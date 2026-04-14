#!/usr/bin/env bash
# Foreman v2 integration gate: OpenClaw gateway, Paperclip API, Supabase env, CEO auth probe.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HISTORY_FILE="${ROOT_DIR}/state/integration-check-history.jsonl"
CEO_AUTH_PROBE_LATEST_FILE="${ROOT_DIR}/state/ceo-agent-auth-probe-latest.json"
ENV_FILE="${ROOT_DIR}/.env"

OVERALL="pass"
CRITICAL_FAIL=0
RESULT_LINES_FILE="$(mktemp)"
GW_OUT="$(mktemp)"
trap 'rm -f "${RESULT_LINES_FILE}" "${GW_OUT}"' EXIT

record() {
  local name="$1"
  local status="$2"
  local detail="$3"
  printf '%s|%s|%s\n' "${name}" "${status}" "${detail}" >> "${RESULT_LINES_FILE}"
  printf '[integration-check] %-8s %s\n' "${status}" "${name}"
  if [[ -n "${detail}" ]]; then
    printf '           %s\n' "${detail}"
  fi
  if [[ "${status}" == "FAIL" ]]; then
    OVERALL="fail"
    CRITICAL_FAIL=1
  elif [[ "${status}" == "WARN" && "${OVERALL}" == "pass" ]]; then
    OVERALL="warn"
  fi
}

if [[ -f "${ENV_FILE}" ]]; then
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    if [[ "${line}" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
      key="${line%%=*}"
      value="${line#*=}"
      export "${key}=${value}"
    fi
  done < "${ENV_FILE}"
fi

mkdir -p "${ROOT_DIR}/state"

if command -v openclaw >/dev/null 2>&1; then
  openclaw agent --session-id "integration-check-$(date +%s)" \
    -m "Integration check (deterministic): reply with one short sentence that includes the literal token IC7 and the digit 7." \
    > "${GW_OUT}" 2>&1 || true

  gw_compact="$(
    tr -d '\0' < "${GW_OUT}" | tr -s '[:space:]' ' ' | sed 's/^ *//;s/ *$//'
  )"
  gw_nonempty_compact="${gw_compact// /}"

  gw_fail=""
  while IFS= read -r marker; do
    [[ -z "${marker}" ]] && continue
    if grep -qiF -- "${marker}" "${GW_OUT}"; then
      gw_fail="${marker}"
      break
    fi
  done <<'EOF'
gateway agent failed
timed out
unauthorized
no reply from agent
llm request failed
context overflow
session history looks corrupted
error:
EOF

  if [[ -z "${gw_nonempty_compact}" ]]; then
    record "gateway_agent_ping" "FAIL" "openclaw agent returned empty output"
  elif [[ -n "${gw_fail}" ]]; then
    record "gateway_agent_ping" "FAIL" "openclaw agent output matched failure marker '${gw_fail}'; snippet: $(head -c 400 "${GW_OUT}" | tr '\n' ' ')"
  else
    record "gateway_agent_ping" "PASS" "openclaw agent returned non-empty output without failure markers"
  fi
else
  record "gateway_agent_ping" "WARN" "openclaw CLI not on PATH"
fi

clip_base="${PAPERCLIP_API_URL:-}"
if [[ -z "${clip_base}" && -n "${PAPERCLIP_BASE_URL:-}" ]]; then
  clip_base="${PAPERCLIP_BASE_URL%/}/api"
fi
clip_key="${PAPERCLIP_CEO_AGENT_API_KEY:-${PAPERCLIP_API_KEY:-}}"
if [[ -z "${clip_key}" && -f "${HOME}/.paperclip/auth.json" && -n "${clip_base}" ]]; then
  clip_key="$(
    python3 - "${clip_base}" <<'PY'
import json, os, sys
api = (sys.argv[1] or "").strip()
path = os.path.expanduser("~/.paperclip/auth.json")
try:
    auth = json.loads(open(path, encoding="utf-8").read())
except Exception:
    raise SystemExit("")
creds = auth.get("credentials") or {}
origin = api.removesuffix("/api")
t = (creds.get(origin) or {}).get("token") or ""
print(str(t).strip())
PY
  )"
fi

if [[ -z "${clip_base}" ]]; then
  record "paperclip_api" "WARN" "PAPERCLIP_API_URL / PAPERCLIP_BASE_URL not set; skipped"
elif [[ -z "${clip_key}" ]]; then
  record "paperclip_api" "WARN" "No Paperclip token (set PAPERCLIP_API_KEY or ~/.paperclip/auth.json)"
else
  clip_base="${clip_base%/}"
  [[ "${clip_base}" == */api ]] || clip_base="${clip_base}/api"
  pc_code="$(curl -sS -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer ${clip_key}" \
    -H "Accept: application/json" \
    "${clip_base}/agents/me" || echo "000")"
  if [[ "${pc_code}" -ge 200 && "${pc_code}" -lt 300 ]]; then
    record "paperclip_api" "PASS" "GET ${clip_base}/agents/me => ${pc_code}"
  else
    record "paperclip_api" "FAIL" "GET ${clip_base}/agents/me => ${pc_code}"
  fi
fi

if [[ -n "${SUPABASE_URL:-}" && -n "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
  record "supabase_env" "PASS" "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are present"
elif [[ -n "${FOREMAN_CLOUD_DB_URL:-}" ]]; then
  record "supabase_env" "PASS" "FOREMAN_CLOUD_DB_URL is present"
else
  record "supabase_env" "WARN" "Supabase env vars are not fully configured"
fi

if [[ -n "${DEEPINFRA_API_KEY:-}" ]]; then
  record "deepinfra_placeholder_probe" "PASS" "DEEPINFRA_API_KEY is set (live endpoint probe lands in Phase 1)"
else
  record "deepinfra_placeholder_probe" "WARN" "DEEPINFRA_API_KEY missing (Phase 1 will add live probe)"
fi

if [[ ! -f "${CEO_AUTH_PROBE_LATEST_FILE}" ]]; then
  record "ceo_agent_auth_probe" "WARN" "Missing ${CEO_AUTH_PROBE_LATEST_FILE}; run ./scripts/ceo-agent-auth-probe.sh"
else
  ceo_probe_res="$(
    python3 - "${CEO_AUTH_PROBE_LATEST_FILE}" <<'PY'
import json
import sys
from datetime import datetime, timezone

path = sys.argv[1]
raw = open(path, "r", encoding="utf-8").read()
payload = json.loads(raw)
status = str(payload.get("status") or "").strip()
ts = str(payload.get("timestamp") or "").strip()
http_status = payload.get("http_status")
detail = str(payload.get("detail") or "").strip()
if not ts:
    print("FAIL|probe artifact missing timestamp")
    raise SystemExit(0)
try:
    if ts.endswith("Z"):
        ts_dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
    else:
        ts_dt = datetime.fromisoformat(ts)
except Exception:
    print(f"FAIL|probe timestamp parse failed: {ts}")
    raise SystemExit(0)
age_sec = int((datetime.now(timezone.utc) - ts_dt).total_seconds())
if age_sec > 36 * 3600:
    print(f"FAIL|probe stale age={age_sec}s status={status} http_status={http_status}")
elif status == "ok":
    print(f"OK|status=ok age={age_sec}s http_status={http_status}")
else:
    print(f"FAIL|status={status} age={age_sec}s http_status={http_status} detail={detail[:240]}")
PY
  )"
  IFS='|' read -r ceo_probe_code ceo_probe_msg <<< "${ceo_probe_res}"
  if [[ "${ceo_probe_code}" == "OK" ]]; then
    record "ceo_agent_auth_probe" "PASS" "${ceo_probe_msg}"
  else
    record "ceo_agent_auth_probe" "FAIL" "${ceo_probe_msg}"
  fi
fi

ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
python3 - "${ts}" "${OVERALL}" "${HISTORY_FILE}" "${RESULT_LINES_FILE}" <<'PY'
import json
import sys
from pathlib import Path

ts, overall, hist_path, lines_path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
checks = []
raw_lines = Path(lines_path).read_text(encoding="utf-8").splitlines()
for raw in raw_lines:
    if not raw.strip():
        continue
    parts = raw.split("|", 2)
    if len(parts) == 3:
        checks.append({"name": parts[0], "status": parts[1], "detail": parts[2]})

record = {
    "timestamp": ts,
    "overall": overall,
    "checks": checks,
}
path = Path(hist_path)
path.parent.mkdir(parents=True, exist_ok=True)
with path.open("a", encoding="utf-8") as fh:
    fh.write(json.dumps(record, ensure_ascii=True) + "\n")
PY

echo ""
echo "Summary: overall=${OVERALL}"
if [[ "${CRITICAL_FAIL}" -eq 1 ]]; then
  exit 1
fi
exit 0
