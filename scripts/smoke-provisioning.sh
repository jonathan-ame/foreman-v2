#!/usr/bin/env bash
set -euo pipefail

cd /Users/jonathanborgia/foreman-git/foreman-v2/backend

pnpm build

CUSTOMER_ID="${FOREMAN_TEST_CUSTOMER_ID:-}"
if [[ -z "${CUSTOMER_ID}" ]]; then
  echo "FOREMAN_TEST_CUSTOMER_ID not set. Inserting test customer..."
  echo "Set FOREMAN_TEST_CUSTOMER_ID=<id> and re-run."
  exit 1
fi

IDEMP_KEY="${IDEMPOTENCY_KEY:-$(uuidgen)}"
AGENT_NAME="${AGENT_NAME:-Smoke CEO $(date +%s)}"

echo "Provisioning agent. customer=${CUSTOMER_ID} idempotency=${IDEMP_KEY} name=${AGENT_NAME}"

pnpm cli agent provision \
  --customer-id "${CUSTOMER_ID}" \
  --agent-name "${AGENT_NAME}" \
  --role "ceo" \
  --model-tier "hybrid" \
  --idempotency-key "${IDEMP_KEY}"
