# CEO Workspace — Repo Authoritative Mirror

This directory is the source of truth for the Foreman CEO agent's OpenClaw workspace behavioral files.

## What's here

- `HEARTBEAT.md` — per-heartbeat operational checklist
- `SOUL.md` — persona, core identity, red lines
- `AGENTS.md` — delegation rules, hiring flow, escalation, comment style
- `TOOLS.md` — Paperclip REST surface, Foreman plugin tools, environment specifics

## What's NOT here (intentionally live-only)

- `IDENTITY.md`, `USER.md` — set at bootstrap, correct in live workspace
- `memory/YYYY-MM-DD.md` — runtime learning; must persist across configure runs
- `BOOTSTRAP.md` — one-time first-run ritual; deleted after bootstrap

## Sync direction

Repo → live. Changes to the four files above must be made HERE first, then propagated to `~/.openclaw/workspace-ceo/` via `scripts/configure.sh` (see `docs/DRIFT-TEARDOWN-FOLLOWUPS.md` item 4 on configure-based workspace sync).

Changes made directly to `~/.openclaw/workspace-ceo/` for the four behavioral files will be overwritten on next configure. If you find yourself editing the live workspace for one of these four files, stop and edit it here instead.

## Canonical CEO agent

Paperclip agent id: `a7a0b631-1b67-452f-bbd2-ea530fdde75d`
Name: `CEO`
Title: `Chief Executive Officer`
Adapter: `openclaw_gateway`
Gateway URL: `ws://127.0.0.1:18789/`
Live workspace on disk: `~/.openclaw/workspace-ceo/`

Direct reports (all four parented under this CEO per Paperclip's strict org-tree invariant; names are spaceless, used as @-mention handles):

- `9a6196ae-4593-4f97-94c2-d57f90448463` — `Engineer`
- `42e5484c-d279-42ff-b321-882b7629fd54` — `Designer`
- `e946fc97-17d6-4022-aa68-fffa64c03198` — `QA`
- `7b154720-0429-460a-ae1b-180e51b93b8a` — `MarketingAnalyst`

## History

Established 2026-04-19 as part of the Foreman drift teardown. Replaces prior drift in `~/.openclaw/workspace-ceo/` that used `sessions_spawn` / `sessions_yield` OpenClaw primitives for delegation. Foreman delegation is Paperclip-native issue assignment.

### 2026-04-19 org-chart normalization

On 2026-04-19 the org tree was normalized to match Paperclip's documented invariant (one CEO, every other agent `reportsTo` a manager). Changes:

- Renamed live CEO from `Foreman CEO` → `CEO`
- Renamed `Engineer 3` → `Engineer`
- Renamed `marketing_analyst 2` → `MarketingAnalyst`
- Parented all four specialists to the CEO
- Terminated error-state `Marketing Analyst` (`60f615b0-78bd-48eb-ad72-c8ed466f3795`); its one open blocked assignment `FOR-239` was first unassigned and reset to `todo` so the board can reassign
- Terminated superseded test CEOs `c1a3c80b-c5f1-4a1f-9dc9-902485f90925` and `dce0f8fd-a030-4fdd-907e-e44e20a70bbf`

Predecessor CEO agents (all terminated):

- `44f95028-f240-4be9-8e9c-e5420240aa41` — original Foreman CEO, terminated 2026-04-18 after tool-calling panic loop. Its exposed API key was revoked 2026-04-19.
- `c1a3c80b-c5f1-4a1f-9dc9-902485f90925` — E2E test CEO, terminated 2026-04-19.
- `dce0f8fd-a030-4fdd-907e-e44e20a70bbf` — superseded process-adapter CEO (used deleted `scripts/ceo-heartbeat.js`), terminated 2026-04-19. Its `adapterConfig.env` leaked an OpenRouter API key; see `docs/DRIFT-TEARDOWN-FOLLOWUPS.md` item 1 on key rotation.
