# Foreman v2 — Phase 1 Plan

**Status:** In progress
**Last updated:** 2026-04-08
**Maintained by:** Jonathan + the PM subagent (`@pm`)

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
| T2.6 | Run `configure.sh` against real `state/pods.json` | blocked | Blocked on T5.1 (first successful provisioning) |

### Cluster 3: RunPod three-pod provisioning scripts

**Goal:** `provision.sh` and `teardown.sh` are correct, audited, and ready to run against RunPod Secure Cloud. The provision script handles the five-mode failure decision tree, has a Ctrl+C handler installed before any pod creation, has a credit balance pre-flight check, writes to `state/pods.json` incrementally, and is idempotent on rerun.

| ID | Task | Status | Notes |
|---|---|---|---|
| T3.1 | Write initial `scripts/provision.sh` with five-mode failure handling, credit check, SKU verification, cost printing | done | Initial draft from corrective Phase 1 prompt |
| T3.2 | Write initial `scripts/teardown.sh` as the kill switch | done | Initial draft from corrective Phase 1 prompt |
| T3.3 | Run Script Auditor on `provision.sh` (first pass) | done | Found 4 BLOCKERS, several WARNINGS — see decision log entry D14 |
| T3.4 | Apply Script Auditor's blocker fixes to `provision.sh` | in progress | Cursor is fixing: Mode C/D pause for inspection, Mode E preserve healthy pods, top-level mode routing, sanitized error messages, GraphQL header auth, GraphQL error handling, clear_state safety, second-Ctrl+C handling. Plus the Mode A timeout policy change (preserve healthy pods, not tear down). |
| T3.5 | Re-run Script Auditor on the patched `provision.sh` | blocked | Blocked on T3.4. Expect at least one more cycle of fix-and-rereview. |
| T3.6 | Run Cost & Infra Reviewer on `provision.sh` | blocked | Blocked on T3.5. Different lens, different concerns — covers SKU selection, hidden line items, savings plan eligibility. |
| T3.7 | Run Script Auditor on `teardown.sh` | not started | Can run in parallel with T3.4–T3.6. |
| T3.8 | Make `provision.sh` idempotent (rerunning skips already-provisioned pods, attempts only the missing ones) | not started | Approved scope addition — needed for clean recovery from partial failures, also enables manual retry of just the missing pod after a Mode A timeout. May be folded into T3.4 if Cursor handles it as part of the failure-mode restructuring. |
| T3.9 | Mock `state/pods.json` verification of `configure.sh` and `smoke-test.sh` parsing/templating | not started | Cursor offered to do this; defer until T3.5 is clean so we don't validate against a buggy parser |
| T3.10 | Final review pass before first real run | blocked | Blocked on T3.5, T3.6, T3.7, T3.9 all being clean |

### Cluster 4: Subagent-based review pipeline

**Goal:** The five subagents (Script Auditor, Cost & Infra Reviewer, License & Attribution Reviewer, Phase Boundary Keeper, PM) are installed in `.cursor/agents/`, smoke-tested, and being used on Phase 1 work as appropriate.

| ID | Task | Status | Notes |
|---|---|---|---|
| T4.1 | Create `.cursor/agents/script-auditor.md` | done | First successful use revealed real bugs in `provision.sh` |
| T4.2 | Create `.cursor/agents/cost-infra-reviewer.md` | done | Not yet invoked |
| T4.3 | Create `.cursor/agents/license-reviewer.md` | done | Not yet invoked |
| T4.4 | Create `.cursor/agents/phase-boundary-keeper.md` | done | Not yet invoked |
| T4.5 | Create `.cursor/agents/pm.md` (this agent) | not started | System prompt to be written next |
| T4.6 | Smoke-test each subagent by name to verify the system prompt loaded | partial | Script Auditor confirmed working (it produced a real review). Others not yet smoke-tested. |
| T4.7 | Verify `.cursor/agents/` is committed to git and not gitignored | not started | Needs explicit `!.cursor/agents/` in `.gitignore` if `.cursor/*` is excluded |
| T4.8 | Document the subagent workflow in `docs/SUBAGENT-WORKFLOW.md` so future-you (or future contributors) know which agent to invoke when | not started | Lower priority — can wait until Phase 1 ships |

### Cluster 5: First successful provisioning run

**Goal:** Execute `provision.sh` against RunPod Secure Cloud and end up with three healthy pods, with `state/pods.json` accurately recording them. This is the moment Phase 1 either works or doesn't.

| ID | Task | Status | Notes |
|---|---|---|---|
| T5.1 | Run `./scripts/provision.sh` for the first time | blocked | Blocked on T3.5, T3.6, T3.7, T3.10 all clean. **High risk:** GPU availability, cost, partial-failure handling. Do not run until all reviews are clean. |
| T5.2 | Verify `state/pods.json` reflects three pods correctly | blocked | Blocked on T5.1 |
| T5.3 | Verify all three pods are reachable via their proxy URLs and serving the expected models | blocked | Blocked on T5.1 |
| T5.4 | Note the actual hourly cost of the provisioned pods (vs. the estimate) and update the cost projection in `docs/INFERENCE-ENDPOINTS.md` if it drifted | blocked | Blocked on T5.1 |

### Cluster 6: Smoke test against real pods

**Goal:** Run the full smoke test against the live pods and confirm OpenClaw chat round-trips through the executor pod, the planner pod responds to reasoning prompts, and the embedding pod returns valid vectors.

| ID | Task | Status | Notes |
|---|---|---|---|
| T6.1 | Run `./scripts/configure.sh` to write the live config | blocked | Blocked on T5.1 |
| T6.2 | Run `./scripts/start.sh` to launch the OpenClaw gateway | blocked | Blocked on T6.1 |
| T6.3 | Run `./scripts/smoke-test.sh` and verify exit 0 | blocked | Blocked on T6.2. **This is the critical Phase 1 success signal.** |
| T6.4 | Open WebChat in a browser and have a multi-turn conversation with the agent | blocked | Blocked on T6.2. Validates the human-facing experience, which `smoke-test.sh` doesn't fully cover. |
| T6.5 | Verify responses are clearly coming from Qwen3-14B-AWQ via RunPod (not Anthropic, OpenAI, or any other backend) | blocked | Blocked on T6.4 |

### Cluster 7: Documentation cleanup and Phase 1 closeout

**Goal:** Documentation reflects what was actually built, all attribution is correct, the Phase 2 backlog is recorded, and Phase 1 is officially closed.

| ID | Task | Status | Notes |
|---|---|---|---|
| T7.1 | Create `THIRD_PARTY_NOTICES.md` with OpenClaw MIT attribution | not started | Should be created before Phase 1 ships, even if not before T5.1 — license compliance is non-negotiable |
| T7.2 | Run License & Attribution Reviewer on `THIRD_PARTY_NOTICES.md`, `README.md`, `docs/INFERENCE-ENDPOINTS.md`, `docs/PHASE-1-PLAN.md`, `docs/PHASE-1-SPIKE.md` | not started | Can run in parallel with other clusters |
| T7.3 | Create `docs/PHASE-2-BACKLOG.md` with all deferred work from Phase 1, organized by target phase | not started | Can be pre-staged now while decisions are fresh — start drafting before T5.1 to capture context |
| T7.4 | Update `docs/INFERENCE-ENDPOINTS.md` with actual hourly costs from T5.4 | blocked | Blocked on T5.4 |
| T7.5 | Update `docs/PHASE-1-SPIKE.md` History section to note the original-to-corrected scope evolution | not started | Mostly already done by Cursor in the corrective work; verify it's accurate |
| T7.6 | Run Phase Boundary Keeper as a final scope check before declaring Phase 1 done | blocked | Blocked on T6.3 |
| T7.7 | Mark Phase 1 complete in this plan file and notify Jonathan | blocked | Blocked on all other Cluster 7 tasks |
| T7.8 | Decide whether to convert pods to a 1-month savings plan now or wait the planned 1-2 weeks | not started | This is a Phase 1 closeout decision, not a Phase 2 task. Default is to wait 1-2 weeks per the original plan. |

---

## Dependencies graph (high level)

The critical path through Phase 1 is:

```
T3.4 (fix provision.sh blockers)
  → T3.5 (re-audit) → T3.6 (cost review) → T3.10 (final review)
  → T5.1 (first provisioning run)
  → T5.2, T5.3, T5.4 (verify pods)
  → T6.1 (run configure.sh) → T6.2 (start gateway) → T6.3 (smoke test) → T6.4, T6.5 (manual verification)
  → T7.4, T7.6, T7.7 (closeout)
```

Tasks that can run in parallel with the critical path:
- T3.7 (audit teardown.sh)
- T4.5–T4.8 (PM agent setup, subagent smoke tests, workflow doc)
- T7.1 (THIRD_PARTY_NOTICES.md)
- T7.2 (License Reviewer pass on docs)
- T7.3 (start drafting Phase 2 backlog)

The single biggest blocker on the critical path right now is **T3.4** — the Cursor coding agent applying the Script Auditor's blocker fixes to `provision.sh`. Until that's done and T3.5 confirms it's clean, nothing downstream of it can move.

---

## Risks

### R1: GPU availability on RunPod Secure Cloud
**Severity:** High
**Description:** When `provision.sh` runs for the first time, the planner-class GPU (L40S/A40/A6000) may not be available on Secure Cloud across any region. This would trigger Mode A retries, and depending on how long the shortage lasts, may force the script to time out and exit with the executor and embedding pods preserved but the planner missing. Phase 1 cannot complete without all three pods.
**Mitigation:** The Mode A retry loop and the planned idempotency of `provision.sh` (T3.8) mean the user can rerun the script until the planner becomes available without losing the already-provisioned pods. The cost of waiting is roughly $1.10/hr for the two healthy pods, which is acceptable for short waits but worth watching for long ones.
**Trigger to revisit:** If `provision.sh` fails to provision the planner across multiple rerun attempts over more than a few hours.

### R2: Cost overruns
**Severity:** Medium
**Description:** A bug in `provision.sh` could create more pods than planned, leave pods running longer than expected during failures, or pick more expensive SKUs than necessary. The user is cost-sensitive and the gap between the target ($1,265/month with savings plan, $1,725/month hourly) and a worst-case scenario could be several hundred dollars per month.
**Mitigation:** Multiple layers — the Script Auditor reviewed for orphan-pod scenarios and credential leaks, the Cost & Infra Reviewer will verify SKU selection logic, the credit balance pre-flight check prevents starting a run that can't be afforded, and `teardown.sh` is the manual kill switch. The Mode A timeout policy (preserve healthy pods + loud cost summary) means the user gets a clear signal if costs are accumulating.
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

This is a preview of what will go into `docs/PHASE-2-BACKLOG.md` (T7.3). The full backlog file will be more detailed; this section is a quick reference so the PM agent and Phase Boundary Keeper can answer "where does this idea go" questions without leaving the plan file.

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

When the PM agent is asked "is Phase 1 done?", it should walk through this checklist mechanically:

- [ ] T5.1: `provision.sh` ran successfully against RunPod
- [ ] T5.2: `state/pods.json` has three pods recorded
- [ ] T5.3: All three pods reachable and serving expected models
- [ ] T6.1: `configure.sh` ran successfully
- [ ] T6.2: OpenClaw gateway running
- [ ] T6.3: `smoke-test.sh` exits 0
- [ ] T6.4: WebChat works in browser, multi-turn conversation possible
- [ ] T6.5: Responses verifiably from Qwen3-14B-AWQ via RunPod
- [ ] T7.1: `THIRD_PARTY_NOTICES.md` exists and is correct
- [ ] T7.2: License Reviewer pass complete
- [ ] T7.3: `PHASE-2-BACKLOG.md` exists and captures all deferred work
- [ ] T7.6: Phase Boundary Keeper final scope check passed

When all twelve are checked, Phase 1 is done. The PM agent should mark the plan file's status as "Complete" and notify Jonathan to start Phase 2 planning.

---

## How this file gets updated

This file is updated by the PM subagent (`@pm`) when:
1. A task moves between status values (`not started` → `in progress` → `done`)
2. A new task is added or an existing one is removed
3. A risk is identified, mitigated, or retired
4. A decision is made and needs to be recorded
5. Deferred work is added to or removed from the Phase 2+ backlog

The PM agent may also be asked to update this file by Jonathan directly (e.g. "PM, mark T3.4 as done and add a new task T3.4a for the second-Ctrl+C handler"). The PM should confirm any update before applying it, then make the edit and report back what changed.

The PM is the only agent with write access to this file. The other four review agents are read-only and may reference this file but cannot modify it.