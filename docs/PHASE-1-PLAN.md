# Foreman v2 — Phase 1 Plan

**Status:** **Complete** — Phase 1 shipped (**2026-04-08**). All exit criteria **1–10** satisfied; **T7.7** / **T7.8** closeout done (**D19**: RunPod 1-month savings-plan conversion **deferred 1–2 weeks** with recorded revisit window).
**Last updated:** 2026-04-08
**Maintained by:** Jonathan + the PM subagent (`@pm`)

---

## Source of truth

**Build / roadmap:** **Notion** is the **canonical** source for task **status**, **owners**, **dates**, and **dependencies**. This file and other repo docs remain **technical evidence**, **decision logs**, and the **historical Phase 1** record — not the live system of record for who owns what or what is in progress.

- **Hub page:** https://www.notion.so/33c6238cef3e8190b695cb3dde3f9c42
- **Task database:** https://www.notion.so/e202cead847b4cb8b7aa032c7a373daa

**Follow-up (this run):** **Notion** remains **canonical** for status, owners, dates, and dependencies (**D21**). **Notion MCP** was **not available** during reconciliation (**D25**), so this mirror was **not** pushed via automation. **Action:** on the next successful Notion MCP session (or manual pass), align **Notion** to repo evidence: **P2.2**, **P2.4**, **P2.5**, **P2.6**, **P2.7** = **done**; **P2.8** = **done (skipped)** with gate doc `docs/P2.8-JUSTIFICATION-GATE.md`; **P2.3** = **in progress** — **Batch 3 first slice** complete (**B3.1–B3.5**), **immediate next executable** = **Batch 3 wave 2** (hierarchy continuation); batch/reviewer metadata per sections below.

---

## Phase 2 handoff — queued start (2026-04-08)

**Execution queue (priority order)** — **Authoritative in Notion** (see **Source of truth**). This section and `docs/PHASE-2-BACKLOG.md` are **mirrors** for repo continuity; update them via the main Cursor agent when structural changes need to land in git.

### Phase 2 scope boundary (Paperclip path)

- **In Phase 2:** Paperclip installed and integrated **on top of** the Phase 1 stack (OpenClaw + three RunPod pods); **per-role routing** to executor / planner / embedding; **Foreman v1 hierarchy** (CoS → Chiefs → Specialists) as Paperclip agents; **scheduled automation** ported or rebuilt from `foreman/`; **Paperclip company isolation** for per-customer separation; **review-style agents** migrated from Cursor subagents into Paperclip where practical; **anti-hallucination** rules in prompts/review loops; **extra model roles** only when a concrete Phase 2 agent needs them (document the justification).
- **Out of Phase 2 (Phase 3+):** Frontend reskin, non-technical onboarding wizard, social publishing pipeline, hosted-gateway / remote-access **polarity** work (**Phase 3** per **D15** and deferred-work list); Stripe/billing, marketing site, support ops, broad analytics (**Phase 4+**). Do not fold these into Phase 2 unless recorded as a **new decision** superseding this boundary.

### Phase 2 task queue

**Mirror / snapshot from Notion:** Rows **P2.2–P2.8** below reflect a **repo copy** of the canonical task database; for live status, owners, and dates, use Notion (**Source of truth**). **P2.1** is retained in the table as a **completed** checkpoint with local evidence in this file.

| ID | Task | Status | Depends on | Notes |
|---|---|---|---|---|
| P2.1 | Paperclip install + baseline integration with OpenClaw | done | Phase 1 complete | Pin versions; document install path; prove co-existence with gateway + pods |
| P2.2 | Per-role routing across executor / planner / embedding | done | P2.1 | **Batch 1** and **Batch 2** completed with reviewer gates and evidence artifacts (`state/p2.2-role-verifier.json`, `state/p2.2-routing-consistency.json`). |
| P2.3 | Recreate v1 hierarchy (CoS → Chiefs → Specialists) in Paperclip | in progress | P2.2 | **Batch 3 — first slice** complete (**B3.1–B3.5**); **P2.3** **not** closed — **Batch 3 wave 2** (hierarchy continuation) is **next executable** (see **Batch 3**). Evidence paths in **Batch 3** section. |
| P2.4 | Anti-hallucination policy + review loops | done | P2.1 (minimal agent shell) | **Batch 4** complete (**B4.1–B4.6**); evidence `docs/P2.4-BATCH-4-ANTI-HALLUCINATION-POLICY.md`; reviewer gates recorded below. |
| P2.5 | Port or rebuild scheduled task automation from `foreman/` | done | P2.3 far enough for triggers | **Batch 5** (**B5.1–B5.6**) complete with evidence and reviewer gates; see Batch 5 closeout section. |
| P2.6 | Multi-tenancy / Paperclip company isolation | done | P2.1 | **Batch 6** complete with isolation contract, pilot verification, runbook, and reviewer gates. |
| P2.7 | Migrate Cursor review subagents → Paperclip-managed agents | done | P2.3 + P2.6 (partial) | **Batch 7** completed with reviewer mapping, Paperclip skeletons, routing contract, proof run, and gate outcomes. |
| P2.8 | Additional model roles (router, coder, etc.) | done (skipped) | Explicit agent need + justification | Justification gate executed; no qualifying trigger found (`docs/P2.8-JUSTIFICATION-GATE.md`). |

**Critical path:** **P2.1 → P2.2** (**done**) → **P2.3** (**in progress**; **Batch 3 first slice** complete, **wave 2** next). **P2.4–P2.7** **done**. **P2.8** **done (skipped)** — justification gate only (`docs/P2.8-JUSTIFICATION-GATE.md`); no extra model roles without trigger.

**Immediate next task:** **P2.3 — Batch 3 wave 2** (**hierarchy continuation**): expand CoS → Chiefs → Specialists beyond the first-slice skeleton per **Batch loop protocol** (evidence + four reviewer gates + **`@pm`** handoff). **Live status, owners, and dates:** **Notion** (**Source of truth**); **Notion MCP unavailable** this run — sync **Notion** to this mirror when MCP or manual pass is available (**Source of truth** follow-up, **D25**).

### Batch loop protocol (Phase 2)

**Canonical status** for who owns what and what is **in progress** / **done** remains **Notion** (**Source of truth**, **D21**). This file holds **technical evidence**, **batch structure**, **decision log**, and **mirrored** Phase 2 queue rows when helpful.

1. **PM handoff after each batch:** When a Phase 2 **batch** reaches **done**, immediately invoke **`@pm`** (project-manager) to queue and record the **next** batch — update this plan’s mirror (task notes, immediate next task) and confirm **Notion** reflects the closed batch and the opened next work.
2. **Mandatory reviewer gates (every batch):** Before marking any batch **done**, run the four read-only review subagents on in-scope artifacts for that batch: **`@script-auditor`**, **`@cost-infra-reviewer`**, **`@license-reviewer`**, **`@phase-boundary-keeper`**. Findings must be **resolved**, **explicitly accepted with rationale**, or **deferred with a logged decision** (same discipline as Phase 1 exit criterion **8**).
3. **Completion criteria before advancing a batch:** (a) Every task in the batch meets its stated **Done when** criteria; (b) **evidence** is captured where agreed (repo paths and/or Notion); (c) **all four** reviewer gates above have a recorded outcome for the batch; (d) **`@pm`** updates this file’s mirror and confirms **Notion** shows the batch **done** and the next executable work **queued**.
4. **If Notion MCP (or equivalent) is unavailable:** **`@pm`** still updates this file and records a **follow-up sync** action in **Source of truth** and/or the **decision log**; human or later MCP session aligns **Notion** — canonicality of **Notion** is unchanged; only the sync mechanism is delayed.

### Batch 1 (P2.2 — per-role routing)

Concrete work for **P2.2** (single source of truth: which pod serves executor / planner / embedding). **Done criteria** below are batch-local; **P2.2** is **done** only after the **agreed P2.2 batch sequence** (currently **Batch 1** + **Batch 2**) each satisfies the **Batch loop protocol** (including reviewer gates + **`@pm`** handoff).

| ID | Task | Done when |
|---|---|---|
| B1.1 | **Routing inventory & target map** | Documented matrix of current vs desired bindings (OpenClaw providers, Paperclip model/agent bindings, gateway paths). Agreed location (Notion page and/or repo doc) is linked from **Notion** task **P2.2** and, if mirrored, noted here. |
| B1.2 | **Single source of truth** | One authoritative config or contract (no conflicting duplicates) defines how each **role** resolves to **executor** / **planner** / **embedding** pod endpoints; checked in or procedural steps are reproducible. |
| B1.3 | **Wire runtime routing** | Runtime paths use **B1.2**: default chat → executor; planning/reasoning → planner; embedding/RAG → embedding. |
| B1.4 | **Verification & failure behavior** | At least **one** successful trace per role (logs, run IDs, or equivalent) proving correct pod; **one** deliberate misconfiguration or negative test proving **loud** failure (no silent fallback to wrong pod). |
| B1.5 | **Evidence, mirror, and batch closeout** | Evidence artifacts referenced from **Notion**; repo technical notes updated if required for audit. **`@script-auditor`**, **`@cost-infra-reviewer`**, **`@license-reviewer`**, **`@phase-boundary-keeper`** complete for Batch 1 scope; **`@pm`** records batch **done** and queues **next** batch per protocol. |

**Batch 1 status:** **done** (**2026-04-08**).

**B1.1–B1.5 evidence (repo mirror):**

- **B1.1 — done:** Routing inventory + target map in `docs/P2.2-BATCH-1-ROUTING-MAP.md` (current vs desired bindings; gap callouts).
- **B1.2 — done:** Checked-in contract `config/role-routing.json` (`source_of_truth`: Phase 2 P2.2 role routing contract); resolves roles to providers/models with `base_url_source: state/pods.json`.
- **B1.3 — done:** Runtime dispatch `scripts/paperclip-role-dispatch.sh` reads `role-routing.json`, resolves URLs/API keys from `state/pods.json` + `~/.openclaw/openclaw.json`, implements **executor** (`openclaw_agent`), **planner** (`openai_chat` → `/chat/completions`), **embedding** (`openai_embeddings` → `/embeddings`).
- **B1.4 — done:** Per-role success path via dispatch script outputs `HEARTBEAT_OK:executor|planner|embedding`; **loud failure** on unknown role, missing pod, missing provider key, HTTP non-2xx, invalid embedding payload, and OpenClaw silent-fallback strings (`falling back to embedded`, `No reply from agent.`).
- **B1.5 — done:** Evidence consolidated above; **`@pm`** batch closeout = this update + **Batch 2** queued below.

**Batch 1 reviewer gates (2026-04-08):**

| Gate | Outcome | Notes |
|---|---|---|
| **`@script-auditor`** | **Signed off** | Batch 1 shell/Python paths for `paperclip-role-dispatch.sh` accepted for scope. |
| **`@cost-infra-reviewer`** | **PASS_WITH_NOTES** | No new pod/SKU changes in Batch 1; notes as surfaced in review (cost posture unchanged vs Phase 1 roster). |
| **`@license-reviewer`** | **PASS_WITH_NOTES** | No new third-party surfaces requiring attribution beyond existing Phase 1 baseline; notes only. |
| **`@phase-boundary-keeper`** | **PASS_WITH_NOTES** | Batch 1 stays within **P2.2** (routing contract + dispatch); no **P2.3** hierarchy or **P2.6** tenancy scope creep. |

### Batch 2 (P2.2 — per-role routing, integration hardening)

**Batch 2 status:** **done** (**2026-04-08**).

**B2.1–B2.5 evidence (repo mirror):**

- **B2.1 — done:** Paperclip agents bound to `scripts/paperclip-role-dispatch.sh` with role-specific `PAPERCLIP_ROLE` (`executor`, `planner`, `embedding`).
- **B2.2 — done:** `scripts/verify-paperclip-role-routing.sh` added and executed successfully; evidence in `state/p2.2-role-verifier.json`.
- **B2.3 — done:** `scripts/check-role-routing-consistency.sh` added and executed successfully; evidence in `state/p2.2-routing-consistency.json`.
- **B2.4 — done:** operator runbook section added to `README.md` under `Phase 2 P2.2 Routing Ops`.
- **B2.5 — done:** reviewer gates completed (below); PM loop advanced to next batch.

**Batch 2 reviewer gates (2026-04-08):**

| Gate | Outcome | Notes |
|---|---|---|
| **`@script-auditor`** | **SIGNED_OFF** | Routing dispatch and verifier scripts signed off after hardening fixes. |
| **`@cost-infra-reviewer`** | **APPROVED** | No new persistent infra or pod-count drift; notes only on usage frequency awareness. |
| **`@license-reviewer`** | **COMPLIANT WITH NOTES** | No blocking licensing/trademark issues for routing artifacts. |
| **`@phase-boundary-keeper`** | **IN SCOPE** | Work remained in P2.2 routing scope; no P2.3+ creep. |

### Batch 3 (P2.3 — hierarchy rebuild, first slice)

| ID | Task | Done when |
|---|---|---|
| B3.1 | **Hierarchy inventory from foreman/v1** | A mapped list of CoS -> Chiefs -> Specialists roles is captured with first migration slice selected. |
| B3.2 | **Paperclip org skeleton creation** | Minimal manager/report chain is created in Paperclip for the selected slice with clear role ownership. |
| B3.3 | **Prompt and responsibility boundaries** | Each migrated role has scoped responsibilities and non-overlapping execution boundaries documented. |
| B3.4 | **Single delegated workflow proof** | One end-to-end delegated workflow succeeds through the new hierarchy slice with visible handoff evidence. |
| B3.5 | **Reviewer gates + PM closeout** | All four reviewer gates complete; PM queues next batch per loop protocol and updates mirror status. |

**Batch 3 — first slice progress snapshot (2026-04-08):**

- **B3.1 — done (first slice):** hierarchy inventory and first-slice selection documented in `docs/P2.3-BATCH-3-HIERARCHY-INVENTORY.md`.
- **B3.2 — done (first slice):** Paperclip org skeleton created (`CEO -> ChiefOfStaff -> EngineeringBuilder/DevOpsAgent/QAEngineer`).
- **B3.3 — done (first slice):** role boundaries documented in `docs/P2.3-BATCH-3-ROLE-BOUNDARIES.md`.
- **B3.4 — done (first slice):** delegated workflow proof captured (`FOR-3` parent, `FOR-4` child, run `42716d3a-802b-4216-b215-c87466194f04`, evidence `state/p2.3-delegation-proof.json`).
- **B3.5 — done (first slice):** reviewer gates complete for the **first slice**; **not** a full **P2.3** closeout — **wave 2** queued per **D25**.

**Batch 3 status:** **wave 2 in progress** (**2026-04-08**). First slice is complete; wave 2 chief-layer expansion has started.

**Batch 3 — wave 2 (next executable, P2.3):** Continue **Foreman v1** hierarchy recreation in Paperclip beyond the first slice; treat as the next batched increment under the **Batch loop protocol** (define slice scope in **Notion** + evidence paths here when wave 2 closes).

**Wave 2 progress snapshot (2026-04-08):**

- Added chief-layer agents under `ChiefOfStaff`: `ProductLeadChief`, `LegalComplianceChief`, `FinanceChief`, `GrowthChief`.
- Captured successful heartbeat proof runs for all four chiefs in `state/p2.3-wave2-proof.json`.
- Documented wave 2 expansion in `docs/P2.3-BATCH-3-WAVE2-HIERARCHY.md`.

**Human decisions before P2.1:** authoritative Paperclip **install/source + version pin**; whether the **first vertical slice** is single-operator (defer full **P2.6** enforcement) or multi-tenant from day one; **ownership boundary** between OpenClaw config/process model and Paperclip (what each layer owns at runtime). *(Historical — **P2.1** **done**.)*

### Batch 4 (P2.4 — anti-hallucination policy + review loops)

| ID | Task | Done when |
|---|---|---|
| B4.1 | **Policy scope, definitions, and enforcement boundaries** | Document states what counts as hallucination risk, which roles/contexts are in scope, and what “compliant output” means for Foreman v2 Phase 2. |
| B4.2 | **Grounding and tool-use rules** | Rules for when agents must use tools vs. answer from context; no silent invention of facts, URLs, or file paths. |
| B4.3 | **Uncertainty, citation, and refusal language** | Standard phrasing for “unknown,” mandatory citations where applicable, and explicit refusal rather than fabrication. |
| B4.4 | **Review-loop triggers and escalation** | Document defines when output is blocked, sent for human or reviewer-agent check, or retried with constraints. |
| B4.5 | **Prompt / agent instruction alignment** | Policy is reflected in agreed agent prompts, templates, or instruction bundles (checked in or linked from the evidence doc). |
| B4.6 | **Evidence, mirror, and batch closeout** | Consolidated evidence path below; all four reviewer gates recorded; **`@pm`** queues **Batch 5** per protocol. |

**Batch 4 status:** **done** (**2026-04-08**).

**B4.1–B4.6 evidence (repo mirror):** All batch tasks satisfied by **`docs/P2.4-BATCH-4-ANTI-HALLUCINATION-POLICY.md`** (full path for local reference: `/Users/jonathanborgia/foreman-git/foreman-v2/docs/P2.4-BATCH-4-ANTI-HALLUCINATION-POLICY.md`).

**Batch 4 reviewer gates (2026-04-08):**

| Gate | Outcome | Notes |
|---|---|---|
| **`@script-auditor`** | **FINDINGS** | **File-path visibility issue** in this run; **accepted with rationale** — Batch 4 changed **docs only** (no script changes); no script re-audit required for scope. |
| **`@cost-infra-reviewer`** | **APPROVED** | |
| **`@license-reviewer`** | **COMPLIANT / PASS_WITH_NOTES** | |
| **`@phase-boundary-keeper`** | **IN_SCOPE** | |

### Batch 5 (P2.5 — scheduled task automation port/rebuild)

**Batch goal:** Port or rebuild the legacy **~63** scheduled agent tasks from `foreman/` onto the Phase 2 stack (Paperclip + agreed scheduler/trigger mechanism), with a repeatable pattern for the long tail.

**Batch 5 done when (whole batch):** (a) **B5.1–B5.5** meet their row **Done when** criteria with **repo and/or Notion** evidence; (b) **B5.6** reviewer gates + PM closeout complete; (c) at least **one** pilot automation is **production-shaped** (not a one-off demo); (d) remaining work is **explicitly batched** (e.g. P2.5a/P2.5b) or deferred with a logged decision if scope explodes.

| ID | Task | Done when |
|---|---|---|
| B5.1 | **Legacy scheduler inventory** | All scheduled/triggered paths in `foreman/` are enumerated (cron, workers, queues, dashboards): **what** runs, **how often**, **inputs/outputs**, and **owner agent or script**; gaps named. |
| B5.2 | **Target architecture on Paperclip** | Written design for how schedules live in Phase 2 (Paperclip routines/triggers vs. external cron + API, secrets, idempotency, failure alerts); agreed with **Notion** task **P2.5**. |
| B5.3 | **Pilot port (1–3 tasks)** | Representative tasks run end-to-end on the new mechanism with **evidence** (run IDs, logs, or `state/*.json` as appropriate); loud failure on misconfiguration. |
| B5.4 | **Operator harness + dry-run** | Script(s) or documented procedure to validate schedule definitions, dry-run or sandbox execution, and rollback/cancel path. |
| B5.5 | **Remaining backlog plan** | The rest of the ~63 tasks are grouped into **waves** or **split tasks** (e.g. **P2.5a** / **P2.5b**) with rough ordering and risk flags; no silent scope creep into **P2.6** / **P2.7** without **Phase Boundary Keeper** + decision log. |
| B5.6 | **Reviewer gates + PM closeout** | **`@script-auditor`**, **`@cost-infra-reviewer`**, **`@license-reviewer`**, **`@phase-boundary-keeper`** outcomes recorded; **`@pm`** updates this mirror and confirms **Notion** reflects Batch 5 status and next work. |

**Batch 5 status:** **done** (**2026-04-08**).

**B5.1–B5.6 evidence (repo mirror):**

- **B5.1 — done:** legacy scheduler inventory in `docs/P2.5-BATCH-5-SCHEDULER-INVENTORY.md`.
- **B5.2 — done:** target scheduler contract in `docs/P2.5-BATCH-5-TARGET-SCHEDULER-ARCHITECTURE.md`.
- **B5.3 — done:** pilot scheduler path via `scripts/paperclip-scheduler-pilot.sh`.
- **B5.4 — done:** validation harness via `scripts/validate-scheduler-pilot.sh`.
- **B5.5 — done:** backlog split plan in `docs/P2.5-BATCH-5-BACKLOG-SPLIT.md`.
- **B5.6 — done:** reviewer gates complete; pilot evidence in `state/p2.5-pilot-run.json`.

**Batch 5 reviewer gates (2026-04-08):**

| Gate | Outcome | Notes |
|---|---|---|
| **`@script-auditor`** | **SIGNED_OFF** | Pilot + validator scripts signed off after auth/error-handling hardening. |
| **`@cost-infra-reviewer`** | **APPROVED WITH NOTES** | No persistent infra drift; usage-frequency notes only. |
| **`@license-reviewer`** | **COMPLIANT WITH NOTES** | No blocking trademark/licensing findings in Batch 5 artifacts. |
| **`@phase-boundary-keeper`** | **IN SCOPE** | Scheduler pilot remains in P2.5 scope. |

### Batch 6 (P2.6 — multi-tenancy/company isolation)

| ID | Task | Done when |
|---|---|---|
| B6.1 | **Isolation requirements + threat model** | Tenant boundary requirements and failure modes are documented and agreed for Paperclip/OpenClaw execution paths. |
| B6.2 | **Company context propagation contract** | One documented source-of-truth for company/tenant identity propagation across API, runtime, and storage paths. |
| B6.3 | **Config/state separation plan** | Shared vs tenant-scoped config/state boundaries are explicitly defined with migration notes. |
| B6.4 | **Pilot tenant-isolation verification path** | A reproducible validation path proves one tenant cannot access another tenant scope; failure path is loud. |
| B6.5 | **Operator runbook and rollback** | Operators have clear isolation verification, incident response, and rollback guidance. |
| B6.6 | **Reviewer gates + PM closeout** | All four reviewer outcomes are recorded and next batch is queued via PM loop protocol. |

**Batch 6 status:** **done** (**2026-04-08**).

**B6.1–B6.6 evidence (repo mirror):**

- **B6.1/B6.2/B6.3 — done:** isolation requirements, context propagation contract, and config/state separation documented in `docs/P2.6-BATCH-6-ISOLATION-CONTRACT.md`.
- **B6.4 — done:** isolation pilot verification via `scripts/verify-tenant-isolation-pilot.sh`; evidence in `state/p2.6-isolation-pilot.json`.
- **B6.5 — done:** operator runbook and rollback in `docs/P2.6-BATCH-6-OPERATOR-RUNBOOK.md`.
- **B6.6 — done:** reviewer gate sweep completed; queue advanced to P2.7.

**Batch 6 reviewer gates (2026-04-08):**

| Gate | Outcome | Notes |
|---|---|---|
| **`@script-auditor`** | **FINDINGS (accepted)** | Non-blocking cleanup/shape warnings accepted for pilot scope; script remains failure-loud and tested. |
| **`@cost-infra-reviewer`** | **APPROVED WITH NOTES** | No persistent infra drift; tenant-test object lifecycle notes only. |
| **`@license-reviewer`** | **COMPLIANT** | No blocking attribution/trademark issues in Batch 6 artifacts. |
| **`@phase-boundary-keeper`** | **IN SCOPE** | Work remained in P2.6 isolation scope. |

### Batch 7 (P2.7 — reviewer agent migration parity)

| ID | Task | Done when |
|---|---|---|
| B7.1 | **Reviewer mapping inventory** | Existing Cursor reviewer gates and target Paperclip agent mappings are documented. |
| B7.2 | **Paperclip reviewer skeletons** | Reviewer agent skeletons exist in Paperclip org with defined ownership chain. |
| B7.3 | **Gate routing contract** | One routing/invocation contract defines outcome tokens and batch closure rules. |
| B7.4 | **Reviewer proof run** | One full reviewer-run proof succeeds with evidence artifact in `state/`. |
| B7.5 | **Reviewer gates + PM closeout** | Four reviewer outcomes are recorded; PM queues next batch per loop protocol. |

**Batch 7 progress snapshot (2026-04-08):**

- **B7.1 — done:** mapping inventory in `docs/P2.7-BATCH-7-REVIEWER-MAPPING.md`.
- **B7.2 — done:** reviewer skeleton agents created (`ReviewScriptAuditor`, `ReviewCostInfra`, `ReviewLicense`, `ReviewPhaseBoundary`).
- **B7.3 — done:** gate routing contract in `docs/P2.7-BATCH-7-GATE-ROUTING-CONTRACT.md`.
- **B7.4 — done:** reviewer proof artifact in `state/p2.7-reviewer-proof.json`.
- **B7.5 — done:** reviewer gate sweep complete and closeout recorded in this mirror.

**Batch 7 reviewer gates (2026-04-08):**

| Gate | Outcome | Notes |
|---|---|---|
| **`@script-auditor`** | **FINDINGS (accepted)** | Non-blocking warnings on reviewer-proof contract/parity details; accepted with rationale for parity-slice scope. |
| **`@cost-infra-reviewer`** | **APPROVED WITH NOTES** | No persistent infra drift; reviewer-run usage notes only. |
| **`@license-reviewer`** | **COMPLIANT WITH NOTES** | No blocking license/trademark issues in Batch 7 artifacts. |
| **`@phase-boundary-keeper`** | **IN SCOPE** | Batch 7 remains in P2.7 migration scope. |

### P2.1 execution checklist (complete)

- [x] **Contract lock:** Confirm Paperclip install/source and version pin; record it in docs.
- [x] **Environment/secrets inventory:** List required env vars/secrets and create/update redacted template guidance.
- [x] **Install baseline:** Install Paperclip and verify basic runtime health on this machine.
- [x] **OpenClaw integration seam:** Wire OpenClaw to Paperclip at the agreed boundary (no Phase 2 routing yet).
- [x] **Smoke proof:** Run one minimal end-to-end interaction through the Paperclip-integrated path and capture evidence.
- [x] **Failure behavior check:** Verify failure mode is loud (no silent fallback) for the minimal P2.1 path.
- [x] **Close P2.1:** Record artifacts/notes and mark P2.1 done once all checks pass.

### P2.1 evidence snapshot (2026-04-08)

- **Local Paperclip baseline:** `paperclipai@2026.403.0` onboarded and running locally in isolated instance `foreman-p21` (`/api/health` reported `deploymentMode=local_trusted`, HTTP 200 on `http://127.0.0.1:3110`).
- **RunPod wiring path:** Paperclip agents switched from local coding adapters to `process` adapter invoking `scripts/paperclip-openclaw-worker.sh`, which calls OpenClaw gateway (already configured to the three RunPod pods).
- **Successful proof runs:** OpenClaw worker run `ee97b599-475d-41d0-895b-478bee5b3d84` and CEO run `14582c91-7c68-42e0-9c2f-9f3cf6f9668d` completed with `HEARTBEAT_OK`.
- **Failure-loud proof:** forced invalid gateway override (`OPENCLAW_GATEWAY_URL=http://127.0.0.1:9`) produced failed run `11c1d128-82d3-4d27-a98c-3d2b9cf24c71` with explicit stderr `ERROR: OpenClaw gateway path failed; refusing silent fallback.`
- **Artifacts:** `state/p2.1-openclawworker-success-final.json`, `state/p2.1-ceo-runpod-run.json`, `state/p2.1-failure-loud-final.json`.

---

## Phase 1 in one sentence

Stand up OpenClaw locally, wired to three always-on RunPod Secure Cloud pods (executor, planner, embedding), with WebChat routing through the executor cleanly, proven by `./scripts/smoke-test.sh` returning exit 0 against real infrastructure.

## Phase 1 exit criteria

Phase 1 is complete when **all** of the following are true:

1. `foreman-v2/scripts/provision.sh` has been run successfully against RunPod Secure Cloud, creating three pods (executor, planner, embedding) on cheapest-acceptable Secure Cloud SKUs.
2. `foreman-v2/state/pods.json` accurately reflects the three running pods with their pod IDs, proxy URLs, GPU types, hourly rates, and provisioned timestamps.
3. `foreman-v2/scripts/configure.sh` has been run successfully, writing a valid OpenClaw config to `~/.openclaw/openclaw.json` that points at all three pods, with reachability checks passing for each.
4. The OpenClaw gateway daemon starts cleanly and serves the WebChat UI on its default port.
5. `foreman-v2/scripts/smoke-test.sh` exits 0, with all three sub-tests passing:
   - Executor test: PONG returned via OpenClaw chat (validates the executor pod and the OpenClaw routing)
   - Planner test: non-empty reasoning response from the planner pod via raw HTTP
   - Embedding test: non-empty vector array from the embedding pod via raw HTTP
6. A human can open the WebChat URL in a browser and have a multi-turn conversation with the agent, with responses that are clearly coming from Qwen3-14B-AWQ via the RunPod executor pod (not from Anthropic, OpenAI, or any other backend).
7. `foreman-v2/scripts/teardown.sh` has been verified to work (either by being tested in a controlled run, or by being audited and found to be correct without being run, with the user accepting the audit-only verification).
8. All four review subagents (Script Auditor, Cost & Infra Reviewer, License & Attribution Reviewer, Phase Boundary Keeper) have been used at least once on Phase 1 work and their findings have been addressed.
9. `foreman-v2/THIRD_PARTY_NOTICES.md` exists and correctly attributes OpenClaw under MIT.
10. `foreman-v2/docs/PHASE-2-BACKLOG.md` exists and contains all deferred work from Phase 1.

When all ten are true, Phase 1 ships. Anything else can be deferred to Phase 2 or later.

**Progress snapshot (2026-04-08 — final):** Items **1–10** of the exit criteria are satisfied: **1–6** as before (including **T6.4** / **T6.5**); **7** via audit (**T3.7**); **8** via Script Auditor + **T3.6** (Cost & Infra, PASS_WITH_NOTES) + **T7.2** (License, PASS_WITH_NOTES) + **T7.6** (Phase Boundary Keeper, PASS_WITH_NOTES); **9** via **T7.1** (`THIRD_PARTY_NOTICES.md` with OpenClaw MIT); **10** via **T7.3** (`docs/PHASE-2-BACKLOG.md`). **T7.4** / **T7.5** doc sync complete (live roster, ~**$0.96/hr**, planner model + vLLM / Mode D–E narrative corrections; **PHASE-1-SPIKE** aligned). **T7.8** **done** — savings-plan conversion **deferred 1–2 weeks** per **D19** (revisit ~**2026-04-15–2026-04-22**). **T7.7** **done** — plan header set to **Complete**; Phase 1 officially closed.

---

## Phase 1 task list

Tasks are organized into seven clusters. Status values: `not started`, `in progress`, `blocked`, `done`. Blockers are listed inline.

### Cluster 1: Foreman v2 directory scaffolding

**Goal:** The `foreman-v2/` directory exists alongside the existing `foreman/` directory, with the basic structure in place: scripts, config, docs, state directory, gitignore, env example, README.

| ID | Task | Status | Notes |
|---|---|---|---|
| T1.1 | Create `foreman-v2/` sibling directory | done | Created in original Phase 1 attempt |
| T1.2 | Create `scripts/`, `config/`, `docs/`, `state/` subdirectories | done | |
| T1.3 | Create `.env.example` with RunPod API key var name reused from `foreman/.env.local` | done | |
| T1.4 | Create `.gitignore` excluding `.env`, `state/pods.json`, `state/logs/` | in progress | `state/logs/` may need to be added if Cursor's blocker fix introduces a logs directory for sanitized error responses |
| T1.5 | Create initial `README.md` with project overview, prerequisites, setup instructions | done | |
| T1.6 | Verify `foreman/` directory remains byte-identical (no accidental modifications) | done | Last verified after the corrective Phase 1 work |

### Cluster 2: OpenClaw install and base configuration

**Goal:** OpenClaw is installable via the script, and a config template exists that defines three custom OpenAI-compatible providers (one per pod). The template uses placeholder URLs that `configure.sh` fills in from `state/pods.json`.

| ID | Task | Status | Notes |
|---|---|---|---|
| T2.1 | Write `scripts/install.sh` (installs OpenClaw globally via npm, runs onboard) | done | Known issue: `openclaw onboard --install-daemon` is interactive in current OpenClaw version; manual completion required |
| T2.2 | Write `config/openclaw.foreman.json` template with three providers (executor, planner, embedding) | done | Uses `gateway.mode: "local"` and `gateway.bind: "loopback"` defaults discovered during Phase 1 |
| T2.3 | Write `scripts/configure.sh` that reads `state/pods.json`, substitutes URLs, writes `~/.openclaw/openclaw.json` with backup of any existing file | done | Fails loudly if `state/pods.json` is missing — verified in dry-run |
| T2.4 | Write `scripts/start.sh` and `scripts/stop.sh` for the OpenClaw gateway lifecycle | done | |
| T2.5 | Audit `configure.sh` with Script Auditor | not started | Lower priority than `provision.sh` audit; can run after T3.5 |
| T2.6 | Run `configure.sh` against real `state/pods.json` | done | Ran successfully after live roster; reachability checks passed (see T6.1) |

### Cluster 3: RunPod three-pod provisioning scripts

**Goal:** `provision.sh` and `teardown.sh` are correct, audited, and ready to run against RunPod Secure Cloud. The provision script handles the five-mode failure decision tree, has a Ctrl+C handler installed before any pod creation, has a credit balance pre-flight check, writes to `state/pods.json` incrementally, and is idempotent on rerun.

| ID | Task | Status | Notes |
|---|---|---|---|
| T3.1 | Write initial `scripts/provision.sh` with five-mode failure handling, credit check, SKU verification, cost printing | done | Initial draft from corrective Phase 1 prompt |
| T3.2 | Write initial `scripts/teardown.sh` as the kill switch | done | Initial draft from corrective Phase 1 prompt |
| T3.3 | Run Script Auditor on `provision.sh` (first pass) | done | Found 4 BLOCKERS, several WARNINGS — see decision log entry D14 |
| T3.4 | Apply Script Auditor's blocker fixes to `provision.sh` | done | Blocker fixes and hardening applied; aligns with post-audit provisioning behavior. |
| T3.5 | Re-run Script Auditor on the patched `provision.sh` | done | Script Auditor signed off after patch cycle (provisioning hardening). |
| T3.6 | Run Cost & Infra Reviewer on `provision.sh` | done | **Verdict:** PASS_WITH_NOTES — no script blockers; `docs/INFERENCE-ENDPOINTS.md` and related cost/roster narrative corrected in same closeout pass. Satisfies exit criterion **8** (Cost & Infra used on Phase 1 work). |
| T3.7 | Run Script Auditor on `teardown.sh` | done | Script Auditor signed off on teardown hardening; satisfies Phase 1 exit criterion 7 via audit path (no controlled live teardown run required for this spike). |
| T3.8 | Make `provision.sh` idempotent (rerunning skips already-provisioned pods, attempts only the missing ones) | done | Delivered and exercised as part of provision hardening / successful roster bring-up. |
| T3.9 | Mock `state/pods.json` verification of `configure.sh` and `smoke-test.sh` parsing/templating | not started | Optional hardening; live `configure.sh` + `smoke-test.sh` already validated against real `state/pods.json`. |
| T3.10 | Final review pass before first real run | done | Script Auditor sign-off on provision + teardown; first real run executed successfully. |

### Cluster 4: Subagent-based review pipeline

**Goal:** The five subagents (Script Auditor, Cost & Infra Reviewer, License & Attribution Reviewer, Phase Boundary Keeper, PM) are installed in `.cursor/agents/`, smoke-tested, and being used on Phase 1 work as appropriate.

| ID | Task | Status | Notes |
|---|---|---|---|
| T4.1 | Create `.cursor/agents/script-auditor.md` | done | First successful use revealed real bugs in `provision.sh` |
| T4.2 | Create `.cursor/agents/cost-infra-reviewer.md` | done | Agent exists; **T3.6** complete (PASS_WITH_NOTES). |
| T4.3 | Create `.cursor/agents/license-reviewer.md` | done | Invoked for **T7.2** (PASS_WITH_NOTES). |
| T4.4 | Create `.cursor/agents/phase-boundary-keeper.md` | done | Invoked for **T7.6** (PASS_WITH_NOTES). |
| T4.5 | Create `.cursor/agents/pm.md` (this agent) | done | PM subagent in use; canonical plan maintenance active |
| T4.6 | Smoke-test each subagent by name to verify the system prompt loaded | partial | Script Auditor, Cost & Infra (**T3.6**), License (**T7.2**), and Phase Boundary Keeper (**T7.6**) all produced real Phase 1 reviews (PASS_WITH_NOTES where noted). Exhaustive “smoke every agent by name” not required for Phase 1 exit. |
| T4.7 | Verify `.cursor/agents/` is committed to git and not gitignored | not started | Needs explicit `!.cursor/agents/` in `.gitignore` if `.cursor/*` is excluded |
| T4.8 | Document the subagent workflow in `docs/SUBAGENT-WORKFLOW.md` so future-you (or future contributors) know which agent to invoke when | not started | Lower priority — Phase 1 complete; optional Phase 2+ |

### Cluster 5: First successful provisioning run

**Goal:** Execute `provision.sh` against RunPod Secure Cloud and end up with three healthy pods, with `state/pods.json` accurately recording them. This is the moment Phase 1 either works or doesn't.

| ID | Task | Status | Notes |
|---|---|---|---|
| T5.1 | Run `./scripts/provision.sh` for the first time | done | Live Secure Cloud roster provisioned successfully. |
| T5.2 | Verify `state/pods.json` reflects three pods correctly | done | Three pods recorded; IDs: executor `fm043taeerxjo2`, planner `tko1uoa413myi6`, embedding `xfz6l2tqiw5sf8`. |
| T5.3 | Verify all three pods are reachable via their proxy URLs and serving the expected models | done | **Official HF models only:** executor `Qwen/Qwen3-14B-AWQ` (pod `fm043taeerxjo2`, NVIDIA RTX A4500, EU-RO-1); planner `Qwen/Qwen3-30B-A3B-Instruct-2507` (pod `tko1uoa413myi6`, NVIDIA A40, EU-SE-1); embedding `Qwen/Qwen3-Embedding-8B` (pod `xfz6l2tqiw5sf8`, NVIDIA RTX A5000, CA-MTL-1). Smoke + configure green. |
| T5.4 | Note the actual hourly cost of the provisioned pods (vs. the estimate) and update the cost projection in `docs/INFERENCE-ENDPOINTS.md` if it drifted | done | Observed ~$0.25/hr executor + ~$0.44/hr planner + ~$0.27/hr embedding ≈ **~$0.96/hr** combined. **T7.4** synced **INFERENCE-ENDPOINTS** to this roster/cost baseline (planner model, runtime flags, Mode D/E behavior). |

### Cluster 6: Smoke test against real pods

**Goal:** Run the full smoke test against the live pods and confirm OpenClaw chat round-trips through the executor pod, the planner pod responds to reasoning prompts, and the embedding pod returns valid vectors.

| ID | Task | Status | Notes |
|---|---|---|---|
| T6.1 | Run `./scripts/configure.sh` to write the live config | done | Succeeded against live `state/pods.json`; reachability checks passed. |
| T6.2 | Run `./scripts/start.sh` to launch the OpenClaw gateway | done | Gateway path exercised for end-to-end smoke (OpenClaw routing / executor PONG path). |
| T6.3 | Run `./scripts/smoke-test.sh` and verify exit 0 | done | **Exit 0;** executor, planner, and embedding sub-tests all green (automated signal). |
| T6.4 | Open WebChat in a browser and have a multi-turn conversation with the agent | done | Human WebChat validation confirmed working in browser (multi-turn pass recorded). |
| T6.5 | Verify responses are clearly coming from Qwen3-14B-AWQ via RunPod (not Anthropic, OpenAI, or any other backend) | done | WebChat responses verified on executor model path (`Qwen/Qwen3-14B-AWQ` via RunPod). |

### Cluster 7: Documentation cleanup and Phase 1 closeout

**Goal:** Documentation reflects what was actually built, all attribution is correct, the Phase 2 backlog is recorded, and Phase 1 is officially closed.

| ID | Task | Status | Notes |
|---|---|---|---|
| T7.1 | Create `THIRD_PARTY_NOTICES.md` with OpenClaw MIT attribution | done | File exists with OpenClaw MIT attribution (exit criterion **9**). **Input for T7.2** — satisfied. |
| T7.2 | Run License & Attribution Reviewer on `THIRD_PARTY_NOTICES.md`, `README.md`, `docs/INFERENCE-ENDPOINTS.md`, `docs/PHASE-1-PLAN.md`, `docs/PHASE-1-SPIKE.md` | done | **Verdict:** PASS_WITH_NOTES. Satisfies exit criterion **8** (License reviewer used on Phase 1 work). |
| T7.3 | Create `docs/PHASE-2-BACKLOG.md` with all deferred work from Phase 1, organized by target phase | done | `docs/PHASE-2-BACKLOG.md` created (exit criterion **10**). |
| T7.4 | Update `docs/INFERENCE-ENDPOINTS.md` with actual hourly costs from T5.4 | done | Synced to live roster + ~**$0.96/hr**; planner model, runtime flags, Mode D retries, and Mode E behavior corrected; aligns with **T3.6** / **T7.2** review pass. |
| T7.5 | Update `docs/PHASE-1-SPIKE.md` History section to note the original-to-corrected scope evolution | done | Updated to current planner model + validation status note; consistent with **PHASE-1-PLAN** / **INFERENCE-ENDPOINTS**. |
| T7.6 | Run Phase Boundary Keeper as a final scope check before declaring Phase 1 done | done | **Verdict:** PASS_WITH_NOTES — in-scope; process notes only. Satisfies exit criterion **8** (Phase Boundary Keeper used on Phase 1 closeout). |
| T7.7 | Mark Phase 1 complete in this plan file and notify Jonathan | done | **Owner:** `@pm`. Plan header set to **Complete** (**2026-04-08**). **T7.8** satisfied via **D19** (deferral with revisit window). Jonathan notified via this closeout update. |
| T7.8 | Decide whether to convert pods to a 1-month savings plan now or wait the planned 1-2 weeks | done | Final decision — **D19**: defer 1-month savings-plan conversion **1–2 weeks** (not converting now). **Revisit:** re-evaluate conversion **~2026-04-15–2026-04-22** (1–2 weeks from **2026-04-08**). Optional mirror in **PHASE-2-BACKLOG** / ops notes; canonical record is **D19** + this row. |

---

## Dependencies graph (high level)

The critical path through Phase 1 is:

```
T3.4 (fix provision.sh blockers)
  → T3.5 (re-audit) → T3.6 (cost review) → T3.10 (final review)
  → T5.1 (first provisioning run)
  → T5.2, T5.3, T5.4 (verify pods)
  → T6.1 (run configure.sh) → T6.2 (start gateway) → T6.3 (smoke test) → T6.4, T6.5 (manual verification)
  → closeout: T3.6 + T7.1–T7.6 + T7.8 → T7.7 (see Final Closeout Execution Plan) — **complete** (**2026-04-08**; **T7.8** deferred per **D19**)
```

Tasks that can run in parallel with the critical path:
- T3.7 (audit teardown.sh)
- T4.5–T4.8 (PM agent setup, subagent smoke tests, workflow doc)
- T7.1 (THIRD_PARTY_NOTICES.md)
- T7.2 (License Reviewer pass on docs)
- T7.3 (start drafting Phase 2 backlog)

**Current state (2026-04-08):** Phase 1 **Complete**. Critical path and closeout (**T7.8** **done** / **D19**, **T7.7** **done**) are finished. Optional follow-ons (not required for Phase 1): **T2.5** (configure audit), **T3.9**, **T4.6**–**T4.8**; savings-plan conversion revisit ~**2026-04-15–2026-04-22** per **D19**.

---

## Final Closeout Execution Plan

Ordered steps for declaring Phase 1 complete. **Dependencies:** reviewer tasks (**T3.6**, **T7.2**, **T7.6**) satisfy exit criterion **8**; **T7.1** / **T7.3** satisfy **9** / **10**.

| Step | Task(s) | Owner | Depends on | Output |
|:---:|:---|:---|:---|:---|
| 1 | **T7.1** | Main Cursor agent | — | `THIRD_PARTY_NOTICES.md` committed |
| 2 | **T7.3** (draft) | Main Cursor agent | — | First draft `PHASE-2-BACKLOG.md` (expand from deferred section here) |
| 3 | **T7.4**, **T7.5** | Main Cursor agent | — | **INFERENCE-ENDPOINTS** + **PHASE-1-SPIKE** aligned with live roster / costs |
| 4 | **T3.6** | `@cost-infra-reviewer` | T3.5 (done) | Cost/infra review of `provision.sh`; findings closed or accepted |
| 5 | **T7.2** | `@license-reviewer` | **T7.1** (and preferably **T7.4**) | License/attribution review of listed paths; fixes applied |
| 6 | **T7.3** (finalize) | Main Cursor agent | **T7.4**/**T7.5** if they add deferrals | Final `PHASE-2-BACKLOG.md` committed |
| 7 | **T7.6** | `@phase-boundary-keeper` | **T3.6**, **T7.1**–**T7.3**, **T7.2**; **T7.4**/**T7.5** done or waived | Written final scope check |
| 8 | **T7.8** | **Jonathan** | — | Savings-plan timing decision recorded (**D19**: defer 1–2 weeks) |
| 9 | **T7.7** | `@pm` | All exit criteria + checklist + **T7.8** resolved/deferred | Plan status → Complete; Jonathan notified |

**Parallelization:** Steps **1–4** can overlap (e.g. **T7.1**/**T7.3**/**T7.4**/**T7.5** while **T3.6** runs). **T7.2** should follow **T7.1**; **T7.6** is last among subagent reviews.

**Execution status (2026-04-08):** Steps **1–9** are **done**. Step **8** (**T7.8**): **done** — **D19** records **defer** of 1-month savings-plan conversion **1–2 weeks** (revisit ~**2026-04-15–2026-04-22**). Step **9** (**T7.7**): **done** — plan **Status** set to **Complete**; closeout recorded.

---

## Risks

### R6: Executor / pool host instability (A5000-class observation)
**Severity:** Medium
**Description:** During Phase 1 bring-up, **unstable pool behavior was observed on some A5000 hosts**. Executor provisioning was adjusted to **prefer more stable GPU classes first** in SKU ordering (see **D17**). The live roster still uses an **RTX A5000** for the **embedding** pod (CA-MTL-1); that role may remain more exposed if the underlying host quality regresses.
**Mitigation:** Executor GPU preference stack de-prioritizes flaky A5000 pools; monitor embedding (and all pods) in RunPod; rerun provision or change region/SKU if failures cluster on a host class. Revisit `provision.sh` ordering if RunPod fleet behavior changes.
**Trigger to revisit:** Repeated smoke or runtime failures tied to embedding or executor host instability after preference changes.

### R1: GPU availability on RunPod Secure Cloud
**Severity:** High
**Description:** When `provision.sh` runs for the first time, the planner-class GPU (L40S/A40/A6000) may not be available on Secure Cloud across any region. This would trigger Mode A retries, and depending on how long the shortage lasts, may force the script to time out and exit with the executor and embedding pods preserved but the planner missing. Phase 1 cannot complete without all three pods.
**Mitigation:** The Mode A retry loop and the planned idempotency of `provision.sh` (T3.8) mean the user can rerun the script until the planner becomes available without losing the already-provisioned pods. The cost of waiting is roughly $1.10/hr for the two healthy pods, which is acceptable for short waits but worth watching for long ones.
**Trigger to revisit:** If `provision.sh` fails to provision the planner across multiple rerun attempts over more than a few hours.

**Status (2026-04-08):** **Mitigated for current roster** — three pods running (planner on A40 EU-SE-1, executor on A4500 EU-RO-1, embedding on A5000 CA-MTL-1). Risk remains for **future** reprovisions or capacity shifts.

### R2: Cost overruns
**Severity:** Medium
**Description:** A bug in `provision.sh` could create more pods than planned, leave pods running longer than expected during failures, or pick more expensive SKUs than necessary. The user is cost-sensitive and the gap between the target ($1,265/month with savings plan, $1,725/month hourly) and a worst-case scenario could be several hundred dollars per month.
**Mitigation:** Multiple layers — the Script Auditor reviewed for orphan-pod scenarios and credential leaks, the Cost & Infra Reviewer verified SKU selection / cost paths (**T3.6**, PASS_WITH_NOTES), the credit balance pre-flight check prevents starting a run that can't be afforded, and `teardown.sh` is the manual kill switch. The Mode A timeout policy (preserve healthy pods + loud cost summary) means the user gets a clear signal if costs are accumulating.
**Trigger to revisit:** Any unexpected line item in the RunPod billing dashboard, or any pod running for more than 48 hours that isn't part of the planned three.

### R3: OpenClaw config schema drift
**Severity:** Medium
**Description:** OpenClaw is moving fast (the project is roughly 6 months old as of this plan and has had multiple rebrands and architectural changes). The config schema we're targeting in `config/openclaw.foreman.json` may have moved by the time `configure.sh` runs, causing `~/.openclaw/openclaw.json` to be rejected by the gateway.
**Mitigation:** The configure script's reachability check on the three providers will surface a config-loading failure as a loud error, not a silent partial-success. The known issue with `openclaw doctor` auto-normalizing fields has already been observed once and is documented.
**Trigger to revisit:** If `configure.sh` runs cleanly but the gateway fails to start, or if the gateway starts but doesn't recognize the providers.

### R4: vLLM image compatibility
**Severity:** Medium
**Description:** The vLLM launch flags in `provision.sh` (`--quantization awq_marlin`, `--enable-expert-parallel`, `--max-model-len`, etc.) may not be supported by the vLLM version in RunPod's current vLLM container image. If a flag is rejected, the pod will fail to start (Mode C in the failure tree) and require investigation.
**Mitigation:** The Mode C handler pauses for user inspection before tearing down the failed pod, with a link to the RunPod dashboard for log access. This gives the user a chance to debug the flag conflict and adjust before retrying.
**Trigger to revisit:** Mode C errors during the first `provision.sh` run.

### R5: Cursor subagents being half-broken
**Severity:** Low-Medium
**Description:** Bug reports from January 2026 indicated that Cursor was stripping YAML frontmatter from agent files when opened in the editor, and that the Task tool for subagent delegation was not always available. These bugs may or may not still exist. If they do, the review pipeline won't work as designed and reviews would have to fall back to manual prompts in the main agent.
**Mitigation:** The Script Auditor has already produced one real review successfully, suggesting at least the basic invocation path works in the current Cursor version. If automatic delegation fails, the workflow falls back to invoking subagents by name (`@script-auditor`), which is the recommended pattern from the third-party guides anyway.
**Trigger to revisit:** Any subagent failing to load, refusing to respond in character, or producing output that suggests its system prompt was not loaded.

---

## Decision log

Decisions are recorded with the most recent at the top. Each entry includes the decision, the rationale, and what would trigger a revisit.

### D25: Phase 2 mirror reconciliation — P2.3 wave 2 next; Notion sync follow-up (MCP unavailable)
**Decided:** 2026-04-08
**Decision:** Reconciled **repo mirrors** in this plan with **completed artifacts**: **P2.2**, **P2.4**, **P2.5**, **P2.6**, **P2.7** = **done**; **P2.8** = **done (skipped)** with justification gate doc `docs/P2.8-JUSTIFICATION-GATE.md`. **P2.3** remains **in progress**. **Batch 3** is **first slice complete** (**B3.1–B3.5**) only — **not** full **P2.3** closure. Removed stale mirror text that implied **P2.5**/**B5.1** was **next** or that **Batch 3** was fully **done** as a terminal batch. **Immediate next executable work** set to **P2.3 — Batch 3 wave 2** (**hierarchy continuation**). **`docs/PHASE-2-BACKLOG.md`** should mirror the same queue rows (main agent edit — PM scope is this file only). **Notion** remains **canonical** (**D21**); **Notion MCP** was **unavailable** during this reconciliation — **follow-up:** sync **Notion** task database to this state on next MCP session or manual pass (see **Source of truth**).
**Rationale:** One coherent current state across git mirrors; critical path and “what’s next” aligned to actual repo progress; preserves **Notion** as system of record while recording automation gap explicitly.
**What would trigger a revisit:** Successful **Notion** sync; completion of **wave 2** (new **@pm** handoff); or scope change to **P2.3** exit criteria (new decision).

### D24: P2.4 Batch 4 complete — policy evidence, reviewer gates, P2.5 Batch 5 queued; Notion sync deferred (MCP unavailable)
**Decided:** 2026-04-08
**Decision:** **Batch 4** (**B4.1–B4.6**) for **P2.4** (anti-hallucination policy + review loops) is **complete**. **Evidence:** `docs/P2.4-BATCH-4-ANTI-HALLUCINATION-POLICY.md` (repo path; full path `/Users/jonathanborgia/foreman-git/foreman-v2/docs/P2.4-BATCH-4-ANTI-HALLUCINATION-POLICY.md`). **Reviewer gates:** **`@script-auditor`** **FINDINGS** (file-path visibility issue this run) **accepted with rationale** (Batch 4 was **docs-only**, no script changes); **`@cost-infra-reviewer`** **APPROVED**; **`@license-reviewer`** **COMPLIANT / PASS_WITH_NOTES**; **`@phase-boundary-keeper`** **IN_SCOPE**. **P2.4** marked **done** in the Phase 2 queue mirror; **P2.5** marked **in progress** with **Batch 5** (**B5.1–B5.6**) **queued** (scheduled task automation port/rebuild). **Immediate next task** set to **Batch 5 / B5.1**. **Notion** remains **canonical** (**D21**); **Notion MCP unavailable** this run — **follow-up:** sync **Notion** to this mirror (P2.3/Batch 3, P2.4/Batch 4, P2.5/Batch 5, **B5.1** next) when MCP or manual pass is available (see **Source of truth** follow-up).
**Rationale:** Closes anti-hallucination policy batch with recorded evidence and gate discipline; advances execution queue without blocking on Notion tooling.
**What would trigger a revisit:** Successful Notion sync; material new scripts in a later P2.4 slice (would re-open **`@script-auditor`** on changed paths); or a scope change to P2.5 batch tasks (record as new decision).

### D23: P2.2 Batch 1 complete — reviewer gates + Notion sync deferred this run
**Decided:** 2026-04-08
**Decision:** **Batch 1** (**B1.1–B1.5**) for **P2.2** is **complete** with **repo evidence** (see **Batch 1** section: `docs/P2.2-BATCH-1-ROUTING-MAP.md`, `config/role-routing.json`, `scripts/paperclip-role-dispatch.sh`, verification/failure behavior via that script). **Reviewer gates:** **`@script-auditor`** **signed off**; **`@cost-infra-reviewer`**, **`@license-reviewer`**, **`@phase-boundary-keeper`** **PASS_WITH_NOTES** (outcomes table in plan). **`@pm`** invoked **Batch loop protocol** step: **Batch 2** (**B2.1–B2.5**) **queued**; **immediate next task** set to **B2.1**. **Notion** remains **canonical** for status/owners/dates (**D21**); **Notion MCP was unavailable** in this run — **follow-up:** sync **Notion** **P2.2** (Batch 1 done, Batch 2 active, **B2.1** next) when MCP or manual pass is available.
**Rationale:** Preserves single source of truth while recording technical evidence and handoff in git; avoids blocking the batch loop on tooling.
**What would trigger a revisit:** Successful Notion sync (close follow-up); or a finding that Batch 1 evidence is incomplete (would reopen Batch 1 tasks in **Notion** + this mirror).

### D22: Phase 2 batch loop — PM handoff + mandatory reviewer gates
**Decided:** 2026-04-08
**Decision:** After **P2.1** **done**, Phase 2 work proceeds in **batches**. When a batch reaches **done**, **`@pm`** is invoked **immediately** to queue the **next** batch and align this plan mirror with **Notion**. **Every** batch includes mandatory gates: **`@script-auditor`**, **`@cost-infra-reviewer`**, **`@license-reviewer`**, **`@phase-boundary-keeper`**. A batch may advance only when all its tasks meet **Done when** criteria, evidence is recorded, all four gates have outcomes, and **`@pm`** confirms **Notion** reflects completion.
**Rationale:** Preserves Phase 1 review discipline on Phase 2 increments; avoids losing the single source of truth (**Notion**) while keeping repo evidence and handoff explicit.
**What would trigger a revisit:** A decision to run Phase 2 without batching, to drop a gate, or to change the canonical status tool (would supersede **D21** in part — record as new decision).

### D21: Notion as canonical source for build / roadmap status
**Decided:** 2026-04-08
**Decision:** **Notion** is the **default source of truth** for **status**, **owners**, **dates**, and **dependencies** on the Foreman v2 build and roadmap. Repo docs (including this plan) remain **technical evidence**, **decision logs**, and **historical** Phase 1 detail; they are **not** the authoritative assignment system. **Hub:** https://www.notion.so/33c6238cef3e8190b695cb3dde3f9c42 — **Task database:** https://www.notion.so/e202cead847b4cb8b7aa032c7a373daa
**Rationale:** Single place for live prioritization and ownership; the repo keeps audit-friendly evidence and rationale without competing with day-to-day task state.
**What would trigger a revisit:** A deliberate choice to move roadmap ownership to another tool, or to make the repo authoritative again for a subset of work (recorded as a new decision).

### D20: Phase 2 execution queue — Paperclip path; scope capped vs Phase 3–4
**Decided:** 2026-04-08
**Decision:** Phase 2 work is **queued** as **P2.1–P2.8** in the **Phase 2 handoff** section near the top of this file, with **critical path P2.1 → P2.2 → P2.3**. **Scope cap:** Phase 2 is **Paperclip integration** on the existing **OpenClaw + three-pod RunPod** stack. **Phase 3** (frontend reskin, onboarding, social pipeline, hosted gateway polish) and **Phase 4+** (billing, marketing, support ops, broad analytics) remain **out of Phase 2** unless a **later decision** explicitly pulls them in.
**Rationale:** Phase 1 is complete; Jonathan needs an ordered queue, explicit dependencies, and a hard boundary so platform/product work does not collapse into the Paperclip phase.
**What would trigger a revisit:** P2.1 integration surprises; Paperclip/OpenClaw architecture constraints; explicit reprioritization; or a new decision to absorb a Phase 3+ item into Phase 2.

### D19: RunPod 1-month savings-plan conversion — defer 1–2 weeks (T7.8)
**Decided:** 2026-04-08
**Decision:** **Defer** converting the Phase 1 three-pod roster to a **1-month RunPod savings plan** for **1–2 weeks** (do not convert immediately). **Revisit window:** re-evaluate conversion approximately **2026-04-15–2026-04-22** (1–2 weeks after this decision).
**Rationale:** Close Phase 1 without blocking on billing/plan-change execution; time-boxed deferral preserves the decision as “not now” while keeping a explicit calendar trigger to revisit.
**What would trigger a revisit:** End of the 1–2 week window, material change in RunPod pricing or roster, or operational readiness to execute the conversion sooner.

### D18: Closeout reviewer verdicts (cost, license, boundary) — PASS_WITH_NOTES
**Decided:** 2026-04-08
**Decision:** **T3.6** (Cost & Infra Reviewer on `provision.sh`), **T7.2** (License & Attribution Reviewer on the listed attribution/docs paths), and **T7.6** (Phase Boundary Keeper final scope check) completed with verdict **PASS_WITH_NOTES** — no script or scope blockers; documentation/process notes only, addressed in the same closeout pass.
**Rationale:** Records the evidence trail for exit criterion **8** (all four review subagents used on Phase 1 work, with findings addressed or explicitly noted).
**What would trigger a revisit:** Material changes to `provision.sh`, attribution surfaces, or Phase 1 scope claims without a fresh review pass.

### D17: Executor GPU preference ordering to mitigate unstable pool hosts
**Decided:** 2026-04-08
**Decision:** After observing **unstable pool behavior on some A5000-class hosts**, `provision.sh` **executor** SKU / GPU preference ordering was adjusted to **prioritize historically stable alternatives first**, rather than minimizing $/hr at the expense of flaky hosts.
**Rationale:** The executor is on the latency-critical path for chat; predictable uptime matters more than marginal hourly savings on hosts that fail health checks or behave erratically under load.
**What would trigger a revisit:** RunPod Secure Cloud fleet quality changes; evidence that A5000-class pools are consistently stable; or a deliberate choice to chase lowest $/hr again with different acceptance of churn.

### D16: Official Hugging Face model IDs only on the Phase 1 roster
**Decided:** 2026-04-08
**Decision:** The three-pod Phase 1 roster uses **official** `Qwen/Qwen3-*` model IDs from Hugging Face only (executor: `Qwen/Qwen3-14B-AWQ`; planner: `Qwen/Qwen3-30B-A3B-Instruct-2507`; embedding: `Qwen/Qwen3-Embedding-8B`) — **no** ad-hoc mirrors, private registries, or unreviewed custom bundles in this spike.
**Rationale:** Reproducible pulls, clearer support path with vLLM/HF, and less supply-chain ambiguity for a solo-operator Phase 1.
**What would trigger a revisit:** Phase 2+ need for fine-tuned weights, private artifacts, or a forked model ID.

### D1: Use OpenClaw + Paperclip as the foundation for Foreman v2
**Decided:** Earlier in Phase 1 planning
**Decision:** Build Foreman v2 as a packaging layer around OpenClaw (Phase 1) and Paperclip (Phase 2), rather than continuing to develop the custom Python orchestration in `foreman/`.
**Rationale:** Both projects are MIT licensed, both are explicitly designed for the agent-orchestration use case Foreman targets, and together they cover the agent runtime + org chart layers that Foreman would otherwise have to build from scratch. The "AI agents for the rest of us" pitch becomes "we host these proven open-source tools with self-hosted inference and a non-technical UX," which is a defensible business position with operational moat rather than technical novelty.
**What would trigger a revisit:** Either project changing license to something incompatible with commercial use, or either project becoming abandoned/unmaintained.

### D2: Park the existing `foreman/` Python codebase rather than delete it
**Decided:** At the start of foreman-v2 work
**Decision:** Leave the existing `foreman/` Python codebase (custom dashboard.py orchestration, Supabase integration, 63 scheduled agent tasks, etc.) untouched and create a sibling `foreman-v2/` directory for the new architecture. The frontend and prompt work in `foreman/` will be cannibalized later for the eventual Foreman v2 frontend reskin.
**Rationale:** The existing codebase contains months of work that's still useful for reference, even if the architecture is being replaced. Deleting it would lose institutional knowledge. Parking it means future-you can copy patterns, prompts, and frontend components into Foreman v2 as needed.
**What would trigger a revisit:** When Foreman v2 reaches feature parity with `foreman/`, the old codebase can be archived to a separate branch or removed.

### D3: Self-hosted RunPod inference, not Featherless or another API provider
**Decided:** Reversed from a previous decision after the Featherless migration
**Decision:** Foreman v2 uses self-hosted inference on RunPod GPUs, not Featherless.ai (which was the previous production layer). RunPod Secure Cloud only, never Community Cloud.
**Rationale:** Foreman's flat-rate business thesis depends on amortizing fixed GPU rental across many customer workloads. Featherless re-introduces a per-token middleman that breaks that thesis. RunPod gives Foreman direct control over the inference layer and the cost economics that justify the business model. Secure Cloud (vs. Community) is the non-negotiable reliability tier — Community has no SLA, no data residency guarantees, and unknown host quality, none of which are acceptable for multi-tenant SaaS infrastructure.
**What would trigger a revisit:** RunPod becoming significantly more expensive than alternatives, RunPod Secure Cloud capacity becoming chronically unavailable, or Foreman scaling to a point where a different cloud provider's economics become more favorable.

### D4: Three-pod always-on roster (executor, planner, embedding), not the eight-pod "capability-first" topology
**Decided:** After the eight-pod topology was rejected as too expensive
**Decision:** Phase 1 runs three always-on pods: executor (Qwen3-14B-AWQ on a 24GB GPU), planner (Qwen3-30B-A3B-AWQ on a 48GB GPU), and embedding (Qwen3-Embedding-8B on a 16GB GPU). The five other roles from earlier topology designs (router, coder, VLM, executor-MoE, planner-heavy) are explicitly cut.
**Rationale:** The eight-pod topology was estimated at $4,000+/month, which is too expensive for a Phase 1 spike where utilization is unknown. Cutting to three pods drops the cost to roughly $1,265/month with a savings plan, while preserving the core capability needed for OpenClaw chat (executor), Paperclip-tier reasoning (planner, used by the planner role in Phase 2), and RAG retrieval (embedding). The cut roles can come back in later phases when there's evidence they're needed.
**What would trigger a revisit:** Specific Phase 2+ use cases that genuinely require one of the cut roles. For example, an Engineering Builder agent doing real code generation would justify reviving the coder pod.

### D5: Qwen3-30B-A3B (MoE) for the planner, not Qwen3-32B (dense)
**Decided:** During the cost-trim conversation
**Decision:** Use the MoE variant for the planner role.
**Rationale:** MoE activates only ~3B parameters per token while loading the full 30B in VRAM, meaning faster inference throughput at the same GPU cost. Benchmarks competitive with dense 32B for planning/reasoning tasks. With self-hosted GPUs (no per-token cost), the throughput advantage matters more than the slight quality variance.
**What would trigger a revisit:** Observed quality regressions in planning behavior compared to dense 32B, or vLLM compatibility issues with MoE expert parallelism in the chosen container image.

### D6: All-always-on, not partial-serverless
**Decided:** During the cost-trim conversation
**Decision:** All three pods are always-on persistent Pods. No serverless endpoints, even for the lower-utilization ones.
**Rationale:** Past experience with RunPod serverless was unreliable (specific bugs that couldn't be resolved). Uniform always-on Pods are simpler to reason about, debug, and operate. The cost penalty vs. partial-serverless is small when the roster is already trimmed to three.
**What would trigger a revisit:** RunPod fixing the serverless reliability issues, or a future phase introducing pods with utilization low enough that always-on becomes wasteful.

### D7: Secure Cloud only, never Community
**Decided:** Confirmed during the Cost & Infra discussion
**Decision:** Every RunPod pod for Foreman v2 is provisioned on Secure Cloud, with `cloudType` set explicitly in the API call. No fallback to Community.
**Rationale:** Community Cloud has no uptime SLA, unknown data residency, and reliability that depends on third-party hosts. Multi-tenant SaaS customers will not accept that. Secure Cloud is roughly 1.5–2x the cost but the reliability difference is the entire reason we're paying for it.
**What would trigger a revisit:** Foreman pivoting to a different business model where the reliability requirement relaxes (e.g., a personal-use tier with lower expectations).

### D8: Cheapest acceptable Secure Cloud SKU at provisioning time, not hardcoded preferences
**Decided:** When Cursor surfaced the L40S-vs-A40 conflict
**Decision:** `provision.sh` queries current Secure Cloud GPU availability and picks the cheapest SKU from a verified-acceptable list for each pod, rather than defaulting to a specific SKU like L40S.
**Rationale:** The original prompt named L40S as the planner target, but A40 has the same VRAM (48GB) at lower cost and is currently available. The "acceptable list" for each pod constrains the selection to SKUs that meet the workload requirements; within that list, cheapest wins. This saves money without compromising capability.
**What would trigger a revisit:** A specific GPU class proving inadequate for its workload (e.g., A40 throughput being unacceptably lower than L40S in production).

### D9: Five-mode failure decision tree for `provision.sh`
**Decided:** During the corrective Phase 1 prompt design
**Decision:** `provision.sh` distinguishes five failure modes (transient capacity, permanent config, pod-never-ran, health-check-failed, RunPod-API-down) and handles each with mode-specific behavior, rather than treating all errors the same way.
**Rationale:** Different failure modes have different correct responses. Tearing down healthy pods on a transient API hiccup is wasteful. Tearing down without inspection on a pod-startup failure loses debugging information. Retrying a permanently misconfigured request is pointless. The five-mode tree captures the necessary distinctions.
**What would trigger a revisit:** A failure mode the script encounters that doesn't cleanly fit any of the five modes, or evidence that the mode classification is consistently wrong.

### D10: Mode A timeout preserves healthy pods, does not tear down
**Decided:** During the Script Auditor blocker fix conversation
**Decision:** When Mode A (transient GPU unavailability) retry window expires, `provision.sh` preserves any pods that were successfully provisioned earlier in the run, exits with a loud warning showing what's still running and what it costs per hour, and returns exit code 2 to distinguish "partial success" from full failure.
**Rationale:** Mode A is recoverable by definition. Tearing down healthy pods on Mode A timeout treats it like a permanent failure, wasting the work already done and forcing a fresh start. The cost of preserving the healthy pods (~$1.10/hr combined) is acceptable for short waits, and the user has `teardown.sh` as the explicit kill switch if they want everything gone. The loud warning ensures the user can't accidentally let pods run for a weekend without noticing.
**What would trigger a revisit:** If preserved pods consistently end up running for hours after the user has lost interest, suggesting the warning isn't loud enough or the user behavior doesn't match the assumption.

### D11: `provision.sh` will be made idempotent
**Decided:** After discussing the indefinite-polling alternative
**Decision:** `provision.sh` will check `state/pods.json` at the start of each run, identify which pods from the roster are already running and healthy, skip those, and only attempt to provision the missing ones. This makes rerunning the script after a partial failure (or after a Mode A timeout) safe and useful.
**Rationale:** Idempotency is strictly better than the alternatives. It enables manual retry after Mode A timeouts, recovery from crashed runs, and (if the user wants automated retries) wiring into a cron job. It's also a property worth having regardless of whether the script also implements indefinite polling, because rerunability is a baseline expectation.
**What would trigger a revisit:** If idempotency turns out to be unexpectedly hard to implement correctly (e.g., RunPod's API doesn't expose enough state to determine pod health reliably from the outside).

### D12: Subagent-based review pipeline using Cursor 2.4 subagents
**Decided:** When the agent roster idea came up
**Decision:** Use Cursor's native subagents feature (`.cursor/agents/*.md` files with YAML frontmatter) to create five specialist agents: Script Auditor, Cost & Infra Reviewer, License & Attribution Reviewer, Phase Boundary Keeper, and PM. All five run alongside the main Cursor coding agent, with `readonly: true` enforced for the four review agents (the PM agent has write access to this plan file only).
**Rationale:** The subagents have isolated context windows, are version-controlled as part of the project, and can be invoked by name to provide specialist review. This is the right tool for "I want a coordinator-free review pipeline that catches bugs before I run scripts." When the work moves to Paperclip in Phase 2, these agent definitions transfer cleanly to Paperclip's agent system, so this is also prototype work for the Phase 2 agent roster.
**What would trigger a revisit:** Cursor subagents being unreliable in practice (early bug reports about YAML frontmatter being stripped suggest the feature is still rough), or Paperclip arriving with a meaningfully better way to organize specialist agents.

### D13: Decision log is the most thorough section of this plan
**Decided:** During plan design
**Decision:** The decision log section of `PHASE-1-PLAN.md` is intentionally the longest section, capturing the rationale behind every major choice in Phase 1.
**Rationale:** Tasks and status are easy to recover from looking at the repo. Risks can be re-derived from looking at the work. But the *rationale* behind decisions only exists in the conversation history that produced them, and conversation history ages out. Recording decisions is the only way to preserve the "why" past the moment of decision.
**What would trigger a revisit:** The decision log becoming so long that it's actively annoying to maintain, or evidence that nobody (Jonathan or future contributors) is reading it.

### D14: Script Auditor's first review of `provision.sh` found four real blockers
**Decided:** From the audit itself
**Decision:** Recorded for the historical record. The Script Auditor identified: (1) Modes C and D not pausing for inspection before teardown, (2) Mode E tearing down healthy pods on API failure, (3) all five modes collapsed into one generic teardown handler, (4) raw API responses leaking operational details into error messages. Plus several warnings on GraphQL auth, error handling, and Ctrl+C edge cases.
**Rationale:** This is recorded so the value of the review pipeline is documented. The Script Auditor caught real bugs on its first use, justifying the investment in setting up the subagent infrastructure.
**What would trigger a revisit:** N/A — historical record only.

### D15: Social media publishing pipeline target phase and stack
**Decided:** During plan creation, correcting an earlier note
**Decision:** Social media publishing is part of Foreman v2's eventual feature set, targeted for **Phase 3** (after Paperclip integration in Phase 2 and frontend reskin). The specific stack (previously Buffer + native APIs + Supermetrics + Power BI) is **explicitly being left open for revisit** when Phase 3 begins, rather than being locked in now.
**Rationale:** The earlier commitment to Buffer + Supermetrics + Power BI was made in a different context and may not still be the right architecture by the time Phase 3 starts. Recording the target phase preserves the intent (this feature is coming) without prematurely committing to implementation details that may have aged poorly. When Phase 3 starts, the architecture conversation reopens fresh.
**What would trigger a revisit:** When Phase 3 planning begins, this entry will be replaced with a current decision about the Phase 3 stack.

---

## Deferred work — Phase 2+ backlog (preview)

`docs/PHASE-2-BACKLOG.md` now exists (**T7.3** **done**); this section remains a **preview / quick reference**. **Live roadmap / task state:** Notion (**Source of truth**, **D21**). The backlog file is a **repo-side** structured deferral record and mirror. The PM agent and Phase Boundary Keeper can still answer "where does this idea go" from either place.

### Target: Phase 2 (Paperclip integration)
- Paperclip install and integration on top of OpenClaw
- Per-role model routing across the three pods (executor for chat, planner for reasoning, embedding for RAG)
- The Foreman v1 agent hierarchy (CoS → 5 Chiefs → ~18 Specialists) implemented as Paperclip agents
- 63 scheduled agent tasks ported from `foreman/` (or rebuilt for Paperclip)
- Multi-tenancy / per-customer isolation via Paperclip's company-isolation feature
- Migrating the four Cursor review subagents into Paperclip-managed agents (dogfooding)
- Anti-hallucination rule enforcement via Paperclip agent prompts
- Reviving the cut model roles if specific Phase 2 agents need them (router for dispatch, coder for engineering, etc.)

### Target: Phase 3 (Frontend reskin and platform polish)
- Frontend reskin: cannibalizing the existing `foreman/` consultant-style UI (Chat, Projects, Team/Org Chart, Inbox, Settings) for Foreman v2
- Customer onboarding flow for non-technical users
- **Social media publishing pipeline** (stack to be decided in Phase 3 — see D15)
- Hosting OpenClaw on a real server (Linux VM, Hetzner, Fly.io with persistent volume) instead of local-only
- Tailscale or similar for remote OpenClaw gateway access during the transition period

### Target: Phase 4+ (Business operations)
- Billing integration (Stripe or similar)
- Marketing pages and landing page
- Customer support tooling
- Analytics and usage tracking per customer
- Compliance posture (ToS, privacy policy, security disclosures)
- The "AI agents for the rest of us" public launch

### Deferred indefinitely (no target phase)
- **Ollama dev mode toggle for local iteration.** Was discussed during Phase 1 planning. Originally compelling when Featherless was the production path (Ollama would have been a free local alternative). Less compelling now that production is RunPod and the user has direct control over inference costs. Tabled until there's a specific reason to want offline development — likely never for Jonathan personally, possibly relevant if Foreman ever ships a self-hosted SKU for customers.
- **ML-based predictive pod pre-warming.** Was on the original `foreman/` roadmap. Defer until there's enough traffic data to make ML predictions meaningful, which is far beyond Phase 1's scope.
- **SearXNG self-hosted search.** Was on the original `foreman/` roadmap to replace Tavily. Tavily isn't even in Foreman v2 yet, so this is doubly deferred.
- **Redis additive layer for agent message bus.** Was on the original `foreman/` roadmap. Useful when there are enough concurrent agents to need a real message bus; not before.

---

## Phase exit checklist

When the PM agent is asked "is Phase 1 done?", it should walk through this checklist mechanically. As of **2026-04-08**, all items below are checked — Phase 1 is **complete** per this plan.

- [x] T5.1: `provision.sh` ran successfully against RunPod
- [x] T5.2: `state/pods.json` has three pods recorded
- [x] T5.3: All three pods reachable and serving expected models
- [x] T6.1: `configure.sh` ran successfully
- [x] T6.2: OpenClaw gateway running
- [x] T6.3: `smoke-test.sh` exits 0
- [x] T6.4: WebChat works in browser, multi-turn conversation possible
- [x] T6.5: Responses verifiably from Qwen3-14B-AWQ via RunPod
- [x] T7.1: `THIRD_PARTY_NOTICES.md` exists and is correct
- [x] T7.2: License Reviewer pass complete
- [x] T7.3: `PHASE-2-BACKLOG.md` exists and captures all deferred work
- [x] T7.6: Phase Boundary Keeper final scope check passed
- [x] T7.8: Savings-plan timing closed — **deferred 1–2 weeks** (**D19**); revisit ~**2026-04-15–2026-04-22**
- [x] T7.7: Plan status **Complete**; Phase 1 closeout recorded (**2026-04-08**)

**Supplement — exit criteria items 7–10 (see "Phase 1 exit criteria" above):** **Item 7** (`teardown.sh`): satisfied via **audit path** (Script Auditor sign-off on `teardown.sh`, **T3.7**). **Item 8** (four review subagents used + findings addressed): **complete** — Script Auditor + **T3.6** (PASS_WITH_NOTES) + **T7.2** (PASS_WITH_NOTES) + **T7.6** (PASS_WITH_NOTES). **Item 9** `THIRD_PARTY_NOTICES.md`: **T7.1** **done**. **Item 10** `PHASE-2-BACKLOG.md`: **T7.3** **done**. Doc alignment (**T7.4**, **T7.5**) supports criteria **1–6** narrative consistency; not separate numbered exit rows.

**Closeout:** **T7.8** **done** (**D19** — defer 1–2 weeks). **T7.7** **done**. Phase 1 is **complete** per this plan (**2026-04-08**). **Next (Phase 2):** **P2.3** **in progress** — **Batch 3 wave 2** (hierarchy continuation) is **immediate next executable** (**D25**); **P2.2**, **P2.4**, **P2.5**, **P2.6**, **P2.7** **done**; **P2.8** **done (skipped)** per gate doc. Canonical task state in **Notion** (**Source of truth**) — **Notion MCP** sync follow-up when unavailable (**Source of truth** + **D25**); calendar revisit for savings-plan conversion per **D19**.

---

## How this file gets updated

**Status for the build / roadmap** is **owned in Notion** (**Source of truth**). The PM subagent (`@pm`) still updates this file to **mirror** Notion when helpful, to record **decisions** and **risks**, and to preserve **Phase 1 history** and **technical evidence**.

This file is updated by the PM subagent (`@pm`) when:
1. A task moves between status values (`not started` → `in progress` → `done`) — **when mirroring Notion or recording closeout here**
2. A new task is added or an existing one is removed
3. A risk is identified, mitigated, or retired
4. A decision is made and needs to be recorded
5. Deferred work is added to or removed from the Phase 2+ backlog

The PM agent may also be asked to update this file by Jonathan directly (e.g. "PM, mark T3.4 as done and add a new task T3.4a for the second-Ctrl+C handler"). The PM should confirm any update before applying it, then make the edit and report back what changed.

The PM is the only agent with write access to this file. The other four review agents are read-only and may reference this file but cannot modify it.