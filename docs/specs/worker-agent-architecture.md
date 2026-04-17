# Worker Agent Architecture — OpenClaw + Qwen

## Purpose

Define how Foreman worker agents operate under the planner/executor CEO
architecture:

- CEO plans and delegates
- Workers execute assigned tasks with native tool usage

This document is the source for worker model selection, workspace templates,
tool boundaries, and provisioning requirements.

## Worker vs CEO Role Separation

### CEO (process adapter + DeepSeek)

- Adapter: Paperclip `process`
- Model: `deepseek/deepseek-chat-v3-0324` via OpenRouter
- Responsibilities:
  - Read inbox/user work
  - Prioritize and decompose into actions/subtasks
  - Create and assign issues
  - Review completed work
  - Hire new agents when required
- Behavior:
  - Planning-first
  - No OpenClaw tool execution path

### Worker (OpenClaw gateway + Qwen)

- Adapter: Paperclip `openclaw_gateway`
- Model: `qwen/qwen-2.5-72b-instruct` via OpenRouter
- Responsibilities:
  - Receive assigned sub-tasks
  - Execute work using tools
  - Post results to issue comments
  - Mark issues `done` or `blocked`
- Behavior:
  - Execution-first
  - Deterministic task completion flow

## Worker Model Configuration

- Primary worker model: `qwen/qwen-2.5-72b-instruct` (OpenRouter)
- Rationale:
  - Qwen reliably issues native tool calls
  - DeepSeek is retained for CEO strategic planning in process adapter path
- Configuration strategy:
  - Prefer per-agent model selection in OpenClaw `agents.list[slug].model`
  - If unavailable, use OpenClaw worker-facing default routing to Qwen
  - Keep CEO unaffected because CEO no longer uses OpenClaw runtime

## Worker Workspace Files

Workers use a dedicated template at `config/worker-workspace/`.

- Required:
  - `SOUL.md` (execution identity)
  - `HEARTBEAT.md` (issue execution checklist)
  - `USER.md` (company/role context)
- Not required for workers:
  - `AGENTS.md` (hiring/delegation policy; CEO-only concern)
- Shared:
  - Paperclip skill guidance remains available to support API interactions

## Worker Tools and Boundaries

- Expected tool access:
  - `read`
  - `exec`
  - `process`
  - `memory_search`
- Plugin access:
  - `escalate_to_frontier` allowed for exceptional execution needs
  - `hire_agent` denied for workers (CEO-only authority)
- Metering:
  - Worker usage is reported through `foreman-token-meter` plugin

## Task Flow

```text
CEO creates sub-task in Paperclip and assigns to worker
  ->
Paperclip assignment wake-up triggers worker heartbeat
  ->
Worker (OpenClaw + Qwen):
  1) reads workspace instructions
  2) validates identity via /api/agents/me
  3) fetches issue + comments
  4) checks out issue
  5) executes with tools
  6) posts results comment
  7) marks issue done (or blocked with reason)
  ->
CEO observes completion in next heartbeat cycle
```

## Provisioning Changes Required

1. `backend/src/provisioning/model-tiers.ts`
   - Add role-aware model resolution so non-CEO roles use Qwen primary.
2. `backend/src/provisioning/steps/step-3-create-workspace.ts`
   - Copy worker workspace template files for non-CEO roles.
3. OpenClaw config (`~/.openclaw/foreman.json5`)
   - Ensure worker slug(s) are routed to Qwen model profile.
4. Paperclip runtime heartbeat policy
   - CEO: proactive polling cadence
   - Workers: reactive assignment wake-up behavior

## Available Worker Roles (v1)

- `marketing_analyst`
  - Competitive intelligence
  - Content/research drafting
  - GTM analysis support

Deferred roles:

- `engineer`
- `qa`
- `designer`

## OpenClaw Model Configuration (Applied)

Worker agents are routed to Qwen 2.5 72B via OpenRouter.

- Config locations:
  - `~/.openclaw/foreman.json5` (Foreman profile source)
  - `~/.openclaw/openclaw.json` (active gateway runtime config)
- Config path used:
  - `agents.defaults.model.primary`
  - `agents.list[].model` for worker slugs
- Model string:
  - `openrouter/qwen/qwen-2.5-72b-instruct`

Validation results:

- `openclaw agents list --json` reports worker agents on Qwen
- gateway log confirms active model switched to Qwen:
  - `agent model: openrouter/qwen/qwen-2.5-72b-instruct`

The CEO does not run through OpenClaw, so this routing applies to worker
agents only.
