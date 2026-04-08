# Inference Endpoints (Phase 1 Corrected)

## Architecture

Foreman v2 Phase 1 uses a three-pod, always-on RunPod Secure Cloud roster. All
pods expose OpenAI-compatible APIs via vLLM on `/v1`.

| Logical name | Model | Role | Default chat route |
| --- | --- | --- | --- |
| embedding | `Qwen/Qwen3-Embedding-8B` | RAG embedding generation | No |
| executor | `Qwen/Qwen3-14B-AWQ` | Main chat and tool-use execution | Yes |
| planner | `Qwen/Qwen3-30B-A3B-Instruct-2507-AWQ` | Higher-depth planning/reasoning | No |

Secure Cloud is mandatory for these pods. Community Cloud is intentionally not
used for production reliability reasons.

## Pod Flags

`scripts/provision.sh` creates each pod using RunPod's vLLM worker image and
applies endpoint-specific environment variables that map to vLLM flags:

- `embedding`
  - `MODEL_NAME=Qwen/Qwen3-Embedding-8B`
  - `TASK=embed`
  - `DTYPE=half`
  - `MAX_MODEL_LEN=32768`
  - `GPU_MEMORY_UTILIZATION=0.90`
  - `MAX_NUM_SEQS=16`
- `executor`
  - `MODEL_NAME=Qwen/Qwen3-14B-AWQ`
  - `QUANTIZATION=awq_marlin`
  - `DTYPE=half`
  - `MAX_MODEL_LEN=32768`
  - `GPU_MEMORY_UTILIZATION=0.90`
  - `MAX_NUM_SEQS=16`
- `planner`
  - `MODEL_NAME=Qwen/Qwen3-30B-A3B-Instruct-2507-AWQ`
  - `QUANTIZATION=awq_marlin`
  - `ENABLE_EXPERT_PARALLEL=true`
  - `MAX_MODEL_LEN=65536`
  - `GPU_MEMORY_UTILIZATION=0.90`
  - `MAX_NUM_SEQS=16`

## OpenClaw Routing Caveat (Intentional)

OpenClaw defaults to `executor/Qwen/Qwen3-14B-AWQ` for chat in Phase 1.
Planner and embedding providers are provisioned and reachable, but are not used
for automatic task routing yet. Paperclip-driven dispatch and deeper provider
routing are Phase 2 concerns.

## Cost Optimization (Verified Current Pricing)

The selected Secure Cloud SKUs are chosen using the "always cheapest acceptable
SKU" rule:

- Embedding: `NVIDIA RTX A4000` at `0.25` credits/hour
- Executor: `NVIDIA RTX A5000` at `0.27` credits/hour
- Planner: `NVIDIA A40` at `0.40` credits/hour

Total baseline compute is `0.92` credits/hour, about `662.40` credits/month
(30-day estimate, compute only).

RunPod savings-plan fields are exposed in GraphQL per GPU type as
`threeMonthPrice` and `sixMonthPrice`. Verified values for selected SKUs:

- A4000: `0.25` -> `0.21` (3-month), `0.20` (6-month)
- A5000: `0.27` -> `0.23` (3-month), `0.21` (6-month)
- A40: `0.40` -> `0.30` (3-month), `0.28` (6-month)

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
- **Mode D - RUNNING but model/health check fails**: three retries, then fail
  and teardown using best-effort lifecycle diagnostics.
- **Mode E - RunPod API infrastructure failure (5xx/429/timeouts)**: retries
  the failing API call for up to 5 minutes, then fails with teardown.

Note: public RunPod REST/GraphQL docs do not currently document a pod container
logs retrieval endpoint. Mode C/D therefore report best-effort state and
lifecycle diagnostics instead of log tails.
