> Archived reference: This document describes the pre-migration RunPod pod architecture and is retained for historical context.

# 2026-04-10 Migration Investigation

## Scope

Phase 0 read-only investigation for:

- endpoint registry source of truth and gateway propagation
- current running pod launch args
- `provision.sh` SKU selection and Mode A-E structure
- role/pod registry and health check tracking
- gateway restart/reload requirements

## 1) Endpoint Registry Location and Propagation

### Source-of-truth files

- Role contract: `config/role-routing.json`
- Pod endpoint registry: `state/pods.json`
- OpenClaw template: `config/openclaw.foreman.json`
- OpenClaw rendered runtime config: `~/.openclaw/openclaw.json` (written by `scripts/configure.sh`)

### How URLs flow to runtime

1. `scripts/provision.sh` provisions pods and writes role->`base_url` into `state/pods.json`.
2. `scripts/configure.sh` reads `state/pods.json`, validates expected role/model mappings, then renders `config/openclaw.foreman.json` placeholders into `~/.openclaw/openclaw.json`.
3. Role dispatch uses:
   - `config/role-routing.json` (role->provider/model/transport contract)
   - `state/pods.json` (provider base URL for role)
   - `~/.openclaw/openclaw.json` (provider `apiKey`, provider sections)
4. `scripts/start.sh` and `scripts/foreman-stack-start.sh` explicitly restart OpenClaw gateway after configure.

### Supabase usage

No Supabase `inference_endpoints` table integration is present in this `foreman-v2` path. Runtime routing is local file-based (`role-routing.json` + `state/pods.json` + rendered OpenClaw config).

## 2) Current Running Pod Launch Args (RunPod API)

Credentials source used for investigation: `.env` (no `.env.local` present in this checkout).

At investigation time, only one Foreman pod is active:

- Pod ID: `iwpu43xdbi2w0h`
- Name: `foreman-v2-embedding`
- Status: `RUNNING`
- Image: `vllm/vllm-openai:latest`
- GPU: `NVIDIA RTX A5000`
- Secure Cloud: `true`
- Region: `CA-MTL-1`

`dockerStartCmd` captured from RunPod API:

- `--model Qwen/Qwen3-Embedding-8B`
- `--dtype half`
- `--max-model-len 4096`
- `--gpu-memory-utilization 0.85`
- `--max-num-seqs 16`
- `--trust-remote-code`
- `--host 0.0.0.0`
- `--port 8000`

No active executor/planner/coder(reviewer) pod existed at capture time, so live launch args for those roles could not be read from current RunPod pod state.

## 3) Current `provision.sh` SKU Selection Logic

### GPU selection function

- `resolve_gpu_candidates(role)`:
  - queries RunPod GraphQL `gpuTypes` for each candidate GPU ID in role config
  - filters to `secureCloud == true`
  - requires `securePrice` presence
  - currently returns sorted by cheapest `securePrice`

### Provision/create path

- `create_pod_with_modes(role, gpu_candidates)`:
  - POST `/v1/pods` with selected `gpuTypeIds`
  - handles Mode E (API infra failures) and Mode A (capacity)
  - Mode A/E time windows are bounded by constants and logged with structured debug artifacts

### Current mode constants

- `MODE_A_WINDOW_SECONDS = 15 * 60`
- `MODE_E_WINDOW_SECONDS = 5 * 60`
- `POD_RUNNING_TIMEOUT_SECONDS = 15 * 60`
- `HEALTH_RETRIES = 80`
- `HEALTH_RETRY_SECONDS = 30`

## 4) Failure Decision Tree (A-E) in Current Script

- **Mode A**: capacity unavailable / no instances (transient). Retries within Mode A time window.
- **Mode B**: permanent request/auth/validation/balance errors. Fails loudly.
- **Mode C**: pod failed to reach `RUNNING` before timeout / terminal state pre-running.
- **Mode D**: pod `RUNNING` but model/health verification failed after retries.
- **Mode E**: RunPod API infra instability (5xx/429/timeouts) beyond Mode E window.

Mode behaviors are implemented in dedicated exception classes and surfaced with debug logs in `state/logs/*`.

## 5) Pod Registry and Health Check Tracking

### Registry/state tracking

- Persistent local registry: `state/pods.json`
- Incremental updates: `save_state_incremental(entry)`
- Startup reconciliation: `reconcile_existing_state_or_abort()`
  - hydrates existing alive pods
  - now resumes with healthy pods and only provisions missing roles

### Health and model checks

- `wait_for_running_or_mode_c(pod_id, role_name)` for run state transition
- `health_check_with_mode_d(role, pod)` for endpoint readiness:
  - `/v1/models` must include expected model ID
  - embedding additionally validates `/v1/embeddings` response shape

## 6) Gateway Restart Requirement

Repository evidence indicates explicit restart after endpoint/config updates:

- `scripts/start.sh` -> `openclaw gateway restart`
- `scripts/foreman-stack-start.sh` -> configure + `openclaw gateway restart`
- `scripts/foreman-stack-health.sh` -> restarts gateway when unhealthy or drift detected

No repository evidence supports live hot-reload or TTL-based endpoint refresh. Operationally, endpoint changes should be followed by explicit gateway restart/reload.

## 7) Role Naming for This Migration

This checkout uses role names:

- `executor`
- `planner`
- `embedding`
- `reviewer`

For migration instructions that reference `coder`, this run maps `coder -> reviewer` (Qwen2.5-Coder-32B-Instruct).
