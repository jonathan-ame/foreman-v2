#!/usr/bin/env bash
set -euo pipefail

API_BASE="${FOREMAN_API_URL:-http://127.0.0.1:8080}"
LOG_DIR="/tmp/foreman"
LOG_FILE="${LOG_DIR}/post-launch-health.log"

mkdir -p "${LOG_DIR}"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "${LOG_FILE}"
}

check_endpoint() {
  local label="$1"
  local path="$2"
  local expected_status="${3:-200}"

  local code
  code="$(curl -sS -o /dev/null -w "%{http_code}" "${API_BASE}${path}" 2>/dev/null || echo "000")"

  if [[ "${code}" == "${expected_status}" ]]; then
    log "  OK   ${label} (${code})"
    return 0
  else
    log "  FAIL ${label} (expected ${expected_status}, got ${code})"
    return 1
  fi
}

check_json_field() {
  local label="$1"
  local path="$2"
  local field="$3"
  local value

  value="$(curl -sS "${API_BASE}${path}" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d${field})" 2>/dev/null || echo "PARSE_ERROR")"

  if [[ "${value}" == "PARSE_ERROR" ]]; then
    log "  WARN ${label} (could not parse response)"
    return 0
  fi

  log "  INFO ${label}: ${value}"
  return 0
}

main() {
  local failures=0

  log "=== Foreman Post-Launch Health Check ==="

  log ""
  log "--- Liveness & Readiness ---"
  check_endpoint "Liveness" "/api/internal/monitoring/liveness" || ((failures++))
  check_endpoint "Readiness" "/api/internal/monitoring/readiness" || ((failures++))

  log ""
  log "--- Integration Health ---"
  check_endpoint "Integration Health" "/api/internal/health/integration" || ((failures++))
  check_endpoint "Credential Health" "/api/internal/health/credentials" || ((failures++))

  log ""
  log "--- Monitoring Dashboard ---"
  check_endpoint "Dashboard" "/api/internal/monitoring/dashboard" || ((failures++))

  log ""
  log "--- Dashboard Metrics ---"
  check_json_field "Integration status" "/api/internal/monitoring/dashboard" "['system']['integration']['status']"
  check_json_field "MRR (cents)" "/api/internal/monitoring/dashboard" "['business']['mrr_cents']"
  check_json_field "Active customers" "/api/internal/monitoring/dashboard" "['business']['active_customers']"
  check_json_field "Active agents" "/api/internal/monitoring/dashboard" "['agents']['active_count']"
  check_json_field "Paused agents" "/api/internal/monitoring/dashboard" "['agents']['paused_count']"
  check_json_field "Signups 30d" "/api/internal/monitoring/dashboard" "['funnel']['signups_30d']"
  check_json_field "NPS" "/api/internal/monitoring/dashboard" "['nps']['nps_score']"

  log ""
  log "--- External Services ---"
  check_endpoint "Supabase (via readiness)" "/api/internal/monitoring/readiness" || ((failures++))
  check_endpoint "Paperclip" "/api/internal/health/integration" || ((failures++))

  log ""
  log "--- Marketing Endpoints ---"
  local subscribe_code
  subscribe_code="$(curl -sS -o /dev/null -w "%{http_code}" -X POST "${API_BASE}/api/marketing/subscribe" -H "Content-Type: application/json" -d '{"email":"_health_check_test@foreman.company","source":"other"}' 2>/dev/null || echo "000")"
  if [[ "${subscribe_code}" == "200" ]]; then
    log "  OK   Subscribe endpoint (${subscribe_code})"
  else
    log "  WARN Subscribe endpoint (${subscribe_code})"
  fi

  local pageview_code
  pageview_code="$(curl -sS -o /dev/null -w "%{http_code}" -X POST "${API_BASE}/api/marketing/pageview" -H "Content-Type: application/json" -d '{"path":"/health-check-test"}' 2>/dev/null || echo "000")"
  if [[ "${pageview_code}" == "200" ]]; then
    log "  OK   Pageview endpoint (${pageview_code})"
  else
    log "  WARN Pageview endpoint (${pageview_code})"
  fi

  log ""
  if [[ ${failures} -eq 0 ]]; then
    log "=== ALL CHECKS PASSED ==="
  else
    log "=== ${failures} CHECK(S) FAILED — investigate immediately ==="
  fi

  return ${failures}
}

main "$@"
