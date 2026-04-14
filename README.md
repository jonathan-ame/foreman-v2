# Foreman v2

Foreman v2 is a Paperclip-orchestrated agent system that uses OpenClaw as the
runtime layer. OpenClaw remains the execution runtime and now targets hosted
inference endpoints instead of self-managed pod infrastructure.

The existing `foreman/` repository remains unchanged. `foreman-v2/` is a
sibling workspace for the current architecture.

## Prerequisites

- Python 3.11+
- Node.js 24.x, or Node.js >= 22.16
- OpenClaw installed (`npm install -g openclaw@latest`)
- DeepInfra API key (stored as `DEEPINFRA_API_KEY`; Phase 1 wires live checks)
- Paperclip installed/onboarded
- Existing Supabase project credentials (unchanged)

## Setup

1. Copy env template:

   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and set at minimum:
   - `DEEPINFRA_API_KEY`
   - Paperclip runtime variables (`PAPERCLIP_BASE_URL`, `PAPERCLIP_INSTANCE_ID`, etc.)

3. Install OpenClaw and complete onboarding:

   ```bash
   ./scripts/install.sh
   ```

4. Configure OpenClaw with Foreman role bindings:

   ```bash
   ./scripts/configure.sh
   ```

5. Start local services:

   ```bash
   ./scripts/start.sh
   ```

## Runtime Notes

- OpenClaw remains the agent runtime between Paperclip and inference providers.
- Role bindings are maintained in `config/openclaw.foreman.json` and
  `config/role-routing.json`.
- The CEO execution path remains `scripts/paperclip-openclaw-executor.sh`.
- Integration gate command:

  ```bash
  ./scripts/integration-check.sh
  ```

## Phase 2 P2.2 Routing Ops

Role routing source-of-truth:

- `config/role-routing.json`

Operational verifier commands:

```bash
./scripts/check-role-routing-consistency.sh
./scripts/verify-paperclip-role-routing.sh
```

Role-dispatch worker entrypoint:

```bash
./scripts/paperclip-role-dispatch.sh
```

The dispatch script enforces:

- `executor` path via OpenClaw agent
- `planner` path via provider `/chat/completions`
- `reviewer` path via provider `/chat/completions`
- `embedding` path via provider `/embeddings`

Failure behavior is loud by design (non-zero exit on unknown role, provider
mismatch, HTTP failure, or OpenClaw fallback patterns).
