> Archived reference: This document describes the pre-migration RunPod pod architecture and is retained for historical context.

# Inference Endpoints (Phase 1 Corrected)

## Architecture

Foreman v2 uses a four-pod, always-on RunPod Secure Cloud roster. All
pods expose OpenAI-compatible APIs via vLLM on `/v1`.

| Logical name | Model | Role | Default chat route |
| --- | --- | --- | --- |
| embedding | `Qwen/Qwen3-Embedding-8B` | RAG embedding generation | No |
| executor | `Qwen/Qwen2.5-32B-Instruct` | Main chat and tool-use execution | Yes |
| planner | `deepseek-ai/DeepSeek-R1-Distill-Qwen-32B` | Higher-depth planning/reasoning | No |
| reviewer | `Qwen/Qwen2.5-Coder-32B-Instruct` | Code review and codebase QA | No |

Quality-first production targets provision executor/planner/reviewer on A100/H100-class
80 GB hardware. `embedding` remains on the cost-efficient embedding tier.

Secure Cloud is mandatory for these pods. Community Cloud is intentionally not
used for production reliability reasons.

## Pod Runtime Flags

`scripts/provision.sh` creates each pod using `vllm/vllm-openai:latest` and
passes endpoint-specific vLLM args via `dockerStartCmd`:

- `embedding`
  - `--model Qwen/Qwen3-Embedding-8B`
  - `--dtype half`
  - `--max-model-len 4096`
  - `--gpu-memory-utilization 0.85`
  - `--max-num-seqs 16`
  - `--trust-remote-code`
- `executor`
  - `--model Qwen/Qwen2.5-32B-Instruct`
  - `--dtype half`
  - `--enable-auto-tool-choice`
  - `--tool-call-parser hermes`
  - `--max-model-len 8192`
  - `--gpu-memory-utilization 0.90`
  - `--max-num-seqs 8`
  - `--trust-remote-code`
- `planner`
  - `--model deepseek-ai/DeepSeek-R1-Distill-Qwen-32B`
  - `--dtype half`
  - `--max-model-len 8192`
  - `--gpu-memory-utilization 0.90`
  - `--max-num-seqs 8`
  - `--trust-remote-code`
- `reviewer`
  - `--model Qwen/Qwen2.5-Coder-32B-Instruct`
  - `--dtype half`
  - `--max-model-len 8192`
  - `--gpu-memory-utilization 0.90`
  - `--max-num-seqs 8`
  - `--trust-remote-code`

### VRAM Budget (32B fp16 on 80 GB GPU)

| Component | Size |
| --- | --- |
| Model weights (32B × 2 bytes) | ~64 GB |
| Available VRAM at 0.90 utilization | 72 GB |
| KV cache headroom | ~8 GB |
| Supported context per request | up to 8192 tokens |
| Concurrent sequences (`max-num-seqs`) | 8 |

`--max-model-len 32768` exceeds KV cache capacity on 80 GB GPUs and causes vLLM to
crash before binding its HTTP port. `8192` is the tested safe ceiling.

### Network Volume Caching

On first successful provisioning, `provision.sh` creates a persistent RunPod
network volume (`foreman-v2-{role}`) in the pod's data center. Subsequent pod
recreations use the cached volume, eliminating the 64 GB model re-download and
reducing startup from ~40 min to ~7 min.

## Auto Up-Tiering Behavior

`scripts/provision.sh` continuously converges roles toward each role's highest
preferred Secure Cloud GPU:

- if a role is missing, the script provisions it first (existing behavior)
- if a role is healthy but running on a fallback SKU, it keeps polling every
  `MISSING_ROLE_RETRY_SECONDS` (`300s`) for better-preference SKUs
- once a better SKU is available, the script performs a safe swap:
  1. provision replacement pod
  2. wait for RUNNING + role health checks
  3. atomically update `state/pods.json` for the role
  4. run `scripts/configure.sh` + `openclaw gateway restart`
  5. run role smoke validation
  6. decommission old fallback pod only after successful smoke
- on any up-tier failure, serving traffic remains on the prior healthy pod and
  retry polling continues

## OpenClaw Routing Caveat (Intentional)

OpenClaw defaults to `executor/Qwen/Qwen2.5-32B-Instruct` for chat.
Planner, reviewer, and embedding providers are provisioned and reachable via role dispatch.

## Balance Guardrail

`scripts/provision.sh` enforces a balance precheck via `RUNPOD_MIN_BALANCE_HOURS`
(default `24`). For controlled H100 capacity retries, use a shorter window
(`RUNPOD_MIN_BALANCE_HOURS=4`) and keep explicit teardown discipline between attempts.

## Current Live Cost Snapshot (2026-04-08)

Observed live roster:

- Embedding: `NVIDIA RTX A5000` at approximately `$0.27`/hour
- Executor: `NVIDIA RTX A4500` at approximately `$0.25`/hour
- Planner: `NVIDIA A40` at approximately `$0.44`/hour

Total baseline compute is approximately `$0.96`/hour, about `$691.20`/month
(30-day estimate, compute only).

RunPod storage is billed separately. Current pod spec uses:

- `containerDiskInGb: 80`
- `volumeInGb: 50`

RunPod savings-plan fields are exposed in GraphQL per GPU type as
`threeMonthPrice` and `sixMonthPrice`. Verified values for selected SKUs:

- A4500: verify at conversion time
- A5000: verify at conversion time
- A40: verify at conversion time

Recommended rollout strategy:

1. Start on hourly pricing during initial bring-up and stability testing.
2. After 1-2 weeks of stable operation, convert to a savings plan for each
   continuously used GPU type.
3. Keep enough account balance for storage + compute; savings plans reduce
   compute rate but do not remove storage billing.

## Failure Modes (A-E) in `provision.sh`

- **Mode A - Capacity unavailable**: retries up to 15 minutes per pod with
  exponential backoff while already-running pods remain up.
- **Mode B - Permanent request/account error**: immediate fail with teardown.
- **Mode C - Pod never reaches RUNNING**: fail and teardown using best-effort
  lifecycle diagnostics from pod state fields.
- **Mode D - RUNNING but model/health check fails**: retries up to `80` checks
  at `30s` intervals, then fail and teardown using best-effort lifecycle diagnostics.
- **Mode E - RunPod API infrastructure failure (5xx/429/timeouts)**: retries
  the failing API call for up to 5 minutes, then preserves already-healthy pods
  with a warning so you can retry or run `./scripts/teardown.sh` explicitly.

Note: public RunPod REST/GraphQL docs do not currently document a pod container
logs retrieval endpoint. Mode C/D therefore report best-effort state and
lifecycle diagnostics instead of log tails.
