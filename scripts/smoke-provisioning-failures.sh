#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/jonathanborgia/foreman-git/foreman-v2"
BACKEND="$ROOT/backend"

set -a
source "$ROOT/.env"
set +a

export SUPABASE_URL="${SUPABASE_URL:-${SUPABASE_PROJECT_URL:-}}"
export SUPABASE_SERVICE_KEY="${SUPABASE_SERVICE_KEY:-${SUPABASE_SERVICE_ROLE:-}}"
export PAPERCLIP_API_BASE="${PAPERCLIP_API_BASE:-${PAPERCLIP_API_URL:-http://localhost:3125}}"
export PAPERCLIP_API_KEY="${PAPERCLIP_API_KEY:-}"

CUSTOMER_ID="${FOREMAN_TEST_CUSTOMER_ID:-}"
if [[ -z "${CUSTOMER_ID}" ]]; then
  echo "FOREMAN_TEST_CUSTOMER_ID is required for failure smoke tests."
  exit 1
fi

if [[ -z "${SUPABASE_URL}" || -z "${SUPABASE_SERVICE_KEY}" || -z "${PAPERCLIP_API_KEY}" ]]; then
  echo "Missing required env for smoke test (SUPABASE_URL, SUPABASE_SERVICE_KEY, PAPERCLIP_API_KEY)."
  exit 1
fi

cd "$BACKEND"
pnpm build

paperclip_count() {
  npx paperclipai agent list -C "${PAPERCLIP_COMPANY_ID}" --json | node -e 'let s="";process.stdin.on("data",d=>s+=d);process.stdin.on("end",()=>{const j=JSON.parse(s);console.log(Array.isArray(j)?j.length:0);});'
}

openclaw_count() {
  openclaw agents list --json | node -e 'let s="";process.stdin.on("data",d=>s+=d);process.stdin.on("end",()=>{const j=JSON.parse(s);if(Array.isArray(j)){console.log(j.length);return;} if(j && Array.isArray(j.agents)){console.log(j.agents.length);return;} console.log(0);});'
}

db_agents_count() {
  node - <<'NODE'
import { createClient } from "@supabase/supabase-js";
const db = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY, { auth: { persistSession: false } });
const customerId = process.env.FOREMAN_TEST_CUSTOMER_ID;
const { count, error } = await db.from("agents").select("*", { count: "exact", head: true }).eq("customer_id", customerId);
if (error) { throw new Error(error.message); }
console.log(count ?? 0);
NODE
}

idemp_keys=()
SMOKE_CASES="${SMOKE_CASES:-step4,step5,step6}"

should_run() {
  local case_name="$1"
  [[ ",${SMOKE_CASES}," == *",${case_name},"* ]]
}

run_failure() {
  local label="$1"
  shift
  local idemp
  idemp="$(uuidgen)"
  idemp_keys+=("$idemp")
  local name="Failure Smoke ${label} $(date +%s)"
  echo "=== ${label} ==="
  set +e
  "$@" pnpm cli agent provision \
    --customer-id "${CUSTOMER_ID}" \
    --agent-name "${name}" \
    --role ceo \
    --model-tier hybrid \
    --idempotency-key "${idemp}"
  local code=$?
  set -e
  echo "exit_code=${code} idempotency=${idemp}"
  if [[ $code -eq 0 ]]; then
    echo "Expected failure for ${label}, but command succeeded."
    exit 1
  fi
}

pre_paperclip="$(paperclip_count)"
pre_openclaw="$(openclaw_count)"
pre_db_agents="$(db_agents_count)"

echo "Pre counts: paperclip=${pre_paperclip} openclaw=${pre_openclaw} db_agents=${pre_db_agents}"

if should_run "step4"; then
  run_failure "step4" env OPENCLAW_BIN=openclaw-missing
fi
if should_run "step5"; then
  run_failure "step5" env PAPERCLIP_API_KEY=invalid-paperclip-token
fi
if should_run "step6"; then
  run_failure "step6" env FOREMAN_FORCE_STEP6_FAILURE=1
fi

export SMOKE_IDEMP_KEYS="$(IFS=,; echo "${idemp_keys[*]}")"

post_paperclip="$(paperclip_count)"
post_openclaw="$(openclaw_count)"
post_db_agents="$(db_agents_count)"

echo "Post counts: paperclip=${post_paperclip} openclaw=${post_openclaw} db_agents=${post_db_agents}"

if [[ "$pre_paperclip" != "$post_paperclip" || "$pre_openclaw" != "$post_openclaw" || "$pre_db_agents" != "$post_db_agents" ]]; then
  echo "Orphan state detected after rollback smoke."
  exit 1
fi

echo "Verifying failure audit rows..."
node - <<'NODE'
import { createClient } from "@supabase/supabase-js";
const db = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY, { auth: { persistSession: false } });
const keys = (process.env.SMOKE_IDEMP_KEYS ?? "").split(",").filter(Boolean);
const { data, error } = await db
  .from("provisioning_log")
  .select("idempotency_key, outcome, failed_step, rollback_performed")
  .in("idempotency_key", keys);
if (error) { throw new Error(error.message); }
console.log(JSON.stringify(data ?? [], null, 2));
if (!data || data.length !== keys.length) {
  throw new Error(`Expected ${keys.length} provisioning_log rows, got ${data?.length ?? 0}`);
}
for (const row of data) {
  if (row.outcome !== "failed" || row.rollback_performed !== true) {
    throw new Error(`Unexpected log row: ${JSON.stringify(row)}`);
  }
}
NODE

echo "Failure smoke completed with no orphaned state."
