#!/usr/bin/env bash
set -euo pipefail

# Syncs OpenClaw gateway token to Paperclip CEO agent adapterConfig.
# Uses BOARD-LEVEL API key (not the agent's claimed key, which lacks
# permission to modify agent configs - Paperclip returns 403).
#
# Run after every `openclaw gateway restart`.

BOARD_KEY="${PAPERCLIP_BOARD_KEY:-$(python3 -c "import re, pathlib; txt=pathlib.Path('/Users/jonathanborgia/foreman-git/foreman-v2/.env').read_text(); m=re.search(r'^PAPERCLIP_API_KEY=(.*)$', txt, re.M); print(m.group(1).strip() if m else '')")}"
GATEWAY_TOKEN="$(python3 -c 'import json; print(json.load(open("/Users/jonathanborgia/.openclaw/openclaw.json"))["gateway"]["auth"]["token"])')"
COMPANY_ID=5d1780c4-7574-4632-a97d-a9917b1f2fc0
CEO_ID=44f95028-f240-4be9-8e9c-e5420240aa41
API_BASE="${PAPERCLIP_API_BASE:-http://localhost:3125}"

if [[ -z "${BOARD_KEY}" ]]; then
  echo "ERROR: Board key missing (set PAPERCLIP_BOARD_KEY or PAPERCLIP_API_KEY in .env)." >&2
  exit 1
fi

# Read full current agent config (preserves all fields).
CURRENT="$(curl -sS "${API_BASE}/api/agents/${CEO_ID}" -H "Authorization: Bearer ${BOARD_KEY}")"

# Merge token + gateway URL + timeout into existing adapterConfig.
PATCH="$(CURRENT_JSON="${CURRENT}" GATEWAY_TOKEN="${GATEWAY_TOKEN}" python3 -c "
import json, os
d = json.loads(os.environ['CURRENT_JSON'])
agent = d.get('agent', d)
ac = dict(agent.get('adapterConfig', {}))
ac['gatewayUrl'] = 'ws://127.0.0.1:18789/'
ac['url'] = 'ws://127.0.0.1:18789/'
ac.setdefault('headers', {})
ac['headers']['x-openclaw-token'] = os.environ['GATEWAY_TOKEN']
ac['timeoutSec'] = 1500
print(json.dumps({'adapterConfig': ac}))
")"

HTTP_CODE="$(curl -sS -o /dev/null -w "%{http_code}" -X PATCH \
  "${API_BASE}/api/agents/${CEO_ID}" \
  -H "Authorization: Bearer ${BOARD_KEY}" \
  -H "Content-Type: application/json" \
  -d "${PATCH}")"

if [[ "${HTTP_CODE}" == "200" ]]; then
  echo "Token synced (prefix: ${GATEWAY_TOKEN:0:8})"
else
  echo "ERROR: PATCH returned HTTP ${HTTP_CODE}" >&2
  exit 1
fi
