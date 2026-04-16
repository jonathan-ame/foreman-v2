# `provisionForemanAgent` — Scope Document

**Version:** 1.2  
**Date:** 2026-04-15  
**Status:** Draft — pending review before Cursor implementation  
**Owner:** Jonathan Borgia  
**Repo target:** `foreman-v2/docs/specs/provision-foreman-agent.md`

**Changelog from v1.1:**
- v1 launch scope expanded to include `marketing_analyst` sub-agent role
  (added during P11 implementation to exercise the real role-separation
  path for P13 e2e testing). Additional sub-agent roles remain deferred.

---

## Purpose

`provisionForemanAgent` is the orchestration function that creates a fully-wired Foreman agent in a single call. After successful return, the agent is ready to receive heartbeats and execute tasks.

It is the single source of truth for agent creation across all surfaces:
- Foreman web UI during customer onboarding
- CLI script during solo-dev work
- CEO agent's `hire_agent` tool when spawning sub-agents

All three call paths invoke the same Python function. The HTTP wrapper, CLI wrapper, and tool wrapper are thin translations to/from the function's typed interface.

**Implementation principle:** Use native Paperclip and OpenClaw integration surfaces only. No forks, no custom adapters, no bypasses. Where native paths have known limitations (e.g., OpenClaw's config absorption behavior), accept them and add operational maintenance tasks rather than working around them in code. Re-evaluate after the foundation is stable.

---

## v1 launch scope

| Feature | In v1 | Notes |
|---|---|---|
| `provisionForemanAgent` core function (10 steps) | ✅ | Required |
| Foreman-managed key billing mode | ✅ | Required |
| BYOK billing mode | ✅ | Required |
| BYOK fallback to Foreman-managed | ✅ | Global per-customer setting |
| Tier-based billing — 3 tiers ($49 / $99 / $199) | ✅ | All three at launch |
| Usage-based billing with prepaid balance + auto-topup | ✅ | Stripe payment intents |
| Tier upgrade with 5%-per-tier surcharge decrease | ✅ | $49 = +20%, $99 = +15%, $199 = +10% |
| Auto-approve sub-agent hiring | ✅ | Default and only mode in v1 |
| CEO role | ✅ | Only role in v1 |
| Hybrid model tier with 2-rejection escalation | ✅ | Open default → frontier on 3rd attempt |
| Open-only and Frontier-only model tiers | ✅ | Single-provider routing |
| Audit log (file + Supabase) | ✅ | Two-write pattern |
| Per-agent cost tracking schema | ✅ | Schema in place; data captured |
| Health checks (gateway connection ping) | ✅ | Every 5min, 3-failure threshold |
| Stripe subscription billing for tier mode | ✅ | Three subscription products |
| Payment validation gate before provisioning | ✅ | Runs first, cheapest gate |
| Idempotency keys (24h TTL) | ✅ | Required on every call |
| Multi-tenant single OpenClaw instance | ✅ | `workspace_slug` namespacing |
| Absorption-maintenance scheduled task | ✅ | Runs daily; restores `$include` directive |
| Manual-approve mode for sub-agent hiring | ❌ | v1.1 — add when first customer asks |
| Behavior monitoring + thresholds | ❌ | Defer until 3 months of customer data |
| Sub-agent roles | ✅ (limited) | v1 ships with `ceo` and `marketing_analyst` roles. Additional roles (CFO, CMO, engineer, etc.) deferred post-v1. |
| Per-customer container migration | ❌ | Revisit at 50 customers or first compliance request |

---

## Function signature

```python
def provisionForemanAgent(
    *,
    customer_id: str,
    agent_name: str,
    role: AgentRole,                  # enum: ceo | marketing_analyst (v1)
    model_tier: ModelTier,            # enum: OPEN | FRONTIER | HYBRID
    idempotency_key: str,             # UUID, required
    workspace_path: Optional[str] = None,  # defaults per role
) -> ProvisioningResult
```

`ProvisioningResult` is a typed dataclass with success and failure variants. The function never returns an untyped dict and never raises uncaught exceptions — all failures map to a `ProvisioningResult.failed(...)` return.

---

## Provisioning steps (in order)

| # | Step | Native API used | Failure rollback |
|---|---|---|---|
| 0 | **Payment gate** — verify subscription active OR balance > $0; verify not delinquent; verify within tier allowance | Stripe API + Foreman customer table | None (no state created) |
| 1 | **Idempotency check** — return cached result if key exists | Supabase `provisioning_idempotency` | None |
| 2 | **Validate inputs** — customer exists, agent_name not duplicate within workspace, role+tier mapping resolves | Foreman customer + agent tables | None |
| 3 | **Create OpenClaw workspace directory** at `~/.openclaw/workspace-{customer_slug}-{agent_slug}` | Filesystem (`mkdir`) | None |
| 4 | **Register agent in OpenClaw** via CLI: `openclaw agents add {customer_slug}-{agent_slug} --workspace {path} --non-interactive` | OpenClaw CLI | `openclaw agents delete {agent_id}` |
| 5 | **Create agent in Paperclip** via `POST /api/companies/{customerId}/agent-hires` with adapterType `openclaw_gateway`, adapterConfig pointing at our gateway URL | Paperclip REST API | `DELETE /api/agents/{agentId}` via Paperclip API |
| 6 | **Auto-approve the hire** (Path B native flow): listen for the auto-created `hire_agent` approval, then `POST /api/approvals/{approvalId}/approve` using stored Foreman board credentials | Paperclip REST API | Approval row remains; manual cleanup via Paperclip dashboard |
| 7 | **Sync gateway token** — PATCH Paperclip agent's `adapterConfig.headers["x-openclaw-token"]` to current OpenClaw gateway token | Paperclip REST API + OpenClaw config read | Token drift logged; recoverable via `docs/PHASE-3-TOKEN-SYNC.md` runbook |
| 8 | **Hot-reload OpenClaw config** so the new agent registration is active | `openclaw secrets reload` (or `openclaw gateway restart` on failure) | If reload fails: leave config in place, log gateway error, return `partial` outcome |
| 9 | **Verify** — Paperclip API reports correct adapterConfig; OpenClaw `agents list` includes new agent | Paperclip REST API + `openclaw agents list --json` | If mismatch: log warning, return `partial_with_warning` outcome |
| 10 | **Write audit log** (success path) and **return success result** | File + Supabase | Log write failure does not abort; file write succeeds even if Supabase write fails |

### Outcome states

- `success` — all 10 steps completed, agent ready for heartbeats
- `partial` — agent exists on both sides but step 8 had issues; agent may need manual repair via runbook
- `partial_with_warning` — verification mismatch but core agent works
- `failed` — agent does not exist on either side after rollback; safe to retry
- `blocked` — payment gate failed before any state was created

---

## Customer-facing surfaces

### Onboarding flow (customer's first agent)

Customer completes signup, lands on "Create your CEO" screen:

1. **Display name** (optional text field, defaults to "CEO")
2. **Model tier** (radio buttons):
   - "Open models — most affordable"
   - "Frontier models — most capable"
   - "Hybrid (recommended) — open by default, frontier when needed"
3. **API key mode** (radio buttons):
   - "Use Foreman's key — easier setup, includes a usage surcharge"
   - "Bring my own OpenRouter key — more control, lower cost"
   - If BYOK selected: text field for OpenRouter API key with live validation
4. **Approval preference** (radio buttons, only shown if customer's tier permits sub-agents):
   - "Let my CEO hire as needed (recommended)"
   - "Notify me to approve each new hire" *(deferred — gray out with "Coming soon")*
5. **Submit** → calls `POST /api/internal/agents/provision`

After submit, customer sees a progress indicator with the current step:
- "Setting up your CEO..."
- "Connecting to your model provider..."
- "Configuring agent permissions..."
- "Almost ready..."
- "Your CEO is ready" → redirect to dashboard

If provisioning fails, customer sees the failure UX (below).

### Failure UX

When provisioning returns `failed` or `partial`:

1. **Stage label** (plain language): "Setup failed during: connecting to model provider"
2. **Suggested action** (actionable next step): "Your OpenRouter key may be invalid. Edit your settings and try again."
3. **"Show technical details" expander** (collapsed by default): reveals
   - Error code (e.g., `OPENROUTER_AUTH_INVALID`)
   - Provisioning ID (for support reference)
   - Failed step name and number
   - Sanitized error message
4. **Retry button** (always shown if outcome is `failed`)
5. **Contact support button** (shown if outcome is `partial` — needs manual repair)

### Sub-agent hiring (v1: auto-approve only)

When CEO hires a sub-agent, customer sees a notification after the fact:
> "Your CEO hired a Marketing agent." [View] [Dismiss]

No approval prompt in v1. Manual-approve mode is a v1.1 feature.

---

## Model tier specification

### Open models tier

```yaml
primary: openrouter/deepseek/deepseek-chat-v3.1
fallbacks:
  - openrouter/qwen/qwen-2.5-72b-instruct
  - openrouter/meta-llama/llama-3.3-70b-instruct
embedding: qwen_embedding/text-embedding-v4
```

### Frontier models tier

```yaml
primary: openrouter/anthropic/claude-sonnet-4.6
fallbacks:
  - openrouter/openai/gpt-5
  - openrouter/google/gemini-2.5-pro
embedding: qwen_embedding/text-embedding-v4
```

(Embedding stays on Qwen even for frontier tier — frontier embedding providers don't justify their cost over Qwen3 Embedding v4 for typical RAG workloads.)

### Hybrid tier

Default routing: Open models tier (config above).

**Escalation rule:** If the CEO agent rejects a deliverable for the same task twice consecutively, the third attempt routes to the best-suited frontier model for that task type.

Task type → frontier model mapping (config-driven, not hardcoded):

| Task type | Frontier model |
|---|---|
| `code_generation` | `openrouter/anthropic/claude-sonnet-4.6` |
| `code_review` | `openrouter/anthropic/claude-sonnet-4.6` |
| `reasoning` | `openrouter/openai/gpt-5` |
| `research` | `openrouter/google/gemini-2.5-pro` |
| `writing` | `openrouter/anthropic/claude-sonnet-4.6` |
| `default` | `openrouter/anthropic/claude-sonnet-4.6` |

Once a task escalates to frontier, it stays on frontier for any further attempts on that same task (does not de-escalate).

CEO agent has an `escalate_to_frontier` tool to bypass the 2-rejection rule and route a task to frontier upfront when CEO knows the task is hard.

---

## Pricing model (full spec)

### Foreman-managed key — Tier-based

| Tier | Price/mo | Surcharge | Token allowance (approx)* |
|---|---|---|---|
| Tier 1 | $49 | OpenRouter cost + 20% | ~$40 of OpenRouter usage |
| Tier 2 | $99 | OpenRouter cost + 15% | ~$85 of OpenRouter usage |
| Tier 3 | $199 | OpenRouter cost + 10% | ~$180 of OpenRouter usage |

*Allowance is calculated as `(tier_price * 0.95) / (1 + surcharge)` to leave Foreman a small platform-fee margin even within tier. Final numbers tuned during pricing finalization.

When customer exhausts tier allowance, four options:
- **(a) One-time token bundle** — purchase additional tokens at same surcharge rate ($25 / $50 / $100 bundles)
- **(b) Tier upgrade** — pro-rated, new surcharge applies forward (not retroactive)
- **(c) Switch to usage-based** — see below
- **(d) Switch to BYOK** — see below

### Foreman-managed key — Usage-based

- No tier subscription; customer pays per token
- Surcharge: OpenRouter cost + 10% (lower than any tier as compensation for unpredictable revenue)
- Prepaid balance with auto-topup:
  - Customer sets balance amount (e.g., $50) and topup threshold (e.g., refill to $50 when balance < $10)
  - Stripe payment intent fires when threshold hit
  - Balance debited in near-real-time per inference call
  - If balance hits $0 before topup completes (failed payment, network error): agents pause + notify customer
  - Failed auto-topup → email + in-app alert + agents pause until resolved

### BYOK

- Customer provides OpenRouter API key
- Customer pays OpenRouter directly for tokens (no Foreman markup)
- Foreman charges customer "platform-only" subscription fee
- Platform-only price: TBD (target: $19-29/mo to be meaningfully cheaper than Tier 1's $49)

### BYOK fallback to Foreman-managed (global setting)

Customer toggle: `byokFallbackEnabled: bool` (default `true`)

If enabled and customer's BYOK key fails for any reason during an inference call:
- Foreman automatically uses its managed key for that request
- Customer is billed at managed rates (cost + 20%, regardless of which tier they were on; flat surcharge during fallback)
- Customer is notified per the notification policy below
- Foreman retries customer's BYOK key on next inference call (does not stick to managed)

If disabled: BYOK key failure → request fails → customer's agents pause → customer must fix key or manually switch modes.

#### Fallback notification policy
- First fallback in 24h → email + in-app banner
- Subsequent fallbacks within 24h → banner only (no email spam)
- Daily digest if any fallbacks fired: total count, total tokens, total dollar cost incurred

### Switching billing modes

| From | To | Behavior |
|---|---|---|
| Tier-based | Usage-based | Effective end of current billing period; no proration |
| Tier-based | BYOK | Effective end of current billing period; tier subscription cancels |
| Usage-based | Tier-based | Effective immediately; remaining balance kept as credit toward future overage |
| Usage-based | BYOK | Effective immediately; remaining balance refunded to payment method |
| BYOK | Tier-based | Effective immediately; new subscription starts |
| BYOK | Usage-based | Effective immediately; customer prompted to set initial balance |

All switches require an explicit customer action in settings; no automatic switching except the BYOK fallback above.

---

## Audit and observability

### Provisioning audit log (two-write pattern)

**File:** `~/.foreman/logs/provisioning.jsonl` (append-only JSON-lines)
**Database:** `provisioning_log` table in Supabase

Schema (both):

```sql
CREATE TABLE provisioning_log (
  provisioning_id UUID PRIMARY KEY,
  workspace_slug TEXT NOT NULL,
  customer_id TEXT NOT NULL,
  agent_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('ceo', 'marketing_analyst')),
  model_tier TEXT NOT NULL,
  billing_mode_at_time TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  duration_ms INTEGER,
  outcome TEXT NOT NULL CHECK (outcome IN ('success', 'failed', 'partial', 'partial_with_warning', 'blocked')),
  failed_step TEXT,
  error_code TEXT,
  error_message TEXT,
  rollback_performed BOOLEAN NOT NULL DEFAULT FALSE,
  steps_completed JSONB NOT NULL DEFAULT '[]',
  raw_payload_excerpts JSONB,  -- sanitized of secrets
  idempotency_key UUID NOT NULL,
  agent_id UUID  -- nullable for failures before agent creation
);

CREATE INDEX idx_provisioning_log_customer ON provisioning_log(customer_id);
CREATE INDEX idx_provisioning_log_workspace ON provisioning_log(workspace_slug);
CREATE INDEX idx_provisioning_log_outcome ON provisioning_log(outcome, started_at);
```

If Supabase write fails, file write still succeeds — function does not abort on log failure.

### Per-agent persisted data

```sql
CREATE TABLE agents (
  agent_id UUID PRIMARY KEY,
  customer_id TEXT NOT NULL,
  workspace_slug TEXT NOT NULL,
  paperclip_agent_id UUID NOT NULL,
  openclaw_agent_id TEXT NOT NULL,  -- the slug used in `openclaw agents add`
  
  -- Identity
  display_name TEXT NOT NULL,
  role TEXT NOT NULL,
  
  -- Configuration
  model_tier TEXT NOT NULL,
  model_primary TEXT NOT NULL,
  model_fallbacks JSONB NOT NULL,
  billing_mode_at_provision TEXT NOT NULL,
  
  -- Lifecycle
  provisioned_at TIMESTAMPTZ NOT NULL,
  last_modified_at TIMESTAMPTZ NOT NULL,
  current_status TEXT NOT NULL CHECK (current_status IN ('active', 'paused', 'suspended', 'terminated')),
  
  -- Cost tracking (lifetime)
  total_tokens_input BIGINT NOT NULL DEFAULT 0,
  total_tokens_output BIGINT NOT NULL DEFAULT 0,
  
  -- Cost tracking (current billing period)
  tokens_input_current_period BIGINT NOT NULL DEFAULT 0,
  tokens_output_current_period BIGINT NOT NULL DEFAULT 0,
  surcharge_accrued_current_period_cents INTEGER,  -- nullable for BYOK
  billing_period_start DATE NOT NULL,
  billing_period_end DATE NOT NULL,
  last_billed_at TIMESTAMPTZ,
  last_billing_amount_cents INTEGER,
  
  -- Health
  last_health_check_at TIMESTAMPTZ,
  last_health_check_result TEXT,
  last_task_completed_at TIMESTAMPTZ
);

CREATE INDEX idx_agents_customer ON agents(customer_id);
CREATE INDEX idx_agents_workspace ON agents(workspace_slug);
CREATE INDEX idx_agents_status ON agents(current_status);
```

### Health checks

- Per-agent gateway connection check every 5 minutes
- Implementation: ping agent's WebSocket connection through Paperclip API
- 1st failure → log only
- 3rd consecutive failure → customer notification + `current_status` flips to `paused`
- 1 successful check after pause → flips back to `active`
- All health check results written to `agents.last_health_check_*` fields

### Behavior monitoring (data collection only in v1)

Foreman collects but does not act on:
- Task success/failure events per agent per task
- Rejection counts (CEO rejecting deliverables) per agent per task
- Time-to-completion per task

Data is stored for future analysis. No alerting in v1. Behavior monitoring as a customer-facing feature ships post-v1 once 3 months of real data exists to set sensible thresholds.

---

## Implementation surface

### HTTP endpoint

```
POST /api/internal/agents/provision
```

**Authentication:** Foreman session token (customer must be logged in). Internal-only — not part of public API surface.

**Request:**
```json
{
  "agent_name": "CEO",
  "role": "ceo",
  "model_tier": "hybrid",
  "idempotency_key": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response (success):**
```json
{
  "agent_id": "uuid",
  "status": "provisioned",
  "provisioning_id": "uuid",
  "model_primary": "openrouter/deepseek/deepseek-chat-v3.1",
  "ready_at": "2026-04-15T20:00:00Z"
}
```

**Response (failure):**
```json
{
  "status": "failed",
  "failed_step": "step_5_paperclip_hire",
  "error_code": "PAPERCLIP_API_TIMEOUT",
  "error_message": "Paperclip API did not respond within 30s",
  "provisioning_id": "uuid",
  "rollback_performed": true,
  "customer_message": "We couldn't reach our orchestration service. Please try again in a few minutes.",
  "technical_details": {
    "step_number": 5,
    "elapsed_ms": 30157,
    "rollback_actions": ["openclaw_agent_deleted"]
  }
}
```

### CLI

```
foreman agent provision \
  --customer-id <id> \
  --agent-name CEO \
  --role ceo \
  --model-tier hybrid \
  --idempotency-key $(uuidgen)
```

CLI generates idempotency key automatically if not supplied. Outputs JSON matching the HTTP response schema.

### CEO agent tool (sub-agent hiring)

CEO invokes `hire_agent` tool registered via OpenClaw plugin system:

```python
# Tool implementation lives in Foreman backend
def hire_agent_tool(
    *,
    role: str,
    display_name: Optional[str] = None,
    invoking_agent: AgentContext,
) -> dict:
    return provisionForemanAgent(
        customer_id=invoking_agent.customer_id,
        agent_name=display_name or role,
        role=role,
        model_tier=invoking_agent.model_tier,  # inherits parent
        idempotency_key=str(uuid.uuid4()),
    ).to_dict()
```

Tool is exposed to CEO via OpenClaw's plugin SDK but the implementation reaches back into Foreman backend (same-process call in v1's single-instance multi-tenant setup).

### Idempotency

```sql
CREATE TABLE provisioning_idempotency (
  idempotency_key UUID NOT NULL,
  customer_id TEXT NOT NULL,
  result JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '24 hours',
  PRIMARY KEY (idempotency_key, customer_id)
);

CREATE INDEX idx_idempotency_expires ON provisioning_idempotency(expires_at);
```

- Every call MUST include `idempotency_key`; calls without one → 400 error
- First call: function executes, result cached for 24h
- Subsequent calls with same key: return cached result (even if original failed)
- Cleanup job runs hourly to delete expired rows
- Key uniqueness scoped to `(idempotency_key, customer_id)` — different customers can theoretically use same UUID without collision

### Payment gate (step 0)

Runs FIRST, before any other validation. Three checks:

1. **Subscription/balance check:**
   - Tier-based mode: Stripe subscription status is `active` or `trialing`
   - Usage-based mode: prepaid balance > $0
   - BYOK mode: platform-only subscription is `active` or `trialing`
2. **Delinquency check:** no failed payment in last 7 days (Stripe API)
3. **Allowance check:** if tier-based and within current period, tokens_consumed < tier_allowance

Any failure → return `blocked` outcome with `error_code: PAYMENT_REQUIRED` and customer message guiding to billing settings. No Paperclip or OpenClaw calls made.

---

## Out of scope for this function (but in scope for Foreman v1)

These exist but live in other functions/services:

- **Customer signup and Stripe subscription creation** — separate onboarding flow before this function is ever called
- **Stripe webhook handlers** — payment success/failure events update `customer.payment_status` which the payment gate reads
- **Token metering at inference time** — OpenClaw plugin layer that intercepts inference calls, counts tokens, debits balance/accrues surcharge
- **Customer dashboard UI** — where customer sees their agents post-provisioning
- **Task assignment UI** — how customer gives work to their agents
- **CEO agent's first heartbeat behavior** — what CEO does when it wakes up

These are real product surface and need their own scope docs. They are *not* this function's responsibility.

---

## Open questions for pricing finalization

These don't block implementation but need answers before launch:

- Exact token allowances per tier (depends on chosen tier dollar amounts and avg blended OpenRouter cost)
- One-time bundle sizes ($25 / $50 / $100? Different splits?)
- Platform-only subscription price (BYOK mode) — target $19-29 range
- Initial prepaid balance default for usage-based ($50? $25? Customer-set with no default?)
- Auto-topup default threshold (refill at $10? $20? Percentage of balance?)
- Tier-upgrade proration policy in detail
- Refund policy for usage-based balance on mode switch
- Surcharge during BYOK fallback — confirmed flat 20% regardless of customer's tier

---

## Failure-rollback table (full)

| Step failed | What's rolled back | What's left orphaned | Customer-visible state |
|---|---|---|---|
| Step 0 (payment gate) | Nothing | Nothing | Blocked: payment required |
| Step 1 (idempotency) | Nothing | Nothing | Returns prior result |
| Step 2 (input validation) | Nothing | Nothing | Failed: invalid input |
| Step 3 (workspace mkdir) | Nothing | Empty workspace dir (cleaned up by daily maintenance task) | Failed: filesystem error |
| Step 4 (OpenClaw `agents add`) | None — directory cleanup deferred to maintenance | Workspace dir + possibly partial agent registration in openclaw.json | Failed: orchestration error |
| Step 5 (Paperclip `agent-hires`) | `openclaw agents delete {agent_id}` | None if delete succeeds | Failed: orchestration error |
| Step 6 (Paperclip approval) | `DELETE /api/agents/{agentId}` + `openclaw agents delete` | None if both deletes succeed | Failed: approval error |
| Step 7 (token sync) | Leave everything in place — token can be synced manually | Agent exists on both sides but token may be drifted | Partial: needs token sync |
| Step 8 (config reload) | Leave config in place; do NOT delete agent | Agent registered but may not be active until next reload | Partial: needs manual reload |
| Step 9 (verification) | Leave everything in place | Mismatch logged but agent likely works | Partial with warning |
| Step 10 (audit log) | Nothing — log failure does not abort | Audit row missing in DB (file copy still exists) | Success (log gap) |

---

## Prerequisites

These are non-negotiable dependencies. If any of these are missing or broken, the provisioning function cannot work.

1. **Stripe account configured** with three subscription products (Tier 1, 2, 3), platform-only subscription product, and ability to fire one-off payment intents for usage-based and one-time bundles
2. **Foreman backend has Stripe API keys** in environment and a thin wrapper for subscription/payment-intent operations
3. **Customer record schema in Supabase** with `customer_id`, `stripe_customer_id`, `current_billing_mode`, `current_tier`, `byok_key_encrypted` (nullable), `byok_fallback_enabled`, `prepaid_balance_cents` (nullable), `payment_status`
4. **Paperclip API key with board-user permissions** for the Foreman-controlled customer companies. Standard credential generated through Paperclip's normal API key flow. Used to call `POST /api/companies/{id}/agent-hires` and `POST /api/approvals/{id}/approve` programmatically.
5. **Foreman backend process can invoke OpenClaw CLI** (`openclaw agents add`, `openclaw agents delete`, `openclaw agents list`, `openclaw secrets reload`). Process runs on same host as OpenClaw gateway (or has equivalent SSH/exec access in containerized deployments).
6. **Token metering plugin in OpenClaw** (separate workstream — must exist before tier allowance gates can fire correctly)
7. **Reference implementation** `pnpm smoke:openclaw-join` from paperclipai/paperclip repo — used as source-of-truth for the join/approve/claim flow during Phase A implementation

---

## Operational maintenance tasks

These are scheduled jobs that the provisioning function depends on but doesn't itself execute.

### `openclaw_config_absorption_repair` — daily at 03:00 UTC

OpenClaw's `agents add` CLI writes to `~/.openclaw/openclaw.json` (the root config file), not to our `foreman.json5` include. Over time, this causes:
- Agent records pile up in the root file
- The `$include` directive may be stripped during OpenClaw's internal reconciliation
- Provider config in `foreman.json5` becomes the authoritative copy but isn't being read because root file overrides it

**Daily maintenance task** runs the strip-and-restore-include logic from tonight's session (`docs/STACK-HEALTH-DISABLED.md` references this pattern):
1. Read current `~/.openclaw/openclaw.json`
2. Identify agent records that should be in `foreman.json5` (Foreman-owned agents)
3. Move them from root → include
4. Restore `$include: "./foreman.json5"` directive in root
5. Strip provider/env/plugin sections from root (these belong in include)
6. `openclaw secrets reload` to re-absorb

**Failure handling:** If maintenance task fails, alert Foreman ops (email). Do NOT auto-retry — manual investigation required because absorption issues compound.

**Future:** When OpenClaw upstream supports `--config-file <path>` for `agents add`, this task can be retired. File a feature request in OpenClaw repo referencing this pain point.

### `provisioning_idempotency_cleanup` — hourly

Delete rows from `provisioning_idempotency` where `expires_at < NOW()`.

### `orphan_workspace_cleanup` — daily at 03:30 UTC

Scan `~/.openclaw/workspace-*` directories for any not corresponding to an active agent in the `agents` table. Delete after 7-day grace period.

---

## Implementation phases (suggested)

Three Cursor prompt batches, each independently shippable to a working state:

### Phase A — Skeleton + happy path (1-2 days)
- Function signature + typed result types
- Steps 0-2 (payment gate, idempotency, validation)
- Steps 3-7 (Paperclip + OpenClaw orchestration via native APIs, no rollback yet)
- HTTP endpoint
- CLI wrapper
- Audit log writes (success path only)
- Manual test: provision one CEO agent end-to-end

### Phase B — Failure handling + rollback (2-3 days)
- Rollback logic per the failure table
- Steps 8-10 (config reload, verification, audit log on failure paths)
- Failure response shaping (customer message, technical details)
- Audit log writes (failure paths)
- Operational maintenance tasks (absorption repair, idempotency cleanup, orphan cleanup)
- Manual test: induce failures at each step, verify rollback

### Phase C — Customer-facing + sub-agent hiring (3-5 days)
- Onboarding UI screens
- Failure UX (stage label + actionable step + technical expander)
- CEO agent `hire_agent` tool
- Sub-agent auto-approval flow + notification
- Health check loop
- Manual test: full customer journey from signup to working CEO

Stripe integration runs in parallel as its own workstream — Phase A can start with a stub payment gate that always passes; real Stripe wiring lands before Phase C ships.

---

## Document status and next steps

- [x] Prerequisites confirmed via Paperclip and OpenClaw documentation
- [ ] Jonathan reviews this doc and pushes back on anything misaligned
- [ ] Pricing finalization addresses the open questions section
- [ ] Confirm OpenClaw token metering plugin (#6) is scoped or scheduled
- [ ] Once approved: write Phase A Cursor prompt against this doc