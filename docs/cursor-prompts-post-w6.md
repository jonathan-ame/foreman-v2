# Cursor Prompt Sequence — Post-W6: Auto-Wakeup, CEO Awareness, Additional Roles

**Predecessor:** `foreman-v2/docs/cursor-prompts-worker-agents.md` (W1–W6, complete)

**Source-of-truth spec:** `foreman-v2/docs/specs/worker-agent-architecture.md`

**Current architecture (post-W6):**
- CEO: Paperclip `process` adapter → `scripts/ceo-heartbeat.js` → DeepSeek V3.1 via OpenRouter (plans) → `scripts/lib/plan-executor.js` (acts)
- CEO Paperclip ID: `dce0f8fd-a030-4fdd-907e-e44e20a70bbf`
- Workers: Paperclip `process` adapter → `scripts/paperclip-openclaw-executor.sh` → `openclaw agent --agent <id>` → Qwen3 Coder via OpenRouter (executes with tools)
- Marketing Analyst Paperclip ID: `60f615b0-78bd-48eb-ad72-c8ed466f3795`
- Marketing Analyst OpenClaw ID: `foreman-marketing-analyst`
- Foreman customer: `31c326fa-2f13-4f57-a448-127a3d3d19ec`
- Paperclip company: `5d1780c4-7574-4632-a97d-a9917b1f2fc0`
- OpenClaw gateway: `ws://127.0.0.1:18789/`
- Provisioning: 10-step orchestrator (`backend/src/provisioning/orchestrator.ts`)

**Goal of this sequence:** After W6 proved the full CEO→worker delegation loop, this sequence adds:
1. Auto-wakeup so workers don't need manual `heartbeat run` triggers
2. Hardened CEO awareness of all available workers for reliable delegation
3. Three new worker roles (`engineer`, `qa`, `designer`) with role-specific workspace files and model configs

**How to use this file:**
- Each prompt below is self-contained and copy-pasteable into Cursor as one chat message.
- Run them in order. Do not skip.
- Each prompt has explicit Stop Conditions and Report requirements.
- Per standing rule: consult https://docs.openclaw.ai and https://docs.paperclip.ing FIRST before any OpenClaw/Paperclip work.

**Total estimated build time:** 10–14 hours across 5 prompts.

---

## Prompt index

| # | Title | Type | Estimate | Deps |
|---|---|---|---|---|
| P1 | Configure Paperclip assignment-wakeup for workers | Config | 2–3 hrs | None |
| P2 | Harden CEO agent discovery and delegation routing | Code | 2–3 hrs | None |
| P3 | Add `engineer` worker role | Code + Content | 2–3 hrs | None |
| P4 | Add `qa` worker role | Code + Content | 1–2 hrs | P3 |
| P5 | Add `designer` worker role + E2E multi-role smoke | Code + Content + Test | 2–3 hrs | P3, P4 |

---

## P1 — Configure Paperclip assignment-wakeup for workers

**Goal:** When the CEO creates a sub-task and assigns it to a worker, Paperclip should automatically trigger the worker's heartbeat (run the `process` adapter script). Currently, worker heartbeats must be triggered manually via `paperclipai heartbeat run`. After this prompt, assignment-wakeup fires automatically.

**Active prompt:**

### Step 1 — Read Paperclip docs for assignment-wakeup

Consult https://docs.paperclip.ing for:
- Assignment-wakeup protocol: how does Paperclip trigger a heartbeat when an issue is assigned to an agent?
- Required agent configuration fields for auto-wakeup (e.g., `runtimeConfig.heartbeat.triggers`, `runtimeConfig.heartbeat.wakeOn`, or similar)
- Does `mode: "reactive"` automatically enable assignment-wakeup, or is there an additional trigger config?
- Does the `process` adapter type support auto-wakeup, or is it only for `openclaw_gateway`?

```bash
BOARD_KEY="$(grep '^PAPERCLIP_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-)"

# Check the current worker's heartbeat/runtime config
echo "=== Current worker runtime config ==="
curl -sS "http://localhost:3125/api/agents/60f615b0-78bd-48eb-ad72-c8ed466f3795" \
  -H "Authorization: Bearer ${BOARD_KEY}" 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
agent = data.get('agent', data)
print(f'adapterType: {agent.get(\"adapterType\")}')
rc = agent.get('runtimeConfig', {})
print(f'runtimeConfig: {json.dumps(rc, indent=2)}')
"

# Check if Paperclip exposes wakeup/trigger config on agents
echo "=== Paperclip agent schema (from API) ==="
curl -sS "http://localhost:3125/api/agents/60f615b0-78bd-48eb-ad72-c8ed466f3795" \
  -H "Authorization: Bearer ${BOARD_KEY}" 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
agent = data.get('agent', data)
# Print all top-level keys to find wakeup-related config
for key in sorted(agent.keys()):
    val = agent[key]
    if isinstance(val, (dict, list)):
        print(f'{key}: {json.dumps(val, indent=2)[:200]}')
    else:
        print(f'{key}: {val}')
"
```

### Step 2 — Check Paperclip server logs for wakeup behavior

When we assigned an issue to the worker in W5/W6 smokes, did Paperclip attempt a wakeup that failed? Or did it not attempt one at all?

```bash
LOG_DIR="/Users/jonathanborgia/foreman-git/foreman-v2/state/paperclip-data/instances/foreman-p21/logs"

echo "=== Recent Paperclip server logs ==="
ls -lt "${LOG_DIR}"/*.log 2>/dev/null | head -5

# Search for wakeup-related log entries
for f in $(ls -t "${LOG_DIR}"/*.log 2>/dev/null | head -3); do
  echo "--- $(basename $f) ---"
  grep -i "wake\|trigger\|assignment\|heartbeat.*invoke\|heartbeat.*start\|process.*spawn\|adapter.*start" "$f" | tail -20
done
```

### Step 3 — Configure assignment-wakeup

Based on the docs and current config, apply the necessary changes.

**If Paperclip requires explicit wakeup trigger config on the agent:**

```bash
BOARD_KEY="$(grep '^PAPERCLIP_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-)"

# Patch the worker agent with wakeup triggers
curl -sS -X PATCH "http://localhost:3125/api/agents/60f615b0-78bd-48eb-ad72-c8ed466f3795" \
  -H "Authorization: Bearer ${BOARD_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "runtimeConfig": {
      "heartbeat": {
        "enabled": true,
        "mode": "reactive",
        "triggers": ["assignment", "comment", "reopen"]
      }
    }
  }' 2>&1 | python3 -m json.tool
```

Adjust the field names based on what the docs specify. The key requirement is: when `PATCH /api/issues/{id}` sets `assigneeAgentId` to this worker, Paperclip should automatically invoke a heartbeat run.

**Also update provisioning** so future workers get this config. Edit `backend/src/provisioning/steps/step-5-paperclip-hire.ts`:

The `heartbeatConfig` for workers currently is:
```typescript
{ enabled: true, mode: "reactive" as const }
```

Add whatever trigger fields the docs specify.

### Step 4 — Test assignment-wakeup

```bash
PAPERCLIP_BIN=/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin/paperclipai
BOARD_KEY="$(grep '^PAPERCLIP_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-)"
COMPANY_ID=5d1780c4-7574-4632-a97d-a9917b1f2fc0
WORKER_ID="60f615b0-78bd-48eb-ad72-c8ed466f3795"

# Create and assign a task — do NOT manually run heartbeat
echo "=== Creating task ==="
"${PAPERCLIP_BIN}" issue create \
  -C "${COMPANY_ID}" \
  --title "P1 auto-wakeup test: list 3 project management tools" \
  --description "List 3 popular project management tools. For each, give: name, URL, one-sentence description. Post results as a comment." \
  --priority high \
  --json | tee /tmp/p1-wake.json

ISSUE_ID=$(jq -r '.id' /tmp/p1-wake.json)

# Assign to worker — this should trigger auto-wakeup
curl -sS -X PATCH "http://localhost:3125/api/issues/${ISSUE_ID}" \
  -H "Authorization: Bearer ${BOARD_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"assigneeAgentId\": \"${WORKER_ID}\", \"status\": \"todo\"}"

echo "Issue assigned. Waiting for auto-wakeup (up to 120s)..."

# Poll for status change — if auto-wakeup works, the issue should move from todo to done
for i in $(seq 1 24); do
  sleep 5
  STATUS=$(curl -sS "http://localhost:3125/api/issues/${ISSUE_ID}" \
    -H "Authorization: Bearer ${BOARD_KEY}" 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('issue', data).get('status', 'unknown'))
" 2>/dev/null)
  echo "  [${i}] status=${STATUS}"
  if [[ "${STATUS}" == "done" || "${STATUS}" == "blocked" ]]; then
    break
  fi
done

echo ""
echo "=== FINAL STATE ==="
curl -sS "http://localhost:3125/api/issues/${ISSUE_ID}" \
  -H "Authorization: Bearer ${BOARD_KEY}" 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
issue = data.get('issue', data)
print(f'Status: {issue.get(\"status\")}')
comments = issue.get('comments', [])
print(f'Comment count: {len(comments)}')
for c in comments:
    print(f'  {(c.get(\"body\") or c.get(\"content\") or \"\")[:200]}')
"

echo ""
echo "=== HEARTBEAT RUNS (last 5) ==="
curl -sS "http://localhost:3125/api/companies/${COMPANY_ID}/heartbeat-runs?limit=5&offset=0" \
  -H "Authorization: Bearer ${BOARD_KEY}" 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
runs = data if isinstance(data, list) else data.get('items', data.get('runs', []))
for r in runs:
    print(f'{r.get(\"id\",\"\")[:12]} agent={r.get(\"agentId\",\"\")[:12]} status={r.get(\"status\")} source={r.get(\"source\",\"\")}')
"
```

**Success criteria:**
1. After assigning the issue, a heartbeat run appears with `source=assignment` (or similar wakeup source)
2. The worker executes and the issue ends as `done` with comments — without any manual `heartbeat run` invocation
3. The heartbeat run shows `agentId` matching the worker

**If auto-wakeup doesn't fire:** check Paperclip logs for errors. Common issues:
- The `process` adapter might need the script to be registered differently for auto-invocation
- Paperclip might need a scheduler or background worker running to dispatch wakeups
- The assignment PATCH might need to go through a specific endpoint (e.g., `/api/issues/{id}/assign`) rather than a generic PATCH

### Step 5 — Commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
git add -A
git commit -m "feat(workers): configure Paperclip assignment-wakeup for auto heartbeat

Workers now auto-wake when assigned an issue. No manual heartbeat
trigger needed. Provisioning updated to set wakeup triggers for
future worker agents.

Spec: docs/specs/worker-agent-architecture.md"
```

### Stop conditions
- Step 1: Paperclip docs confirm `process` adapter does NOT support auto-wakeup → document this limitation and investigate alternatives (Paperclip webhook, cron polling, or a lightweight watcher process)
- Step 4: auto-wakeup fires but worker fails → separate issue from wakeup config, report and stop
- Step 4: no heartbeat run created after 120s → check Paperclip logs, report findings

### Report
- Paperclip wakeup config fields used
- Provisioning changes
- Auto-wakeup test: did it fire? Source field? Worker result?
- Commit hash

---

## P2 — Harden CEO agent discovery and delegation routing

**Goal:** Make the CEO's delegation routing robust. Currently `ceo-heartbeat.js` fetches `availableAgents` from `/api/companies/{companyId}/agents` and includes them in the planner context. This prompt hardens that path: ensure the CEO reliably discovers workers by role, picks the right one for each task, and handles edge cases (no worker for role, worker busy, worker disabled).

**Active prompt:**

### Step 1 — Audit current CEO awareness of workers

```bash
# Check what the CEO currently sees
BOARD_KEY="$(grep '^PAPERCLIP_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-)"
COMPANY_ID=5d1780c4-7574-4632-a97d-a9917b1f2fc0

curl -sS "http://localhost:3125/api/companies/${COMPANY_ID}/agents" \
  -H "Authorization: Bearer ${BOARD_KEY}" 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
agents = data if isinstance(data, list) else data.get('agents', data.get('data', []))
for a in agents:
    print(f'{a.get(\"id\",\"\")[:12]}: name={a.get(\"name\")} role={a.get(\"role\")} status={a.get(\"status\")} adapter={a.get(\"adapterType\")}')
"
```

Also read the current CEO planner prompt to see how `availableAgents` is formatted:

```bash
# Find the buildUserPrompt function in ceo-heartbeat.js
grep -n "availableAgents\|buildUserPrompt\|delegation" /Users/jonathanborgia/foreman-git/foreman-v2/scripts/ceo-heartbeat.js | head -20

# Read the relevant section
cat /Users/jonathanborgia/foreman-git/foreman-v2/scripts/ceo-heartbeat.js
```

### Step 2 — Improve the CEO's delegation context

Edit `scripts/ceo-heartbeat.js` to enhance the `availableAgents` context block sent to the planner:

**2a — Add role-to-capability mapping:**

The planner needs to know which agent handles which kind of task. Add a mapping from role to capabilities that the planner can reference:

```javascript
const ROLE_CAPABILITIES = {
  marketing_analyst: "Market research, competitive analysis, content strategy, campaign analysis, funnel diagnostics",
  engineer: "Code implementation, bug fixes, architecture, technical documentation, code review",
  qa: "Test planning, test execution, bug reporting, quality standards, regression testing",
  designer: "UI/UX design, visual assets, design systems, wireframes, prototyping",
};
```

Include this in the user prompt so the planner can match task requirements to worker capabilities.

**2b — Add delegation routing rules to the planner system prompt:**

In `buildSystemPrompt()` or `buildUserPrompt()`, add explicit delegation rules:

```
## Delegation rules
- When creating a sub-task, always assign it to the worker whose role best matches the task.
- Use the availableAgents list below to find the correct agent ID for assignment.
- If no worker exists for the required role, execute the task yourself or note it as blocked.
- Never assign a task to an agent with status "disabled" or "paused".
- When a delegated child task is marked done, review its results (check child comments) before closing the parent.
- Prefer delegating to existing workers over executing research/implementation tasks yourself.
```

**2c — Format availableAgents with capabilities:**

Update the `availableAgents` section in the user prompt from:
```
Available agents: [{"id": "60f615...", "name": "Marketing Analyst", "role": "cmo", "status": "active"}]
```
to:
```
Available workers for delegation:
- Marketing Analyst (id: 60f615b0-78bd-48eb-ad72-c8ed466f3795)
  Role: marketing_analyst
  Capabilities: Market research, competitive analysis, content strategy
  Status: active
  Assign sub-tasks about market research, competitors, or content to this agent.
```

### Step 3 — Add a role-lookup helper for the plan executor

The plan executor (`scripts/lib/plan-executor.js`) handles `create_issue` actions from the planner. When the planner says "assign this research task to the marketing analyst," the executor needs to resolve the agent ID.

Check if the plan executor already handles `assigneeAgentId` in `create_issue` actions:

```bash
grep -n "assignee\|agentId\|assign\|create_issue" /Users/jonathanborgia/foreman-git/foreman-v2/scripts/lib/plan-executor.js | head -20
```

If it does: verify it uses the correct field name for the Paperclip API.
If it doesn't: add `assigneeAgentId` to the `create_issue` payload so the planner can delegate in one step.

### Step 4 — Test delegation with enhanced context

```bash
PAPERCLIP_BIN=/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin/paperclipai
BOARD_KEY="$(grep '^PAPERCLIP_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-)"
COMPANY_ID=5d1780c4-7574-4632-a97d-a9917b1f2fc0
CEO_ID=dce0f8fd-a030-4fdd-907e-e44e20a70bbf

# Create a task that the CEO should delegate
"${PAPERCLIP_BIN}" issue create \
  -C "${COMPANY_ID}" \
  --title "P2 delegation test: analyze Foreman positioning vs CrewAI" \
  --description "Research how Foreman compares to CrewAI as an AI agent orchestration platform. Identify 3 key differentiators. This is a research task — delegate it to the marketing analyst." \
  --priority high \
  --json | tee /tmp/p2-delegate.json

ISSUE_ID=$(jq -r '.id' /tmp/p2-delegate.json)
"${PAPERCLIP_BIN}" issue update "${ISSUE_ID}" --status todo --json 2>/dev/null

# Run CEO heartbeat
"${PAPERCLIP_BIN}" heartbeat run \
  --agent-id "${CEO_ID}" \
  --api-base http://localhost:3125 \
  --api-key "${BOARD_KEY}" \
  --timeout-ms 300000 \
  2>&1 | tee /tmp/p2-ceo-hb.txt

# Check if CEO delegated
echo ""
echo "=== CEO PLAN ==="
cat /tmp/p2-ceo-hb.txt | python3 -c "
import json, sys
txt = sys.stdin.read()
try:
    data = json.loads(txt)
    print(f'Reasoning: {data.get(\"reasoning\", \"\")[:300]}')
    print(f'Actions planned: {data.get(\"actionsPlanned\", 0)}')
    for r in data.get('results', []):
        print(f'  {r.get(\"action\", \"\")}: {r.get(\"status\", \"\")} - {json.dumps(r.get(\"details\", {}))[:200]}')
except:
    print(txt[:500])
"

echo ""
echo "=== SUB-TASKS CREATED ==="
"${PAPERCLIP_BIN}" issue list -C "${COMPANY_ID}" --json 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
issues = data if isinstance(data, list) else data.get('issues', data.get('items', data.get('data', [])))
for i in issues:
    if i.get('parentId') == '${ISSUE_ID}' or 'crewai' in (i.get('title') or '').lower() or 'positioning' in (i.get('title') or '').lower():
        print(f'{i.get(\"identifier\", i[\"id\"][:12])}: {i.get(\"title\")} (status={i.get(\"status\")}, assignee={i.get(\"assigneeAgentId\", \"none\")[:12]})')
"
```

**Success criteria:**
1. CEO's plan output includes a `create_issue` action
2. The created sub-task has `assigneeAgentId` set to the marketing analyst's Paperclip ID
3. The CEO's reasoning mentions the marketing analyst by name or role

### Step 5 — Commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
git add scripts/ceo-heartbeat.js scripts/lib/plan-executor.js
git commit -m "feat(ceo): harden worker discovery and delegation routing

CEO planner now receives structured worker capabilities and explicit
delegation rules. Plan executor supports assigneeAgentId on create_issue.
CEO reliably delegates research tasks to the marketing analyst.

Spec: docs/specs/worker-agent-architecture.md"
```

### Stop conditions
- Step 4: CEO plans but doesn't delegate (does the work itself) → planner prompt needs stronger delegation preference. Iterate on the delegation rules
- Step 4: CEO delegates but to wrong agent ID → check how availableAgents is formatted and whether the planner is parsing it correctly

### Report
- Changes to `ceo-heartbeat.js` (summary)
- Changes to `plan-executor.js` (summary)
- Delegation test: did CEO create a sub-task? Was it assigned to the right worker?
- Commit hash

---

## P3 — Add `engineer` worker role

**Goal:** Add the `engineer` role to the provisioning system. After this prompt, `role: "engineer"` can be provisioned via the `/api/internal/agents/provision` endpoint and produces a working agent with engineering-focused workspace files and model config.

**Active prompt:**

### Step 1 — Add the role to the type system

Edit `backend/src/provisioning/types.ts`:

```typescript
export type AgentRole = "ceo" | "marketing_analyst" | "engineer";
```

### Step 2 — Add role config

Edit `backend/src/provisioning/role-config.ts`:

Add to `ROLE_CONFIGS`:

```typescript
engineer: {
  toolsAllow: [
    "read", "write", "edit", "exec", "process",
    "sessions_spawn", "sessions_list", "sessions_history"
  ],
  toolsDeny: ["browser", "canvas", "nodes", "cron", "hire_agent"],
  paperclipRole: "engineer",
  budgetMonthlyCents: 30_000,
  capabilities: "Code implementation, bug fixes, architecture design, technical documentation, code review, shell commands",
  systemPromptTemplate: "ENGINEER_TEMPLATE_V1",
},
```

### Step 3 — Add model tier override

Edit `backend/src/provisioning/model-tiers.ts`:

Add to `WORKER_ROLE_MODEL_OVERRIDES`:

```typescript
engineer: {
  primary: "openrouter/qwen/qwen3-coder",
  fallbacks: [
    "openrouter/deepseek/deepseek-chat-v3.1",
    "openrouter/qwen/qwen-2.5-72b-instruct",
  ],
},
```

Engineers get `qwen3-coder` as primary — it's optimized for code generation and has 262K context.

### Step 4 — Create engineer workspace files

Create `config/engineer-workspace/SOUL.md`:

```markdown
# Engineer Agent

You are an engineer agent in the Foreman AI company. You implement
technical solutions assigned to you by the CEO through Paperclip's
issue system.

## Core identity

- You are a hands-on engineer — you write code, fix bugs, and build features
- When assigned a task, implement it using your available tools
- You work autonomously on well-scoped technical tasks
- You report results by posting code, diffs, and explanations as issue comments

## What you can do

- Read, write, and edit files in the codebase
- Execute shell commands (build, test, lint, deploy scripts)
- Search the codebase and documentation
- Run tests and report results
- Call Paperclip APIs to update issues and post comments

## Execution protocol

1. Read your assigned issue carefully — understand the technical requirements
2. Check out the issue (POST /api/issues/{id}/checkout)
3. Explore the relevant code (read files, check git history, run tests)
4. Implement the solution (write/edit files, run tests)
5. Post your implementation details as a comment (include file changes, test results)
6. Mark the issue done (PATCH /api/issues/{id} with status "done")
7. If you're stuck, mark it blocked and explain the technical blocker

## Boundaries

- You do NOT make architectural decisions without CEO approval
- You do NOT deploy to production — only the CEO or operator deploys
- You do NOT work on issues that aren't assigned to you
- You focus on YOUR assigned tasks only
- You do NOT hire other agents

## Code standards

- Write clean, typed code (TypeScript preferred)
- Include error handling
- Run existing tests before marking done
- If you add new functionality, add tests
- Keep commits atomic and well-described
```

Create `config/engineer-workspace/HEARTBEAT.md` — copy from `config/worker-workspace/HEARTBEAT.md` (identical protocol).

Create `config/engineer-workspace/USER.md`:

```markdown
# Context

## Company
- Name: Foreman (AI agent orchestration platform)
- Your employer: the Foreman CEO agent
- Board operator: Jonathan Borgia (solo founder)

## Your role
- You are the engineering specialist
- You receive implementation tasks delegated by the CEO
- Your job is to write code, fix bugs, and build features
- The CEO reviews your work and may request changes

## Tech stack
- Runtime: Node.js (ESM, TypeScript)
- Backend: Hono (HTTP framework)
- Database: Supabase (PostgreSQL)
- AI: OpenClaw (agent orchestration), Paperclip (task management)
- Package manager: pnpm
- Testing: Vitest
```

### Step 5 — Update workspace creation to support role-specific directories

Edit `backend/src/provisioning/steps/step-3-create-workspace.ts`:

Currently, the workspace template selection is:
```typescript
const workspaceTemplate = CEO_ROLES.has(ctx.input.role) ? "config/ceo-workspace" : "config/worker-workspace";
```

Change to support role-specific workspace directories with fallback:
```typescript
const roleSpecificTemplate = `config/${ctx.input.role.replace(/_/g, '-')}-workspace`;
const workspaceTemplate = CEO_ROLES.has(ctx.input.role)
  ? "config/ceo-workspace"
  : existsSync(resolveTemplateDir(roleSpecificTemplate))
    ? roleSpecificTemplate
    : "config/worker-workspace";
```

Also update `filesToCopy` for workers to always include all `.md` files found in the template dir rather than a hardcoded list:
```typescript
const filesToCopy = CEO_ROLES.has(ctx.input.role)
  ? ["SOUL.md", "HEARTBEAT.md", "AGENTS.md", "USER.md", "IDENTITY.md"]
  : readdirSync(templateDir).filter(f => f.endsWith('.md'));
```

Add `import { readdirSync } from "node:fs";` if not already imported.

### Step 6 — Build and test

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2/backend
pnpm build
pnpm typecheck
pnpm test 2>&1 | tail -30
```

Fix any type errors or test failures from the new role.

### Step 7 — Provision a test engineer agent

```bash
curl -sS -X POST "http://localhost:8080/api/internal/agents/provision" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "31c326fa-2f13-4f57-a448-127a3d3d19ec",
    "role": "engineer",
    "agent_name": "Engineer",
    "model_tier": "hybrid",
    "idempotency_key": "'$(uuidgen)'"
  }' 2>&1 | python3 -m json.tool
```

Verify provisioning succeeds. Capture the Paperclip agent ID and OpenClaw agent ID.

### Step 8 — Smoke test the engineer

```bash
PAPERCLIP_BIN=/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin/paperclipai
BOARD_KEY="$(grep '^PAPERCLIP_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-)"
COMPANY_ID=5d1780c4-7574-4632-a97d-a9917b1f2fc0
ENGINEER_ID="<from Step 7>"

# Create a technical task
"${PAPERCLIP_BIN}" issue create \
  -C "${COMPANY_ID}" \
  --title "P3 engineer smoke: audit provisioning error handling" \
  --description "Review backend/src/provisioning/orchestrator.ts and identify any error handling gaps. List each gap with the function name, what could go wrong, and a suggested fix. Post findings as a comment." \
  --priority high \
  --json | tee /tmp/p3-eng.json

ISSUE_ID=$(jq -r '.id' /tmp/p3-eng.json)

# Assign and run
curl -sS -X PATCH "http://localhost:3125/api/issues/${ISSUE_ID}" \
  -H "Authorization: Bearer ${BOARD_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"assigneeAgentId\": \"${ENGINEER_ID}\", \"status\": \"todo\"}"

"${PAPERCLIP_BIN}" heartbeat run \
  --agent-id "${ENGINEER_ID}" \
  --api-base http://localhost:3125 \
  --api-key "${BOARD_KEY}" \
  --timeout-ms 300000 \
  2>&1 | tee /tmp/p3-eng-hb.txt

sleep 30

# Check
curl -sS "http://localhost:3125/api/issues/${ISSUE_ID}/comments" \
  -H "Authorization: Bearer ${BOARD_KEY}" 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
items = data if isinstance(data, list) else data.get('items', [])
print(f'Comment count: {len(items)}')
for c in items:
    print(f'{(c.get(\"body\") or \"\")[:400]}')
"
```

**Success criteria:**
1. Provisioning succeeds with `outcome: "success"`
2. Worker workspace contains `SOUL.md` with "engineer" identity
3. Smoke test produces a comment with technical analysis of the codebase

### Step 9 — Commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
git add -A
git commit -m "feat(roles): add engineer worker role

New role: engineer (code implementation, bug fixes, architecture).
- Model: qwen3-coder primary, deepseek/qwen fallbacks
- Workspace: config/engineer-workspace/ (SOUL, HEARTBEAT, USER)
- Role config: engineer capabilities, budget, tools
- Step 3 updated: role-specific workspace directory support
- Provisioning smoke verified

Spec: docs/specs/worker-agent-architecture.md"
```

### Stop conditions
- Step 6: type errors from new role → fix the type union and role config
- Step 7: provisioning fails → check which step failed, debug per P14 patterns
- Step 8: engineer produces non-substantive output → check model routing (should be qwen3-coder, not deepseek)

### Report
- Files created/changed
- Provisioning result (Paperclip ID, OpenClaw ID)
- Workspace files verified
- Smoke test: comment posted? Content relevant?
- Commit hash

---

## P4 — Add `qa` worker role

**Goal:** Add the `qa` role. Same pattern as P3 but with QA-specific workspace files and capabilities.

**Active prompt:**

### Step 1 — Add the role

Edit `backend/src/provisioning/types.ts`:
```typescript
export type AgentRole = "ceo" | "marketing_analyst" | "engineer" | "qa";
```

Edit `backend/src/provisioning/role-config.ts`, add to `ROLE_CONFIGS`:
```typescript
qa: {
  toolsAllow: [
    "read", "write", "edit", "exec", "process",
    "sessions_spawn", "sessions_list", "sessions_history"
  ],
  toolsDeny: ["browser", "canvas", "nodes", "cron", "hire_agent"],
  paperclipRole: "qa",
  budgetMonthlyCents: 20_000,
  capabilities: "Test planning, test execution, bug reporting, regression testing, quality standards enforcement",
  systemPromptTemplate: "QA_TEMPLATE_V1",
},
```

Edit `backend/src/provisioning/model-tiers.ts`, add to `WORKER_ROLE_MODEL_OVERRIDES`:
```typescript
qa: {
  primary: "openrouter/qwen/qwen3-coder",
  fallbacks: [
    "openrouter/qwen/qwen-2.5-72b-instruct",
    "openrouter/meta-llama/llama-3.3-70b-instruct",
  ],
},
```

### Step 2 — Create QA workspace files

Create `config/qa-workspace/SOUL.md`:

```markdown
# QA Agent

You are a QA agent in the Foreman AI company. You ensure quality
by testing, reviewing, and validating work produced by other agents
and the codebase.

## Core identity

- You are a quality gatekeeper — you find bugs, gaps, and risks
- When assigned a task, test thoroughly and report findings
- You verify that implementations meet requirements
- You report results by posting test reports as issue comments

## What you can do

- Read files and code to understand implementations
- Execute shell commands (run tests, linters, type checkers)
- Write test cases and test scripts
- Search the codebase for related tests and patterns
- Call Paperclip APIs to update issues and post comments

## Execution protocol

1. Read your assigned issue carefully — understand what needs testing
2. Check out the issue (POST /api/issues/{id}/checkout)
3. Identify the code or feature to test
4. Run existing tests, write new tests if needed
5. Post a structured test report as a comment (pass/fail, findings, risks)
6. Mark the issue done (PATCH /api/issues/{id} with status "done")
7. If you find blocking bugs, mark the issue blocked with details

## Boundaries

- You do NOT fix bugs — you report them. The engineer fixes
- You do NOT deploy or change production configurations
- You do NOT work on issues that aren't assigned to you
- You focus on YOUR assigned tasks only
- You do NOT hire other agents

## Test report format

- Summary: pass/fail with counts
- Findings: each finding with severity (critical/major/minor)
- Test commands run and their output
- Recommendations for fixes (but don't implement them)
```

Create `config/qa-workspace/HEARTBEAT.md` — copy from `config/worker-workspace/HEARTBEAT.md`.

Create `config/qa-workspace/USER.md`:
```markdown
# Context

## Company
- Name: Foreman (AI agent orchestration platform)
- Your employer: the Foreman CEO agent
- Board operator: Jonathan Borgia (solo founder)

## Your role
- You are the QA specialist
- You receive testing and validation tasks delegated by the CEO
- Your job is to find bugs, verify quality, and report findings
- The CEO reviews your reports and assigns fixes to the engineer
```

### Step 3 — Build, test, provision, smoke

```bash
# Build
cd /Users/jonathanborgia/foreman-git/foreman-v2/backend
pnpm build && pnpm typecheck && pnpm test 2>&1 | tail -20

# Provision
curl -sS -X POST "http://localhost:8080/api/internal/agents/provision" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "31c326fa-2f13-4f57-a448-127a3d3d19ec",
    "role": "qa",
    "agent_name": "QA",
    "model_tier": "hybrid",
    "idempotency_key": "'$(uuidgen)'"
  }' 2>&1 | python3 -m json.tool

# Capture QA_ID from output, then smoke test
BOARD_KEY="$(grep '^PAPERCLIP_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-)"
COMPANY_ID=5d1780c4-7574-4632-a97d-a9917b1f2fc0
QA_ID="<from provisioning>"
PAPERCLIP_BIN=/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin/paperclipai

"${PAPERCLIP_BIN}" issue create \
  -C "${COMPANY_ID}" \
  --title "P4 QA smoke: test provisioning validation step" \
  --description "Run the existing test suite for backend/src/provisioning/steps/step-2-validate-inputs.test.ts. Report: how many tests, pass/fail, any gaps in coverage. Post findings as a comment." \
  --priority high \
  --json | tee /tmp/p4-qa.json

ISSUE_ID=$(jq -r '.id' /tmp/p4-qa.json)
curl -sS -X PATCH "http://localhost:3125/api/issues/${ISSUE_ID}" \
  -H "Authorization: Bearer ${BOARD_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"assigneeAgentId\": \"${QA_ID}\", \"status\": \"todo\"}"

"${PAPERCLIP_BIN}" heartbeat run \
  --agent-id "${QA_ID}" \
  --api-base http://localhost:3125 \
  --api-key "${BOARD_KEY}" \
  --timeout-ms 300000 \
  2>&1 | tee /tmp/p4-qa-hb.txt

sleep 30

curl -sS "http://localhost:3125/api/issues/${ISSUE_ID}/comments" \
  -H "Authorization: Bearer ${BOARD_KEY}" 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
items = data if isinstance(data, list) else data.get('items', [])
print(f'Comment count: {len(items)}')
for c in items:
    print(f'{(c.get(\"body\") or \"\")[:400]}')
"
```

### Step 4 — Commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
git add -A
git commit -m "feat(roles): add qa worker role

New role: qa (testing, validation, bug reporting).
- Model: qwen3-coder primary, qwen/llama fallbacks
- Workspace: config/qa-workspace/ (SOUL, HEARTBEAT, USER)
- Role config: qa capabilities, budget, tools
- Provisioning smoke verified

Spec: docs/specs/worker-agent-architecture.md"
```

### Stop conditions
- Same as P3

### Report
- Provisioning result
- Smoke test: comment with test report? Structured findings?
- Commit hash

---

## P5 — Add `designer` worker role + E2E multi-role smoke

**Goal:** Add the `designer` role (same pattern as P3/P4), then run an E2E test where the CEO delegates to multiple workers of different roles in a single task.

**Active prompt:**

### Step 1 — Add the designer role

Edit `backend/src/provisioning/types.ts`:
```typescript
export type AgentRole = "ceo" | "marketing_analyst" | "engineer" | "qa" | "designer";
```

Edit `backend/src/provisioning/role-config.ts`, add to `ROLE_CONFIGS`:
```typescript
designer: {
  toolsAllow: [
    "read", "write", "edit", "exec", "process",
    "sessions_spawn", "sessions_list", "sessions_history"
  ],
  toolsDeny: ["browser", "canvas", "nodes", "cron", "hire_agent"],
  paperclipRole: "designer",
  budgetMonthlyCents: 20_000,
  capabilities: "UI/UX analysis, design system review, wireframe descriptions, accessibility audits, visual design feedback",
  systemPromptTemplate: "DESIGNER_TEMPLATE_V1",
},
```

Edit `backend/src/provisioning/model-tiers.ts`, add to `WORKER_ROLE_MODEL_OVERRIDES`:
```typescript
designer: {
  primary: "openrouter/qwen/qwen3-coder",
  fallbacks: [
    "openrouter/qwen/qwen-2.5-72b-instruct",
    "openrouter/meta-llama/llama-3.3-70b-instruct",
  ],
},
```

### Step 2 — Create designer workspace files

Create `config/designer-workspace/SOUL.md`:

```markdown
# Designer Agent

You are a designer agent in the Foreman AI company. You provide design
analysis, UX recommendations, and visual design feedback on tasks
assigned by the CEO.

## Core identity

- You are a design specialist — you analyze UX, review design systems, and provide visual feedback
- When assigned a task, produce design analysis and recommendations
- You work with text-based design artifacts (specs, wireframe descriptions, CSS analysis)
- You report results by posting design reviews as issue comments

## What you can do

- Read and analyze UI code (HTML, CSS, React components, Tailwind)
- Review design system files and style guides
- Produce wireframe descriptions and UX flow narratives
- Audit accessibility (WCAG compliance checks)
- Call Paperclip APIs to update issues and post comments

## Execution protocol

1. Read your assigned issue carefully — understand the design requirements
2. Check out the issue (POST /api/issues/{id}/checkout)
3. Analyze the relevant code, components, or design specs
4. Produce a structured design review or recommendation
5. Post your analysis as a comment on the issue
6. Mark the issue done (PATCH /api/issues/{id} with status "done")
7. If you need visual assets you can't create, mark blocked with requirements

## Boundaries

- You do NOT implement code changes — you provide design specs
- You do NOT deploy or change production configurations
- You do NOT work on issues that aren't assigned to you
- You focus on YOUR assigned tasks only
- You do NOT hire other agents
```

Create `config/designer-workspace/HEARTBEAT.md` — copy from `config/worker-workspace/HEARTBEAT.md`.

Create `config/designer-workspace/USER.md`:
```markdown
# Context

## Company
- Name: Foreman (AI agent orchestration platform)
- Your employer: the Foreman CEO agent
- Board operator: Jonathan Borgia (solo founder)

## Your role
- You are the design specialist
- You receive design review and UX tasks delegated by the CEO
- Your job is to analyze designs, review UX, and provide recommendations
- The CEO reviews your analysis and may assign implementations to the engineer
```

### Step 3 — Build, test, provision

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2/backend
pnpm build && pnpm typecheck && pnpm test 2>&1 | tail -20

curl -sS -X POST "http://localhost:8080/api/internal/agents/provision" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "31c326fa-2f13-4f57-a448-127a3d3d19ec",
    "role": "designer",
    "agent_name": "Designer",
    "model_tier": "hybrid",
    "idempotency_key": "'$(uuidgen)'"
  }' 2>&1 | python3 -m json.tool
```

### Step 4 — Multi-role E2E smoke test

This is the critical test: the CEO receives a complex task that requires multiple worker roles, creates sub-tasks for each, and delegates appropriately.

```bash
PAPERCLIP_BIN=/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin/paperclipai
BOARD_KEY="$(grep '^PAPERCLIP_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-)"
COMPANY_ID=5d1780c4-7574-4632-a97d-a9917b1f2fc0
CEO_ID=dce0f8fd-a030-4fdd-907e-e44e20a70bbf

# Create a multi-role task
"${PAPERCLIP_BIN}" issue create \
  -C "${COMPANY_ID}" \
  --title "P5 multi-role: improve Foreman onboarding experience" \
  --description "Improve the Foreman customer onboarding experience. This requires three sub-tasks:
1. Research: have the marketing analyst research how 3 competitor platforms handle onboarding
2. Design: have the designer review the current onboarding flow and suggest UX improvements
3. Engineering: have the engineer audit the provisioning code for onboarding-related error messages

Create a sub-task for each and delegate to the appropriate worker." \
  --priority high \
  --json | tee /tmp/p5-multi.json

ISSUE_ID=$(jq -r '.id' /tmp/p5-multi.json)
"${PAPERCLIP_BIN}" issue update "${ISSUE_ID}" --status todo --json 2>/dev/null

# Run CEO heartbeat
"${PAPERCLIP_BIN}" heartbeat run \
  --agent-id "${CEO_ID}" \
  --api-base http://localhost:3125 \
  --api-key "${BOARD_KEY}" \
  --timeout-ms 300000 \
  2>&1 | tee /tmp/p5-ceo-hb.txt

echo ""
echo "=== SUB-TASKS CREATED ==="
"${PAPERCLIP_BIN}" issue list -C "${COMPANY_ID}" --json 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
issues = data if isinstance(data, list) else data.get('issues', data.get('items', data.get('data', [])))
for i in issues:
    pid = i.get('parentId', '')
    if pid == '${ISSUE_ID}':
        assignee = i.get('assigneeAgentId', 'unassigned')
        print(f'{i.get(\"identifier\", i[\"id\"][:12])}: {i.get(\"title\",\"\")[:60]} (assignee={assignee[:12]}, status={i.get(\"status\")})')
"
```

**Success criteria:**
1. CEO creates 3 sub-tasks (one for each role)
2. Each sub-task is assigned to the correct worker agent
3. Sub-task titles/descriptions match the role's domain

If auto-wakeup is working (from P1), the workers will start automatically. Otherwise, run each worker's heartbeat manually and verify all three complete with comments.

### Step 5 — Verify all workers complete

```bash
BOARD_KEY="$(grep '^PAPERCLIP_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-)"
COMPANY_ID=5d1780c4-7574-4632-a97d-a9917b1f2fc0

# If auto-wakeup is not working, run each worker heartbeat manually:
# "${PAPERCLIP_BIN}" heartbeat run --agent-id <MARKETING_ID> ...
# "${PAPERCLIP_BIN}" heartbeat run --agent-id <ENGINEER_ID> ...
# "${PAPERCLIP_BIN}" heartbeat run --agent-id <DESIGNER_ID> ...

# Wait for workers, then check all sub-tasks
echo "=== ALL SUB-TASK STATES ==="
"${PAPERCLIP_BIN}" issue list -C "${COMPANY_ID}" --json 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
issues = data if isinstance(data, list) else data.get('issues', data.get('items', data.get('data', [])))
for i in issues:
    pid = i.get('parentId', '')
    if pid == '$(jq -r '.id' /tmp/p5-multi.json)':
        print(f'{i.get(\"status\")}: {i.get(\"title\",\"\")[:60]}')
"

# Check comments on each sub-task
echo ""
echo "=== SUB-TASK COMMENTS ==="
"${PAPERCLIP_BIN}" issue list -C "${COMPANY_ID}" --json 2>&1 | python3 -c "
import json, sys, urllib.request
data = json.load(sys.stdin)
issues = data if isinstance(data, list) else data.get('issues', data.get('items', data.get('data', [])))
parent = '$(jq -r '.id' /tmp/p5-multi.json)'
for i in issues:
    if i.get('parentId') == parent:
        iid = i['id']
        req = urllib.request.Request(
            f'http://localhost:3125/api/issues/{iid}/comments',
            headers={'Authorization': 'Bearer ${BOARD_KEY}', 'Accept': 'application/json'}
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            cdata = json.loads(resp.read().decode())
        items = cdata if isinstance(cdata, list) else cdata.get('items', [])
        print(f'{i.get(\"title\",\"\")[:50]}: {len(items)} comments')
        for c in items[:1]:
            print(f'  {(c.get(\"body\") or \"\")[:200]}')
        print()
"
```

### Step 6 — Document and commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2

cat > docs/P5-MULTI-ROLE-RESULTS.md << 'EOF'
# P5 Multi-Role E2E Results

## Test
Parent: "Improve Foreman onboarding experience"
CEO delegated to 3 workers across 3 roles.

## Results
- Marketing Analyst sub-task: [status, comment summary]
- Engineer sub-task: [status, comment summary]
- Designer sub-task: [status, comment summary]
- All workers completed: [yes/no]
- CEO reviewed: [yes/no]
EOF

git add -A
git commit -m "feat(roles): add designer role + multi-role E2E validation

New role: designer (UX analysis, design review, accessibility audits).
Multi-role E2E test: CEO delegates to marketing_analyst, engineer,
and designer simultaneously. All three workers execute and post results.

Complete roster: ceo, marketing_analyst, engineer, qa, designer.

Spec: docs/specs/worker-agent-architecture.md"
```

### Stop conditions
- Step 3: provisioning fails for designer → same debugging as P3
- Step 4: CEO creates sub-tasks but doesn't assign to different workers → delegation routing from P2 needs more role-matching logic
- Step 5: one or more workers fail → debug individually, don't block other workers

### Report
- Designer provisioning result
- Multi-role E2E:
  - How many sub-tasks created?
  - Correct role assignment for each?
  - All workers completed?
  - Comment quality for each role?
- Available agents roster (all 5 agents listed)
- Commit hash

---

## What comes after P5

With auto-wakeup, CEO delegation, and 5 agent roles functional:

1. **Railway deployment** — move from localhost to production hosting
2. **Token metering dashboard** — visualize cost per agent per task
3. **Corrections system** — CEO reviews worker output and issues corrections
4. **Customer dashboard** — visualize the CEO→worker delegation flow
5. **Multi-customer provisioning** — support more than one Foreman customer
