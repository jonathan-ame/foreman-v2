# Phase 2+ Backlog

This backlog captures work intentionally deferred from Phase 1.
Phase 2 is now queued as an actionable execution plan.

## Source of truth

- Canonical status/owners/dates/dependencies now live in Notion:
  - Hub: https://www.notion.so/33c6238cef3e8190b695cb3dde3f9c42
  - Task database: https://www.notion.so/e202cead847b4cb8b7aa032c7a373daa
- This file is a git-tracked mirror for technical narrative and scope notes.

## Phase 2 Queue (Paperclip integration)

**Status:** in progress (closeout stage)  
**Scope cap:** stay on OpenClaw + the current hosted inference substrate; do not pull in Phase 3/4 work unless explicitly re-decided.

| ID | Task | Status | Depends on | Notes |
|---|---|---|---|---|
| P2.1 | Paperclip install + baseline integration with OpenClaw | done | Phase 1 complete | Pin versions, document install path, prove Paperclip + gateway coexistence |
| P2.2 | Per-role routing across executor / planner / embedding | done | P2.1 | Completed with routing contract, runtime wiring, and verification evidence |
| P2.3 | Recreate v1 hierarchy (CoS -> Chiefs -> Specialists) in Paperclip | in progress | P2.2 | Batch 3 first slice complete; wave 2 hierarchy continuation is next executable |
| P2.4 | Anti-hallucination policy + review loops | done | P2.1 (minimal agent shell) | Policy + escalation/trigger matrix captured and reviewed |
| P2.5 | Port or rebuild scheduled task automation from `foreman/` | done | P2.2, P2.3 | Pilot scheduler path and validation harness complete |
| P2.6 | Multi-tenancy / Paperclip company isolation | done | P2.1 | Isolation contract, verification pilot, and operator runbook complete |
| P2.7 | Migrate Cursor review subagents into Paperclip-managed agents | done | P2.3, P2.6 | Reviewer mapping, skeleton agents, routing contract, proof run complete |
| P2.8 | Reintroduce additional model roles only with evidence | done (skipped) | Explicit agent need + justification | Justification gate executed; no qualifying trigger |

**Critical path:** `P2.1 -> P2.2 -> P2.3`  
**Immediate next executable:** `P2.3` wave 2 hierarchy continuation (Batch 3 wave 2).

## P2.1 contract lock (complete)

- Canonical source/docs: `paperclip.ing` and `docs.paperclip.ing`.
- Baseline local install command: `npx paperclipai onboard --yes`.
- Baseline requirements from upstream docs: Node.js 20+.
- Runtime boundary for this project: Paperclip is the org layer; OpenClaw runs
  as agent runtime under Paperclip.
- Reproducibility policy: capture the resolved `paperclipai` version during
  onboarding and pin follow-up runs with `npx paperclipai@<version> ...`.

## P2.1 execution checklist

- [x] Contract lock captured from upstream docs and recorded.
- [x] Environment/secrets inventory captured in `.env.example` and docs.
- [x] Paperclip local onboarding completed and health-verified.
- [x] OpenClaw wired under Paperclip as an agent runtime.
- [x] One minimal Paperclip -> OpenClaw proof interaction succeeds.
- [x] Failure mode is loud and documented.

## P2.1 completion evidence (2026-04-08)

- Local trusted Paperclip baseline running on `http://127.0.0.1:3110` after `npx paperclipai@2026.403.0 onboard --yes`.
- Paperclip agents moved off `cursor`/`opencode` path to OpenClaw process wrapper (`scripts/paperclip-openclaw-worker.sh`) so runtime goes through OpenClaw provider routing.
- Success runs captured: `ee97b599-475d-41d0-895b-478bee5b3d84` (OpenClawWorker), `14582c91-7c68-42e0-9c2f-9f3cf6f9668d` (CEO).
- Failure-loud run captured: `11c1d128-82d3-4d27-a98c-3d2b9cf24c71` (intentional broken gateway override, exits non-zero with explicit error).

## Phase 2 completion evidence snapshots (post-P2.1)

- P2.2 evidence: `config/role-routing.json`, `scripts/paperclip-role-dispatch.sh`, `state/p2.2-role-verifier.json`, `state/p2.2-routing-consistency.json`.
- P2.4 evidence: `docs/P2.4-BATCH-4-ANTI-HALLUCINATION-POLICY.md`.
- P2.5 evidence: `docs/P2.5-BATCH-5-SCHEDULER-INVENTORY.md`, `docs/P2.5-BATCH-5-TARGET-SCHEDULER-ARCHITECTURE.md`, `docs/P2.5-BATCH-5-BACKLOG-SPLIT.md`, `scripts/paperclip-scheduler-pilot.sh`, `scripts/validate-scheduler-pilot.sh`, `state/p2.5-pilot-run.json`.
- P2.6 evidence: `docs/P2.6-BATCH-6-ISOLATION-CONTRACT.md`, `docs/P2.6-BATCH-6-OPERATOR-RUNBOOK.md`, `scripts/verify-tenant-isolation-pilot.sh`, `state/p2.6-isolation-pilot.json`.
- P2.7 evidence: `docs/P2.7-BATCH-7-REVIEWER-MAPPING.md`, `docs/P2.7-BATCH-7-GATE-ROUTING-CONTRACT.md`, `state/p2.7-reviewer-proof.json`.
- P2.8 gate decision: `docs/P2.8-JUSTIFICATION-GATE.md` (skipped due to no trigger).

## Human decisions before P2.1

- Confirm Paperclip install/source and version pin policy.
- Choose first vertical slice: single-operator first vs multi-tenant from day one.
- Confirm runtime ownership boundary between OpenClaw and Paperclip.

## P2.1 environment/secrets inventory (redacted)

Required:

- `DEEPINFRA_API_KEY` (OpenClaw provider auth for hosted inference)
- `PAPERCLIP_BASE_URL` (default `http://127.0.0.1:3100`)
- `OPENCLAW_GATEWAY_URL` (default `http://127.0.0.1:18789`)

Optional (recommended local defaults in `.env.example`):

- `PAPERCLIP_INSTANCE_ID` (default `default`)
- `PAPERCLIP_HOME` (override data dir if needed)
- `PAPERCLIP_DEPLOYMENT_MODE` (`local_trusted` for local baseline)
- `PAPERCLIP_TELEMETRY_DISABLED=1` (disable telemetry for local dev)
- `OPENCLAW_GATEWAY_TOKEN` (only if gateway auth mode requires token)

## Target: Phase 3 (out of Phase 2 by default)

- Frontend reskin using the consultant-style UX pattern from `foreman/`.
- User onboarding flow for non-technical users.
- Social media publishing pipeline (stack TBD in Phase 3).
- Hosted gateway/platform polish beyond local-first validation.
- Secure remote gateway access during hosted transition.

## Target: Phase 4+ (out of Phase 2 by default)

- Billing integration (for example, Stripe).
- Marketing site and landing pages.
- Customer support tooling and operational workflows.
- Broader analytics/reporting beyond core operational telemetry.

## Notes

- Phase 1 remains complete as OpenClaw runtime + hosted inference routing + verified WebChat.
- Any Phase 3/4 item pulled into Phase 2 requires an explicit plan decision update.
