# Corrections System Design

**Status:** Approved — pending reliability workstream
**Date:** 2026-04-11 (rev 2)
**Phase:** 1 (authorized scope extension; see PHASE-1-PLAN.md Cluster 8)
**Replaces:** CORRECTIONS-SYSTEM-DESIGN.md (rev 1)

## Purpose

When a manager agent (e.g. the CEO) reviews a subordinate's work and wants the subordinate to do something differently in the future, that guidance is captured as a **correction**. Corrections persist across heartbeats and accumulate over the agent's lifetime, forming organizational memory specific to each agent within each Foreman company.

Two jobs:
1. **Audit trail** — every correction traceable in Paperclip's UI for board oversight.
2. **Curation at delegation time** — the CEO reviews the subordinate's correction history and weaves relevant ones into new task descriptions.

## Non-goals
- Does not replace Paperclip's existing review flow.
- Does not auto-modify subordinate behavior.
- Other communication types (preferences, escalations) deferred to future phases.
- Consolidation deferred (RAG handles relevance).

## Architecture

### Source of truth: Paperclip Issues/Comments
Each subordinate has a dedicated **journal issue**: unassigned, `backlog` indefinitely, named `[JOURNAL] {agent_title} — Standing Corrections`. Its ID is stored in the agent's `metadata.journal_issue_id` via `PATCH /api/agents/{id}` with read-modify-write merge (Paperclip PATCH replaces the metadata object wholesale).

Corrections are posted as comments on the journal. Author derives from auth context (`authorAgentId`) — cannot be set in body. CEO must use its own API key/run JWT.

### Fast retrieval store: Supabase + pgvector
Project `bsgpogxfhcaxjlrsmsaj`, `workspace_slug='foreman'`.

```sql
create extension if not exists vector;

create table agent_corrections (
  id                    bigserial primary key,
  workspace_slug        text not null default 'foreman',
  paperclip_agent_id    text not null,
  paperclip_comment_id  text not null unique,
  paperclip_issue_id    text not null,
  source_issue_id       text,
  source_agent_id       text,
  correction_type       text not null default 'correction',
  guidance_text         text not null,
  created_at            timestamptz not null,
  superseded_at         timestamptz,
  embedding             vector(4096)
);

create index idx_corrections_agent on agent_corrections (workspace_slug, paperclip_agent_id) where superseded_at is null;
create index idx_corrections_embedding on agent_corrections using hnsw (embedding vector_cosine_ops) where superseded_at is null;

create table sync_cursors (
  workspace_slug         text not null,
  paperclip_agent_id     text not null,
  last_synced_comment_id text,
  last_synced_at         timestamptz not null default now(),
  cursor_owner           text,
  cursor_owner_expires   timestamptz,
  primary key (workspace_slug, paperclip_agent_id)
);
```

Paperclip is the write path; Supabase is a derived view, always reconstructable via re-sync. Sync cursor state is operational metadata only.

## Flows

### 1. Hire-time setup (mandatory — no fallback)
1. Create journal issue (no assignee, `backlog`).
2. `GET /api/agents/{id}` to read existing metadata.
3. `PATCH /api/agents/{id}` with merged metadata including `journal_issue_id`.
4. Insert row in `sync_cursors` with `last_synced_comment_id = null`.

Hire fails if any step fails. **Legacy agents** (predating this system) are handled by a one-time backfill script run manually at rollout — never auto-created mid-flight in delegation.

### 2. Correction issuance (CEO review path)
1. Planner emits `verdict` + `correction_text` + `source_issue_id`.
2. If correction issued: lookup `journal_issue_id`, post structured comment to journal, post verdict separately on the original issue. Missing journal → fail loudly, log full correction text for manual recovery, halt review path.

Side-effect writes are Foreman orchestration, not pod calls.

### 3. Heartbeat sync
1. Acquire single-flight lock on `sync_cursors` (60s TTL). Locked by another worker → skip.
2. `GET /issues/{journal_id}/comments?after={cursor}&limit=500`, paginate.
3. Per parseable correction comment: embed via embedding pod, upsert to `agent_corrections` (idempotent via unique `paperclip_comment_id`).
4. Update cursor, release lock.

Failure modes: embedding pod down → log warning, leave unsynced; Supabase down → skip; Paperclip down → skip; lock expired → next heartbeat retries (idempotent).

### 4. Curation at delegation time (domino-gated, restart-on-next-heartbeat)
1. **Acquire delegation lock** keyed `(subordinate_id, parent_issue_id)`, 120s TTL.
2. **Fetch journal metadata.** Missing → fail loudly, surface to board, no auto-create.
3. **RAG retrieval.** Embed task description (embedding pod down → 503). Query: `SELECT ... WHERE workspace_slug = 'foreman' AND paperclip_agent_id = ? AND superseded_at IS NULL ORDER BY embedding <=> ? LIMIT 50`. Apply threshold (default 0.65). Empty result valid (clean slate).
4. **Planner curation.** Pass task + corrections (or empty marker) + curation prompt. Planner returns rewritten description. Highest-priority constraint: never invent corrections not in input. Planner unavailable → 503.
5. **Create delegation issue.** `POST /companies/{id}/issues` with curated description, release lock.

Failed delegations restart from Step 1 on next heartbeat — no persistent half-built state.

### 5. Subordinate execution
Receives curated task description as part of assigned issue. Unaware of corrections system. No changes to `paperclip-openclaw-executor.sh`.

## Comment payload format

```
---
type: correction
source_issue_id: {uuid}
source_agent_id: {uuid}
timestamp: 2026-04-11T14:30:00Z
---

{guidance text}
```

Sync parser splits on second `---`. Validation: rejects malformed frontmatter, missing fields, unknown `type`. Rejected comments logged and skipped. This is the security guard against malicious correction injection.

## Pod routing

| Step | Pod |
|---|---|
| CEO review reasoning | Planner |
| Comment write | None (orchestration) |
| Embedding generation (sync) | Embedding |
| Embedding generation (delegation) | Embedding |
| Supabase RAG query | None (orchestration) |
| Curation | Planner |
| Delegation issue creation | None (orchestration) |
| Subordinate execution | Executor or Reviewer |

## Hard constraints

1. **No hallucinated corrections.** Empty input → empty citations. Highest-priority constraint in curation prompt.
2. **No CEO termination.** Runtime-enforced: chief executor strips terminate endpoint from CEO toolset before invocation.
3. **Purely additive.** No patches, no private state, no contract violations.
4. **No silent fallback.** Embedding/planner/Supabase down → 503. Explicit 503 branches in delegation Steps 3 and 4.
5. **Audit trail integrity.** Author from auth context only.
6. **Domino gating.** Five steps in strict sequence; failure restarts from Step 1 next heartbeat.
7. **Supabase derived view.** Reconstructable from Paperclip via re-sync.

## Fragility risks (undocumented behavior dependencies)

1. Comment pagination params (`after`, `limit`) — present in Paperclip code, not documented.
2. Unassigned backlog issues remain passive — observed runtime, not contractual.
3. `agents.metadata` jsonb field — no documented merge semantics; we read-modify-write.

## Concurrency policy

- Sync per agent: single-flight lock in `sync_cursors`, 60s TTL.
- Delegation per `(subordinate_id, parent_issue_id)`: lock 120s TTL.
- Lock TTL is the recovery mechanism for crashed workers.

## Failure modes

| Failure | Recovery |
|---|---|
| Paperclip API down | All flows fail loudly; retry next heartbeat |
| Supabase down (sync) | Sync skipped; previously-indexed corrections still available |
| Supabase down (delegation) | 503; retry next heartbeat |
| Embedding pod down (sync) | New comments unsynced; warning logged |
| Embedding pod down (delegation) | 503 |
| Planner pod down (curation) | 503 |
| CEO auth expired | 401 from Paperclip; refresh on next invocation |
| Journal deleted | Fail loudly; manual recovery via backfill script |
| Lock holder crashes | TTL expires; next heartbeat acquires |

## Decision log

| # | Decision | Made by |
|---|---|---|
| 1 | Corrections via dedicated journal issues | Jonathan |
| 2 | One type for Phase 1, type field present for forward compat | Jonathan |
| 3 | CEO curates at delegation, not subordinate self-read | Jonathan |
| 4 | Curation runs every delegation, no shortcut | Jonathan |
| 5 | Citation structurally required | Jonathan |
| 6 | Domino gating, restart-on-next-heartbeat | Jonathan |
| 7 | No termination; runtime tool stripping enforces | Jonathan |
| 8 | RAG from day one, no journal cap | Jonathan |
| 9 | Supabase authorized for Phase 1 | Jonathan |
| 10 | Hire-time journal mandatory; legacy via backfill | Jonathan |
| 11 | Consolidation deferred | Jonathan |
| 12 | metadata.journal_issue_id with read-modify-write | Claude |
| 13 | sync_cursors as separate table | Claude |
| 14 | Single-flight locks (sync 60s, delegation 120s) | Claude |
| 15 | Embedding dim 4096, MRL truncation available | Claude |
| 16 | Reviewer label confirmed for Qwen2.5-Coder | Cursor |

## Implementation stages

Each independently testable. Execution prompts written after reliability workstream completes.

**Stage 1 — Journal plumbing.** Hire-time hook + read-modify-write metadata + legacy backfill. Test: hire → verify journal + metadata. Run backfill against existing CEO and OpenClawWorker.

**Stage 2 — Correction issuance.** CEO review verdict path posts structured comments. Test: simulate review with correction → verify comment with valid frontmatter and CEO authorship.

**Stage 3 — Sync and storage.** Heartbeat sync with embedding generation. Test: known comment → sync → exactly one row with embedding. Re-sync → no duplicates. Concurrent sync → lock holds.

**Stage 4 — Curation and delegation.** RAG + planner curation + curated delegation issues. Test: seeded history + relevant task → cited correction. Unrelated task → no-relevant-corrections + unchanged description. Clean slate → zero fabrication.

**Prerequisites:** Stage 2 needs Stage 1. Stage 3 needs Stage 2. Stage 4 needs Stage 3.

## Observability

Counters: corrections synced, sync failures, embedding failures, retrieval queries, retrieval empty rate, curation calls, fabrication-guard violations. Structured logs per sync run, delegation, correction issuance with agent_id and run_id. Alerts: fabrication-guard violations (page), embedding pod failures during delegation (page), sync failures (warning).

## Rollback / rebuild runbook

**Full re-sync:** `TRUNCATE agent_corrections; TRUNCATE sync_cursors;` → insert one row per agent in `sync_cursors` with null cursor → trigger heartbeats → verify row count matches Paperclip correction-formatted comments.

**Single agent cursor reset:** `UPDATE sync_cursors SET last_synced_comment_id = null WHERE paperclip_agent_id = ?;` → trigger next heartbeat.

## Open items (Claude resolves during implementation, no product input needed)

- Curation prompt wording
- Structured review verdict output format
- Hire-time hook location in chief executor (Cursor identifies in Stage 1)
- Similarity threshold tuning (start 0.65)

## Dependencies

- Reliability workstream completes first
- Supabase project `bsgpogxfhcaxjlrsmsaj` accessible with pgvector enabled
- Embedding pod healthy
- Paperclip running with Foreman company `4a314bff-55a4-4939-bbb7-b3d73c7db1ce`