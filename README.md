# Foreman v2 (Phase 1 Complete, Phase 2 In Progress)

Foreman v2 is a packaging/wrapper layer around OpenClaw that is wired to a
four-endpoint RunPod Secure Cloud roster (`embedding`, `executor`, `planner`, `reviewer`).
Phase 1 packaged and validated the OpenClaw + RunPod baseline. Phase 2 starts
with Paperclip as the org layer, with OpenClaw running as agents under
Paperclip control.

The existing `foreman/` repository remains unchanged. `foreman-v2/` is a
sibling distribution workspace and provisioning layer.

## Prerequisites

- Node.js 24.x, or Node.js >= 22.16
- A valid RunPod API key (`RUNPOD_API_KEY`)
- Sufficient RunPod account balance for all four always-on pods

## Setup

1. Copy env template:

   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and set:
   - `RUNPOD_API_KEY`
   - (optional) `RUNPOD_MIN_BALANCE_HOURS` (default `24`; use `4` for controlled H100 retry loops)

3. Install OpenClaw:

   ```bash
   ./scripts/install.sh
   ```

4. Provision pods (manual review + explicit run):

   ```bash
   ./scripts/provision.sh
   ```

   Quality-first cutover policy uses H100-backed `executor`, `planner`, and `reviewer` roles.

5. Configure OpenClaw for Foreman v2:

   ```bash
   ./scripts/configure.sh
   ```

6. Start OpenClaw gateway:

   ```bash
   ./scripts/start.sh
   ```

## Verify Phase 1

1. Run smoke test (executor + planner + reviewer + embedding):

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

4. Cleanup stale RunPod storage volumes (dry-run first):

   ```bash
   ./scripts/cleanup-stale-volumes.sh --dry-run
   ./scripts/cleanup-stale-volumes.sh --apply
   ```

   By default this targets names with prefix `foreman-models-`. Configure
   keep-list and limits via `.env` (`RUNPOD_VOLUME_KEEP_NAMES`,
   `RUNPOD_VOLUME_CLEANUP_MAX_DELETE`).

## Phase 1 Scope (Corrected)

- Install OpenClaw locally
- Provision a three-pod Secure Cloud vLLM roster
- Configure OpenClaw with provider-per-role endpoints
- Verify executor/planner/reviewer/embedding end-to-end health checks

## Explicit Non-goals (Phase 1)

- Paperclip integration is in scope and active: live Foreman agents run via `scripts/paperclip-chief-executor.sh` and `scripts/paperclip-openclaw-executor.sh` using `adapterType: "process"`.
- No frontend reskin
- No multi-tenant architecture
- No Docker, Railway, or app cloud deploy
- No edits in the existing `foreman/` codebase
- No custom agent hierarchy (CoS/Chiefs/Specialists), no scheduled tasks
- Supabase is now in Phase 1 scope, specifically for the corrections system described in `docs/CORRECTIONS-SYSTEM-DESIGN.md`. The existing Supabase project (`bsgpogxfhcaxjlrsmsaj`) from v1 is being reused with `workspace_slug='foreman'` as the multi-tenancy key.

Phase 1 includes the corrections system deliverable defined in `docs/CORRECTIONS-SYSTEM-DESIGN.md`, and execution of that work is gated on the pod/gateway reliability workstream completing first.

See:
- `docs/PHASE-1-SPIKE.md` for corrected success criteria and history
- `docs/INFERENCE-ENDPOINTS.md` for endpoint roster, flags, cost, and failure modes

## Phase 2 P2.1 Baseline (local)

Contract lock for P2.1:

- Source of truth: [`paperclip.ing`](https://paperclip.ing) and [`docs.paperclip.ing`](https://docs.paperclip.ing)
- Quickstart command: `npx paperclipai onboard --yes`
- Runtime boundary: Paperclip is the org/orchestration layer; OpenClaw is an
  agent runtime managed by Paperclip
- Hosting mode: local

Recommended reproducible install practice:

1. Resolve and record installed version:
   ```bash
   npx paperclipai --version
   ```
2. Pin that version for repeatability:
   ```bash
   npx paperclipai@<version> onboard --yes
   ```

Default local endpoints:

- Paperclip UI/API: `http://127.0.0.1:3100`
- OpenClaw gateway: `http://127.0.0.1:18789`

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
- `planner` path via planner pod `/chat/completions`
- `reviewer` path via reviewer pod `/chat/completions`
- `embedding` path via embedding pod `/embeddings`

Failure behavior is loud by design (non-zero exit on unknown role, provider mismatch, HTTP failure, or OpenClaw fallback patterns).
