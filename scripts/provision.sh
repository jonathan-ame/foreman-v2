#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
STATE_DIR="${ROOT_DIR}/state"
STATE_FILE="${STATE_DIR}/pods.json"

DRY_RUN_SKU_CHAIN=0
PROVISION_MODE="production"
TRAINING_LIFETIME=""
TRAINING_GPU="NVIDIA H100 PCIe"

for arg in "$@"; do
  case "${arg}" in
    --dry-run-sku-chain) DRY_RUN_SKU_CHAIN=1 ;;
    --mode=production) PROVISION_MODE="production" ;;
    --mode=training) PROVISION_MODE="training" ;;
    --lifetime=*) TRAINING_LIFETIME="${arg#--lifetime=}" ;;
    --gpu=*) TRAINING_GPU="${arg#--gpu=}" ;;
    *)
      echo "ERROR: Unknown arguments: ${arg}" >&2
      exit 1
      ;;
  esac
done

if [[ "${PROVISION_MODE}" == "training" ]]; then
  if [[ -z "${TRAINING_LIFETIME}" ]]; then
    echo "ERROR: --lifetime is required when --mode=training." >&2
    exit 1
  fi
fi

export PROVISION_MODE TRAINING_LIFETIME TRAINING_GPU

if [[ "${DRY_RUN_SKU_CHAIN}" -eq 1 ]]; then
  python3 - <<'PY'
DEFAULT_GPU_PREFERENCE_CHAIN = [
    "NVIDIA A100 80GB PCIe",
    "NVIDIA A100-SXM4-80GB",
    "NVIDIA RTX PRO 6000 Blackwell Server Edition",
    "NVIDIA RTX PRO 6000 Blackwell Workstation Edition",
    "NVIDIA RTX PRO 6000 Blackwell Max-Q Workstation Edition",
    "NVIDIA H100 PCIe",
    "NVIDIA H100 NVL",
    "NVIDIA H100 80GB HBM3",
    "NVIDIA H200",
    "NVIDIA H200 NVL",
]

GPU_ID_ALIASES: dict = {}

roles = ["executor", "planner", "reviewer"]
print("[dry-run] SKU chain validation (no RunPod API calls)")
print("[dry-run] default chain order (official RunPod API type IDs):")
for idx, sku in enumerate(DEFAULT_GPU_PREFERENCE_CHAIN, start=1):
    print(f"  {idx}. {sku}")

for role in roles:
    chain = DEFAULT_GPU_PREFERENCE_CHAIN[:]
    print(f"[dry-run] {role} iteration simulation:")
    for attempt in range(1, len(chain) + 2):
        sku = chain[(attempt - 1) % len(chain)]
        print(f"  attempt {attempt}: {sku}")

def rank_for_gpu(current_gpu: str) -> int:
    current = current_gpu.strip().lower()
    for idx, pref in enumerate(DEFAULT_GPU_PREFERENCE_CHAIN):
        if current == pref.strip().lower():
            return idx
    return -1

print("[dry-run] up-tier eligibility simulation:")
for sample in ["NVIDIA H200", "NVIDIA H100 PCIe", "NVIDIA A100 80GB PCIe"]:
    rank = rank_for_gpu(sample)
    if rank <= 0:
        print(f"  current={sample}: already top-preference or unknown, no up-tier candidates")
        continue
    better = DEFAULT_GPU_PREFERENCE_CHAIN[:rank]
    print(f"  current={sample} (rank {rank}): better candidates -> {', '.join(better)}")
print("[dry-run] validation completed successfully.")
PY
  exit 0
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "ERROR: Missing ${ENV_FILE}. Copy .env.example to .env first." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

if [[ -z "${RUNPOD_API_KEY:-}" ]]; then
  echo "ERROR: RUNPOD_API_KEY is required in ${ENV_FILE}." >&2
  exit 1
fi

mkdir -p "${STATE_DIR}"

python3 - "${STATE_FILE}" <<'PY'
import datetime as dt
import json
import os
import re
import signal
import subprocess
import sys
import time
import urllib.error
import urllib.request

API_KEY = os.environ["RUNPOD_API_KEY"]
PROVISION_MODE = os.environ.get("PROVISION_MODE", "production").strip().lower()
TRAINING_LIFETIME = os.environ.get("TRAINING_LIFETIME", "").strip()
TRAINING_GPU = os.environ.get("TRAINING_GPU", "NVIDIA H100 PCIe").strip() or "NVIDIA H100 PCIe"
STATE_FILE = sys.argv[1]
STATE_DIR = os.path.dirname(STATE_FILE)
LOG_DIR = os.path.join(STATE_DIR, "logs")
TRAINING_STATE_FILE = os.path.join(STATE_DIR, "training-pods.json")
TRAINING_JOB_LOG_DIR = os.path.join(STATE_DIR, "training-jobs")

REST_BASE = "https://rest.runpod.io/v1"
GRAPHQL_URL = "https://api.runpod.io/graphql"

MODE_A_WINDOW_SECONDS = 15 * 60
MODE_E_WINDOW_SECONDS = 5 * 60
POD_RUNNING_TIMEOUT_SECONDS = 15 * 60
HEALTH_RETRIES = 120   # 60-minute window: 120 × 30s; 32B model needs ~30-45 min
HEALTH_RETRY_SECONDS = 30
MISSING_ROLE_RETRY_SECONDS = 300

VLLM_IMAGE = "vllm/vllm-openai:latest"
TRAINING_IMAGE = "runpod/pytorch:2.2.0-py3.10-cuda12.1.1-devel-ubuntu22.04"
PROXY_PORT = 8000

# GPU type IDs must match the official RunPod REST API enum exactly.
# Verified 2026-04-09 against https://rest.runpod.io/v1/openapi.json
# Ordered: best price-performance first; premium tiers at the end.
DEFAULT_GPU_PREFERENCE_CHAIN = [
    "NVIDIA A100 80GB PCIe",                               # ~$1.39/hr
    "NVIDIA A100-SXM4-80GB",                               # ~$1.49/hr
    "NVIDIA RTX PRO 6000 Blackwell Server Edition",        # ~$1.89/hr
    "NVIDIA RTX PRO 6000 Blackwell Workstation Edition",   # ~$1.89/hr
    "NVIDIA RTX PRO 6000 Blackwell Max-Q Workstation Edition",
    "NVIDIA H100 PCIe",                                    # ~$2.49/hr
    "NVIDIA H100 NVL",                                     # ~$2.49/hr
    "NVIDIA H100 80GB HBM3",                               # ~$2.99/hr (SXM class)
    "NVIDIA H200",                                         # ~$3.59/hr
    "NVIDIA H200 NVL",                                     # top tier
]

# All entries in DEFAULT_GPU_PREFERENCE_CHAIN are exact official API strings;
# no aliases are needed. Kept empty for backward compatibility.
GPU_ID_ALIASES: dict[str, list[str]] = {}

ROSTER = [
    {
        "logical_name": "embedding",
        "model_id": "Qwen/Qwen3-Embedding-8B",
        "gpu_candidates": [
            "NVIDIA RTX A5000",
            "NVIDIA RTX A6000",
            "NVIDIA A40",
        ],
        "docker_start_cmd": [
            "--model", "Qwen/Qwen3-Embedding-8B",
            "--dtype", "half",
            "--max-model-len", "4096",
            "--gpu-memory-utilization", "0.85",
            "--max-num-seqs", "16",
            "--trust-remote-code",
            "--host", "0.0.0.0",
            "--port", "8000",
        ],
        "env": {},
    },
    {
        "logical_name": "executor",
        "model_id": "Qwen/Qwen2.5-32B-Instruct",
        "gpu_preference_chain": DEFAULT_GPU_PREFERENCE_CHAIN,
        "docker_start_cmd": [
            "--model", "Qwen/Qwen2.5-32B-Instruct",
            "--dtype", "half",
            "--enable-auto-tool-choice",
            "--tool-call-parser", "hermes",
            "--max-model-len", "32768",
            "--gpu-memory-utilization", "0.85",
            "--max-num-seqs", "8",
            "--trust-remote-code",
            "--host", "0.0.0.0",
            "--port", "8000",
        ],
        "env": {},
    },
    {
        "logical_name": "planner",
        "model_id": "deepseek-ai/DeepSeek-R1-Distill-Qwen-32B",
        "gpu_preference_chain": DEFAULT_GPU_PREFERENCE_CHAIN,
        "docker_start_cmd": [
            "--model", "deepseek-ai/DeepSeek-R1-Distill-Qwen-32B",
            "--dtype", "half",
            "--max-model-len", "32768",
            "--gpu-memory-utilization", "0.85",
            "--max-num-seqs", "8",
            "--trust-remote-code",
            "--host", "0.0.0.0",
            "--port", "8000",
        ],
        "env": {},
    },
    {
        "logical_name": "reviewer",
        "model_id": "Qwen/Qwen2.5-Coder-32B-Instruct",
        "gpu_preference_chain": DEFAULT_GPU_PREFERENCE_CHAIN,
        "docker_start_cmd": [
            "--model", "Qwen/Qwen2.5-Coder-32B-Instruct",
            "--dtype", "half",
            "--max-model-len", "32768",
            "--gpu-memory-utilization", "0.85",
            "--max-num-seqs", "8",
            "--trust-remote-code",
            "--host", "0.0.0.0",
            "--port", "8000",
        ],
        "env": {},
    },
]

created_pods = []
teardown_in_progress = False
teardown_force_window_until = 0.0


def now_iso() -> str:
    return dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"


def print_status(msg: str) -> None:
    print(f"[provision] {msg}", flush=True)


class RunPodScriptError(Exception):
    def __init__(
        self,
        role: str,
        mode: str,
        safe_message: str,
        status: int | None = None,
        category: str | None = None,
        pod_id: str | None = None,
        log_path: str | None = None,
    ) -> None:
        super().__init__(safe_message)
        self.role = role
        self.mode = mode
        self.safe_message = safe_message
        self.status = status
        self.category = category
        self.pod_id = pod_id
        self.log_path = log_path


class RunPodModeAError(RunPodScriptError):
    pass


class RunPodModeBError(RunPodScriptError):
    pass


class RunPodModeCError(RunPodScriptError):
    pass


class RunPodModeDError(RunPodScriptError):
    pass


class RunPodModeEError(RunPodScriptError):
    pass


class RunPodUnclassifiedError(RunPodScriptError):
    pass


class RunPodPartialPreserveExit(RunPodScriptError):
    pass


def write_debug_log(role: str, mode: str, status: int | None, payload: dict | str) -> str:
    os.makedirs(LOG_DIR, exist_ok=True)
    stamp = dt.datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    path = os.path.join(LOG_DIR, f"{stamp}-{role}-{mode}.log")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(
            {
                "timestamp": now_iso(),
                "role": role,
                "mode": mode,
                "status": status,
                "payload": payload,
            },
            f,
            indent=2,
            ensure_ascii=True,
        )
        f.write("\n")
    return path


def payload_text(payload: dict | str) -> str:
    if isinstance(payload, dict):
        return json.dumps(payload, ensure_ascii=True).lower()
    return str(payload).lower()


def safe_message_from_payload(payload: dict | str) -> str:
    if isinstance(payload, dict):
        error_obj = payload.get("error")
        if isinstance(error_obj, dict):
            msg = error_obj.get("message")
            if isinstance(msg, str) and msg.strip():
                return msg.strip()
        if isinstance(error_obj, str) and error_obj.strip():
            return error_obj.strip()
        errors = payload.get("errors")
        if isinstance(errors, list) and errors:
            first = errors[0]
            if isinstance(first, dict):
                msg = first.get("message")
                if isinstance(msg, str) and msg.strip():
                    return msg.strip()
            if isinstance(first, str) and first.strip():
                return first.strip()
        msg = payload.get("message")
        if isinstance(msg, str) and msg.strip():
            return msg.strip()
    elif str(payload).strip():
        return str(payload).strip()
    return "No additional details available."


def classify_error_category(status: int | None, payload: dict | str) -> str:
    text = payload_text(payload)
    if status in {401, 403} or "unauthorized" in text or "forbidden" in text:
        return "authentication_or_permission_error"
    if status == 429:
        return "rate_limited"
    if status is not None and status >= 500:
        return "server_error"
    if status == 0 or "timeout" in text:
        return "network_or_timeout_error"
    if is_mode_a(status or 0, payload):
        return "out_of_capacity"
    if "invalid" in text or "malformed" in text or "not eligible" in text:
        return "invalid_configuration"
    return "api_error"


def build_mode_error(
    exc_type,
    role: str,
    mode: str,
    status: int | None,
    payload: dict | str,
    fallback_message: str,
    pod_id: str | None = None,
) -> RunPodScriptError:
    category = classify_error_category(status, payload)
    safe_detail = safe_message_from_payload(payload)
    safe = f"{fallback_message} (category={category}; status={status}; message={safe_detail})"
    log_path = write_debug_log(role, mode, status, payload)
    return exc_type(
        role=role,
        mode=mode,
        safe_message=safe,
        status=status,
        category=category,
        pod_id=pod_id,
        log_path=log_path,
    )


def api_request(
    method: str,
    url: str,
    body: dict | None = None,
    headers: dict | None = None,
    timeout: int = 30,
) -> tuple[int, dict | str]:
    merged_headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}",
        "User-Agent": "foreman-v2/1.0 (provision.sh)",
    }
    if headers:
        merged_headers.update(headers)
    data = None
    if body is not None:
        data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=merged_headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            status = resp.getcode()
            raw = resp.read().decode("utf-8") or "{}"
            try:
                return status, json.loads(raw)
            except Exception:
                return status, raw
    except urllib.error.HTTPError as e:
        raw = (e.read() or b"").decode("utf-8")
        try:
            return e.code, json.loads(raw)
        except Exception:
            return e.code, raw or str(e)
    except Exception as e:
        return 0, {"error": str(e)}


def graphql(query: str, role: str = "graphql") -> dict:
    status, payload = api_request("POST", GRAPHQL_URL, {"query": query})
    if status != 200:
        if is_mode_e(status, payload):
            raise build_mode_error(
                RunPodModeEError,
                role=role,
                mode="E",
                status=status,
                payload=payload,
                fallback_message="RunPod GraphQL API is unavailable.",
            )
        raise build_mode_error(
            RunPodModeBError,
            role=role,
            mode="B",
            status=status,
            payload=payload,
            fallback_message="RunPod GraphQL request failed permanently.",
        )

    if not isinstance(payload, dict):
        raise build_mode_error(
            RunPodUnclassifiedError,
            role=role,
            mode="U",
            status=status,
            payload=payload,
            fallback_message="GraphQL response was not valid JSON.",
        )

    gql_errors = payload.get("errors")
    if gql_errors:
        msg = safe_message_from_payload(payload)
        msg_l = msg.lower()
        if any(k in msg_l for k in ("unauthorized", "forbidden", "invalid", "malformed", "permission")):
            raise build_mode_error(
                RunPodModeBError,
                role=role,
                mode="B",
                status=status,
                payload=payload,
                fallback_message="RunPod GraphQL returned a permanent request/account error.",
            )
        raise build_mode_error(
            RunPodModeEError,
            role=role,
            mode="E",
            status=status,
            payload=payload,
            fallback_message="RunPod GraphQL returned errors despite HTTP 200.",
        )
    return payload


def is_mode_a(status: int, payload: dict | str) -> bool:
    """Capacity/availability errors — GPU not available right now, retry later."""
    text = payload_text(payload)
    capacity_needles = (
        "no gpu available",
        "out of capacity",
        "insufficient capacity",
        "not enough gpu",
        "currently unavailable",
        "no instances",
        "stock",
    )
    if any(n in text for n in capacity_needles):
        return True
    if status in {400, 409, 422} and any(n in text for n in capacity_needles):
        return True
    return False


def is_mode_e(status: int, payload: dict | str) -> bool:
    """Infrastructure/transient errors — NOT capacity (those are Mode A)."""
    if is_mode_a(status, payload):
        return False
    if status in {429, 500, 502, 503, 504, 0}:
        return True
    text = payload_text(payload)
    return "timeout" in text


def mode_b_error(status: int, payload: dict | str) -> bool:
    if status in {401, 403}:
        return True
    if status in {400, 422, 404} and not is_mode_a(status, payload):
        return True
    text = payload_text(payload)
    needles = (
        "invalid",
        "malformed",
        "unauthorized",
        "forbidden",
        "not eligible",
        "permission",
    )
    return any(n in text for n in needles)


def load_state() -> dict:
    if not os.path.exists(STATE_FILE):
        return {"pods": []}
    try:
        with open(STATE_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as exc:
        raise RunPodUnclassifiedError(
            role="state-file",
            mode="U",
            safe_message=(
                f"Failed to parse {STATE_FILE}; refusing to continue with unknown state. "
                "Fix or remove the invalid state file first."
            ),
            status=500,
            category="state_file_invalid",
            log_path=write_debug_log(
                "state-file",
                "U",
                500,
                {"error": str(exc), "state_file": STATE_FILE},
            ),
        )


def write_state_atomic(state: dict) -> None:
    tmp_path = f"{STATE_FILE}.tmp-{int(time.time() * 1000)}"
    with open(tmp_path, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2)
        f.write("\n")
    os.replace(tmp_path, STATE_FILE)


def save_state_incremental(entry: dict) -> None:
    state = load_state()
    pods = [p for p in state.get("pods", []) if p.get("logical_name") != entry.get("logical_name")]
    pods.append(entry)
    state["pods"] = sorted(pods, key=lambda x: x.get("logical_name", ""))
    write_state_atomic(state)


def remove_state_role(role_name: str) -> None:
    state = load_state()
    pods = [p for p in state.get("pods", []) if p.get("logical_name") != role_name]
    state["pods"] = sorted(pods, key=lambda x: x.get("logical_name", ""))
    write_state_atomic(state)


def clear_state() -> None:
    write_state_atomic({"pods": []})


def parse_lifetime_seconds(raw: str) -> int:
    match = re.fullmatch(r"(\d+)([smhd])", raw.strip().lower())
    if not match:
        raise RunPodModeBError(
            role="training",
            mode="B",
            safe_message=(
                "Invalid --lifetime format. Use one of: <N>s, <N>m, <N>h, <N>d "
                "(example: --lifetime=10h)."
            ),
            status=400,
            category="invalid_training_lifetime",
        )
    value = int(match.group(1))
    unit = match.group(2)
    mult = {"s": 1, "m": 60, "h": 3600, "d": 86400}[unit]
    seconds = value * mult
    if seconds <= 0:
        raise RunPodModeBError(
            role="training",
            mode="B",
            safe_message="Training lifetime must be greater than zero.",
            status=400,
            category="invalid_training_lifetime",
        )
    if seconds > 24 * 3600:
        raise RunPodModeBError(
            role="training",
            mode="B",
            safe_message="Training lifetime cannot exceed 24h.",
            status=400,
            category="training_lifetime_too_long",
        )
    return seconds


def load_training_state() -> dict:
    if not os.path.exists(TRAINING_STATE_FILE):
        return {"pods": []}
    try:
        with open(TRAINING_STATE_FILE, "r", encoding="utf-8") as f:
            payload = json.load(f)
    except Exception as exc:
        raise RunPodUnclassifiedError(
            role="training",
            mode="U",
            safe_message=f"Failed parsing {TRAINING_STATE_FILE}: {exc}",
            status=500,
            category="training_state_invalid",
        )
    if not isinstance(payload, dict) or not isinstance(payload.get("pods"), list):
        raise RunPodUnclassifiedError(
            role="training",
            mode="U",
            safe_message=f"Invalid training state structure in {TRAINING_STATE_FILE}.",
            status=500,
            category="training_state_invalid",
        )
    return payload


def save_training_entry(entry: dict) -> None:
    state = load_training_state()
    pods = [p for p in state.get("pods", []) if p.get("pod_id") != entry.get("pod_id")]
    pods.append(entry)
    state["pods"] = sorted(pods, key=lambda x: x.get("created_at", ""))
    tmp_path = f"{TRAINING_STATE_FILE}.tmp-{int(time.time() * 1000)}"
    with open(tmp_path, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2)
        f.write("\n")
    os.replace(tmp_path, TRAINING_STATE_FILE)


def schedule_training_teardown(pod_id: str, lifetime_seconds: int) -> tuple[str, str]:
    os.makedirs(TRAINING_JOB_LOG_DIR, exist_ok=True)
    log_path = os.path.join(TRAINING_JOB_LOG_DIR, f"{pod_id}-teardown.log")
    script = (
        "import json, os, time, urllib.request, urllib.error\n"
        f"time.sleep({lifetime_seconds})\n"
        "pod_id = os.environ['TRAINING_POD_ID']\n"
        "api_key = os.environ['RUNPOD_API_KEY']\n"
        "req = urllib.request.Request(\n"
        "    f'https://rest.runpod.io/v1/pods/{pod_id}',\n"
        "    headers={'Authorization': f'Bearer {api_key}'},\n"
        "    method='DELETE',\n"
        ")\n"
        "try:\n"
        "    with urllib.request.urlopen(req, timeout=60) as resp:\n"
        "        print(json.dumps({'pod_id': pod_id, 'status': resp.getcode()}), flush=True)\n"
        "except urllib.error.HTTPError as exc:\n"
        "    print(json.dumps({'pod_id': pod_id, 'status': exc.code, 'error': 'http_error'}), flush=True)\n"
        "except Exception as exc:\n"
        "    print(json.dumps({'pod_id': pod_id, 'error': str(exc)}), flush=True)\n"
    )
    env = dict(os.environ)
    env["TRAINING_POD_ID"] = pod_id
    proc = subprocess.Popen(  # noqa: S603
        [sys.executable, "-c", script],
        stdout=open(log_path, "a", encoding="utf-8"),
        stderr=subprocess.STDOUT,
        env=env,
        start_new_session=True,
    )
    return str(proc.pid), log_path


def current_hourly_cost() -> float:
    return sum(float(p.get("hourly_rate", 0.0)) for p in created_pods)


def remove_created_role(role_name: str) -> None:
    global created_pods
    created_pods = [p for p in created_pods if p.get("logical_name") != role_name]


def upsert_created_role(entry: dict) -> None:
    global created_pods
    role_name = entry.get("logical_name")
    created_pods = [p for p in created_pods if p.get("logical_name") != role_name]
    created_pods.append(entry)
    created_pods.sort(key=lambda x: x.get("logical_name", ""))


def get_role_by_name(role_name: str) -> dict:
    for role in ROSTER:
        if role.get("logical_name") == role_name:
            return role
    raise RunPodModeBError(
        role=role_name,
        mode="B",
        safe_message=f"Unknown role: {role_name}",
        status=400,
        category="unknown_role",
    )


def _norm_gpu(value: str | None) -> str:
    return str(value or "").strip().lower()


def role_preference_chain(role: dict) -> list[str]:
    chain = (
        role.get("gpu_preference_chain")
        or role.get("gpu_candidates")
        or DEFAULT_GPU_PREFERENCE_CHAIN
    )
    if not isinstance(chain, list) or not chain:
        raise RunPodModeBError(
            role=role["logical_name"],
            mode="B",
            safe_message=f"GPU preference chain is missing/invalid for role {role['logical_name']}.",
            status=400,
            category="invalid_gpu_chain",
        )
    return chain


def preference_index_for_running_gpu(role: dict, current_gpu: str) -> int:
    current = _norm_gpu(current_gpu)
    chain = role_preference_chain(role)
    for idx, pref in enumerate(chain):
        aliases = [pref] + GPU_ID_ALIASES.get(pref, [])
        if any(current == _norm_gpu(a) for a in aliases):
            return idx
    return -1


def preference_index_for_candidate(role: dict, candidate: dict) -> int:
    chain = role_preference_chain(role)
    preferred = candidate.get("requested_preference")
    if preferred in chain:
        return chain.index(preferred)
    gpu_id = candidate.get("id")
    for idx, pref in enumerate(chain):
        aliases = [pref] + GPU_ID_ALIASES.get(pref, [])
        if any(_norm_gpu(gpu_id) == _norm_gpu(a) for a in aliases):
            return idx
    return -1


def resolve_better_gpu_candidates(role: dict, current_gpu: str) -> list[dict]:
    current_idx = preference_index_for_running_gpu(role, current_gpu)
    if current_idx <= 0:
        return []
    resolved = resolve_gpu_candidates(role)
    return [
        c
        for c in resolved
        if 0 <= preference_index_for_candidate(role, c) < current_idx
    ]


def teardown_single_pod(pod_id: str, role_name: str) -> None:
    status, payload = api_request("DELETE", f"{REST_BASE}/pods/{pod_id}")
    if status in {200, 202, 204, 404}:
        print_status(f"Removed failed {role_name} pod {pod_id} before retry.")
        return
    msg = safe_message_from_payload(payload)
    print_status(f"WARNING: Failed to remove {role_name} pod {pod_id}: HTTP {status}; message={msg}")


def print_billing_window(role_waiting: str, attempt: int, next_wait: int, elapsed: int, total_window: int) -> None:
    hourly = current_hourly_cost()
    per_min = hourly / 60.0
    for pod in created_pods:
        print_status(
            f"{pod['logical_name']} pod RUNNING (${pod['hourly_rate']:.2f}/hr) — waiting for {role_waiting} GPU..."
        )
    print_status(
        f"Currently billing: ${hourly:.2f}/hr (${per_min:.4f}/min) for {len(created_pods)} of {len(ROSTER)} pods"
    )
    remaining = max(total_window - elapsed, 0)
    print_status(
        f"{role_waiting} GPU availability check: attempt {attempt}, next retry in {next_wait}s ({remaining}s remaining)"
    )
    print_status("Press Ctrl+C to abort and tear down all pods from this run")


def is_alive_status(value: str) -> bool:
    return value.upper() not in {"TERMINATED", "EXITED", "FAILED"}


def summarize_running_pods() -> list[dict]:
    return [
        {
            "logical_name": p.get("logical_name"),
            "pod_id": p.get("pod_id"),
            "proxy_url": p.get("proxy_url") or p.get("base_url"),
            "hourly_rate": float(p.get("hourly_rate", 0.0)),
        }
        for p in created_pods
    ]


def preserve_and_warn(mode: str, failed_role: str, safe_message: str, log_path: str | None) -> int:
    running = summarize_running_pods()
    if not running:
        print_status(f"ERROR: {safe_message}")
        if log_path:
            print_status(f"Debug details written to: {log_path}")
        return 1

    print()
    print("==============================================================")
    print(f"WARNING: Mode {mode} timeout while provisioning role '{failed_role}'.")
    print("Healthy pods are being preserved and continue billing.")
    print(f"Details: {safe_message}")
    if log_path:
        print(f"Debug details: {log_path}")
    print("Currently running pods:")
    for row in running:
        print(
            f"- {row['logical_name']}: pod_id={row['pod_id']} "
            f"proxy_url={row['proxy_url']} "
            f"hourly=${row['hourly_rate']:.2f}"
        )
    total_hourly = current_hourly_cost()
    print(f"Current billing: ${total_hourly:.2f}/hr")
    print(
        f"Run ./scripts/provision.sh to retry the {failed_role}, "
        "or run ./scripts/teardown.sh to stop all billing."
    )
    print("==============================================================")
    print()
    return 2


def pause_for_inspection(err: RunPodScriptError) -> None:
    print()
    print("==============================================================")
    print(f"Mode {err.mode} requires manual inspection before teardown.")
    print("Container logs are not available via the documented RunPod public API.")
    if err.pod_id:
        print(f"Inspect pod dashboard: https://runpod.io/console/pods/{err.pod_id}")
    print(f"Failure details: {err.safe_message}")
    if err.log_path:
        print(f"Debug details: {err.log_path}")
    print("Press Enter to continue with teardown, or Ctrl+C to abort and inspect manually.")
    print("==============================================================")
    try:
        with open("/dev/tty", "r") as tty:
            tty.readline()
    except (OSError, EOFError):
        print("(non-interactive shell detected — proceeding with teardown automatically)")


def reconcile_existing_state_or_abort() -> None:
    if not os.path.exists(STATE_FILE):
        return
    state = load_state()
    pods = [p for p in state.get("pods", []) if isinstance(p, dict)]
    if not pods:
        backup = f"{STATE_FILE}.bak-{dt.datetime.utcnow().strftime('%Y%m%d-%H%M%S')}"
        os.replace(STATE_FILE, backup)
        clear_state()
        print_status(f"Backed up empty prior state file to {backup} and reset state/pods.json.")
        return

    alive_entries: list[dict] = []
    alive_entries_runtime: list[dict] = []
    for row in pods:
        pod_id = str(row.get("pod_id") or "").strip()
        role = str(row.get("logical_name") or "unknown")
        if not pod_id:
            continue
        status, payload = api_request("GET", f"{REST_BASE}/pods/{pod_id}?includeMachine=true")
        if status == 200 and isinstance(payload, dict):
            desired = str(payload.get("desiredStatus") or payload.get("status") or "").upper()
            if desired and is_alive_status(desired):
                hydrated = dict(row)
                hydrated["status"] = "healthy" if desired == "RUNNING" else desired.lower()
                alive_entries_runtime.append({**hydrated, "preexisting": True})
                alive_entries.append(hydrated)
        elif status == 404:
            continue
        elif status in {401, 403}:
            raise build_mode_error(
                RunPodModeBError,
                role="startup",
                mode="B",
                status=status,
                payload=payload,
                fallback_message="Cannot verify existing state due to auth/permission error.",
            )
        elif is_mode_e(status, payload):
            raise build_mode_error(
                RunPodModeEError,
                role="startup",
                mode="E",
                status=status,
                payload=payload,
                fallback_message="RunPod API unavailable while checking existing state.",
            )
        else:
            raise build_mode_error(
                RunPodUnclassifiedError,
                role="startup",
                mode="U",
                status=status,
                payload=payload,
                fallback_message=(
                    "Unexpected response while checking existing state; refusing to clear local state."
                ),
            )

    if alive_entries:
        alive_entries.sort(key=lambda x: x.get("logical_name", ""))
        alive_entries_runtime.sort(key=lambda x: x.get("logical_name", ""))
        created_pods.extend(alive_entries_runtime)
        write_state_atomic({"pods": alive_entries})
        details = ", ".join(
            f"{p.get('logical_name')}:{p.get('pod_id')}({p.get('status')})"
            for p in alive_entries
        )
        print_status(
            "Resuming with already-running pods from existing state: "
            f"{details}. Missing roles will be provisioned."
        )
        return

    backup = f"{STATE_FILE}.bak-{dt.datetime.utcnow().strftime('%Y%m%d-%H%M%S')}"
    os.replace(STATE_FILE, backup)
    clear_state()
    print_status(f"Backed up prior state to {backup} and reset state/pods.json.")


def teardown_created_pods(reason: str) -> None:
    global teardown_in_progress, teardown_force_window_until
    teardown_targets = [p for p in created_pods if not p.get("preexisting")]
    if not teardown_targets:
        print_status(f"Teardown skipped: no pods created in this run ({reason}).")
        return
    print_status(f"Teardown started ({reason}).")
    teardown_in_progress = True
    teardown_force_window_until = 0.0
    failures = []
    try:
        for pod in reversed(teardown_targets):
            pod_id = pod["pod_id"]
            status, payload = api_request("DELETE", f"{REST_BASE}/pods/{pod_id}")
            if status in {404}:
                print_status(f"Teardown confirmed {pod_id} already absent (404).")
            elif status not in {200, 202, 204}:
                failures.append((pod_id, status, payload))
                msg = safe_message_from_payload(payload)
                print_status(
                    f"Teardown failed for {pod_id}: HTTP {status}; message={msg}"
                )
            else:
                print_status(f"Teardown accepted for {pod_id}.")
    finally:
        teardown_in_progress = False

    if failures:
        for pod_id, status, payload in failures:
            log_path = write_debug_log("teardown", "T", status, payload)
            print_status(f"Teardown debug details for {pod_id}: {log_path}")
        print_status("Teardown finished with failures; state file retained for manual cleanup.")
    else:
        preserved = [
            {k: v for k, v in pod.items() if k != "preexisting"}
            for pod in created_pods
            if pod.get("preexisting")
        ]
        if preserved:
            write_state_atomic({"pods": preserved})
            print_status("Teardown completed for new pods; preserved preexisting state entries.")
        else:
            clear_state()
            print_status("Teardown completed successfully; state/pods.json reset.")


def resolve_gpu_candidates(role: dict) -> list[dict]:
    """Return an ordered list of candidate GPU dicts for the given role.

    Attempts to enrich each candidate via GraphQL (availability/price data).
    If GraphQL is unavailable (403, 500, etc.) falls back to using the preference
    chain IDs directly — the actual pod creation call will confirm availability.
    Because GPU_ID_ALIASES is now empty and all chain IDs are exact official API
    strings, no alias probing is needed.
    """
    chain = (
        role.get("gpu_preference_chain")
        or role.get("gpu_candidates")
        or DEFAULT_GPU_PREFERENCE_CHAIN
    )
    if not isinstance(chain, list) or not chain:
        raise RunPodModeBError(
            role=role["logical_name"],
            mode="B",
            safe_message=f"GPU preference chain is missing/invalid for role {role['logical_name']}.",
            status=400,
            category="invalid_gpu_chain",
        )

    fields = """
id
displayName
memoryInGb
secureCloud
securePrice
"""
    out = []
    graphql_available = True
    for preferred_id in chain:
        enriched = None
        if graphql_available:
            query = f"""
query {{
  gpuTypes(input: {{id: "{preferred_id}"}}) {{
    {fields}
  }}
}}
"""
            try:
                data = graphql(query, role=f"gpu-resolve-{role['logical_name']}")
                items = (data.get("data") or {}).get("gpuTypes") or []
                if items:
                    row = items[0]
                    if row.get("secureCloud") and row.get("securePrice") is not None:
                        row["requested_preference"] = preferred_id
                        enriched = row
            except Exception as gql_err:
                # GraphQL is forbidden or unavailable for this key — fall back to
                # using IDs directly. The pod creation call is the authoritative
                # availability check.
                graphql_available = False
                print_status(
                    f"GraphQL unavailable ({gql_err!s:.80}); "
                    "falling back to direct REST provisioning for GPU candidates."
                )

        if enriched is None:
            # Use the chain ID directly; let the REST pod creation call decide.
            enriched = {
                "id": preferred_id,
                "displayName": preferred_id,
                "memoryInGb": None,
                "secureCloud": True,
                "securePrice": None,
                "requested_preference": preferred_id,
            }
        out.append(enriched)

    if not out:
        raise RunPodModeAError(
            role=role["logical_name"],
            mode="A",
            safe_message=(
                "No acceptable Secure Cloud GPU found from candidate list. "
                f"Candidates checked: {', '.join(chain)}."
            ),
            status=409,
            category="out_of_capacity",
        )
    return out


def check_balance(required_hourly: float) -> None:
    query = """
query {
  myself {
    clientBalance
  }
}
"""
    data = graphql(query, role="balance-check")
    balance = float(((data.get("data") or {}).get("myself") or {}).get("clientBalance") or 0.0)
    min_hours_raw = os.environ.get("RUNPOD_MIN_BALANCE_HOURS", "24").strip()
    try:
        min_hours = float(min_hours_raw)
    except ValueError:
        raise RunPodModeBError(
            role="balance-check",
            mode="B",
            safe_message=(
                f"Invalid RUNPOD_MIN_BALANCE_HOURS value: {min_hours_raw!r}. "
                "Expected a positive number."
            ),
            status=400,
            category="invalid_balance_window",
        )
    if min_hours <= 0:
        raise RunPodModeBError(
            role="balance-check",
            mode="B",
            safe_message=(
                f"Invalid RUNPOD_MIN_BALANCE_HOURS value: {min_hours_raw!r}. "
                "Expected a positive number."
            ),
            status=400,
            category="invalid_balance_window",
        )
    required = required_hourly * min_hours
    if balance < required:
        raise RunPodModeBError(
            role="balance-check",
            mode="B",
            safe_message=(
                f"Insufficient RunPod balance. Need at least ${required:.2f} for {min_hours:g} hours; "
                f"current balance is ${balance:.2f}. Aborting before creating any pod."
            ),
            status=402,
            category="insufficient_balance",
        )
    print_status(
        f"Balance check passed: ${balance:.2f} available; {min_hours:g}-hour minimum required is ${required:.2f}."
    )


def create_pod_with_modes(role: dict, gpu_candidates: list[dict]) -> tuple[dict, dict]:
    role_name = role["logical_name"]
    # Disk sizing: vllm/vllm-openai:latest image is ~15-20 GB.
    # A 32B fp16 model is ~64 GB. We redirect HF_HOME to /workspace so that
    # model weights land on the network volume (100 GB) rather than the
    # container disk. Container disk only needs to hold the image + vLLM state.
    role_env = dict(role.get("env") or {})
    role_env.setdefault("HF_HOME", "/workspace/hf_cache")
    role_env.setdefault("HUGGINGFACE_HUB_CACHE", "/workspace/hf_cache/hub")

    payload_base = {
        "name": f"foreman-v2-{role_name}",
        "computeType": "GPU",
        "cloudType": "SECURE",
        "imageName": VLLM_IMAGE,
        "gpuCount": 1,
        "containerDiskInGb": 60,   # vllm image ~25 GB + runtime headroom
        "volumeInGb": 100,         # 64 GB model weights + cache
        "volumeMountPath": "/workspace",
        "ports": [f"{PROXY_PORT}/http"],
        "interruptible": False,
        "env": role_env,
        "dockerStartCmd": role.get("docker_start_cmd") or [],
        "dataCenterPriority": "availability",
        "gpuTypePriority": "custom",
    }

    started = time.time()
    attempt = 1
    wait_seconds = 60
    candidate_idx = 0
    mode_a_cycle = 1
    while True:
        selected = gpu_candidates[candidate_idx]
        payload = dict(payload_base)
        payload["gpuTypeIds"] = [selected["id"]]
        status, resp = api_request("POST", f"{REST_BASE}/pods", payload)

        if status in {200, 201} and isinstance(resp, dict) and resp.get("id"):
            return resp, selected

        elapsed = int(time.time() - started)

        # Check Mode A (capacity) before Mode E (infrastructure) — capacity errors
        # from RunPod arrive as HTTP 500 with "no instances currently available" and
        # must trigger SKU chain advancement, not infrastructure retry.
        if is_mode_a(status, resp):
            candidate_idx += 1
            if candidate_idx < len(gpu_candidates):
                next_id = gpu_candidates[candidate_idx]["id"]
                print_status(
                    f"Mode A (capacity) for {role_name} on {selected['id']}; "
                    f"trying next preferred SKU: {next_id}"
                )
                attempt += 1
                continue

            candidate_idx = 0
            if elapsed >= MODE_A_WINDOW_SECONDS:
                raise build_mode_error(
                    RunPodModeAError,
                    role=role_name,
                    mode="A",
                    status=status,
                    payload=resp,
                    fallback_message=(
                        f"Could not provision {role_name} on Secure Cloud within 15 minutes due to capacity."
                    ),
                )
            print_billing_window(role_name, mode_a_cycle, wait_seconds, elapsed, MODE_A_WINDOW_SECONDS)
            time.sleep(wait_seconds)
            wait_seconds = min(wait_seconds * 2, 240)
            mode_a_cycle += 1
            attempt += 1
            continue

        if is_mode_e(status, resp):
            if elapsed >= MODE_E_WINDOW_SECONDS:
                raise build_mode_error(
                    RunPodModeEError,
                    role=role_name,
                    mode="E",
                    status=status,
                    payload=resp,
                    fallback_message=(
                        f"RunPod API is unavailable for more than 5 minutes while creating {role_name}."
                    ),
                )
            msg = safe_message_from_payload(resp)
            print_status(
                f"Mode E (infra) for {role_name}: HTTP {status}; message={msg}. Retrying in {wait_seconds}s."
            )
            time.sleep(wait_seconds)
            wait_seconds = min(wait_seconds * 2, 120)
            attempt += 1
            continue

        if mode_b_error(status, resp):
            raise build_mode_error(
                RunPodModeBError,
                role=role_name,
                mode="B",
                status=status,
                payload=resp,
                fallback_message=f"Permanent provisioning error while creating {role_name}.",
            )

        raise build_mode_error(
            RunPodUnclassifiedError,
            role=role_name,
            mode="U",
            status=status,
            payload=resp,
            fallback_message=f"Unclassified provisioning error while creating {role_name}.",
        )


def get_pod(pod_id: str) -> dict:
    status, resp = api_request("GET", f"{REST_BASE}/pods/{pod_id}?includeMachine=true")
    if status != 200 or not isinstance(resp, dict):
        raise build_mode_error(
            RunPodUnclassifiedError,
            role="pod-query",
            mode="U",
            status=status,
            payload=resp,
            fallback_message=f"Failed to fetch pod status for {pod_id}.",
            pod_id=pod_id,
        )
    return resp


def wait_for_running_or_mode_c(pod_id: str, role_name: str) -> dict:
    deadline = time.time() + POD_RUNNING_TIMEOUT_SECONDS
    while time.time() < deadline:
        pod = get_pod(pod_id)
        desired = str(pod.get("desiredStatus") or "").upper()
        if desired == "RUNNING":
            return pod
        if desired in {"EXITED", "TERMINATED", "FAILED"}:
            raise RunPodModeCError(
                role=role_name,
                mode="C",
                safe_message=(
                    f"Pod entered terminal state {desired} before reaching RUNNING. "
                    "Container logs are not available via the documented RunPod public API."
                ),
                status=409,
                category="pod_failed_to_start",
                pod_id=pod_id,
                log_path=write_debug_log(
                    role_name,
                    "C",
                    409,
                    {
                        "desiredStatus": desired,
                        "lastStatusChange": pod.get("lastStatusChange"),
                        "podSnapshot": pod,
                    },
                ),
            )
        time.sleep(10)
    pod = get_pod(pod_id)
    raise RunPodModeCError(
        role=role_name,
        mode="C",
        safe_message=(
            "Pod did not reach RUNNING within 15 minutes. "
            "Container logs are not available via the documented RunPod public API."
        ),
        status=408,
        category="pod_start_timeout",
        pod_id=pod_id,
        log_path=write_debug_log(
            role_name,
            "C",
            408,
            {
                "lastStatusChange": pod.get("lastStatusChange"),
                "podSnapshot": pod,
            },
        ),
    )


def health_check_with_mode_d(role: dict, pod: dict) -> str:
    pod_id = pod["id"]
    role_name = role["logical_name"]
    model_id = role["model_id"]
    base_url = f"https://{pod_id}-{PROXY_PORT}.proxy.runpod.net/v1"
    models_url = f"{base_url}/models"

    for attempt in range(1, HEALTH_RETRIES + 1):
        status, resp = api_request("GET", models_url)
        if status == 200 and isinstance(resp, dict):
            model_ids = [m.get("id") for m in (resp.get("data") or []) if isinstance(m, dict)]
            if model_id in model_ids:
                if role_name == "embedding":
                    emb_status, emb_resp = api_request(
                        "POST",
                        f"{base_url}/embeddings",
                        {"model": model_id, "input": "foreman-v2 embedding health probe"},
                    )
                    if emb_status == 200 and isinstance(emb_resp, dict):
                        data = emb_resp.get("data") or []
                        if data and isinstance(data[0], dict) and isinstance(data[0].get("embedding"), list):
                            return base_url
                    if attempt < HEALTH_RETRIES:
                        print_status(
                            f"Embedding probe retry {attempt}/{HEALTH_RETRIES} failed for {role_name}. Waiting {HEALTH_RETRY_SECONDS}s."
                        )
                        time.sleep(HEALTH_RETRY_SECONDS)
                        continue
                else:
                    return base_url
        if attempt < HEALTH_RETRIES:
            detail = f"HTTP {status}" if status else "no response"
            if attempt % 10 == 0:
                pod_snap = get_pod(pod_id)
                runtime = pod_snap.get("runtime")
                desired = pod_snap.get("desiredStatus", "?")
                detail += f" | desired={desired} runtime={'active' if runtime else 'not started'}"
            elapsed_min = (attempt * HEALTH_RETRY_SECONDS) // 60
            print_status(
                f"Health check {attempt}/{HEALTH_RETRIES} for {role_name}: {detail} ({elapsed_min}m elapsed). Waiting {HEALTH_RETRY_SECONDS}s."
            )
            time.sleep(HEALTH_RETRY_SECONDS)

    diagnostics = get_pod(pod_id)
    raise RunPodModeDError(
        role=role_name,
        mode="D",
        safe_message=(
            "Pod is RUNNING but failed health/model verification after retries. "
            "Container logs are not available via the documented RunPod public API."
        ),
        status=422,
        category="health_check_failed",
        pod_id=pod_id,
        log_path=write_debug_log(
            role_name,
            "D",
            422,
            {
                "desiredStatus": diagnostics.get("desiredStatus"),
                "lastStatusChange": diagnostics.get("lastStatusChange"),
                "podSnapshot": diagnostics,
            },
        ),
    )


def run_cmd_checked(cmd: list[str], env_overrides: dict | None = None) -> tuple[int, str]:
    env = dict(os.environ)
    if env_overrides:
        env.update(env_overrides)
    proc = subprocess.run(  # noqa: S603
        cmd,
        capture_output=True,
        text=True,
        env=env,
        cwd=os.path.dirname(STATE_DIR),
    )
    out = (proc.stdout or "") + (proc.stderr or "")
    return proc.returncode, out


def role_gateway_smoke(role_name: str) -> tuple[bool, str]:
    if role_name == "executor":
        code, out = run_cmd_checked(
            [
                "openclaw",
                "agent",
                "--session-id",
                f"uptier-executor-{int(time.time())}",
                "-m",
                "Reply with exactly CUTOVER_OK and nothing else.",
            ]
        )
        return (code == 0 and "CUTOVER_OK" in out), out
    code, out = run_cmd_checked(
        [os.path.join(os.path.dirname(STATE_DIR), "scripts", "paperclip-role-dispatch.sh")],
        env_overrides={"PAPERCLIP_ROLE": role_name},
    )
    return (code == 0 and f"HEARTBEAT_OK:{role_name}" in out), out


def apply_gateway_config_with_restart() -> None:
    root_dir = os.path.dirname(STATE_DIR)
    configure = os.path.join(root_dir, "scripts", "configure.sh")
    code, out = run_cmd_checked([configure])
    if code != 0:
        raise RunPodUnclassifiedError(
            role="gateway",
            mode="U",
            safe_message="Failed running configure.sh during up-tier cutover.",
            status=500,
            category="configure_failed",
            log_path=write_debug_log("gateway", "U", code, {"output": out}),
        )
    code, out = run_cmd_checked(["openclaw", "gateway", "restart"])
    if code != 0:
        raise RunPodUnclassifiedError(
            role="gateway",
            mode="U",
            safe_message="Failed restarting OpenClaw gateway during up-tier cutover.",
            status=500,
            category="gateway_restart_failed",
            log_path=write_debug_log("gateway", "U", code, {"output": out}),
        )
    time.sleep(60)


def attempt_uptier_swap(role: dict, old_entry: dict, better_candidates: list[dict]) -> tuple[bool, str]:
    role_name = role["logical_name"]
    old_pod_id = old_entry["pod_id"]
    old_pref_idx = preference_index_for_running_gpu(role, old_entry.get("gpu_type", ""))
    if old_pref_idx <= 0:
        return False, f"{role_name} already at top-preference GPU."
    if not better_candidates:
        return False, f"{role_name} has no higher-preference candidates currently resolvable."

    try:
        created, selected_gpu = create_pod_with_modes(role, better_candidates)
        new_pod_id = created["id"]
        running_pod = wait_for_running_or_mode_c(new_pod_id, role_name)
        base_url = health_check_with_mode_d(role, running_pod)

        machine = running_pod.get("machine") or {}
        new_gpu = machine.get("gpuTypeId") or running_pod.get("gpuTypeId") or selected_gpu["id"]
        new_rate = float(selected_gpu.get("securePrice") or old_entry.get("hourly_rate", 0.0))
        new_entry = dict(old_entry)
        new_entry.update(
            {
                "pod_id": new_pod_id,
                "base_url": base_url,
                "proxy_url": base_url,
                "gpu_type": new_gpu,
                "hourly_rate": new_rate,
                "region": machine.get("dataCenterId") or machine.get("location") or old_entry.get("region", "unknown"),
                "status": "healthy",
                "provisioned_at": now_iso(),
            }
        )
        if old_entry.get("preexisting"):
            new_entry["preexisting"] = True

        save_state_incremental({k: v for k, v in new_entry.items() if k != "preexisting"})
        upsert_created_role(new_entry)
        apply_gateway_config_with_restart()
        ok, smoke_out = role_gateway_smoke(role_name)
        if not ok:
            save_state_incremental({k: v for k, v in old_entry.items() if k != "preexisting"})
            upsert_created_role(old_entry)
            apply_gateway_config_with_restart()
            teardown_single_pod(new_pod_id, role_name)
            return False, f"Gateway smoke failed for {role_name}; rollback applied. Output: {smoke_out[:500]}"

        teardown_single_pod(old_pod_id, role_name)
        return True, (
            f"{role_name} up-tiered successfully: {old_entry.get('gpu_type')} -> {new_gpu} "
            f"(pod {old_pod_id} -> {new_pod_id})"
        )
    except (RunPodModeAError, RunPodModeEError) as exc:
        return False, f"Up-tier deferred for {role_name} ({exc.mode}): {exc.safe_message}"
    except (RunPodModeCError, RunPodModeDError) as exc:
        if exc.pod_id:
            teardown_single_pod(exc.pod_id, role_name)
        return False, f"Up-tier failed health/start for {role_name} ({exc.mode}): {exc.safe_message}"
    except RunPodScriptError as exc:
        if exc.log_path:
            print_status(f"Debug details: {exc.log_path}")
        return False, f"Up-tier failed for {role_name} ({exc.mode}): {exc.safe_message}"


def on_interrupt(signum, frame):  # noqa: ANN001
    del signum, frame
    global teardown_force_window_until
    if teardown_in_progress:
        now = time.time()
        if now <= teardown_force_window_until:
            print_status(
                "TEARDOWN ABORTED - PODS MAY STILL BE RUNNING - check state/pods.json and the RunPod dashboard."
            )
            raise SystemExit(130)
        teardown_force_window_until = now + 5
        print_status(
            "Teardown in progress. Press Ctrl+C again within 5 seconds to force abort (will leave pods running)."
        )
        return
    raise KeyboardInterrupt


def monthly_cost(hourly: float) -> float:
    return hourly * 24 * 30


def run_training_mode() -> int:
    lifetime_seconds = parse_lifetime_seconds(TRAINING_LIFETIME)
    training_role = {
        "logical_name": "training",
        "model_id": "training-job",
        "gpu_preference_chain": [TRAINING_GPU],
        "docker_start_cmd": ["sleep", "infinity"],
        "env": {},
    }

    gpu_candidates = resolve_gpu_candidates(training_role)
    selected = gpu_candidates[0]
    check_balance(float(selected.get("securePrice") or 0.0))
    print_status(
        "Training mode requested. Provisioning one Secure Cloud training pod "
        f"using preference chain: {', '.join(training_role['gpu_preference_chain'])}."
    )

    created, selected_gpu = create_pod_with_modes(training_role, gpu_candidates)
    pod_id = created["id"]
    running = wait_for_running_or_mode_c(pod_id, "training")
    machine = running.get("machine") or {}
    base_url = f"https://{pod_id}-{PROXY_PORT}.proxy.runpod.net/v1"

    scheduler_pid, scheduler_log = schedule_training_teardown(pod_id, lifetime_seconds)
    teardown_at = dt.datetime.utcnow() + dt.timedelta(seconds=lifetime_seconds)

    entry = {
        "pod_id": pod_id,
        "name": created.get("name") or f"foreman-v2-training-{pod_id}",
        "gpu_type": machine.get("gpuTypeId") or selected_gpu["id"],
        "hourly_rate": float(created.get("costPerHr") or selected_gpu.get("securePrice") or 0.0),
        "proxy_url": base_url,
        "lifetime_seconds": lifetime_seconds,
        "teardown_at_utc": teardown_at.replace(microsecond=0).isoformat() + "Z",
        "scheduler_pid": scheduler_pid,
        "scheduler_log": scheduler_log,
        "created_at": now_iso(),
        "status": str(running.get("desiredStatus") or "unknown").lower(),
    }
    save_training_entry(entry)

    print("Training pod provisioned successfully.")
    print(f"pod_id: {pod_id}")
    print(f"api_endpoint: {base_url}")
    print(f"dashboard_url: https://runpod.io/console/pods/{pod_id}")
    print(f"scheduled_teardown_utc: {entry['teardown_at_utc']}")
    print(f"teardown_scheduler_pid: {scheduler_pid}")
    print(f"teardown_scheduler_log: {scheduler_log}")
    print(f"training_state: {TRAINING_STATE_FILE}")
    return 0


def main() -> int:
    signal.signal(signal.SIGINT, on_interrupt)
    signal.signal(signal.SIGTERM, on_interrupt)

    try:
        if PROVISION_MODE == "training":
            return run_training_mode()

        if PROVISION_MODE != "production":
            raise RunPodModeBError(
                role="startup",
                mode="B",
                safe_message=f"Unsupported --mode value: {PROVISION_MODE}",
                status=400,
                category="invalid_mode",
            )

        reconcile_existing_state_or_abort()

        chosen = {}
        total_hourly_estimate = 0.0
        for role in ROSTER:
            candidates = resolve_gpu_candidates(role)
            chosen[role["logical_name"]] = candidates
            first_priced = next((c for c in candidates if c.get("securePrice") is not None), None)
            if first_priced is not None:
                total_hourly_estimate += float(first_priced["securePrice"])
            gpu_summary = ", ".join(
                f"{g['id']}(${float(g['securePrice']):.2f}/hr)" if g.get("securePrice") is not None else g["id"]
                for g in candidates
            )
            print_status(
                f"GPU candidates for {role['logical_name']} (preference order): {gpu_summary}"
            )

        check_balance(total_hourly_estimate)
    except RunPodModeAError as exc:
        return preserve_and_warn("A", exc.role, exc.safe_message, exc.log_path)
    except RunPodModeEError as exc:
        return preserve_and_warn("E", exc.role, exc.safe_message, exc.log_path)
    except RunPodModeBError as exc:
        print_status(f"ERROR: {exc.safe_message}")
        if exc.log_path:
            print_status(f"Debug details: {exc.log_path}")
        teardown_created_pods("mode-b-failure")
        return 1
    except RunPodUnclassifiedError as exc:
        print_status(f"ERROR: {exc.safe_message}")
        if exc.log_path:
            print_status(f"Debug details: {exc.log_path}")
        if created_pods:
            return preserve_and_warn("U", exc.role, exc.safe_message, exc.log_path)
        return 1

    while True:
        missing_roles = [
            role for role in ROSTER if not any(p.get("logical_name") == role["logical_name"] for p in created_pods)
        ]

        for role in missing_roles:
            role_name = role["logical_name"]
            gpu_candidates = chosen[role_name]
            try:
                gpu_ids_str = ", ".join(g["id"] for g in gpu_candidates)
                print_status(
                    f"Provisioning {role_name} pod on Secure Cloud (candidates: {gpu_ids_str})..."
                )
                created, selected_gpu = create_pod_with_modes(role, gpu_candidates)
                pod_id = created["id"]

                # Persist immediately after create to minimize any untracked-billing window.
                preliminary_base_url = f"https://{pod_id}-{PROXY_PORT}.proxy.runpod.net/v1"
                # Use the actual cost from the creation response; fall back to the
                # candidate's listed securePrice, then 0.0 if neither is available.
                actual_cost = float(
                    created.get("costPerHr")
                    or selected_gpu.get("securePrice")
                    or 0.0
                )
                gpu_price_map = {
                    g["id"]: float(g["securePrice"]) if g.get("securePrice") is not None else actual_cost
                    for g in gpu_candidates
                }
                entry = {
                    "logical_name": role_name,
                    "pod_id": pod_id,
                    "base_url": preliminary_base_url,
                    "proxy_url": preliminary_base_url,
                    "model_id": role["model_id"],
                    "gpu_type": selected_gpu["id"],
                    "hourly_rate": actual_cost,
                    "region": "pending",
                    "status": "provisioning",
                    "provisioned_at": now_iso(),
                }
                created_pods.append(entry)
                save_state_incremental(entry)
                print_status(f"Created {role_name} pod: {pod_id} (recorded in state immediately)")

                preliminary_gpu = (
                    created.get("gpuTypeId")
                    or (created.get("machine") or {}).get("gpuTypeId")
                    or entry["gpu_type"]
                )
                preliminary_rate = gpu_price_map.get(preliminary_gpu, entry["hourly_rate"])
                entry.update({"gpu_type": preliminary_gpu, "hourly_rate": preliminary_rate})
                save_state_incremental(entry)

                running_pod = wait_for_running_or_mode_c(pod_id, role_name)
                base_url = health_check_with_mode_d(role, running_pod)

                machine = running_pod.get("machine") or {}
                actual_gpu_id = (
                    machine.get("gpuTypeId") or running_pod.get("gpuTypeId") or preliminary_gpu
                )
                hourly_rate = gpu_price_map.get(actual_gpu_id, preliminary_rate)
                status = str(running_pod.get("desiredStatus") or "unknown").lower()
                entry.update(
                    {
                        "base_url": base_url,
                        "proxy_url": base_url,
                        "gpu_type": actual_gpu_id,
                        "hourly_rate": hourly_rate,
                        "region": machine.get("dataCenterId") or machine.get("location") or "unknown",
                        "status": "healthy" if status == "running" else status,
                    }
                )
                save_state_incremental(entry)
                print_status(f"{role_name} healthy at {base_url} ({entry['region']}).")
            except (RunPodModeAError, RunPodModeEError) as exc:
                print_status(f"{role_name} not yet available ({exc.mode}): {exc.safe_message}.")
                if exc.log_path:
                    print_status(f"Debug details: {exc.log_path}")
                continue
            except (RunPodModeCError, RunPodModeDError) as exc:
                if exc.pod_id:
                    teardown_single_pod(exc.pod_id, role_name)
                remove_created_role(role_name)
                remove_state_role(role_name)
                print_status(f"{role_name} pod failed health startup ({exc.mode}); will retry in next cycle.")
                if exc.log_path:
                    print_status(f"Debug details: {exc.log_path}")
                continue
            except RunPodModeBError as exc:
                print_status(f"ERROR: {exc.safe_message}")
                if exc.log_path:
                    print_status(f"Debug details: {exc.log_path}")
                return 1
            except RunPodUnclassifiedError as exc:
                print_status(f"ERROR: {exc.safe_message}")
                if exc.log_path:
                    print_status(f"Debug details: {exc.log_path}")
                return 1

        still_missing = [
            role["logical_name"]
            for role in ROSTER
            if not any(p.get("logical_name") == role["logical_name"] for p in created_pods)
        ]
        fallback_roles: list[str] = []
        for entry in list(created_pods):
            role_name = str(entry.get("logical_name") or "")
            if not role_name:
                continue
            role = get_role_by_name(role_name)
            if str(entry.get("status") or "").lower() != "healthy":
                continue
            current_gpu = str(entry.get("gpu_type") or "")
            current_idx = preference_index_for_running_gpu(role, current_gpu)
            if current_idx <= 0:
                continue
            better_candidates = resolve_better_gpu_candidates(role, current_gpu)
            if not better_candidates:
                continue
            fallback_roles.append(role_name)
            better_ids = ", ".join(c["id"] for c in better_candidates)
            print_status(
                f"{role_name} is on fallback GPU {current_gpu}; higher-preference candidates: {better_ids}. "
                "Attempting safe up-tier."
            )
            swapped, message = attempt_uptier_swap(role, entry, better_candidates)
            print_status(message)

        if not still_missing and not fallback_roles:
            break

        if still_missing:
            print_status(
                "Missing roles after this cycle: "
                + ", ".join(still_missing)
                + f". Retrying all missing roles in {MISSING_ROLE_RETRY_SECONDS}s while keeping healthy pods running."
            )
        elif fallback_roles:
            print_status(
                "All roles are provisioned, but fallback pods remain for: "
                + ", ".join(sorted(set(fallback_roles)))
                + f". Polling for higher-preference GPUs again in {MISSING_ROLE_RETRY_SECONDS}s."
            )
        time.sleep(MISSING_ROLE_RETRY_SECONDS)

    total = current_hourly_cost()
    print()
    print("Role       Pod ID             GPU Type                     Hourly   Region")
    print("---------  -----------------  ---------------------------  -------  ------------")
    for row in created_pods:
        print(
            f"{row['logical_name']:<9}  {row['pod_id']:<17}  {row['gpu_type']:<27}  "
            f"${row['hourly_rate']:<6.2f}  {row['region']}"
        )
    print()
    print(f"Total estimated hourly cost: ${total:.2f}/hr")
    print(f"Total estimated monthly cost (30d): ${monthly_cost(total):.2f}/month")
    print(f"State written to: {STATE_FILE}")
    return 0


try:
    code = main()
except KeyboardInterrupt:
    print_status("Interrupt received. Tearing down all pods created in this run...")
    teardown_created_pods("user-interrupt")
    code = 1
except Exception as exc:
    log_path = write_debug_log("fatal", "U", None, {"error": str(exc)})
    if created_pods:
        print_status(
            "Unclassified fatal error occurred after healthy pods were created. Preserving pods for safety."
        )
        print_status(f"Debug details: {log_path}")
        code = preserve_and_warn("U", "unknown", "Unexpected fatal error occurred.", log_path)
    else:
        print_status("ERROR: Unexpected fatal error occurred before any healthy pod was created.")
        print_status(f"Debug details: {log_path}")
        code = 1

sys.exit(code)
PY
