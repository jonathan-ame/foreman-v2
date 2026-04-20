# Drift Teardown — Followups

Outstanding items from the 2026-04-19 Foreman drift teardown. These are the concrete loose ends after Gate B's org-chart normalization, captured here so they survive across sessions.

Each item states scope, why it's deferred, and what "done" looks like.

---

## 1. Rotate the OpenRouter API key

**Scope:** security hygiene.

**Background.** The key `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` was found embedded in the Paperclip DB on terminated agent `dce0f8fd-a030-4fdd-907e-e44e20a70bbf`. That agent is now terminated, but the key is not agent-specific — the same key is reused across the stack. Grep'ed disk locations holding the literal value:

- `/Users/jonathanborgia/foreman-git/foreman-v2/.env` (line `OPENROUTER_API_KEY=…`)
- `~/.openclaw/foreman.json5` — three embedded copies: `env.vars.OPENROUTER_API_KEY`, `models.providers.openrouter.apiKey`, `models.providers.executor.apiKey`
- Hundreds of `~/.openclaw/foreman.json5.bak-*` and `openclaw.json.bak-*` and `openclaw.json.clobbered.*` files from the 2026-04-09 through 2026-04-14 config-write loop (see item 5 below)
- No references in `backend/src/` — all consumption is via `process.env.OPENROUTER_API_KEY` or OpenClaw's provider config

**Why deferred.** The termination of `dce0f8fd` did not reduce exposure because the key lives in 5+ other places. Rotating is a dedicated, ordered workstream, not a mid-session side-quest.

**Done when:**
1. New key generated in OpenRouter dashboard
2. `.env` updated
3. `~/.openclaw/foreman.json5` updated in all three locations
4. `~/.openclaw/foreman.json5.bak-*`, `openclaw.json.bak-*`, and `openclaw.json.clobbered.*` files are either purged (preferred — they're from a resolved config-write bug) or the old key removed from each
5. Old key revoked in OpenRouter
6. Heartbeat runs on CEO and all four specialists confirm the new key works

---

## 2. Diagnose and repair the `foreman.json5` stale `PAPERCLIP_AGENT_ID`

**Scope:** config reconcile.

**Background.** `~/.openclaw/foreman.json5` sets `env.vars.PAPERCLIP_AGENT_ID = "f4d652b8-75b4-4bac-bdfd-a5b75d499ec1"`. That UUID does not match any of the eight Paperclip agents inventoried during Gate A (the canonical CEO is `a7a0b631-1b67-452f-bbd2-ea530fdde75d`). The same stale id is referenced under `plugins.entries.foreman-token-meter.config.paperclipAgentId`.

**Why it matters.** Token-meter plugin and any tool that resolves "my agent id" from this env var points at a ghost. Depending on how the plugin handles a 404 on that id, this could be silently dropping token usage reports or hitting the backend with a bad id.

**Done when:**
- `foreman.json5` points `PAPERCLIP_AGENT_ID` and `plugins.entries.foreman-token-meter.config.paperclipAgentId` at `a7a0b631-1b67-452f-bbd2-ea530fdde75d` (CEO)
- Decision recorded on whether this value should be statically set in config at all, or whether the plugin should resolve it from `GET /api/agents/me` at runtime (Paperclip injects the run JWT; `/agents/me` is the authoritative answer)
- Token-meter heartbeat logs show successful posts against the canonical id

---

## 3. Remove `hire_agent` auto-approve from the provisioning orchestrator

**Scope:** governance correctness.

**Background.** Foreman's provisioning orchestrator `step-6-paperclip-approve.ts` auto-approves hires after Step 5 submits the Paperclip hire request. Paperclip docs say hires go through a board-approval governance gate; auto-approving bypasses it. A temporary caveat block in `config/ceo-workspace/TOOLS.md` (Section 2, "Known limitation (temporary)") documents the deviation.

**Done when:**
- `step-6-paperclip-approve.ts` no longer auto-approves; it waits for a real board-approval callback (or a configured test bypass, clearly gated)
- The caveat block in `config/ceo-workspace/TOOLS.md` is removed
- An e2e test exercises the real board-approval flow for a `hire_agent` call and verifies the CEO wakes on `$PAPERCLIP_APPROVAL_ID`

---

## 4. Build `scripts/configure.sh` repo→live workspace sync

**Scope:** config tooling.

**Background.** `config/ceo-workspace/README.md` declares the repo as the source of truth for the four CEO behavioral files (HEARTBEAT.md, SOUL.md, AGENTS.md, TOOLS.md) and says they should be propagated to `~/.openclaw/workspace-ceo/` via `scripts/configure.sh`. That propagation is currently manual. `scripts/configure.sh` exists but does not today copy these four files from repo to live.

**Done when:**
- `scripts/configure.sh` (or a new script, decision at implementation time) copies the four CEO workspace files from `config/ceo-workspace/` into `~/.openclaw/workspace-ceo/` on each invocation
- Behavior is: overwrite the four named files only, preserve everything else (`IDENTITY.md`, `USER.md`, `memory/`, `BOOTSTRAP.md` etc. — anything bootstrap-created or runtime-mutable)
- A dry-run / diff mode exists so the operator can see what will change before committing
- Equivalent sync exists or is scoped for the four specialist workspaces once their canonical content stabilizes (currently out of scope; specialists are not yet repo-authoritative)

---

## 5. Clean up the `~/.openclaw/` backup-file sprawl

**Scope:** disk hygiene.

**Background.** `~/.openclaw/` contains 1,500+ files matching `openclaw.json.bak-*`, `foreman.json5.bak-*`, and `openclaw.json.clobbered.*`, timestamped 2026-04-08 through 2026-04-14. These came from a config-write loop that was resolved on/around 2026-04-14. They are no longer being generated. Each file likely contains a copy of the exposed OpenRouter key (see item 1) and other secrets.

**Done when:**
- Files archived or purged
- If archived: moved to a single compressed archive outside `~/.openclaw/` (so `openclaw doctor` stops flagging them and provider config lookups don't accidentally read a backup)
- If purged: confirm no in-flight rollback needs them before deletion
- Underlying config-write loop cause is verified fixed (not just quiescent) so the sprawl doesn't regenerate

---

## 6. Reconcile the seven OpenClaw specialist workspace directories against five live Paperclip agents

**Scope:** workspace inventory.

**Background.** `~/.openclaw/` contains seven workspace directories for specialists:
- `workspace-foreman-designer`
- `workspace-foreman-engineer`
- `workspace-foreman-market-research-analyst`
- `workspace-foreman-market-research-specialist`
- `workspace-foreman-marketing-analyst`
- `workspace-foreman-marketing-insights-specialist`
- `workspace-foreman-qa`

But only four live specialists exist in Paperclip after Gate B: Engineer, Designer, QA, MarketingAnalyst. So three directories are orphans (likely `market-research-analyst`, `market-research-specialist`, `marketing-insights-specialist` based on names, but confirm). Additionally, every `IDENTITY.md` in these directories is an unfilled template.

**Done when:**
- Each of the seven workspace directories is either bound to a live Paperclip agent (via `foreman.json5`'s `agents.list[].workspace` field) or archived
- `IDENTITY.md` in each live-bound workspace is filled in using `openclaw agents set-identity --from-identity` or explicit CLI args (name, theme, emoji, avatar), matching the Paperclip agent name
- `openclaw doctor` stops warning about extra workspace directories

---

## 7. Upgrade `@paperclipai/adapter-openclaw-gateway` past PR #1801 and add hooks section to `~/.openclaw/openclaw.json`

**Scope:** platform version tracking.

**Background.** Current installed adapter version is `2026.403.0`, which predates Paperclip PR #1801. The hooks section in `~/.openclaw/openclaw.json` is missing.

**Done when:**
- Adapter upgraded to a version at or after PR #1801
- `hooks` section added to `~/.openclaw/openclaw.json` per upgraded adapter's expected shape
- CEO heartbeat runs successfully against the new adapter; no regressions

---

## 8. Land Stage 1 corrections orchestrator step

**Scope:** corrections system.

**Background.** The provisioning orchestrator's Step 5b is documented in `config/ceo-workspace/TOOLS.md` as creating a `[JOURNAL]` issue, patching `metadata.journal_issue_id`, and inserting a Supabase `sync_cursors` row. Implementation status is unknown from this session's investigation — last known was "pending Cursor work."

**Done when:**
- Step 5b implementation verified in `backend/src/` provisioning orchestrator
- Unit / integration tests cover the journal-issue creation and `sync_cursors` row insert
- Operator runbook references this step as the canonical correction-entry mechanism

---

## 9. Revisit the ClawHub skill audit plan

**Scope:** skill governance.

**Background.** An earlier session produced a `SKILL-AUDIT-PLAN.md` Cursor prompt covering a ClawHub skill-vetting process (anti-hallucination, research, image/video gen, department-specific skill candidates; three-bucket split between skill-candidates, backend-only, and hybrid). The prompt was delivered to Cursor but the resulting `docs/SKILL-AUDIT-PLAN.md` file was never written to disk.

**Done when:**
- Decision: either rewrite and land `SKILL-AUDIT-PLAN.md`, or document that the audit was completed informally and record findings elsewhere
- If rewriting: recover the eight-point vetting checklist and three-bucket split from session history; write to `docs/SKILL-AUDIT-PLAN.md`

---

## Items explicitly NOT on this list

Not because they're unimportant — because they're either already done or are already tracked elsewhere:

- Org-chart normalization (DONE 2026-04-19, Gate B)
- Workspace file swap from drift to Paperclip-native (DONE 2026-04-19, Gate 2)
- Panic-artifact archival in `~/.openclaw/archive/workspace-ceo-panic-artifacts-20260419T171728Z/` (DONE 2026-04-19)
- Terminated-agent cleanup for `44f95028`, `c1a3c80b`, `dce0f8fd`, `60f615b0` (DONE 2026-04-19)
- Behavioral delegation test TEST-1 through TEST-5 (NOT YET RUN — see next session)
- Stale `in_review` Phase 4 dry-run issues FOR-251, FOR-248, FOR-246 (NOT YET CLOSED — see next session)
