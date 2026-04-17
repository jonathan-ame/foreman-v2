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

```text
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
