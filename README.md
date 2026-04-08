# Foreman v2 (Phase 1 Corrected)

Foreman v2 is a packaging/wrapper layer around OpenClaw that is wired to a
three-endpoint RunPod Secure Cloud roster (`embedding`, `executor`, `planner`).
Phase 1 builds and validates local packaging + provisioning scripts; it does not
introduce Paperclip or multi-tier routing logic yet.

The existing `foreman/` repository remains unchanged. `foreman-v2/` is a
sibling distribution workspace and provisioning layer.

## Prerequisites

- Node.js 24.x, or Node.js >= 22.16
- A valid RunPod API key (`RUNPOD_API_KEY`)
- Sufficient RunPod account balance for all three always-on pods

## Setup

1. Copy env template:

   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and set:
   - `RUNPOD_API_KEY`

3. Install OpenClaw:

   ```bash
   ./scripts/install.sh
   ```

4. Provision pods (manual review + explicit run):

   ```bash
   ./scripts/provision.sh
   ```

5. Configure OpenClaw for Foreman v2:

   ```bash
   ./scripts/configure.sh
   ```

6. Start OpenClaw gateway:

   ```bash
   ./scripts/start.sh
   ```

## Verify Phase 1

1. Run smoke test (executor + planner + embedding):

   ```bash
   ./scripts/smoke-test.sh
   ```

2. Open WebChat/Control UI:
   - `http://127.0.0.1:18789`
   - Send a prompt and confirm responses are from the configured RunPod-hosted Qwen model.

3. Emergency stop all billing pods if needed:

   ```bash
   ./scripts/teardown.sh
   ```

## Phase 1 Scope (Corrected)

- Install OpenClaw locally
- Provision a three-pod Secure Cloud vLLM roster
- Configure OpenClaw with provider-per-role endpoints
- Verify executor/planner/embedding end-to-end health checks

## Explicit Non-goals (Phase 1)

- No Paperclip integration
- No frontend reskin
- No multi-tenant architecture
- No Docker, Railway, or app cloud deploy
- No edits in the existing `foreman/` codebase
- No custom agent hierarchy (CoS/Chiefs/Specialists), no scheduled tasks
- No Supabase integration

See:
- `docs/PHASE-1-SPIKE.md` for corrected success criteria and history
- `docs/INFERENCE-ENDPOINTS.md` for endpoint roster, flags, cost, and failure modes
