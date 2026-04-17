# Cursor Prompt Sequence — CEO Planner / Executor Split Architecture

**Predecessor:** `foreman-v2/docs/cursor-prompts-full-functional.md` (P15-P22, complete)

**Source-of-truth scope doc:** `foreman-v2/docs/specs/provision-foreman-agent-scope.md` (v1.2)

**Stack decisions (locked — inherited from P0-P22):**
- Language: TypeScript/Node (Node 20 LTS)
- Backend location: `foreman-v2/backend/`
- Database: Supabase (existing project `bsgpogxfhcaxjlrsmsaj`)
- Orchestration: Paperclip (localhost:3125) + OpenClaw (localhost:18789)
- Inference: OpenRouter (DeepSeek V3.1 for planning, Qwen 2.5 72B for execution)
- Production CEO (current): Paperclip `44f95028-f240-4be9-8e9c-e5420240aa41` / OpenClaw `foreman-foreman-ceo`
- Foreman customer: `31c326fa-2f13-4f57-a448-127a3d3d19ec` (BYOK, founder coupon)
- Paperclip company: `5d1780c4-7574-4632-a97d-a9917b1f2fc0`

---

## Problem Statement

DeepSeek V3.1 is the best reasoning model in our OpenRouter catalog, but it does not natively execute tool calls. The current CEO runs DeepSeek through the OpenClaw gateway adapter, which means heartbeat runs produce planning text ("I'll run the procedure step by step...") but zero actual tool invocations — no API calls, no `hire_agent`, no issue updates.

Qwen 2.5 72B handles tool calls natively but is weaker at strategic reasoning and planning.

## Architecture: Planner / Executor Split

**CEO (Planner)** — Paperclip `process` adapter, runs DeepSeek V3.1 via OpenRouter.
- Receives heartbeat with issue context
- Reasons about what to do: triage, prioritize, decompose into sub-tasks
- Outputs a structured plan (JSON) with sub-tasks, assignments, comments
- Does NOT execute tool calls — only produces the plan

**CEO Executor (Executor)** — A Node.js script that reads the CEO's plan output and executes it against the Paperclip API.
- Creates sub-issues in Paperclip
- Assigns issues to agents
- Posts comments on issues
- Calls `hire_agent` via the Foreman backend when the plan says to hire
- Updates issue status (checkout, done, blocked)
- This is deterministic code, not an LLM — it just executes the plan

**Worker agents (future)** — OpenClaw gateway adapter, run Qwen 2.5 72B.
- Receive assigned sub-tasks via Paperclip heartbeats
- Execute tool calls natively (file operations, API calls, etc.)
- Report results back via issue comments

This prompt sequence builds the CEO Planner + Executor. Worker agents are a separate future workstream.

---

## How it works end-to-end

```
User creates issue in Paperclip
    ↓
Paperclip heartbeat fires for CEO (process adapter)
    ↓
Process adapter spawns: node scripts/ceo-heartbeat.js
    ↓
ceo-heartbeat.js:
  1. Reads env vars (PAPERCLIP_AGENT_ID, PAPERCLIP_COMPANY_ID, PAPERCLIP_API_KEY, etc.)
  2. Calls Paperclip API: GET /api/agents/me, GET issues inbox
  3. Builds a prompt with the issue context + SOUL.md + HEARTBEAT.md
  4. Calls OpenRouter API: POST /v1/chat/completions (DeepSeek V3.1)
  5. Parses the structured JSON plan from DeepSeek's response
  6. Executes each action in the plan against Paperclip API:
     - POST /api/issues/{id}/checkout
     - POST /api/issues/{id}/comments
     - PATCH /api/issues/{id} (status changes)
     - POST /api/companies/{id}/issues (create sub-tasks)
     - POST /api/internal/agents/provision (hire_agent)
  7. Outputs result JSON to stdout (Paperclip captures this)
    ↓
Paperclip records the run as succeeded/failed
```

---

## Prompt index

| # | Title | Type | Estimate | Deps |
|---|---|---|---|---|
| S1 | Design doc: CEO planner/executor split | Design | 1-2 hrs | None |
| S2 | Build ceo-heartbeat.js — the process adapter script | Code | 4-6 hrs | S1 |
| S3 | Build the plan executor module | Code | 3-4 hrs | S2 |
| S4 | Provision new CEO as process adapter in Paperclip | Config | 2-3 hrs | S3 |
| S5 | Migrate workspace files + heartbeat config to new CEO | Config | 1-2 hrs | S4 |
| S6 | Smoke test: full planner/executor cycle | Test | 2-3 hrs | S5 |
| S7 | Wire token metering for process adapter CEO | Code | 2-3 hrs | S6 |
| S8 | Cleanup old OpenClaw CEO + update docs | Cleanup | 1-2 hrs | S7 |

**Total estimated build time:** 16-24 hours across 8 prompts.

---

## S1 — Design doc: CEO planner/executor split

**Goal:** Write the design doc that defines the plan schema, the executor's action set, the process adapter configuration, and the interaction contract between planner and executor.

**Active prompt:**

### Step 1 — Read the Paperclip process adapter docs

Before writing anything, read the authoritative docs:
- https://docs.paperclip.ing (search for "process adapter", "adapterType process", "child process")
- Understand: what env vars does Paperclip inject into the child process? How does it capture output? What is the expected exit behavior?

Per the docs, Paperclip's process adapter:
- Spawns a child process with `spawn(command, args, { cwd, env })`
- Injects env vars: `PAPERCLIP_RUN_ID`, `PAPERCLIP_AGENT_ID`, `PAPERCLIP_COMPANY_ID`, `PAPERCLIP_API_URL`, `PAPERCLIP_API_KEY` (run JWT), `PAPERCLIP_TASK_ID`, `PAPERCLIP_WAKE_REASON`
- Captures stdout/stderr
- Expects exit code 0 for success
- Supports `promptTemplate` for the prompt passed via stdin
- Supports `timeoutSec` and `graceSec`

### Step 2 — Write the design doc

Create `foreman-v2/docs/specs/ceo-planner-executor-split.md`:

```markdown
# CEO Planner/Executor Split — Design Document

## Problem
DeepSeek V3.1 produces excellent strategic reasoning but cannot execute
tool calls through the OpenClaw gateway. The CEO agent produces plans
but never acts on them.

## Solution
Split the CEO into two phases within a single heartbeat run:

1. **Planner** (DeepSeek V3.1 via OpenRouter): reads context, reasons,
   outputs a structured JSON plan
2. **Executor** (deterministic Node.js code): reads the plan, executes
   each action against the Paperclip API

Both phases run inside a single `process` adapter invocation
(`scripts/ceo-heartbeat.js`), so from Paperclip's perspective it's
one heartbeat run with one exit code.

## Plan Schema

The planner outputs a JSON object with this shape:

```json
{
  "reasoning": "Brief explanation of what I assessed and decided",
  "actions": [
    {
      "type": "checkout_issue",
      "issue_id": "xxx"
    },
    {
      "type": "comment",
      "issue_id": "xxx",
      "body": "Status update text"
    },
    {
      "type": "update_status",
      "issue_id": "xxx",
      "status": "done",
      "comment": "Completed because..."
    },
    {
      "type": "create_issue",
      "title": "Sub-task title",
      "description": "What needs to be done",
      "priority": "high",
      "assignee_agent_id": "optional-agent-id",
      "parent_id": "optional-parent-issue-id"
    },
    {
      "type": "hire_agent",
      "role": "marketing_analyst",
      "display_name": "Marketing Analyst"
    },
    {
      "type": "escalate",
      "message": "Need board input on strategic direction"
    }
  ]
}
```

## Action Types

| Type | Description | Paperclip API |
|------|-------------|---------------|
| `checkout_issue` | Claim a task for work | `POST /api/issues/{id}/checkout` |
| `comment` | Post a progress comment | `POST /api/issues/{id}/comments` |
| `update_status` | Change issue status | `PATCH /api/issues/{id}` |
| `create_issue` | Create a sub-task | `POST /api/companies/{companyId}/issues` |
| `hire_agent` | Provision a new AI agent | `POST localhost:8080/api/internal/agents/provision` |
| `escalate` | Flag for board attention | `POST /api/issues/{id}/comments` with [ESCALATION] prefix |
| `no_action` | Nothing to do this cycle | (no API call) |

## Process Adapter Config

```json
{
  "name": "Foreman CEO",
  "role": "ceo",
  "adapterType": "process",
  "adapterConfig": {
    "command": "node",
    "args": ["scripts/ceo-heartbeat.js"],
    "cwd": "/Users/jonathanborgia/foreman-git/foreman-v2",
    "env": {
      "OPENROUTER_API_KEY": "<from .env>",
      "DEEPSEEK_MODEL": "deepseek/deepseek-chat-v3-0324",
      "FOREMAN_API_BASE": "http://localhost:8080"
    },
    "timeoutSec": 300,
    "graceSec": 30
  }
}
```

Paperclip injects: `PAPERCLIP_RUN_ID`, `PAPERCLIP_AGENT_ID`,
`PAPERCLIP_COMPANY_ID`, `PAPERCLIP_API_URL`, `PAPERCLIP_API_KEY`,
`PAPERCLIP_TASK_ID`, `PAPERCLIP_WAKE_REASON`

The script reads these from `process.env` — no claimed key file needed.

## Script Flow (ceo-heartbeat.js)

1. Read injected env vars
2. Call `GET /api/agents/me` to confirm identity
3. If `PAPERCLIP_TASK_ID` is set: fetch that specific issue
4. Else: fetch inbox (`GET /api/companies/{id}/issues?assigneeAgentId=...&status=todo,in_progress,blocked`)
5. Read SOUL.md, HEARTBEAT.md, AGENTS.md from `cwd` (the repo root, where `config/ceo-workspace/` lives)
6. Build the DeepSeek prompt:
   - System: SOUL.md + HEARTBEAT.md + available action types
   - User: current inbox state + issue details + "Output a JSON plan"
7. Call OpenRouter: `POST https://openrouter.ai/api/v1/chat/completions`
8. Parse JSON plan from response
9. Execute each action via Paperclip API
10. Output summary to stdout
11. Exit 0 on success, exit 1 on failure

## Token Metering

The script calls OpenRouter directly (not through OpenClaw), so the
`foreman-token-meter` OpenClaw plugin won't fire. Instead, the script
POSTs cost events to Paperclip directly after each OpenRouter call:

```
POST /api/companies/{companyId}/cost-events
{
  "agentId": "{paperclipAgentId}",
  "provider": "openrouter",
  "model": "deepseek/deepseek-chat-v3-0324",
  "inputTokens": N,
  "outputTokens": M,
  "costCents": C,
  "occurredAt": "ISO timestamp"
}
```

## What stays on OpenClaw

- Worker agents (marketing_analyst, future roles) stay on OpenClaw
  with Qwen for tool execution
- The `foreman-token-meter` plugin continues to meter those agents
- The CEO no longer runs through OpenClaw at all

## Migration Path

1. Create new Paperclip agent with `adapterType: "process"`
2. Disable current OpenClaw CEO agent
3. Transfer heartbeat config, budget, workspace files
4. Verify via smoke test
5. Clean up old OpenClaw agent registration
```

### Step 3 — Commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
git add docs/specs/ceo-planner-executor-split.md
git commit -m "docs: design doc for CEO planner/executor split architecture

DeepSeek V3.1 plans (via process adapter), deterministic Node.js
code executes the plan against Paperclip API. Replaces the current
OpenClaw gateway adapter which can't execute tool calls with DeepSeek.

Defines: plan schema, action types, process adapter config, script
flow, token metering approach, migration path.

Spec: docs/specs/ceo-planner-executor-split.md"
```

### Report
- Design doc created and committed
- Commit hash

---

## S2 — Build ceo-heartbeat.js

**Goal:** Create the Node.js script that Paperclip's process adapter will spawn on each heartbeat. This script is the CEO's brain — it reads context, calls DeepSeek for planning, and outputs a structured plan.

**Active prompt:**

### Step 1 — Read the design doc

```bash
cat /Users/jonathanborgia/foreman-git/foreman-v2/docs/specs/ceo-planner-executor-split.md
```

This is the source of truth for the plan schema and script flow.

### Step 2 — Create the script

Create `foreman-v2/scripts/ceo-heartbeat.js` (or `.ts` compiled to JS — your choice, but the process adapter needs to run it with `node`):

The script must:

**2a — Read Paperclip context from env vars:**
```javascript
const {
  PAPERCLIP_RUN_ID,
  PAPERCLIP_AGENT_ID,
  PAPERCLIP_COMPANY_ID,
  PAPERCLIP_API_URL,    // e.g. http://127.0.0.1:3125
  PAPERCLIP_API_KEY,    // run JWT injected by Paperclip
  PAPERCLIP_TASK_ID,    // set when woken for a specific task
  PAPERCLIP_WAKE_REASON,
  OPENROUTER_API_KEY,
  DEEPSEEK_MODEL,       // default: deepseek/deepseek-chat-v3-0324
  FOREMAN_API_BASE,     // default: http://localhost:8080
} = process.env;
```

Validate that required vars are present. Exit 1 with error message if not.

**2b — Fetch agent identity and inbox:**
```javascript
// GET /api/agents/me
const me = await paperclipGet('/api/agents/me');

// Fetch inbox or specific task
let issues;
if (PAPERCLIP_TASK_ID) {
  const issue = await paperclipGet(`/api/issues/${PAPERCLIP_TASK_ID}`);
  const comments = await paperclipGet(`/api/issues/${PAPERCLIP_TASK_ID}/comments`);
  issues = [{ ...issue, comments }];
} else {
  issues = await paperclipGet(
    `/api/companies/${PAPERCLIP_COMPANY_ID}/issues?assigneeAgentId=${PAPERCLIP_AGENT_ID}&status=todo,in_progress,blocked`
  );
}
```

**2c — Read workspace files from repo:**
```javascript
import { readFileSync } from 'fs';
import { resolve } from 'path';

const wsDir = resolve(process.cwd(), 'config/ceo-workspace');
const soulMd = readFileSync(resolve(wsDir, 'SOUL.md'), 'utf8');
const heartbeatMd = readFileSync(resolve(wsDir, 'HEARTBEAT.md'), 'utf8');
const agentsMd = readFileSync(resolve(wsDir, 'AGENTS.md'), 'utf8');
```

**2d — Build the DeepSeek prompt:**

System prompt should include:
- SOUL.md content
- HEARTBEAT.md content (adapted — remove the API-call steps since the executor handles those)
- The plan schema definition with all action types
- Clear instruction: "Output ONLY a valid JSON object matching the plan schema. No prose, no markdown, no code blocks."

User prompt should include:
- Current agent identity (from /agents/me)
- Wake reason
- Full inbox state (issues with titles, descriptions, statuses, comments)
- Specific task details if PAPERCLIP_TASK_ID is set

**2e — Call OpenRouter:**
```javascript
const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
    'HTTP-Referer': 'https://foreman.us',
    'X-Title': 'Foreman CEO Heartbeat',
  },
  body: JSON.stringify({
    model: DEEPSEEK_MODEL || 'deepseek/deepseek-chat-v3-0324',
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt },
    ],
    response_format: { type: 'json_object' },
    max_tokens: 4096,
    temperature: 0.3,
  }),
});
```

**2f — Parse the plan:**
```javascript
const data = await response.json();
const content = data.choices[0].message.content;
const plan = JSON.parse(content);
// Validate plan shape
```

Capture token usage from `data.usage` for metering.

**2g — Output the plan to stdout** (the executor in S3 will read and execute it, but for now just output it):
```javascript
console.log(JSON.stringify({
  status: 'plan_ready',
  reasoning: plan.reasoning,
  actions: plan.actions,
  usage: {
    inputTokens: data.usage.prompt_tokens,
    outputTokens: data.usage.completion_tokens,
    model: DEEPSEEK_MODEL || 'deepseek/deepseek-chat-v3-0324',
  },
}));
process.exit(0);
```

### Step 3 — Make the script self-contained

The script should have zero npm dependencies beyond Node.js built-ins (`fetch` is built into Node 20, `fs` and `path` are built-in). No `pnpm install` needed — the process adapter just runs `node scripts/ceo-heartbeat.js`.

If you need to compile TypeScript: create `scripts/ceo-heartbeat.ts` and add a build step that compiles to `scripts/ceo-heartbeat.js`. But plain JS is simpler for the process adapter.

### Step 4 — Test the script standalone

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2

# Simulate the env vars Paperclip would inject
BOARD_KEY="$(grep '^PAPERCLIP_API_KEY=' .env | cut -d= -f2-)"
OPENROUTER_KEY="$(grep '^OPENROUTER_API_KEY=' .env | cut -d= -f2-)"

PAPERCLIP_RUN_ID=test-run-001 \
PAPERCLIP_AGENT_ID=44f95028-f240-4be9-8e9c-e5420240aa41 \
PAPERCLIP_COMPANY_ID=5d1780c4-7574-4632-a97d-a9917b1f2fc0 \
PAPERCLIP_API_URL=http://127.0.0.1:3125 \
PAPERCLIP_API_KEY="${BOARD_KEY}" \
OPENROUTER_API_KEY="${OPENROUTER_KEY}" \
DEEPSEEK_MODEL=deepseek/deepseek-chat-v3-0324 \
FOREMAN_API_BASE=http://localhost:8080 \
node scripts/ceo-heartbeat.js 2>&1 | python3 -m json.tool
```

Expected: a JSON object with `status: "plan_ready"`, `reasoning`, `actions` array, and `usage` counts.

If the script errors: fix it before proceeding.

### Step 5 — Commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
git add scripts/ceo-heartbeat.js
git commit -m "feat(ceo): planner script — DeepSeek via OpenRouter, structured JSON plan output

scripts/ceo-heartbeat.js is the CEO's brain for the process adapter:
- Reads Paperclip context from injected env vars
- Fetches inbox/task from Paperclip API
- Reads SOUL.md + HEARTBEAT.md from config/ceo-workspace/
- Calls DeepSeek V3.1 via OpenRouter for strategic planning
- Outputs structured JSON plan (actions + reasoning + token usage)
- Zero npm dependencies (Node.js built-ins only)

Does NOT execute actions yet — that's S3 (plan executor).

Spec: docs/specs/ceo-planner-executor-split.md"
```

### Stop conditions
- Step 4: OpenRouter returns an error → check API key, model name, rate limits
- Step 4: DeepSeek returns non-JSON output → adjust the system prompt to be more explicit about JSON-only output
- Step 4: script can't reach Paperclip API → check PAPERCLIP_API_URL

### Report
- Script created (file path, line count)
- Step 4 standalone test result: did DeepSeek produce a valid JSON plan?
- Token usage from the test call
- Commit hash

---

## S3 — Build the plan executor module

**Goal:** Create the module that reads the CEO's plan and executes each action against the Paperclip API. Then integrate it into `ceo-heartbeat.js` so the full planner→executor cycle runs in one process.

**Active prompt:**

### Step 1 — Create the executor module

Create `foreman-v2/scripts/lib/plan-executor.js`:

The executor takes a plan object and executes each action sequentially:

```javascript
export async function executePlan(plan, context) {
  const { apiUrl, apiKey, companyId, agentId, runId, foremanApiBase, logger } = context;
  const results = [];

  for (const action of plan.actions) {
    try {
      const result = await executeAction(action, context);
      results.push({ action: action.type, status: 'ok', ...result });
      logger(`✓ ${action.type}: ${result.summary || 'done'}`);
    } catch (err) {
      results.push({ action: action.type, status: 'error', error: err.message });
      logger(`✗ ${action.type}: ${err.message}`);
      // Continue with remaining actions — don't abort the whole plan
    }
  }

  return results;
}

async function executeAction(action, context) {
  switch (action.type) {
    case 'checkout_issue':
      return checkoutIssue(action, context);
    case 'comment':
      return postComment(action, context);
    case 'update_status':
      return updateIssueStatus(action, context);
    case 'create_issue':
      return createIssue(action, context);
    case 'hire_agent':
      return hireAgent(action, context);
    case 'escalate':
      return postEscalation(action, context);
    case 'no_action':
      return { summary: 'No action needed this cycle' };
    default:
      throw new Error(`Unknown action type: ${action.type}`);
  }
}
```

Implement each action handler:

**checkout_issue:**
```javascript
async function checkoutIssue(action, ctx) {
  await paperclipPost(ctx, `/api/issues/${action.issue_id}/checkout`, {
    agentId: ctx.agentId,
    expectedStatuses: ['todo', 'backlog', 'blocked'],
  }, { 'X-Paperclip-Run-Id': ctx.runId });
  return { summary: `Checked out ${action.issue_id}` };
}
```

**comment:**
```javascript
async function postComment(action, ctx) {
  await paperclipPost(ctx, `/api/issues/${action.issue_id}/comments`, {
    body: action.body,
  }, { 'X-Paperclip-Run-Id': ctx.runId });
  return { summary: `Commented on ${action.issue_id}` };
}
```

**update_status:**
```javascript
async function updateIssueStatus(action, ctx) {
  await paperclipPatch(ctx, `/api/issues/${action.issue_id}`, {
    status: action.status,
    comment: action.comment,
  }, { 'X-Paperclip-Run-Id': ctx.runId });
  return { summary: `${action.issue_id} → ${action.status}` };
}
```

**create_issue:**
```javascript
async function createIssue(action, ctx) {
  const body = {
    title: action.title,
    description: action.description,
    priority: action.priority || 'medium',
  };
  if (action.assignee_agent_id) body.assigneeAgentId = action.assignee_agent_id;
  if (action.parent_id) body.parentId = action.parent_id;

  const result = await paperclipPost(ctx, `/api/companies/${ctx.companyId}/issues`, body,
    { 'X-Paperclip-Run-Id': ctx.runId });
  return { summary: `Created: ${action.title}`, issueId: result.id };
}
```

**hire_agent:**
```javascript
async function hireAgent(action, ctx) {
  const result = await fetch(`${ctx.foremanApiBase}/api/internal/agents/provision`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      customer_id: ctx.customerId, // resolved from env or DB
      role: action.role,
      agent_name: action.display_name || action.role,
      model_tier: 'hybrid',
      idempotency_key: crypto.randomUUID(),
    }),
  });
  const data = await result.json();
  if (!result.ok) throw new Error(data.customer_message || data.error || 'Hire failed');
  return { summary: `Hired ${action.role}: ${data.agent_id}` };
}
```

**escalate:**
```javascript
async function postEscalation(action, ctx) {
  // Post as a comment with [ESCALATION] prefix so board operator notices
  await paperclipPost(ctx, `/api/issues/${action.issue_id || 'inbox'}/comments`, {
    body: `[ESCALATION] ${action.message}`,
  }, { 'X-Paperclip-Run-Id': ctx.runId });
  return { summary: `Escalated: ${action.message.slice(0, 50)}` };
}
```

### Step 2 — Integrate executor into ceo-heartbeat.js

Update `scripts/ceo-heartbeat.js` to call the executor after getting the plan from DeepSeek:

```javascript
import { executePlan } from './lib/plan-executor.js';

// ... after parsing the plan from DeepSeek ...

const executionResults = await executePlan(plan, {
  apiUrl: PAPERCLIP_API_URL,
  apiKey: PAPERCLIP_API_KEY,
  companyId: PAPERCLIP_COMPANY_ID,
  agentId: PAPERCLIP_AGENT_ID,
  runId: PAPERCLIP_RUN_ID,
  foremanApiBase: FOREMAN_API_BASE || 'http://localhost:8080',
  logger: (msg) => process.stderr.write(`[ceo-executor] ${msg}\n`),
});

// Output final result
console.log(JSON.stringify({
  status: 'completed',
  reasoning: plan.reasoning,
  actionsPlanned: plan.actions.length,
  actionsExecuted: executionResults.filter(r => r.status === 'ok').length,
  actionsFailed: executionResults.filter(r => r.status === 'error').length,
  results: executionResults,
  usage: { /* token counts from DeepSeek call */ },
}));
```

### Step 3 — Test end-to-end standalone

Create a test issue first, then run the script:

```bash
BOARD_KEY="$(grep '^PAPERCLIP_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-)"
PAPERCLIP_BIN=/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin/paperclipai
COMPANY_ID=5d1780c4-7574-4632-a97d-a9917b1f2fc0
CEO_ID=44f95028-f240-4be9-8e9c-e5420240aa41

# Create a test issue
"${PAPERCLIP_BIN}" issue create \
  -C "${COMPANY_ID}" \
  --title "S3 executor test: write a status report" \
  --description "Write a brief 3-sentence status report on the Foreman workspace. Post it as a comment on this issue and mark it done." \
  --priority high \
  --json | tee /tmp/s3-test.json

ISSUE_ID=$(jq -r '.id' /tmp/s3-test.json)
"${PAPERCLIP_BIN}" issue update "${ISSUE_ID}" --status todo --json

# Run the full planner + executor
cd /Users/jonathanborgia/foreman-git/foreman-v2
OPENROUTER_KEY="$(grep '^OPENROUTER_API_KEY=' .env | cut -d= -f2-)"

PAPERCLIP_RUN_ID=test-run-s3 \
PAPERCLIP_AGENT_ID="${CEO_ID}" \
PAPERCLIP_COMPANY_ID="${COMPANY_ID}" \
PAPERCLIP_API_URL=http://127.0.0.1:3125 \
PAPERCLIP_API_KEY="${BOARD_KEY}" \
PAPERCLIP_TASK_ID="${ISSUE_ID}" \
PAPERCLIP_WAKE_REASON=issue_assigned \
OPENROUTER_API_KEY="${OPENROUTER_KEY}" \
DEEPSEEK_MODEL=deepseek/deepseek-chat-v3-0324 \
FOREMAN_API_BASE=http://localhost:8080 \
node scripts/ceo-heartbeat.js 2>&1

# Check the issue state after execution
"${PAPERCLIP_BIN}" issue get "${ISSUE_ID}" --json 2>&1 | python3 -c "
import json, sys
txt = sys.stdin.read()
data = json.loads(txt[txt.find('{'):])
print(f'Status: {data.get(\"status\")}')
for c in data.get('comments', []):
    print(f'Comment: {c.get(\"body\", \"\")[:200]}')
"
```

Expected:
- Script outputs JSON with `status: "completed"`, `actionsExecuted > 0`
- Issue has a new comment from the CEO
- Issue status changed to `done`

### Step 4 — Commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
git add scripts/lib/plan-executor.js scripts/ceo-heartbeat.js
git commit -m "feat(ceo): plan executor — executes DeepSeek's plan against Paperclip API

scripts/lib/plan-executor.js executes structured plans:
- checkout_issue, comment, update_status, create_issue
- hire_agent (calls Foreman provisioning endpoint)
- escalate (posts [ESCALATION] comment for board attention)
- Continues on individual action failure (doesn't abort plan)

Integrated into ceo-heartbeat.js: DeepSeek plans → executor acts.
Full cycle tested: issue commented + marked done.

Spec: docs/specs/ceo-planner-executor-split.md"
```

### Stop conditions
- Step 3: DeepSeek produces a plan but executor fails to execute → report which action failed and the error
- Step 3: issue doesn't get commented or status doesn't change → the executor's API calls are failing; check stderr output

### Report
- Plan executor module created (file path, action count)
- Step 3 test result: DeepSeek plan (reasoning + actions), execution results, final issue state
- Commit hash

---

## S4 — Provision new CEO as process adapter in Paperclip

**Goal:** Create a new Paperclip agent with `adapterType: "process"` that runs `node scripts/ceo-heartbeat.js`. Disable the current OpenClaw CEO.

**Active prompt:**

### Step 1 — Create the process adapter CEO in Paperclip

```bash
BOARD_KEY="$(grep '^PAPERCLIP_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-)"
COMPANY_ID=5d1780c4-7574-4632-a97d-a9917b1f2fc0
OPENROUTER_KEY="$(grep '^OPENROUTER_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-)"

curl -sS -X POST "http://localhost:3125/api/companies/${COMPANY_ID}/agents" \
  -H "Authorization: Bearer ${BOARD_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Foreman CEO\",
    \"role\": \"ceo\",
    \"title\": \"Chief Executive Officer\",
    \"adapterType\": \"process\",
    \"adapterConfig\": {
      \"command\": \"node\",
      \"args\": [\"scripts/ceo-heartbeat.js\"],
      \"cwd\": \"/Users/jonathanborgia/foreman-git/foreman-v2\",
      \"env\": {
        \"OPENROUTER_API_KEY\": \"${OPENROUTER_KEY}\",
        \"DEEPSEEK_MODEL\": \"deepseek/deepseek-chat-v3-0324\",
        \"FOREMAN_API_BASE\": \"http://localhost:8080\"
      },
      \"timeoutSec\": 300,
      \"graceSec\": 30
    },
    \"budgetMonthlyCents\": 5000
  }" \
  -w "\nHTTP %{http_code}\n" 2>&1 | tee /tmp/s4-new-ceo.json
```

Capture the new agent ID.

If the agent name conflicts with the existing OpenClaw CEO: use a different name temporarily, or disable the old CEO first.

### Step 2 — Configure heartbeat on the new CEO

```bash
NEW_CEO_ID="<from Step 1>"

# Read full config, merge heartbeat settings
CURRENT=$(curl -sS "http://localhost:3125/api/agents/${NEW_CEO_ID}" \
  -H "Authorization: Bearer ${BOARD_KEY}")

PATCH=$(python3 -c "
import json
d = json.loads('''${CURRENT}''')
agent = d.get('agent', d)
ac = dict(agent.get('adapterConfig', {}))
ac['timeoutSec'] = 300
patch = {
    'runtimeConfig': {
        'heartbeat': {
            'enabled': True,
            'intervalSec': 1800,
            'mode': 'proactive'
        }
    },
    'adapterConfig': ac
}
print(json.dumps(patch, indent=2))
")

curl -sS -X PATCH "http://localhost:3125/api/agents/${NEW_CEO_ID}" \
  -H "Authorization: Bearer ${BOARD_KEY}" \
  -H "Content-Type: application/json" \
  -d "${PATCH}" \
  -w "\nHTTP %{http_code}\n"
```

### Step 3 — Disable the old OpenClaw CEO

```bash
OLD_CEO_ID=44f95028-f240-4be9-8e9c-e5420240aa41

# Zero out adapter config
CURRENT=$(curl -sS "http://localhost:3125/companies/${COMPANY_ID}/agents/${OLD_CEO_ID}" \
  -H "Authorization: Bearer ${BOARD_KEY}")

PATCH=$(python3 -c "
import json
d = json.loads('''${CURRENT}''')
agent = d.get('agent', d)
ac = dict(agent.get('adapterConfig', {}))
ac['gatewayUrl'] = ''
ac['url'] = ''
ac.pop('headers', None)
print(json.dumps({'adapterConfig': ac}))
")

curl -sS -X PATCH "http://localhost:3125/api/agents/${OLD_CEO_ID}" \
  -H "Authorization: Bearer ${BOARD_KEY}" \
  -H "Content-Type: application/json" \
  -d "${PATCH}" \
  -w "\nHTTP %{http_code}\n"
```

### Step 4 — Test the new CEO via heartbeat

```bash
PAPERCLIP_BIN=/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin/paperclipai

# Create a test issue
"${PAPERCLIP_BIN}" issue create \
  -C "${COMPANY_ID}" \
  --title "S4 process adapter smoke" \
  --description "Post a comment saying 'Process adapter CEO is working' and mark this done." \
  --priority high \
  --json | tee /tmp/s4-smoke.json

ISSUE_ID=$(jq -r '.id' /tmp/s4-smoke.json)
"${PAPERCLIP_BIN}" issue update "${ISSUE_ID}" --status todo --json

# Run heartbeat via Paperclip (not standalone — this tests the full adapter)
"${PAPERCLIP_BIN}" heartbeat run \
  --agent-id "${NEW_CEO_ID}" \
  --api-base http://localhost:3125 \
  --api-key "${BOARD_KEY}" \
  --timeout-ms 300000 \
  2>&1 | tee /tmp/s4-hb.txt

sleep 30

# Check result
"${PAPERCLIP_BIN}" issue get "${ISSUE_ID}" --json 2>&1 | python3 -c "
import json, sys
txt = sys.stdin.read()
data = json.loads(txt[txt.find('{'):])
print(f'Status: {data.get(\"status\")}')
for c in data.get('comments', []):
    print(f'Comment: {c.get(\"body\", \"\")[:200]}')
"
```

Expected: issue has a CEO comment and status is `done`.

### Step 5 — Update backup cron, sync script, plugin config

All references to the old CEO ID need to be updated to the new process adapter CEO ID:

- `~/Library/LaunchAgents/ai.foreman.ceo-heartbeat-backup.plist`
- `scripts/sync-gateway-token.sh` (can be removed — process adapter doesn't use OpenClaw gateway token)
- `~/.openclaw/foreman.json5` plugin config `paperclipAgentId`
- Foreman DB agents table

### Step 6 — Commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
git add -A
git commit -m "feat(ceo): switch CEO to process adapter with DeepSeek planner

New Paperclip agent with adapterType=process running
scripts/ceo-heartbeat.js. DeepSeek V3.1 plans, executor code acts.
Old OpenClaw gateway CEO disabled.

Spec: docs/specs/ceo-planner-executor-split.md"
```

### Stop conditions
- Step 1: agent creation fails → report error
- Step 4: heartbeat doesn't spawn the process → check process adapter config
- Step 4: process spawns but DeepSeek call fails → check env vars in adapterConfig

### Report
- New CEO Paperclip agent ID
- Step 4 heartbeat result
- Issue state after heartbeat
- Commit hash

---

## S5 — Migrate workspace files + heartbeat config

**Goal:** Ensure the new process adapter CEO has all the same operational config as the old one: workspace files accessible, heartbeat schedule, budget, backup cron.

**Active prompt:**

### Step 1 — Verify workspace files are accessible

The process adapter sets `cwd` to `/Users/jonathanborgia/foreman-git/foreman-v2`. The script reads workspace files from `config/ceo-workspace/` relative to `cwd`. Verify:

```bash
ls -la /Users/jonathanborgia/foreman-git/foreman-v2/config/ceo-workspace/
```

Should contain: SOUL.md, HEARTBEAT.md, AGENTS.md, USER.md, IDENTITY.md.

### Step 2 — Update HEARTBEAT.md for the process adapter model

The current HEARTBEAT.md has steps like "call GET /api/agents/me" — but now the script does that automatically. Update HEARTBEAT.md to focus on strategic decision-making rather than API mechanics:

```markdown
# CEO Heartbeat Checklist

You are the strategic planner. On each heartbeat, analyze the situation
and output a JSON plan. The executor will handle all API calls.

## Step 1: Assess current state
- Review assigned issues (provided in context)
- Identify stuck issues (in_progress with no recent activity)
- Identify blocked issues and whether blockers are resolved

## Step 2: Prioritize
- Work highest-priority actionable issues first
- If multiple issues: plan actions for the most important 2-3

## Step 3: Decide actions
For each issue, decide:
- Can I complete it? → plan checkout + comment with result + update to done
- Does it need delegation? → plan create_issue for sub-tasks
- Is it blocked? → plan comment explaining the block
- Does it need a new agent? → plan hire_agent with the appropriate role

## Step 4: Check for proactive work
- Any unassigned issues that should be claimed?
- Any opportunities to create useful sub-tasks?
- Any escalations needed for board attention?

## Output format
Respond with ONLY a JSON object:
{
  "reasoning": "Brief assessment of what you found and decided",
  "actions": [
    { "type": "...", ... }
  ]
}
```

Copy updated file to repo and to Paperclip's workspace (if process adapter uses a different workspace dir).

### Step 3 — Update backup cron

```bash
NEW_CEO_ID="<new process adapter CEO ID>"

launchctl bootout gui/$(id -u)/ai.foreman.ceo-heartbeat-backup 2>/dev/null || true

cat > ~/Library/LaunchAgents/ai.foreman.ceo-heartbeat-backup.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>ai.foreman.ceo-heartbeat-backup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>BOARD_KEY=\$(grep '^PAPERCLIP_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-) &amp;&amp; /Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin/paperclipai heartbeat run --agent-id ${NEW_CEO_ID} --api-base http://localhost:3125 --api-key "\$BOARD_KEY" --timeout-ms 300000 >> /Users/jonathanborgia/.foreman/logs/ceo-heartbeat-backup.log 2>&1</string>
    </array>
    <key>StartInterval</key>
    <integer>1800</integer>
    <key>RunAtLoad</key>
    <false/>
    <key>StandardErrorPath</key>
    <string>/Users/jonathanborgia/.foreman/logs/ceo-heartbeat-backup-err.log</string>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/ai.foreman.ceo-heartbeat-backup.plist
```

Note: `--timeout-ms 300000` (5 minutes) instead of the old 25 minutes — the process adapter is much faster because it's a single OpenRouter API call + API execution, not a long interactive OpenClaw session.

### Step 4 — Commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
git add config/ceo-workspace/HEARTBEAT.md
git commit -m "chore: migrate CEO config to process adapter model

Updated HEARTBEAT.md for planner/executor model (strategic decisions
only, executor handles API calls). Backup cron updated with new CEO ID
and 5-minute timeout.

Spec: docs/specs/ceo-planner-executor-split.md"
```

### Report
- Workspace files accessible at cwd/config/ceo-workspace/
- HEARTBEAT.md updated
- Backup cron updated with new CEO ID
- Commit hash

---

## S6 — Smoke test: full planner/executor cycle

**Goal:** Verify the full autonomous loop works: Paperclip heartbeat fires → process adapter spawns ceo-heartbeat.js → DeepSeek plans → executor acts → issue updated.

**Active prompt:**

### Step 1 — Create a multi-action workload

```bash
PAPERCLIP_BIN=/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin/paperclipai
COMPANY_ID=5d1780c4-7574-4632-a97d-a9917b1f2fc0

# Task 1: simple completion
"${PAPERCLIP_BIN}" issue create -C "${COMPANY_ID}" \
  --title "S6 Task 1: Write a mission statement" \
  --description "Write a 2-sentence mission statement for Foreman. Post as a comment and mark done." \
  --priority high --json

# Task 2: delegation/sub-task creation
"${PAPERCLIP_BIN}" issue create -C "${COMPANY_ID}" \
  --title "S6 Task 2: Plan GTM strategy" \
  --description "Break this into 3 concrete sub-tasks for the marketing team. Create each as a new issue." \
  --priority medium --json

# Task 3: hiring
"${PAPERCLIP_BIN}" issue create -C "${COMPANY_ID}" \
  --title "S6 Task 3: Hire a marketing analyst" \
  --description "Use the hire_agent tool to provision a marketing analyst for this workspace." \
  --priority low --json
```

Set all to `todo`.

### Step 2 — Run heartbeat and observe

```bash
NEW_CEO_ID="<process adapter CEO ID>"
BOARD_KEY="$(grep '^PAPERCLIP_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-)"

"${PAPERCLIP_BIN}" heartbeat run \
  --agent-id "${NEW_CEO_ID}" \
  --api-base http://localhost:3125 \
  --api-key "${BOARD_KEY}" \
  --timeout-ms 300000 \
  2>&1 | tee /tmp/s6-hb.txt
```

### Step 3 — Verify results

```bash
# Check all S6 issues
"${PAPERCLIP_BIN}" issue list -C "${COMPANY_ID}" --json 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
issues = data if isinstance(data, list) else data.get('issues', data.get('data', [data]))
for i in issues:
    if 'S6' in i.get('title', ''):
        print(f'{i[\"title\"]}: {i[\"status\"]}')
"

# Check for new sub-tasks created by Task 2
"${PAPERCLIP_BIN}" issue list -C "${COMPANY_ID}" --json 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
issues = data if isinstance(data, list) else data.get('issues', data.get('data', [data]))
for i in issues:
    if 'GTM' in i.get('title', '') or 'marketing' in i.get('title', '').lower():
        print(f'  Sub-task: {i[\"title\"]} ({i[\"status\"]})')
"

# Check agent list for new marketing analyst
curl -sS "http://localhost:3125/companies/${COMPANY_ID}/agents" \
  -H "Authorization: Bearer ${BOARD_KEY}" 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
agents = data if isinstance(data, list) else data.get('agents', data.get('data', [data]))
for a in agents:
    gw = a.get('adapterConfig', {}).get('gatewayUrl', '')
    cmd = a.get('adapterConfig', {}).get('command', '')
    if gw or cmd:
        print(f'{a[\"id\"][:12]}: {a[\"name\"]} (active)')
"
```

### Step 4 — Checklist

- [ ] Task 1 moved to `done` with a comment containing the mission statement
- [ ] Task 2 resulted in sub-tasks being created
- [ ] Task 3 triggered a `hire_agent` action (check Foreman backend logs)
- [ ] CEO's stdout output is valid JSON with execution results
- [ ] No errors in stderr

### Step 5 — Commit results doc

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
# Write results to docs
git add docs/
git commit -m "test(ceo): S6 planner/executor smoke results

Full autonomous cycle verified: heartbeat → DeepSeek plan → executor
actions → Paperclip issues updated.

Spec: docs/specs/ceo-planner-executor-split.md"
```

### Stop conditions
- Step 2: heartbeat fails to spawn process → check adapter config
- Step 2: DeepSeek returns non-JSON → adjust system prompt
- Step 3: no issues updated → executor failed; check stderr in heartbeat output

### Report
- Heartbeat stdout (the JSON output from ceo-heartbeat.js)
- Issue states after heartbeat
- Sub-tasks created (if any)
- New agents (if any)
- Checklist results
- Commit hash

---

## S7 — Wire token metering for process adapter CEO

**Goal:** The process adapter calls OpenRouter directly (not through OpenClaw), so the `foreman-token-meter` plugin won't capture its usage. Add metering directly to `ceo-heartbeat.js`.

**Active prompt:**

### Step 1 — Add cost reporting to ceo-heartbeat.js

After the OpenRouter call returns, the script has `data.usage` with token counts. Post a cost event to Paperclip:

```javascript
// After the OpenRouter call
const usage = data.usage;
const costCents = calculateCost(usage.prompt_tokens, usage.completion_tokens, model);

await fetch(`${PAPERCLIP_API_URL}/api/companies/${PAPERCLIP_COMPANY_ID}/cost-events`, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${PAPERCLIP_API_KEY}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    agentId: PAPERCLIP_AGENT_ID,
    provider: 'openrouter',
    model: model,
    inputTokens: usage.prompt_tokens,
    outputTokens: usage.completion_tokens,
    costCents,
    occurredAt: new Date().toISOString(),
  }),
});
```

Add a `calculateCost` function based on OpenRouter's model pricing (DeepSeek V3.1 pricing from our config).

### Step 2 — Also update Foreman DB

```javascript
await fetch(`${FOREMAN_API_BASE}/api/internal/agents/${PAPERCLIP_AGENT_ID}/usage`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    inputTokens: usage.prompt_tokens,
    outputTokens: usage.completion_tokens,
    costCents,
    model,
    occurredAt: new Date().toISOString(),
    provider: 'openrouter',
  }),
});
```

Both POSTs should be fire-and-forget (don't fail the heartbeat if metering fails).

### Step 3 — Test

Run a heartbeat, then check:
```bash
curl -sS "http://localhost:3125/api/companies/${COMPANY_ID}/costs/summary" \
  -H "Authorization: Bearer ${BOARD_KEY}" | python3 -m json.tool
```

`spendCents` should increase.

### Step 4 — Commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
git add scripts/ceo-heartbeat.js
git commit -m "feat(metering): add cost reporting to process adapter CEO

ceo-heartbeat.js now POSTs cost events to Paperclip after each
OpenRouter call. Also updates Foreman DB usage counters.
Both are fire-and-forget (metering failure doesn't block heartbeat).

Spec: docs/specs/ceo-planner-executor-split.md"
```

### Report
- Cost reporting added
- Pre/post spendCents
- Commit hash

---

## S8 — Cleanup old OpenClaw CEO + update docs

**Goal:** Remove the old OpenClaw CEO registration, clean up stale config references, update all docs to reflect the new architecture.

**Active prompt:**

### Step 1 — Delete old OpenClaw agent

```bash
openclaw agents delete foreman-foreman-ceo --force 2>&1
rm -rf ~/.openclaw/workspace-foreman-foreman-ceo 2>/dev/null
```

### Step 2 — Clean up sync script

The `scripts/sync-gateway-token.sh` synced the OpenClaw gateway token to the Paperclip CEO agent. The process adapter CEO doesn't use OpenClaw, so this script is no longer needed for the CEO. However, worker agents (like marketing_analyst) may still use OpenClaw and need token sync. Update the script to only sync worker agents, not the CEO:

```bash
# Update sync script to skip the CEO
# Or if there are no OpenClaw worker agents yet, just leave it as-is
# and document that it's only needed for OpenClaw-based agents
```

### Step 3 — Update launch-readiness.md

Update `docs/launch-readiness.md` to reflect the new architecture:

```markdown
## Architecture
- CEO: Paperclip process adapter → DeepSeek V3.1 via OpenRouter (plans) → Node.js executor (acts)
- Workers: Paperclip OpenClaw gateway adapter → Qwen 2.5 72B via OpenRouter (tool execution)
- Token metering: CEO reports directly to Paperclip; workers via foreman-token-meter plugin
```

### Step 4 — Update foreman.json5

Remove or update the `paperclipAgentId` in the token-meter plugin config — it no longer needs to track the CEO (the CEO meters itself). If worker agents exist, point it at them.

### Step 5 — Commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
git add -A
git commit -m "chore: cleanup old OpenClaw CEO + update docs for planner/executor architecture

Deleted old OpenClaw foreman-foreman-ceo agent and workspace.
Updated launch-readiness and architecture docs.
Sync script retained for future OpenClaw worker agents.

Spec: docs/specs/ceo-planner-executor-split.md"
```

### Report
- Old OpenClaw agent deleted
- Docs updated
- Commit hash

---

## What comes after S8

With the CEO planner/executor working, the next workstreams are:

1. **Worker agents on OpenClaw + Qwen** — provision Qwen-powered workers that receive delegated tasks from the CEO and execute them with tool calls. This is where the OpenClaw gateway adapter and `foreman-token-meter` plugin continue to matter.

2. **Multi-turn planning** — if an issue is complex, the CEO may need multiple heartbeats to decompose it. Add state tracking so the CEO remembers what it planned in previous cycles.

3. **Plan validation** — before the executor runs, validate the plan against business rules (e.g., don't hire agents if budget is exhausted, don't create duplicate sub-tasks).

4. **Customer dashboard** — now that the CEO produces structured JSON plans, the dashboard can show what the CEO planned and what it executed, with clear audit trail.
