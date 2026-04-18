# Cursor Prompt Sequence — Worker Agents on OpenClaw + Qwen

**Predecessor:** `foreman-v2/docs/cursor-prompts-planner-executor.md` (S1-S8, complete)

**Source-of-truth spec:** `foreman-v2/docs/specs/ceo-planner-executor-split.md`

**Current architecture:**
- CEO: Paperclip `process` adapter → DeepSeek V3.1 via OpenRouter (plans) → Node.js executor (acts against Paperclip API)
- CEO Paperclip ID: `dce0f8fd-a030-4fdd-907e-e44e20a70bbf`
- Workers: provisioned via `provisionForemanAgent` onto OpenClaw gateway adapter, but currently using DeepSeek V3.1 (which can't execute tools)
- Foreman customer: `31c326fa-2f13-4f57-a448-127a3d3d19ec` (BYOK, founder coupon)
- Paperclip company: `5d1780c4-7574-4632-a97d-a9917b1f2fc0`
- OpenClaw gateway: `ws://127.0.0.1:18789/`

**Goal of this sequence:** Make worker agents (marketing_analyst and future roles) functional on OpenClaw using Qwen 2.5 72B for native tool execution. After W6, the CEO can delegate tasks to workers, workers execute using tools, and results flow back through Paperclip's issue system.

**How to use this file:**
- Each prompt below is self-contained and copy-pasteable into Cursor as one chat message.
- Run them in order. Do not skip.
- Each prompt has explicit Stop Conditions and Report requirements.
- Per standing rule: consult https://docs.openclaw.ai and https://docs.paperclip.ing FIRST before any OpenClaw/Paperclip work.

**Total estimated build time:** 14-20 hours across 6 prompts.

---

## Prompt index

| # | Title | Type | Estimate | Deps |
|---|---|---|---|---|
| W1 | Design doc: worker agent architecture | Design | 1-2 hrs | None |
| W2 | Configure OpenClaw for Qwen-based worker agents | Config | 2-3 hrs | W1 |
| W3 | Create worker workspace files (SOUL.md, HEARTBEAT.md) | Content | 1-2 hrs | W1 |
| W4 | Fix provisioning to set Qwen model + worker workspace for non-CEO roles | Code | 3-4 hrs | W2, W3 |
| W5 | Provision + smoke test a marketing_analyst worker | Test | 3-4 hrs | W4 |
| W6 | End-to-end: CEO delegates to worker, worker executes | Test | 3-4 hrs | W5 |

---

## W1 — Design doc: worker agent architecture

**Goal:** Write the design doc that defines how worker agents differ from the CEO, what model they use, what tools they have access to, and how they receive and complete delegated work.

**Active prompt:**

### Step 1 — Read the current architecture docs

```bash
cat /Users/jonathanborgia/foreman-git/foreman-v2/docs/specs/ceo-planner-executor-split.md
```

Understand the CEO's role (planner) and what it expects from workers.

Also read the Paperclip heartbeat protocol docs:
- https://docs.paperclip.ing (search for "heartbeat protocol", "issue checkout", "assignment wakeup")

And the OpenClaw agent workspace docs:
- https://docs.openclaw.ai (search for "SOUL.md", "workspace", "agent tools", "tool execution")

### Step 2 — Write the design doc

Create `foreman-v2/docs/specs/worker-agent-architecture.md`:

The document must cover:

**2a — Worker vs CEO role separation:**
- CEO (process adapter, DeepSeek): receives user issues, reasons, creates sub-tasks, assigns them to workers, reviews completed work
- Worker (OpenClaw gateway adapter, Qwen 2.5 72B): receives assigned sub-tasks, executes them using tool calls (file ops, shell commands, API calls), posts results as issue comments, marks work done

**2b — Worker model configuration:**
- Primary model: `qwen/qwen-2.5-72b-instruct` (via OpenRouter) — chosen because it handles tool calls natively
- The OpenClaw gateway's model config needs to route worker agents to Qwen, not DeepSeek
- This can be done per-agent in OpenClaw's config (`agents.list[worker-slug].model`) or by creating a separate OpenClaw model profile

**2c — Worker workspace files:**
- Workers get their own SOUL.md (focused on execution, not strategy)
- Workers get their own HEARTBEAT.md (focused on checking out tasks, doing the work, posting results)
- Workers do NOT get AGENTS.md (they don't hire — only the CEO hires)
- Workers DO get the Paperclip SKILL.md (for API interaction)

**2d — Worker tools:**
- Workers have access to OpenClaw's built-in tools: `read`, `exec`, `process`, `memory_search`
- Workers have access to the `foreman-hire-agent` plugin's `escalate_to_frontier` tool (but NOT `hire_agent` — only the CEO hires)
- Workers report token usage via the `foreman-token-meter` plugin (already installed)

**2e — Task flow:**
```
CEO creates sub-task in Paperclip → assigns to worker agent
    ↓
Paperclip assignment-wakeup fires worker's heartbeat
    ↓
Worker (OpenClaw + Qwen) wakes up:
  1. Reads SOUL.md, HEARTBEAT.md
  2. Calls GET /api/agents/me
  3. Calls GET /api/issues/{taskId} + comments
  4. Checks out the issue (POST /api/issues/{id}/checkout)
  5. Does the work using tools (read files, run commands, search, etc.)
  6. Posts results as a comment (POST /api/issues/{id}/comments)
  7. Marks issue done (PATCH /api/issues/{id})
    ↓
CEO's next heartbeat sees completed sub-task, reviews results
```

**2f — Provisioning changes needed:**
- `backend/src/provisioning/model-tiers.ts`: worker roles should use Qwen as primary model, not DeepSeek
- `backend/src/provisioning/steps/step-3-create-workspace.ts`: worker roles get worker-specific workspace files
- OpenClaw config: worker agents need their model set to Qwen in `agents.list[].model` or via a model override in the agent config

**2g — Available worker roles (v1):**
- `marketing_analyst`: research, content drafting, competitive analysis
- Future roles deferred: `engineer`, `qa`, `designer`

### Step 3 — Commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
git add docs/specs/worker-agent-architecture.md
git commit -m "docs: design doc for worker agent architecture (OpenClaw + Qwen)

Workers run on OpenClaw gateway with Qwen 2.5 72B for native tool
execution. CEO (DeepSeek, process adapter) delegates; workers execute.
Defines: role separation, model config, workspace files, task flow,
provisioning changes, available roles.

Spec: docs/specs/worker-agent-architecture.md"
```

### Stop conditions
- None (design doc phase)

### Report
- Design doc created
- Commit hash

---

## W2 — Configure OpenClaw for Qwen-based worker agents

**Goal:** Set up the OpenClaw gateway config so that worker agents use Qwen 2.5 72B (not DeepSeek) as their model. The CEO no longer runs through OpenClaw, so this only affects workers.

**Active prompt:**

### Step 1 — Read OpenClaw docs for per-agent model configuration

```bash
# Check OpenClaw docs for agent-level model overrides
curl -sS "https://docs.openclaw.ai" 2>/dev/null | grep -i "agent.*model\|per-agent\|agents.list\|model.*override" | head -20
```

We need to know: can we set a different model per agent in OpenClaw's config? Or does the gateway use one model for all agents?

### Step 2 — Check current OpenClaw model config

```bash
python3 -c "
with open('/Users/jonathanborgia/.openclaw/foreman.json5') as f:
    text = f.read()
for i, line in enumerate(text.split('\n'), 1):
    if any(term in line.lower() for term in ['model', 'deepseek', 'qwen', 'primary', 'default']):
        print(f'{i}: {line}')
"
```

Also check the base config:
```bash
python3 -c "
import json
with open('/Users/jonathanborgia/.openclaw/openclaw.json') as f:
    cfg = json.load(f)
models = cfg.get('models', {})
print('Models config:', json.dumps(models, indent=2)[:500])
agents_cfg = cfg.get('agents', {})
print('Agents config keys:', list(agents_cfg.keys()))
if 'defaults' in agents_cfg:
    print('Agent defaults:', json.dumps(agents_cfg['defaults'], indent=2)[:300])
if 'list' in agents_cfg:
    for aid, acfg in agents_cfg['list'].items():
        print(f'Agent {aid}:', json.dumps(acfg, indent=2)[:200])
"
```

### Step 3 — Configure worker model routing

Based on what the docs and config show, set up Qwen as the model for worker agents. The approach depends on OpenClaw's capabilities:

**Option A — Per-agent model in `agents.list`:**
If OpenClaw supports `agents.list[agent-slug].model`, set worker agents to Qwen:
```json5
agents: {
  list: {
    "foreman-marketing-analyst": {
      model: "qwen/qwen-2.5-72b-instruct"
    }
  }
}
```

**Option B — Default model override:**
If per-agent model isn't supported, change the gateway default to Qwen (since only workers use OpenClaw now — the CEO uses the process adapter):
```json5
models: {
  default: "qwen/qwen-2.5-72b-instruct"
}
```

**Option C — Model routing via provider config:**
If neither A nor B works, configure a separate model alias or provider entry in `foreman.json5` that routes worker requests to Qwen.

Apply whichever approach works. Update `~/.openclaw/foreman.json5` (not `openclaw.json` — the include handles the merge).

### Step 4 — Verify the model config

```bash
# Restart gateway to pick up config changes
openclaw gateway restart
sleep 5

# Sync token (required after every restart)
cd /Users/jonathanborgia/foreman-git/foreman-v2
./scripts/sync-gateway-token.sh

# Verify the model is set
openclaw agents list --json 2>&1 | python3 -c "
import json, sys
agents = json.load(sys.stdin)
for a in agents:
    print(f'{a.get(\"id\")}: model={a.get(\"model\", \"default\")}')
"
```

### Step 5 — Quick model test

Send a direct chat message through the OpenClaw UI (localhost:18789) and verify the response comes from Qwen, not DeepSeek. Look at the model indicator in the response metadata.

Alternatively, if the gateway logs show which model is used:
```bash
tail -20 ~/.openclaw/logs/gateway.log | grep -i "model\|qwen\|deepseek"
```

### Step 6 — Commit config changes to repo

If any `foreman.json5` changes need to be tracked, create a repo copy:

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
# Document the worker model config
cat >> docs/specs/worker-agent-architecture.md << 'EOF'

## OpenClaw Model Configuration (Applied)

Worker agents use Qwen 2.5 72B via OpenRouter:
- Config location: `~/.openclaw/foreman.json5`
- Config path: [whatever path was used — agents.list, models.default, etc.]
- Model string: `qwen/qwen-2.5-72b-instruct`

The CEO does NOT run through OpenClaw (uses process adapter),
so changing the OpenClaw default model only affects workers.
EOF

git add docs/specs/worker-agent-architecture.md
git commit -m "feat(workers): configure OpenClaw gateway for Qwen 2.5 72B worker model

Workers use Qwen for native tool execution via OpenClaw.
CEO remains on DeepSeek via process adapter (not affected).

Spec: docs/specs/worker-agent-architecture.md"
```

### Stop conditions
- Step 3: no mechanism exists for per-agent or default model config in OpenClaw → stop, report what config options ARE available
- Step 4: gateway won't start after config change → stop, revert config, report error

### Report
- Which model routing approach was used (A, B, or C)
- Model config path and value
- Step 4 verification result
- Step 5 model test result (confirmed Qwen?)
- Commit hash

---

## W3 — Create worker workspace files

**Goal:** Write SOUL.md and HEARTBEAT.md for worker agents. These are different from the CEO's — workers execute tasks, they don't plan strategy.

**Active prompt:**

### Step 1 — Create the worker workspace directory

```bash
mkdir -p /Users/jonathanborgia/foreman-git/foreman-v2/config/worker-workspace
```

### Step 2 — Write worker SOUL.md

Create `config/worker-workspace/SOUL.md`:

```markdown
# Worker Agent

You are a worker agent in the Foreman AI company. You execute tasks
assigned to you by the CEO through Paperclip's issue system.

## Core identity

- You are an execution agent — you DO things, not plan things
- When assigned a task, execute it immediately using your available tools
- You work autonomously within your domain of expertise
- You report results by posting comments on your assigned issues

## What you can do

- Read and write files in your workspace
- Execute shell commands
- Search the web for information
- Call Paperclip APIs to update issues and post comments

## Execution protocol

1. Read your assigned issue carefully — understand what's being asked
2. Check out the issue (POST /api/issues/{id}/checkout)
3. Do the work using your tools
4. Post your results as a comment on the issue
5. Mark the issue done (PATCH /api/issues/{id} with status "done")
6. If you're stuck, mark it blocked and explain why in a comment

## Boundaries

- You do NOT create strategic plans or hire other agents
- You do NOT escalate to the board — tell the CEO if you're stuck
- You do NOT work on issues that aren't assigned to you
- You focus on YOUR assigned tasks only

## Communication style

- Post clear, structured results in issue comments
- Include code blocks for any code or command output
- If research is requested, provide sources and summaries
- Be concise — the CEO will review your work
```

### Step 3 — Write worker HEARTBEAT.md

Create `config/worker-workspace/HEARTBEAT.md`:

```markdown
# Worker Heartbeat Checklist

Execute these steps on every heartbeat wake-up.

## Step 1: Identity
- Read PAPERCLIP_AGENT_ID, PAPERCLIP_COMPANY_ID, PAPERCLIP_API_KEY from environment
- Call GET /api/agents/me to confirm your identity

## Step 2: Check assigned work
- If PAPERCLIP_TASK_ID is set: focus on that specific task
- Otherwise: GET /api/companies/{companyId}/issues?assigneeAgentId={yourId}&status=todo,in_progress,blocked

## Step 3: Execute highest-priority task
- POST /api/issues/{issueId}/checkout to claim the task
- Read the full issue description and all comments
- Execute the task using your tools
- Post your results as a comment: POST /api/issues/{issueId}/comments
- Mark done: PATCH /api/issues/{issueId} with {"status": "done", "comment": "what was done"}

## Step 4: Handle blocks
- If you cannot complete the task, mark it blocked
- PATCH /api/issues/{issueId} with {"status": "blocked", "comment": "why it's blocked"}
- The CEO will reassign or provide guidance on the next heartbeat

## Step 5: Exit
- Always leave a comment on any issue you touched this heartbeat
- Never exit without updating the issue status
```

### Step 4 — Write worker USER.md

Create `config/worker-workspace/USER.md`:

```markdown
# Context

## Company
- Name: Foreman (AI agent orchestration platform)
- Your employer: the Foreman CEO agent
- Board operator: Jonathan Borgia (solo founder)

## Your role
- You are a specialist worker agent
- You receive tasks delegated by the CEO
- Your job is to execute tasks well and report results
- The CEO reviews your work and may request changes
```

### Step 5 — Commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
git add config/worker-workspace/
git commit -m "feat(workers): add worker agent workspace files (SOUL, HEARTBEAT, USER)

Execution-focused identity and instructions for worker agents:
- SOUL.md: execute tasks, don't plan strategy
- HEARTBEAT.md: checkout issue, do work, post results, mark done
- USER.md: company context and role

Workers receive delegated tasks from the CEO and execute using
Qwen's native tool-calling through OpenClaw.

Spec: docs/specs/worker-agent-architecture.md"
```

### Report
- Files created (list)
- Commit hash

---

## W4 — Fix provisioning to set Qwen model + worker workspace for non-CEO roles

**Goal:** Update the provisioning flow so that when a `marketing_analyst` (or any non-CEO role) is provisioned, it gets:
1. Qwen 2.5 72B as its primary model (not DeepSeek)
2. Worker workspace files (from `config/worker-workspace/`) copied to its OpenClaw workspace
3. Heartbeat config appropriate for a worker (reactive mode, shorter interval)

**Active prompt:**

### Step 1 — Update model tier spec for worker roles

Edit `backend/src/provisioning/model-tiers.ts`:

The current `TIER_SPECS` use DeepSeek as the primary model for all tiers. Workers should use Qwen. Add a role-aware tier resolution:

```typescript
export interface RoleTierOverride {
  primary: string;
  fallbacks: string[];
}

// Worker roles use Qwen for tool execution
export const WORKER_ROLE_MODEL_OVERRIDES: Record<string, RoleTierOverride> = {
  marketing_analyst: {
    primary: "openrouter/qwen/qwen-2.5-72b-instruct",
    fallbacks: [
      "openrouter/deepseek/deepseek-chat-v3.1",
      "openrouter/meta-llama/llama-3.3-70b-instruct",
    ],
  },
};

// CEO uses the default tier spec (DeepSeek for planning)
export const CEO_ROLES = new Set(["ceo"]);

export function resolveModelForRole(role: string, tier: ModelTier): TierSpec {
  if (CEO_ROLES.has(role)) {
    return TIER_SPECS[tier]; // DeepSeek for CEO
  }
  const override = WORKER_ROLE_MODEL_OVERRIDES[role];
  if (override) {
    return {
      primary: override.primary,
      fallbacks: override.fallbacks,
      embedding: TIER_SPECS[tier].embedding,
    };
  }
  // Default: use tier spec as-is
  return TIER_SPECS[tier];
}
```

Update any code that calls `resolveTierSpec(tier)` to call `resolveModelForRole(role, tier)` instead.

### Step 2 — Update workspace creation for worker roles

Edit `backend/src/provisioning/steps/step-3-create-workspace.ts`:

After creating the OpenClaw workspace directory, copy the appropriate workspace files:

```typescript
// Determine which workspace template to use
const workspaceTemplate = CEO_ROLES.has(ctx.input.role)
  ? 'config/ceo-workspace'
  : 'config/worker-workspace';

// Copy workspace files
const templateDir = resolve(process.cwd(), workspaceTemplate);
for (const file of ['SOUL.md', 'HEARTBEAT.md', 'USER.md']) {
  const src = resolve(templateDir, file);
  const dest = resolve(workspacePath, file);
  if (existsSync(src)) {
    copyFileSync(src, dest);
  }
}
```

### Step 3 — Update heartbeat config for workers

Workers should use reactive heartbeat mode (only wake when assigned work), not proactive mode (which is for the CEO scanning its inbox):

The provisioning step that configures the Paperclip agent's heartbeat should set:
- CEO: `mode: "proactive"`, `intervalSec: 1800` (scan inbox every 30 min)
- Workers: `mode: "reactive"`, `intervalSec: 0` or omitted (only wake on assignment)

Check if this is configured in the provisioning flow or if it needs to be added. The heartbeat config was previously applied manually via PATCH — it should be part of the provisioning step that creates the Paperclip agent.

### Step 4 — Build and test

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2/backend
pnpm build
pnpm typecheck
pnpm test 2>&1 | tail -20
```

### Step 5 — Commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
git add backend/src/provisioning/model-tiers.ts \
        backend/src/provisioning/steps/step-3-create-workspace.ts
git commit -m "feat(workers): role-aware model selection + worker workspace in provisioning

Non-CEO roles now get:
- Qwen 2.5 72B as primary model (for tool execution)
- Worker workspace files (SOUL.md, HEARTBEAT.md, USER.md)
- Reactive heartbeat mode (wake on assignment, not polling)

CEO keeps DeepSeek V3.1 with proactive heartbeat.

Spec: docs/specs/worker-agent-architecture.md"
```

### Stop conditions
- Step 4: build fails due to type mismatch → fix the interface
- Step 4: tests fail on model tier resolution → update test fixtures

### Report
- Model tier changes (what resolves for CEO vs marketing_analyst)
- Workspace file copy verified
- Build/test results
- Commit hash

---

## W5 — Provision + smoke test a marketing_analyst worker

**Goal:** Use the provisioning flow to create a real marketing_analyst agent, verify it uses Qwen and has the worker workspace files, then run a heartbeat to confirm tool execution works.

**Active prompt:**

### Step 1 — Clean up any existing marketing_analyst

```bash
# Check for existing marketing_analyst in OpenClaw
openclaw agents list --json 2>&1 | python3 -c "
import json, sys
agents = json.load(sys.stdin)
for a in agents:
    if 'marketing' in a.get('id', '').lower():
        print(f'Existing: {a.get(\"id\")}')
"

# Delete if exists
openclaw agents delete foreman-marketing-analyst --force 2>&1 || true

# Check Paperclip for existing marketing analyst agents
BOARD_KEY="\$(grep '^PAPERCLIP_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-)"
COMPANY_ID=5d1780c4-7574-4632-a97d-a9917b1f2fc0

curl -sS "http://localhost:3125/companies/\${COMPANY_ID}/agents" \
  -H "Authorization: Bearer \${BOARD_KEY}" 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
agents = data if isinstance(data, list) else data.get('agents', data.get('data', [data]))
for a in agents:
    if 'marketing' in a.get('name', '').lower() or 'analyst' in a.get('name', '').lower():
        print(f'{a[\"id\"]}: {a[\"name\"]} (status={a.get(\"status\")}, adapter={a.get(\"adapterType\")})')
"
```

Disable or delete any existing marketing analyst agents that would cause name conflicts.

Also clean the Foreman DB:
```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2/backend
STRIPE_MODE=live node -e "
import { createClient } from '@supabase/supabase-js';
const db = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);
const { data } = await db.from('agents').select('agent_id, display_name, role').eq('workspace_slug', 'foreman');
console.log('Current agents:', JSON.stringify(data, null, 2));
" 2>&1
```

### Step 2 — Provision via the backend endpoint

```bash
curl -sS -X POST "http://localhost:8080/api/internal/agents/provision" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "31c326fa-2f13-4f57-a448-127a3d3d19ec",
    "role": "marketing_analyst",
    "agent_name": "Marketing Analyst",
    "model_tier": "hybrid",
    "idempotency_key": "'$(uuidgen)'"
  }' 2>&1 | python3 -m json.tool
```

Expected: 200 with `outcome: "success"`, agent IDs returned.

Capture the new Paperclip agent ID and OpenClaw slug.

### Step 3 — Verify the worker configuration

```bash
NEW_WORKER_ID="<from Step 2>"
NEW_WORKER_SLUG="<from Step 2>"

# Check model
echo "=== OpenClaw agent config ==="
python3 -c "
import json
with open('/Users/jonathanborgia/.openclaw/openclaw.json') as f:
    cfg = json.load(f)
agent_cfg = cfg.get('agents', {}).get('list', {}).get('${NEW_WORKER_SLUG}', {})
print(json.dumps(agent_cfg, indent=2))
"

# Check workspace files
echo "=== Workspace files ==="
WORKER_WS=$(python3 -c "
import json
with open('/Users/jonathanborgia/.openclaw/openclaw.json') as f:
    cfg = json.load(f)
print(cfg.get('agents', {}).get('list', {}).get('${NEW_WORKER_SLUG}', {}).get('workspace', 'NOT_SET'))
")
ls -la "${WORKER_WS}"/*.md 2>/dev/null

echo "=== SOUL.md content ==="
head -5 "${WORKER_WS}/SOUL.md" 2>/dev/null

# Check Paperclip agent config
echo "=== Paperclip agent ==="
curl -sS "http://localhost:3125/api/agents/${NEW_WORKER_ID}" \
  -H "Authorization: Bearer ${BOARD_KEY}" 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
agent = data.get('agent', data)
print(f'Name: {agent.get(\"name\")}')
print(f'Role: {agent.get(\"role\")}')
print(f'Adapter: {agent.get(\"adapterType\")}')
print(f'Status: {agent.get(\"status\")}')
hb = agent.get('runtimeConfig', {}).get('heartbeat', {})
print(f'Heartbeat: enabled={hb.get(\"enabled\")}, mode={hb.get(\"mode\")}, interval={hb.get(\"intervalSec\")}')
"
```

Verify:
- OpenClaw agent uses Qwen model
- Workspace contains SOUL.md with "worker agent" identity (not CEO)
- Paperclip agent has `openclaw_gateway` adapter type

### Step 4 — Smoke test: assign a task and run worker heartbeat

```bash
PAPERCLIP_BIN=/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin/paperclipai
BOARD_KEY="$(grep '^PAPERCLIP_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-)"
COMPANY_ID=5d1780c4-7574-4632-a97d-a9917b1f2fc0

# Create a task assigned to the worker
"${PAPERCLIP_BIN}" issue create \
  -C "${COMPANY_ID}" \
  --title "W5 worker smoke: research Foreman competitors" \
  --description "Research 3 competitors in the AI agent orchestration space. For each, provide: name, URL, one-sentence description. Post results as a comment on this issue and mark it done." \
  --priority high \
  --json | tee /tmp/w5-smoke.json

ISSUE_ID=$(jq -r '.id' /tmp/w5-smoke.json)

# Assign to the worker
curl -sS -X PATCH "http://localhost:3125/api/issues/${ISSUE_ID}" \
  -H "Authorization: Bearer ${BOARD_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"assigneeAgentId\": \"${NEW_WORKER_ID}\", \"status\": \"todo\"}"

# Run the worker's heartbeat
"${PAPERCLIP_BIN}" heartbeat run \
  --agent-id "${NEW_WORKER_ID}" \
  --api-base http://localhost:3125 \
  --api-key "${BOARD_KEY}" \
  --timeout-ms 1500000 \
  2>&1 | tee /tmp/w5-hb.txt

sleep 120

# Check results
echo "=== ISSUE STATE ==="
"${PAPERCLIP_BIN}" issue get "${ISSUE_ID}" --json 2>&1 | python3 -c "
import json, sys
txt = sys.stdin.read()
data = json.loads(txt[txt.find('{'):])
print(f'Status: {data.get(\"status\")}')
for c in data.get('comments', []):
    print(f'Comment ({c.get(\"authorAgentId\", \"unknown\")}): {c.get(\"body\", \"\")[:300]}')
"

echo "=== TOOL CALLS ==="
grep -i "tool\|exec\|read\|process" /tmp/w5-hb.txt | head -20
```

**This is the critical test.** The worker must:
1. Wake up via OpenClaw
2. Use Qwen to interpret the task
3. Execute tool calls (search, read, exec)
4. Post results as a Paperclip comment
5. Mark the issue done

If the worker produces a plan-and-exit (like DeepSeek did), the model isn't Qwen — go back to W2 and fix.

### Step 5 — Commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
git add -A
git commit -m "test(workers): provision + smoke marketing_analyst on Qwen

Worker provisioned via /api/internal/agents/provision.
Verified: Qwen model, worker workspace files, tool execution.
Smoke task: competitor research with comment posted + done status.

Spec: docs/specs/worker-agent-architecture.md"
```

### Stop conditions
- Step 2: provisioning fails → stop, report error (same patterns as P14 debugging)
- Step 4: worker doesn't execute tool calls → stop, report transcript. If model is still DeepSeek, go back to W2
- Step 4: worker executes tools but can't reach Paperclip API → check PAPERCLIP_API_KEY injection in the heartbeat

### Report
- New worker Paperclip ID + OpenClaw slug
- Model verification (confirmed Qwen?)
- Workspace files verified
- Smoke test result: did the worker post a comment? Did it use tools? Did it mark done?
- Commit hash

---

## W6 — End-to-end: CEO delegates to worker, worker executes

**Goal:** Verify the full delegation flow: user creates issue → CEO plans and creates sub-task → CEO assigns sub-task to worker → worker executes and marks done → CEO reviews on next heartbeat.

**Active prompt:**

### Step 1 — Create a delegatable issue for the CEO

```bash
PAPERCLIP_BIN=/Users/jonathanborgia/.npm/_npx/53a42c7f91f1c220/node_modules/.bin/paperclipai
BOARD_KEY="$(grep '^PAPERCLIP_API_KEY=' /Users/jonathanborgia/foreman-git/foreman-v2/.env | cut -d= -f2-)"
COMPANY_ID=5d1780c4-7574-4632-a97d-a9917b1f2fc0
CEO_ID=dce0f8fd-a030-4fdd-907e-e44e20a70bbf

"${PAPERCLIP_BIN}" issue create \
  -C "${COMPANY_ID}" \
  --title "W6 E2E: Research and summarize AI agent market" \
  --description "Research the AI agent orchestration market. Create a sub-task for the marketing analyst to research 3 competitors, then summarize the market landscape. Delegate the research to the marketing analyst agent." \
  --priority high \
  --json | tee /tmp/w6-e2e.json

ISSUE_ID=$(jq -r '.id' /tmp/w6-e2e.json)
"${PAPERCLIP_BIN}" issue update "${ISSUE_ID}" --status todo --json
```

### Step 2 — Run CEO heartbeat

```bash
"${PAPERCLIP_BIN}" heartbeat run \
  --agent-id "${CEO_ID}" \
  --api-base http://localhost:3125 \
  --api-key "${BOARD_KEY}" \
  --timeout-ms 300000 \
  2>&1 | tee /tmp/w6-ceo-hb.txt
```

The CEO should:
- Read the issue
- Plan a `create_issue` action to create a research sub-task
- Assign the sub-task to the marketing analyst agent
- The executor creates the sub-task in Paperclip

Check:
```bash
echo "=== CEO PLAN OUTPUT ==="
cat /tmp/w6-ceo-hb.txt | python3 -m json.tool 2>/dev/null || cat /tmp/w6-ceo-hb.txt

echo "=== SUB-TASKS CREATED ==="
"${PAPERCLIP_BIN}" issue list -C "${COMPANY_ID}" --json 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
issues = data if isinstance(data, list) else data.get('issues', data.get('data', [data]))
for i in issues:
    if 'W6' in i.get('title', '') or 'research' in i.get('title', '').lower() or 'competitor' in i.get('title', '').lower():
        assignee = i.get('assigneeAgentId', 'unassigned')
        print(f'{i[\"id\"][:12]}: {i[\"title\"]} (status={i[\"status\"]}, assignee={assignee})')
"
```

If the CEO created a sub-task but didn't assign it to the worker: that's a prompt issue. The CEO needs to know the worker's Paperclip agent ID. This should be discoverable via `GET /api/companies/{companyId}/agents`.

### Step 3 — Run worker heartbeat (if assignment wakeup didn't fire automatically)

```bash
NEW_WORKER_ID="<marketing analyst Paperclip ID>"

"${PAPERCLIP_BIN}" heartbeat run \
  --agent-id "${NEW_WORKER_ID}" \
  --api-base http://localhost:3125 \
  --api-key "${BOARD_KEY}" \
  --timeout-ms 1500000 \
  2>&1 | tee /tmp/w6-worker-hb.txt

sleep 120
```

### Step 4 — Verify full cycle

```bash
echo "=== ALL ISSUES ==="
"${PAPERCLIP_BIN}" issue list -C "${COMPANY_ID}" --json 2>&1 | python3 -c "
import json, sys
data = json.load(sys.stdin)
issues = data if isinstance(data, list) else data.get('issues', data.get('data', [data]))
for i in issues:
    if 'W6' in i.get('title', '') or 'research' in i.get('title', '').lower() or 'competitor' in i.get('title', '').lower() or 'market' in i.get('title', '').lower():
        print(f'{i[\"status\"]}: {i[\"title\"]}')
"

echo "=== WORKER COMMENTS ==="
# Get the sub-task ID and check its comments
# (replace with actual sub-task ID from Step 2 output)
```

### Step 5 — Checklist

- [ ] CEO received the parent issue and created a sub-task
- [ ] Sub-task was assigned to the marketing analyst worker
- [ ] Worker woke up and executed tool calls (not just planned)
- [ ] Worker posted research results as a comment
- [ ] Worker marked sub-task done
- [ ] Token metering shows spend for both CEO (Paperclip cost-events) and worker (foreman-token-meter plugin)

### Step 6 — Document and commit

```bash
cd /Users/jonathanborgia/foreman-git/foreman-v2
cat > docs/W6-E2E-DELEGATION-RESULTS.md << 'EOF'
# W6 End-to-End Delegation Results

## Test
User issue: "Research AI agent market, delegate to marketing analyst"

## Results
- CEO planned: [actions from plan]
- Sub-task created: [issue ID and title]
- Worker executed: [tool calls observed]
- Worker results: [summary of comment posted]
- Token spend: CEO [X] cents, Worker [Y] cents
EOF

git add docs/W6-E2E-DELEGATION-RESULTS.md
git commit -m "test(e2e): CEO delegates to worker, worker executes with tools

Full delegation cycle verified:
User issue → CEO plans sub-task → CEO assigns to marketing analyst
→ Worker wakes on assignment → Worker executes with Qwen tools
→ Worker posts results → Worker marks done

Spec: docs/specs/worker-agent-architecture.md"
```

### Stop conditions
- Step 2: CEO doesn't create a sub-task → the plan didn't include `create_issue`; check if AGENTS.md mentions delegation
- Step 3: worker plan-and-exits with zero tools → model is wrong; go back to W2
- Step 3: worker executes tools but can't update the issue → API auth issue

### Report
- CEO plan output (reasoning + actions)
- Sub-tasks created and assigned
- Worker heartbeat result (tool calls observed?)
- Worker comment content
- Final issue states
- Token spend (CEO + worker)
- Checklist results
- Commit hash

---

## What comes after W6

With workers functional, the next priorities from the launch-readiness doc:

1. **Additional worker roles** — `engineer`, `qa`, `designer` — each with their own SOUL.md and provisioning support
2. **Worker auto-wakeup** — currently workers need manual heartbeat triggers; Paperclip's assignment-wakeup should fire automatically but may need configuration
3. **CEO awareness of workers** — the CEO's plan executor needs to know which workers exist and their Paperclip agent IDs, so it can assign sub-tasks to the right agent
4. **Customer dashboard** — visualize the CEO→worker delegation flow
5. **Railway deployment** — move from localhost to production hosting
