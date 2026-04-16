#!/usr/bin/env bash
# Foreman v2 integration check
# Verifies the backend can reach all external dependencies and
# that agent state is consistent. Replaces the v1 probe-based
# integration check that was tied to the deprecated process-adapter
# CEO agent.

set -euo pipefail

BACKEND_BASE="${FOREMAN_BACKEND_BASE:-http://localhost:8080}"

response="$(curl -sS -w "\n%{http_code}" "${BACKEND_BASE}/api/internal/health/integration")"
body="$(echo "${response}" | sed '$d')"
status_code="$(echo "${response}" | tail -n1)"

if [[ "${status_code}" != "200" ]]; then
  echo "FAIL: backend returned HTTP ${status_code}"
  echo "${body}"
  exit 1
fi

overall="$(echo "${body}" | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])")"

if [[ "${overall}" == "ok" ]]; then
  echo "PASS: all integration checks green"
  echo "${body}" | python3 -m json.tool
  exit 0
elif [[ "${overall}" == "degraded" ]]; then
  echo "DEGRADED: some checks failed but core is up"
  echo "${body}" | python3 -m json.tool
  exit 1
else
  echo "DOWN: critical checks failed"
  echo "${body}" | python3 -m json.tool
  exit 2
fi
