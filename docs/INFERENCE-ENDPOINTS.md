# Inference Endpoints (Phase 1 Corrected)

## Architecture

Foreman v2 Phase 1 uses a three-pod, always-on RunPod Secure Cloud roster. All
pods expose OpenAI-compatible APIs via vLLM on `/v1`.

| Logical name | Model | Role | Default chat route |
| --- | --- | --- | --- |
| embedding | `Qwen/Qwen3-Embedding-8B` | RAG embedding generation | No |
| executor | `Qwen/Qwen3-14B-AWQ` | Main chat and tool-use execution | Yes |
| planner | `Qwen/Qwen3-30B-A3B-Instruct-2507` | Higher-depth planning/reasoning | No |

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
  - `--model Qwen/Qwen3-14B-AWQ`
  - `--quantization awq_marlin`
  - `--dtype half`
  - `--enable-auto-tool-choice`
  - `--tool-call-parser hermes`
  - `--max-model-len 32768`
  - `--gpu-memory-utilization 0.85`
  - `--max-num-seqs 8`
  - `--trust-remote-code`
- `planner`
  - `--model Qwen/Qwen3-30B-A3B-Instruct-2507`
  - `--quantization fp8`
  - `--max-model-len 16384`
  - `--gpu-memory-utilization 0.85`
  - `--max-num-seqs 8`
  - `--trust-remote-code`

## OpenClaw Routing Caveat (Intentional)

OpenClaw defaults to `executor/Qwen/Qwen3-14B-AWQ` for chat in Phase 1.
Planner and embedding providers are provisioned and reachable, but are not used
for automatic task routing yet. Paperclip-driven dispatch and deeper provider
routing are Phase 2 concerns.

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
