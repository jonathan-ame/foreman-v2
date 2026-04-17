# Phase 3: Paperclip <-> OpenClaw token sync

## When this is needed

After any change that causes OpenClaw to regenerate `gateway.auth.token`
in `~/.openclaw/openclaw.json`, the `ceo-test-adapter` agent (or any
other `openclaw_gateway` adapter agent) will fail with:

```
unauthorized: gateway token mismatch (provide gateway auth token)
```

The Paperclip adapter stores its copy of the gateway token in
`adapterConfig.headers["x-openclaw-token"]`, which does not auto-sync
when OpenClaw rotates the gateway token. The two halves drift.

## Triggers

- Running `openclaw doctor --generate-gateway-token` (manual rotation)
- OpenClaw self-healing after a config write anomaly (for example, the
  Phase 3 stack-health watchdog incident)
- `openclaw gateway install --force` with a new token
- Any other path where OpenClaw rewrites `gateway.auth.token`

## Fix

Run the token sync sequence:

```bash
PAPERCLIP_BIN=/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin/paperclipai
export PAPERCLIP_API_BASE=http://localhost:3125
export PAPERCLIP_API_KEY="$(python3 -c 'import json; print(json.load(open("/Users/jonathanborgia/.openclaw/workspace/paperclip-claimed-api-key.json"))["token"])')"
export GATEWAY_TOKEN="$(python3 -c 'import json; print(json.load(open("/Users/jonathanborgia/.openclaw/openclaw.json"))["gateway"]["auth"]["token"])')"
COMPANY_ID=5d1780c4-7574-4632-a97d-a9917b1f2fc0
AGENT_ID=080d7809-f561-4158-bcf3-12526961a1d5

# 1. GET full agent body
curl -sS "${PAPERCLIP_API_BASE}/api/agents/${AGENT_ID}" \
  -H "Authorization: Bearer ${PAPERCLIP_API_KEY}" \
  > /tmp/agent-before-patch.json

# 2. Build patch body (preserves all other adapterConfig fields)
python3 <<PY > /tmp/patch-body.json
import json, os
with open('/tmp/agent-before-patch.json') as f:
    a = json.load(f)
agent = a.get('agent', a)
ac = dict(agent.get('adapterConfig', {}))
headers = dict(ac.get('headers', {}))
headers['x-openclaw-token'] = os.environ['GATEWAY_TOKEN']
ac['headers'] = headers
print(json.dumps({"adapterConfig": ac}, indent=2))
PY

# 3. Safety check: abort if merge would wipe critical fields
python3 <<PY
import json, sys
agent = json.load(open('/tmp/agent-before-patch.json'))
agent = agent.get('agent', agent)
patch = json.load(open('/tmp/patch-body.json'))
merged = patch.get('adapterConfig', {})
current = agent.get('adapterConfig', {})
if current.get('gatewayUrl') and not merged.get('gatewayUrl'):
    sys.exit('ABORT: patch would wipe adapterConfig.gatewayUrl')
if current.get('headers', {}).get('x-openclaw-token') and not merged.get('headers', {}).get('x-openclaw-token'):
    sys.exit('ABORT: patch would wipe adapterConfig.headers[\"x-openclaw-token\"]')
print('SAFE: critical adapter fields preserved')
PY

# 4. PATCH the agent
curl -sS -X PATCH "${PAPERCLIP_API_BASE}/api/agents/${AGENT_ID}" \
  -H "Authorization: Bearer ${PAPERCLIP_API_KEY}" \
  -H "Content-Type: application/json" \
  -d @/tmp/patch-body.json \
  -w "\nHTTP %{http_code}\n"
```

## Why PATCH instead of CLI

`paperclipai agent` only exposes `list`, `get`, and `local-cli`
subcommands as of 2026-04. There is no `agent update` CLI surface,
so direct REST PATCH is the only path.

## Why send the full adapterConfig

Per Paperclip GitHub issue #964, the PATCH handler replaces (does
not merge) the `adapterConfig` field. We must GET the full object,
modify only the token, and PATCH the entire merged object back.
Sending a partial object would wipe `url`, `gatewayUrl`,
`devicePrivateKeyPem`, `sessionKey`, `sessionKeyStrategy`, and any
other fields not explicitly included.

## Verification

```bash
"${PAPERCLIP_BIN}" agent get "${AGENT_ID}" --json | python3 -c "
import json, sys, os
raw = sys.stdin.read()
data = json.loads(raw[raw.find('{'):])
agent = data.get('agent', data)
tok = agent.get('adapterConfig', {}).get('headers', {}).get('x-openclaw-token', '')
expected = os.environ['GATEWAY_TOKEN']
print('MATCH' if tok == expected else 'DRIFT')
"
```

Then run a heartbeat with an explicit long timeout:

```bash
"${PAPERCLIP_BIN}" heartbeat run \
  --agent-id "${AGENT_ID}" \
  --api-base "${PAPERCLIP_API_BASE}" \
  --timeout-ms 1500000
```

`Status: succeeded` means the substrate is healthy.

## OpenClaw config include (CRITICAL)

`~/.openclaw/openclaw.json` MUST contain:

```json
"$include": "./foreman.json5"
```

Without this, `foreman.json5` is never loaded and:

- `PAPERCLIP_*` env vars do not reach the gateway process
- Plugin config (`paperclipCompanyId`, `paperclipAgentId`) is missing
- Token metering plugin skips all events

If `openclaw doctor` reports `must NOT have additional properties` for plugin config keys, this is cosmetic for current runtime behavior and does not block plugin execution.

## Phase 6 retirement

This runbook becomes obsolete when Paperclip's OpenClaw integration
auto-syncs the gateway token (tracked upstream in paperclipai/paperclip
issues #744, #44493, and #880). Until then, treat token drift as a
known operational hazard after any OpenClaw config change.
