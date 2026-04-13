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

### A2. Rebinding mechanism recommendation

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

**Recommendation: (b)** (CEO-specific agent bindings in OpenClaw config and `--agent` selection per step).

Impact checks:

- Corrections system: unaffected directly (lives in Chief path, not CEO worker), but avoid default-flip side effects that could alter Chief behavior.
- Compaction safeguard: currently set to planner model (`config/openclaw.foreman.json:8-11`); retained unchanged.
- Existing tests: reliability tests are end-to-end status/auth/ownership focused; they do not currently validate model identity, so model rebinding should add explicit checks in D5.
- ChiefOfStaff path: **should not receive this global rebind** by default. Keep Chief behavior unchanged unless explicitly approved.

### A3. DeepSeek context and token settings suitability

Current planner settings:
- `contextWindow: 16384` (`config/openclaw.foreman.json:55`)
- `maxTokens: 2048` (`config/openclaw.foreman.json:56`)

Assessment:
- For CEO synthesis over multi-step outputs, `maxTokens: 2048` is likely tight when requiring structured evidence, risk notes, and comprehensive findings.
- Proposed target for CEO planner-bound synthesis: **`maxTokens: 4096`** (initial), with telemetry-based tuning.
- `contextWindow: 16384` is acceptable for first rollout if step outputs are summarized/compacted before synthesis; if full raw artifacts are injected, consider `32768` in a second pass.

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
    "input_refs": ["task_body", "s1_output", "s2_output"]
  }
}
```

Coverage:
- step ordering: array order + step_id.
- input/output passing: `input_refs`, `output_ref`.
- pod/model selection: `pod`, `model`, `agent_binding`.
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

### B5. Fail-loud rules

- Pod unreachable: fail current step -> mark task `blocked` with exact endpoint/error.
- Empty/malformed step output: fail step immediately; no implicit alternate model routing.
- Plan references unknown pod/model or missing `state/pods.json` mapping: hard fail before step execution.
- Verification timeout/failure: reject step output; do not synthesize from unverified text.

No silent downgrade rules:
- no auto switch planner->executor or reviewer->executor.
- no hidden retries on other models.
- retries only same step/model with explicit log marker (bounded count, default 0 or 1).

### B6. How many OpenClaw agents?

Options:
- Single persistent session with model switching: lower process overhead, but cross-step context contamination and unclear model-switch semantics.
- Fresh OpenClaw process/session per step with explicit binding: deterministic boundaries, cleaner provenance.
- Direct HTTP calls bypass OpenClaw for worker steps: strongest control, highest implementation surface.

**Recommendation: fresh OpenClaw invocation per step with explicit `--agent` binding**, keeping orchestration in one heartbeat run.

Rationale:
- clear provenance per step,
- avoids hidden state bleed across heterogeneous models,
- keeps compatibility with existing session-id plumbing (`scripts/paperclip-openclaw-executor.sh:647-648`).

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

### C2. Claim extraction/grounding mechanism

Options:
- (a) LLM claim extraction: expensive and itself can hallucinate.
- (b) Force fully structured free-text claims: brittle authoring burden.
- (c) Tool-evidence-first references (recommended): model must cite evidence IDs from recorded tool calls.

**Recommendation: (c) primary**.

Required changes:
- Prompt contract: every factual claim must include `[evidence:<id>]`.
- Tool-call recorder writes canonical evidence objects.
- Verification pass rejects claims lacking valid evidence IDs.

OpenClaw integration note:
- current config allows tools (`read`, `edit`, `write`, `exec`, `process`, `web_search`, `web_fetch`) at `config/openclaw.foreman.json:17-20`.
- current CEO script does not ingest structured tool-call trace from OpenClaw output path, so additive recorder/parsing is required.

### C3. Verification pass design

Per-step flow:
1. Parse step output into claims + evidence references.
2. Resolve each evidence ID from `tool-calls.jsonl`.
3. Re-verify cheap classes when needed (e.g., short `git status` freshness checks).
4. Emit `VerificationResult`:
   - `pass`: all claims verified
   - `partial`: subset verified (with list)
   - `fail`: one or more critical claims unverifiable/false
5. Acceptance policy:
   - default **fail-whole-step** if any critical claim fails.
   - optional non-critical stripping only for explicitly-marked non-critical claims.

Recommendation: **fail-whole-step** for CEO final deliverables (stricter, consistent with anti-hallucination principle).

### C4. FOR-78 regression walkthrough

Would this design catch the two regressions?

- Hallucinated bash output:
  - claim references command output but no matching recorded `exec/process` evidence ID -> verification fail.
  - if ID exists but output mismatch -> verification fail.
- `.git/hooks/sendemail-validate.sample` false finding:
  - must cite file-read evidence with matching path/lines.
  - if absent or mismatched from recorded read -> verification fail.

Therefore both failures are blocked before final comment posting.

### C5. Prompt-level anti-hallucination text (exact additions)

Add to all three prompt classes (plan generation, step execution, synthesis):

> Non-negotiable: Do not fabricate facts, command output, file contents, API responses, or tool results.  
> Every factual claim must include an evidence tag in the form `[evidence:<id>]` that maps to a recorded tool call.  
> If evidence is missing or a tool call failed, explicitly state `unknown` or `tool_call_failed` instead of guessing.  
> Claims without valid evidence tags will be rejected by verification and the run will fail.

### C6. Fact-checker module placement

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

### C7. Performance budget

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

Failure modes caught:
- accidental fallback to single-model path,
- silent verifier disablement,
- reviewer pod never used,
- drift between planned and executed routing.

### D4. Migration plan

Recommendation: **feature flag + shadow mode**.

- Flag: `FOREMAN_CEO_PIPELINE_MODE=single|shadow|multi`
  - `single`: current stable path (default initially).
  - `shadow`: run new planner/step/verifier pipeline but do not post/close from shadow output; log diffs only.
  - `multi`: promote new path for posting/closure.

Reason:
- preserves known-good path while proving new behavior.
- allows side-by-side quality and latency measurement before cutover.

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

---

## Section E — Open Questions for Jonathan

1. **Model-binding strategy: Option A vs B**
   - A: global default flip to planner.
   - B: scoped CEO agent bindings + per-step `--agent` selection.
   - Tradeoff: A is simpler but high blast radius; B is explicit and safer.
   - Recommendation: **B**.
   - Need confirmation: proceed with scoped bindings only?

2. **Planner token budget: keep 2048 vs increase to 4096**
   - Tradeoff: 4096 increases latency/cost but reduces synthesis truncation risk.
   - Recommendation: **4096 for CEO synthesis path**.
   - Need confirmation: approve initial increase?

3. **Step acceptance policy: strip unverifiable claims vs hard fail**
   - Tradeoff: stripping can salvage runs but risks partial-truth outputs; hard fail is stricter and noisier.
   - Recommendation: **hard fail for CEO deliverables**.
   - Need confirmation: strict fail policy acceptable?

4. **Pipeline mode rollout: `single -> shadow -> multi` vs direct cutover**
   - Tradeoff: shadow adds operational time but lowers launch risk.
   - Recommendation: **shadow first**.
   - Need confirmation: required shadow soak duration (e.g., 24h, 3 days, N runs)?

5. **OpenClaw session strategy: per-step fresh session vs shared session**
   - Tradeoff: shared session lowers overhead but risks cross-step/model contamination.
   - Recommendation: **fresh per-step session**.
   - Need confirmation: acceptable to prioritize determinism over slight latency increase?

6. **Evidence-tag format strictness**
   - Option A: mandatory `[evidence:<id>]` tag on every factual sentence.
   - Option B: mandatory tag per paragraph/claim block.
   - Tradeoff: A strongest precision, B lower authoring friction.
   - Recommendation: **A for implementation/review steps, B allowed only in synthesis if each summarized claim maps to listed evidence IDs**.
   - Need confirmation.

7. **ChiefOfStaff path alignment**
   - Option A: leave Chief path unchanged in this phase.
   - Option B: partially adopt planner binding/fact-check contracts for Chief now.
   - Tradeoff: B improves consistency but broadens scope significantly.
   - Recommendation: **A (leave Chief unchanged now)**.
   - Need confirmation.

8. **Verifier implementation depth in phase 1**
   - Option A: tool-evidence-only verifier first (no secondary LLM claim extraction).
   - Option B: hybrid with LLM extraction fallback.
   - Tradeoff: A more deterministic and cheaper; B broader coverage but more complexity/hallucination risk.
   - Recommendation: **A first**.
   - Need confirmation.

