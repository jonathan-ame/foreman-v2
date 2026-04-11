# 2026-04-10 H100 -> A100 Cutover Report

## Summary

Cutover execution is currently **partially blocked by upstream RunPod Secure Cloud capacity** for remaining large-model roles.

- `planner` is now healthy (`deepseek-ai/DeepSeek-R1-Distill-Qwen-32B` on H100 PCIe).
- `executor` and `coder(reviewer)` are still pending due repeated `create pod: There are no instances currently available`.
- Healthy already-provisioned pods are now preserved while missing-role retries continue every 5 minutes.
- No production role endpoint was cut over to a degraded model output path.

## Timeline (UTC)

- **Phase 0 completed**: endpoint registry, gateway propagation, role routing, and running pod inspection documented in `docs/migrations/2026-04-10-investigation.md`.
- **Phase 1/2 implemented**:
  - SKU-chain expansion and per-role preference support in `scripts/provision.sh`.
  - dry-run SKU-chain validation mode (`--dry-run-sku-chain`).
  - training mode (`--mode=training --lifetime=...`) with lifetime safety rails and auto-teardown scheduler.
  - auto up-tiering for fallback pods: roles continue 5-minute polling for higher-preference SKUs and perform safe swap (health -> configure/restart -> smoke -> old pod teardown) when available.
- **Provisioning loop behavior corrected**:
  - previous behavior that decommissioned already-running resumed pods on Mode B preflight failure was fixed.
  - script now preserves preexisting healthy pods and retries missing roles only.
- **Current active retry loop**:
  - `embedding` and `planner` roles are healthy.
  - `executor` / `reviewer` provisioning attempts still hit repeated RunPod 500 capacity responses.
  - retry cycle waits 300s between missing-role rounds.

## Health/Verification Results

Verification commands executed in current state:

- `./scripts/check-role-routing-consistency.sh` -> **failed**
  - `ERROR: role 'embedding' base URL mismatch between OpenClaw provider and state/pods.json`
- `./scripts/smoke-test.sh` -> **failed**
  - `ERROR: Missing executor in state/pods.json`
- `./scripts/verify-paperclip-role-routing.sh` -> **failed**
  - connection refused to local Paperclip API endpoint in current runtime state

These failures are expected while `executor` and `reviewer` are still pending capacity.

## Deviations from Intended End State

1. `executor/planner/coder(reviewer)` migration did not execute end-to-end because no eligible Secure Cloud capacity was available for missing role provisioning.
2. One-shot cutover script is created but not successfully run yet:
   - `scripts/migrations/2026-04-10-h100-to-a100-cutover.sh`
3. Final smoke and role-verifier gates cannot pass until all required runtime roles are present and healthy.

## Evidence

- Active pod registry snapshot:
  - `state/pods.json` (currently only `embedding`)
- Capacity/error logs:
  - `state/logs/*-executor-E.log`
  - `state/logs/*-planner-E.log`
  - `state/logs/*-reviewer-E.log`
- Provisioning lifecycle output captured in terminal logs during retries.

## Next Required Step

Continue retry loop until all three missing roles (`executor`, `planner`, `reviewer`) are provisioned on Secure Cloud, then run:

1. `scripts/configure.sh`
2. `openclaw gateway restart`
3. `scripts/check-role-routing-consistency.sh`
4. `scripts/smoke-test.sh`
5. `scripts/verify-paperclip-role-routing.sh`

After these pass, execute the sequential one-shot cutover script and then finalize decision log + savings summary.
