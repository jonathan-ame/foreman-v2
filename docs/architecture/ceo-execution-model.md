# CEO Execution Model Rework (Design-Only)

Status: proposed (no implementation in this document)
Scope: CEO execution path in `scripts/paperclip-openclaw-executor.sh` plus additive pipeline modules and config wiring
Out of scope: changing auth/checkout semantics validated in `b3fab4b`, changing RunPod provisioning scripts, replacing Paperclip heartbeat protocol

---

## Executive Summary

The current loop is reliable but behaviorally weak: the CEO heartbeat executes one unconditional `openclaw agent` turn against the executor model, then posts that output if it looks long enough. There is no explicit per-task decomposition, no per-step model routing, and no source-of-truth fact verification before posting a final Paperclip comment.

This design proposes:

1. **Global CEO reasoning bind to planner (DeepSeek)** for plan and synthesis.
2. **Plan-driven multi-step execution** where each step selects planner/executor/reviewer intentionally.
3. **Mandatory fact-check acceptance gate** so unverified claims never reach completion comments.

The migration recommendation is feature-flagged rollout with shadow mode before cutover.

---

## Current-State Evidence Map

- CEO worker script runs exactly one OpenClaw turn with no model selector:
  - `scripts/paperclip-openclaw-executor.sh:656-697`
  - command: `["openclaw", "agent", "--session-id", ..., "-m", prompt]` at `scripts/paperclip-openclaw-executor.sh:663`
- OpenClaw defaults pin primary model to executor:
  - `config/openclaw.foreman.json:4-7` (`agents.defaults.model.primary: "executor/Qwen/Qwen2.5-32B-Instruct"`)
- Reviewer model is configured but not selected anywhere in CEO script:
  - configured at `config/openclaw.foreman.json:60-73`
  - no reviewer/pod selection branch in `scripts/paperclip-openclaw-executor.sh:620-739`
- Executor path preflights only executor `/models`, never planner/reviewer:
  - `scripts/paperclip-openclaw-executor.sh:220-424`
- Completion gate is output-shape based, not evidence-grounding based:
  - `is_substantive_deliverable()` in `scripts/paperclip-openclaw-executor.sh:156-190`
  - completion comment posts raw model text at `scripts/paperclip-openclaw-executor.sh:718-725`
- Fact-check or claim-verification module does not exist on CEO path:
  - no verification pass between `run_openclaw_attempt` and `patch_issue(..., done, ...)` in `scripts/paperclip-openclaw-executor.sh:697-726`

---

## Section A — Change 1: CEO Global Binding to DeepSeek

### A1. Current pinning path (where CEO reasoning is forced to executor)

1. Heartbeat invokes OpenClaw without explicit model/provider:
   - `scripts/paperclip-openclaw-executor.sh:663`
2. OpenClaw resolves model via defaults:
   - `config/openclaw.foreman.json:4-7`
3. Default primary is executor:
   - `config/openclaw.foreman.json:6`
4. Preflight hard-codes executor model expectation:
   - expected model at `scripts/paperclip-openclaw-executor.sh:306`
5. Script has no branch for planner/reviewer model selection:
   - single run path in `scripts/paperclip-openclaw-executor.sh:656-739`

### A2. Rebinding mechanism (decision locked)

Options evaluated:

- **(a) Flip `agents.defaults.model.primary` to planner**
  - Pros: one-line behavior shift.
  - Cons: global blast radius; affects ChiefOfStaff planning/review calls and any other OpenClaw path relying on defaults.
  - Conflict: Chief path currently uses `openclaw agent` without `--agent` override in both planning and Stage-2 review (`scripts/paperclip-chief-executor.sh:225-227`, `scripts/paperclip-chief-executor.sh:585-587`), so default flip can alter non-CEO behavior unintentionally.

- **(b) Add CEO-specific entries in `agents.list` and invoke with `--agent`**
  - Pros: scoped rebinding; explicit per-step model selection; reversible; lowest operational risk.
  - Cons: requires additive config and explicit `--agent` wiring in execution loop.
  - This aligns with available CLI capability (`openclaw agent --agent <id>`, observed from `openclaw agent --help`).

- **(c) Bypass OpenClaw and call planner `/chat/completions` directly**
  - Pros: deterministic model targeting.
  - Cons: bypasses existing OpenClaw behavior, toolchain context, and consistency guarantees; larger divergence from working loop.
  - Higher complexity and rollback risk than necessary for first migration.

**Decision locked: use (b)** (CEO-specific agent bindings in OpenClaw config and `--agent` selection per step). Do not flip global defaults.

Impact checks:

- Corrections system: unaffected directly (lives in Chief path, not CEO worker), but avoid default-flip side effects that could alter Chief behavior.
- Compaction safeguard: currently set to planner model (`config/openclaw.foreman.json:8-11`); retained unchanged.
- Existing tests: reliability tests are end-to-end status/auth/ownership focused; they do not currently validate model identity, so model rebinding should add explicit checks in D5.
- ChiefOfStaff path: **do not change in this phase**. Keep Chief behavior unchanged.

### A3. DeepSeek context and token settings suitability

Current planner settings:
- `contextWindow: 16384` (`config/openclaw.foreman.json:55`)
- default `maxTokens: 1024` with purpose override for synthesis (`config/openclaw.foreman.json`)

Assessment:
- A single planner `maxTokens` value is insufficient because planner serves multiple purposes (short JSON plan generation vs long-form synthesis).
- **Decision locked:** use hybrid budgeting:
  - provider default for planner remains small (`1024`) for routine/short calls,
  - synthesis calls use a purpose override (`max_output_tokens=6144`),
  - runtime preflight clamps against pod hard ceiling and fails loud on overflow risk.
- With `contextWindow: 16384`, synthesis at `6144` leaves ~10k input-token budget for verified step outputs and evidence manifests.

### A4. DeepSeek `<think>` trace handling

Current path does not strip reasoning traces:
- Output is consumed directly from `proc.stdout` and posted (`scripts/paperclip-openclaw-executor.sh:686-687`, `scripts/paperclip-openclaw-executor.sh:718-723`).
- No sanitization hook for `<think>...</think>` exists in CEO path.

Proposal:
- Add a normalization function in new pipeline module:
  - strip or quarantine `<think>...</think>` before downstream verification/posting.
  - retain raw output in per-run artifact store for debugging only.
- Enforce final comment policy: no internal reasoning traces in Paperclip comments.

Tradeoff:
- Stripping traces may remove useful context for debugging; mitigated by storing raw step output in run logs (B4).

---

## Section B — Change 2: Per-Task Model Sequence Planning + Step Routing

### B1. Task plan schema

Proposed JSON schema:

```json
{
  "task_id": "uuid",
  "task_identifier": "FOR-78",
  "plan_version": 1,
  "generated_at": "ISO-8601",
  "steps": [
    {
      "step_id": "s1",
      "intent": "Classify task and gather required evidence",
      "pod": "planner|executor|reviewer",
      "model": "provider/model-id",
      "agent_binding": "ceo-planner|ceo-executor|ceo-reviewer",
      "budget_purpose": "plan_generation|step_execution|code_analysis|synthesis|probe",
      "max_output_tokens": 1024,
      "input_refs": ["task_body", "repo_context"],
      "output_ref": "s1_output",
      "acceptance": {
        "must_include": ["..."],
        "must_not_include": ["unverified claims"]
      },
      "verification": {
        "required": true,
        "claim_types": ["file_content", "shell_output"]
      }
    }
  ],
  "synthesis": {
    "pod": "planner",
    "model": "deepseek-ai/DeepSeek-R1-Distill-Qwen-32B",
    "agent_binding": "ceo-planner",
    "budget_purpose": "synthesis",
    "max_output_tokens": 6144,
    "input_refs": ["task_body", "s1_output", "s2_output"]
  }
}
```

Coverage:
- step ordering: array order + step_id.
- input/output passing: `input_refs`, `output_ref`.
- pod/model selection: `pod`, `model`, `agent_binding`.
- token budgeting: `budget_purpose`, `max_output_tokens` with hard-ceiling preflight clamp.
- final synthesis: dedicated `synthesis` object.

### B2. CEO task-evaluation prompt (plan generation)

Proposed planner prompt (first call every task):

> You are the CEO planner. Return only strict JSON (no markdown, no prose).  
> Build an execution plan for task `{task_id}`.  
> You may choose only from this pod/model menu:
> - planner: deepseek-ai/DeepSeek-R1-Distill-Qwen-32B (`agent_binding=ceo-planner`)
> - executor: Qwen/Qwen2.5-32B-Instruct (`agent_binding=ceo-executor`)
> - reviewer: Qwen/Qwen2.5-Coder-32B-Instruct (`agent_binding=ceo-reviewer`)
>  
> Rules:
> - Include 1..N ordered steps and one synthesis section.
> - Each step must define `step_id`, `intent`, `pod`, `model`, `agent_binding`, `input_refs`, `output_ref`, and `verification`.
> - Do not invent unavailable pods/models.
> - Use one step only if the task is trivially answerable without tool-backed claims.

Plan validation behavior:
- Parse JSON with strict schema validation.
- Validate pod/model against an allowed static menu derived from `state/pods.json` + config.
- On malformed/invalid plan: **fail loud** and mark issue `blocked` with validation error (no fallback single-step auto-plan).

### B3. Execution loop design

Loop:
1. Generate plan via planner binding.
2. Validate plan schema/menu.
3. For each step:
   - Resolve `input_refs`.
   - Execute with selected binding.
   - Capture raw output and metadata.
   - Run verification pass (Section C).
   - If verified, persist as `output_ref`; else fail per policy.
4. Run synthesis via planner binding using verified outputs only.
5. Post final comment and close issue.

Model switching mechanism recommendation:
- **Use OpenClaw `--agent <binding>` per step** (least invasive and reversible).
- Configure three CEO bindings in `agents.list`:
  - `ceo-planner` -> planner model
  - `ceo-executor` -> executor model
  - `ceo-reviewer` -> reviewer model
- Keep one orchestration loop in heartbeat script; select binding per step.

Why this over config reload or direct HTTP calls:
- No runtime config rewrite race.
- No custom HTTP client complexity per provider.
- Uses proven CLI invocation path already in production (`scripts/paperclip-openclaw-executor.sh:663`).

### B4. Intermediate output persistence

Proposed per-run layout:

- `state/run-logs/<run_id>/plan.json`
- `state/run-logs/<run_id>/step-<n>-<step_id>-<pod>.raw.txt`
- `state/run-logs/<run_id>/step-<n>-<step_id>-<pod>.verified.json`
- `state/run-logs/<run_id>/step-<n>-<step_id>-<pod>.accepted.md`
- `state/run-logs/<run_id>/synthesis.raw.txt`
- `state/run-logs/<run_id>/synthesis.verified.md`
- `state/run-logs/<run_id>/tool-calls.jsonl`
- `state/run-logs/<run_id>/verification-summary.json`

This enables:
- deterministic input chaining,
- post-hoc debugging,
- reproducibility of verification outcomes.

### B5. Fail-loud rules (decision locked)

- Pod unreachable: fail current step -> mark task `blocked` with exact endpoint/error.
- Empty/malformed step output: fail step immediately; no implicit alternate model routing.
- Plan references unknown pod/model or missing `state/pods.json` mapping: hard fail before step execution.
- Verification timeout/failure: reject step output; do not synthesize from unverified text.

No silent downgrade rules:
- no auto switch planner->executor or reviewer->executor.
- no hidden retries on other models.
- retries only same step/model with explicit log marker (bounded count, default 0 or 1).

**Decision locked:** any unverified claim in a CEO deliverable causes hard failure. On failure, the system must:
1) mark the step failed,
2) post a verification report as failure evidence to the Paperclip issue,
3) transition issue state to `blocked`,
4) never transition to `done` for that run.

### B6. How many OpenClaw agents? (decision locked)

Options:
- Single persistent session with model switching: lower process overhead, but cross-step context contamination and unclear model-switch semantics.
- Fresh OpenClaw process/session per step with explicit binding: deterministic boundaries, cleaner provenance.
- Direct HTTP calls bypass OpenClaw for worker steps: strongest control, highest implementation surface.

**Decision locked:** fresh OpenClaw invocation per step with explicit `--agent` binding, keeping orchestration in one heartbeat run.

Rationale:
- clear provenance per step,
- avoids hidden state bleed across heterogeneous models,
- keeps compatibility with existing session-id plumbing (`scripts/paperclip-openclaw-executor.sh:647-648`).
- enables deterministic, traceable step session identifiers (`<run_id>-step-<n>-<pod>`) for debugging.

### B7. Backward compatibility for short tasks

Allow plan to contain exactly one execution step + synthesis, both on planner binding when task is simple.

Decision rule:
- planner decides one-step vs multi-step during plan generation,
- but heartbeat applies guardrails:
  - if task requires factual claims/tool references, enforce at least one tool-capable execution step before synthesis.

This preserves low overhead for short tasks while keeping anti-hallucination guarantees.

---

## Section C — Change 3: Fact-Check Guardrails

### C1. Claim taxonomy and verification source

Fact-checkable claim classes:

1. File existence (`path exists`): verify via filesystem stat/read result.
2. File content (`line says`): verify via recorded read output with line ranges.
3. Shell output (`command returned X`): verify against recorded command stdout/stderr/exit.
4. API response (`status/body`): verify against recorded HTTP response metadata/body.
5. Git claim (`branch/commit`): verify against recorded git command output.
6. External URL claim: verify against recorded fetch output + URL/timestamp.
7. Dependency/version claim: verify against recorded package manager or lockfile read.

If a claim cannot be verified cheaply post-hoc, enforce production rule:
- claim must reference recorded tool evidence ID; otherwise claim is rejected.

### C2. Claim extraction/grounding mechanism (decision locked)

Options:
- (a) LLM claim extraction: expensive and itself can hallucinate.
- (b) Force fully structured free-text claims: brittle authoring burden.
- (c) Tool-evidence-first references (recommended): model must cite evidence IDs from recorded tool calls.

**Decision locked: (c) primary (tool-evidence-first)**.

Required changes:
- Prompt contract: every factual claim must include `[evidence:<id>]`.
- Tool-call recorder writes canonical evidence objects.
- Verification pass rejects claims lacking valid evidence IDs.

Locked synthesis exception:
- Implementation/review steps use per-factual-sentence evidence tags (strict).
- Synthesis step may use claim-block references only if it appends a machine-readable evidence manifest:
  - `synthesis_evidence_manifest` JSON mapping each synthesis claim block to evidence IDs and resolved tool-call record IDs.
- If synthesis manifest is missing or any manifest ID fails resolution, synthesis hard-fails.

OpenClaw integration note:
- current config allows tools (`read`, `edit`, `write`, `exec`, `process`, `web_search`, `web_fetch`) at `config/openclaw.foreman.json:17-20`.
- current CEO script does not ingest structured tool-call trace from OpenClaw output path, so additive recorder/parsing is required.

### C3. Verification pass design (decision locked)

Per-step flow:
1. Parse step output into claims + evidence references.
2. Resolve each evidence ID from `tool-calls.jsonl`.
3. Re-verify cheap classes when needed (e.g., short `git status` freshness checks).
4. Emit `VerificationResult`:
   - `pass`: all claims verified
   - `partial`: subset verified (with list)
   - `fail`: one or more critical claims unverifiable/false
5. Acceptance policy:
   - **hard fail-whole-step** if any claim fails verification.
   - no silent stripping for CEO deliverables.

6. Synthesis-manifest validation:
   - required for synthesis output acceptance when claim-block citation mode is used.
   - verifier validates manifest completeness and evidence-id resolvability before accepting synthesis.

### C4. FOR-78 regression walkthrough

Would this design catch the two regressions?

- Hallucinated bash output:
  - claim references command output but no matching recorded `exec/process` evidence ID -> verification fail.
  - if ID exists but output mismatch -> verification fail.
- `.git/hooks/sendemail-validate.sample` false finding:
  - must cite file-read evidence with matching path/lines.
  - if absent or mismatched from recorded read -> verification fail.

Therefore both failures are blocked before final comment posting.

### C5. FOR-78 fixed regression test (gating)

FOR-78 becomes a fixed verifier fixture. The original problematic output pattern (hallucinated bash outputs and the `.git/hooks/sendemail-validate.sample` false finding) is replayed as test input against the verifier.

Gate requirements:

1. Input fixture contains the original FOR-78 regression text patterns.
2. Verifier must fail the output with claim-level diagnostics for both:
   - command-output claim without valid evidence,
   - file-content/finding claim without valid evidence.
3. The verifier is **not considered implemented** until this gate passes and evidence is documented.

Required evidence artifacts to store and cite in this doc once implemented:

- `state/run-logs/for78-regression/fixture-input.md`
- `state/run-logs/for78-regression/tool-calls.jsonl`
- `state/run-logs/for78-regression/verification-summary.json`
- `state/run-logs/for78-regression/failure-report.md`

### C6. Prompt-level anti-hallucination text (exact additions)

Add to all three prompt classes (plan generation, step execution, synthesis):

> Non-negotiable: Do not fabricate facts, command output, file contents, API responses, or tool results.  
> Every factual claim must include an evidence tag in the form `[evidence:<id>]` that maps to a recorded tool call.  
> If evidence is missing or a tool call failed, explicitly state `unknown` or `tool_call_failed` instead of guessing.  
> Claims without valid evidence tags will be rejected by verification and the run will fail.

### C7. Fact-checker module placement

Proposed module: `scripts/lib/fact_checker.py`

Entry point:

```python
def verify_step_output(step: dict, output_text: str, tool_call_log: list[dict]) -> VerificationResult:
    ...
```

Inputs:
- `step` plan step metadata,
- raw model output,
- structured tool call records for the run/step.

Output:
- verdict (`pass|partial|fail`),
- claim-level diagnostics,
- sanitized accepted text (optional),
- timing metrics.

Invocation point:
- after each step execution and before output is accepted into step store.

### C8. Performance budget

Proposed budgets:
- verification target: <= 8s per step soft budget
- hard timeout: 20s per step

On timeout:
- **fail loud** (`blocked`) with explicit message `verification_timeout`.
- no acceptance of unverified step output.

---

## Section D — Cross-Cutting Concerns

### D1. Tool-call recording infrastructure

Current state:
- CEO script logs coarse events (`[executor] ...`) but not canonical per-tool evidence objects.
- No structured per-tool record consumed by verifier exists in CEO path.

Design:
- Add `state/run-logs/<run_id>/tool-calls.jsonl`.
- Record fields:
  - `evidence_id`, `step_id`, `tool_name`, `args`, `started_at`, `finished_at`,
  - `exit_code` (if command), `stdout`, `stderr`,
  - `http_status`/`response_body` (if API/web),
  - `source` (`openclaw_tool` or `heartbeat_native`).
- Interception strategy:
  - parse OpenClaw JSON output mode where possible and map tool events,
  - supplement with native wrapper logging for heartbeat-owned operations.

### D2. Auth / run-id / checkout invariants

No changes required to:
- run-scoped header injection (`scripts/paperclip-openclaw-executor.sh:527-537`),
- checkout ownership path (`scripts/paperclip-openclaw-executor.sh:564-577`, `scripts/paperclip-openclaw-executor.sh:608-615`),
- fail-loud API-key/run-id assumptions (`scripts/paperclip-openclaw-executor.sh:49-53`, `scripts/paperclip-openclaw-executor.sh:529-531`).

If any future implementation attempts to bypass these, treat as blocker.

### D3. Integration-check signal additions

Current checks include pod liveness, config coherence, gateway ping, executor API probe, paperclip API, and CEO auth probe (`scripts/integration-check.sh:2-10`, `scripts/integration-check.sh:321-360`).

Additive signals proposed:
- `ceo_multistep_rate`: last N CEO runs with `steps_count > 1`.
- `ceo_step_verification_pass_rate`: verified claims pass ratio.
- `ceo_unverified_claim_blocks`: count of blocked runs due to verification.
- `ceo_model_route_coverage`: planner/executor/reviewer usage distribution.
- `ceo_synthesis_output_length_p95`: synthesis output length trend.
- `ceo_synthesis_near_ceiling_rate`: percent of synthesis outputs at >=90% of configured synthesis budget (watching for 6144 saturation).

Failure modes caught:
- accidental fallback to single-model path,
- silent verifier disablement,
- reviewer pod never used,
- drift between planned and executed routing.

### D4. Migration plan (decision locked)

**Decision locked:** feature flag + staged rollout `single -> shadow -> multi`.

- Flag: `FOREMAN_CEO_PIPELINE_MODE=single|shadow|multi`
  - `single`: current stable path (default initially).
  - `shadow`: run new planner/step/verifier pipeline in parallel for every CEO task, but do not post/close from shadow output.
  - `multi`: promote new path for posting/closure.

Reason:
- preserves known-good path while proving new behavior.
- allows side-by-side quality and latency measurement before cutover.

Shadow soak requirement (locked):

- minimum 48 hours **and**
- minimum 20 real CEO runs spanning at least 4 distinct task shapes,
- whichever is later.

Shadow behavior requirements (locked):

- Write shadow artifacts to `state/run-logs/<run_id>/shadow-*.{json,md}`.
- Always run verification in shadow mode.
- Shadow verification failures must be logged with full claim-level report.
- If 20+ shadow runs complete with zero verification failures, treat that as a verifier-looseness risk requiring manual review before cutover approval.

#### D4.1 Cutover-readiness report contract

Before flipping to `multi`, generate:

- `state/run-logs/cutover-readiness/ceo-pipeline-cutover-report.json`
- `state/run-logs/cutover-readiness/ceo-pipeline-cutover-report.md`

Required report fields:

1. `window_start`, `window_end`
2. `total_shadow_runs`
3. `task_shapes_covered` (distinct shape list + counts)
4. `shadow_pass_rate_overall`
5. `shadow_pass_rate_by_shape`
6. `verification_failures` (count + per-run references)
7. `verification_failure_examples` (at least one detailed case, if any)
8. `single_vs_shadow_divergences` (counts and representative diffs)
9. `synthesis_length_metrics` (p50/p95/max and near-ceiling rate)
10. `go_no_go_recommendation` (agent recommendation with rationale)

Go/no-go criteria (locked):

- No automatic cutover by agent.
- Operator (Jonathan) reviews report artifacts and approves cutover explicitly.
- Block cutover if:
  - shadow coverage requirement not met,
  - unresolved high-severity verifier failures remain,
  - divergence quality is unacceptable,
  - no verification failures were caught across broad shadow runs (possible verifier looseness; requires manual explanation before approval),
  - verifier appears too loose (e.g., zero failures across broad shadow runs with known noisy tasks).

### D5. Testing methodology

Augment current 6-shape x 2-batch reliability suite with:

1. **Plan quality tests**:
   - validate schema and meaningful step decomposition per shape.
2. **Routing correctness tests**:
   - assert executed step bindings/pods match plan.
3. **Fact-check recall tests**:
   - inject known hallucination patterns (FOR-78 style); verifier must fail.
4. **Fact-check precision tests**:
   - known-correct grounded claims should pass unstripped.
5. **Synthesis quality tests**:
   - final comment must be evidence-tagged, coherent, and free of `<think>`.

FOR-78 regression fixture:
- include prior failure patterns explicitly in fixture prompt and require verifier rejection unless tool evidence exists.

### D6. Scope sanity check

Proposed change is additive and does not require modifying:
- auth/run-jwt/run-id mechanics (`b3fab4b` path),
- checkout ownership handling,
- heartbeat picker logic,
- RunPod provisioning scripts.

Expected implementation shape:
- new pipeline module(s),
- one branch point in `scripts/paperclip-openclaw-executor.sh` gated by `FOREMAN_CEO_PIPELINE_MODE`,
- keep existing single-pod path intact during migration.

Potentially impacted by config-only decisions:
- if default model is globally flipped instead of scoped bindings, Chief path behavior may change (not recommended).

Future-phase note (locked):
- ChiefOfStaff remains unchanged in this phase.
- Design new pipeline/fact-check components as shared libraries so Chief adoption can happen later without CEO-specific rewrites.

---

## Decisions locked

- Scoped model binding (no global default flip): use `ceo-planner` / `ceo-executor` / `ceo-reviewer` with per-step `--agent` routing (A2, B3).
- Token budgeting is hybrid: per-provider defaults plus per-purpose overrides with hard-ceiling fail-loud clamp; planner synthesis budget target is `max_output_tokens=6144` (A3, B1, D3).
- Verification is hard-fail only for CEO deliverables; unverifiable claims block completion and force `blocked` with verification evidence (B5, C3).
- Rollout is `single -> shadow -> multi` with locked shadow soak and explicit operator-approved cutover report (D4, D4.1).
- Session strategy is fresh OpenClaw session per step with deterministic session IDs (`<run_id>-step-<n>-<pod>`) (B6).
- Evidence tags are strict per factual sentence for implementation/review steps; synthesis allows claim-block tagging only with required machine-readable evidence manifest (C2, C3).
- ChiefOfStaff remains unchanged in this phase; design remains shared-library-friendly for later Chief adoption (A2, D6).
- Verifier depth is tool-evidence-only in phase 1 (no secondary LLM claim extraction) (C2, C3).

