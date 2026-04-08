#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
STATE_DIR="${ROOT_DIR}/state"
STATE_FILE="${STATE_DIR}/pods.json"

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
import signal
import sys
import time
import urllib.error
import urllib.request

API_KEY = os.environ["RUNPOD_API_KEY"]
STATE_FILE = sys.argv[1]
STATE_DIR = os.path.dirname(STATE_FILE)
LOG_DIR = os.path.join(STATE_DIR, "logs")

REST_BASE = "https://rest.runpod.io/v1"
GRAPHQL_URL = "https://api.runpod.io/graphql"

MODE_A_WINDOW_SECONDS = 15 * 60
MODE_E_WINDOW_SECONDS = 5 * 60
POD_RUNNING_TIMEOUT_SECONDS = 15 * 60
HEALTH_RETRIES = 3
HEALTH_RETRY_SECONDS = 30

VLLM_IMAGE = "runpod/worker-v1-vllm:stable-cuda12.1.0"
PROXY_PORT = 8000

ROSTER = [
    {
        "logical_name": "embedding",
        "model_id": "Qwen/Qwen3-Embedding-8B",
        "gpu_candidates": [
            "NVIDIA RTX A4000",
            "NVIDIA RTX A5000",
            "NVIDIA RTX A4500",
            "NVIDIA RTX 4000 Ada Generation",
        ],
        "env": {
            "MODEL_NAME": "Qwen/Qwen3-Embedding-8B",
            "DTYPE": "half",
            "MAX_MODEL_LEN": "32768",
            "GPU_MEMORY_UTILIZATION": "0.90",
            "MAX_NUM_SEQS": "16",
            "TASK": "embed",
        },
    },
    {
        "logical_name": "executor",
        "model_id": "Qwen/Qwen3-14B-AWQ",
        "gpu_candidates": [
            "NVIDIA RTX A5000",
            "NVIDIA RTX A4500",
            "NVIDIA RTX 4000 Ada Generation",
            "NVIDIA A100 40GB PCIe",
        ],
        "env": {
            "MODEL_NAME": "Qwen/Qwen3-14B-AWQ",
            "QUANTIZATION": "awq_marlin",
            "DTYPE": "half",
            "MAX_MODEL_LEN": "32768",
            "GPU_MEMORY_UTILIZATION": "0.90",
            "MAX_NUM_SEQS": "16",
        },
    },
    {
        "logical_name": "planner",
        "model_id": "Qwen/Qwen3-30B-A3B-Instruct-2507-AWQ",
        "gpu_candidates": [
            "NVIDIA L40S",
            "NVIDIA RTX A6000",
            "NVIDIA A40",
        ],
        "env": {
            "MODEL_NAME": "Qwen/Qwen3-30B-A3B-Instruct-2507-AWQ",
            "QUANTIZATION": "awq_marlin",
            "ENABLE_EXPERT_PARALLEL": "true",
            "MAX_MODEL_LEN": "65536",
            "GPU_MEMORY_UTILIZATION": "0.90",
            "MAX_NUM_SEQS": "16",
        },
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
    merged_headers = {"Content-Type": "application/json", "Authorization": f"Bearer {API_KEY}"}
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


def is_mode_e(status: int, payload: dict | str) -> bool:
    if status in {429, 500, 502, 503, 504, 0}:
        return True
    text = payload_text(payload)
    return "timeout" in text


def is_mode_a(status: int, payload: dict | str) -> bool:
    if status not in {400, 409, 422}:
        return False
    text = payload_text(payload)
    needles = (
        "no gpu available",
        "out of capacity",
        "insufficient capacity",
        "not enough gpu",
        "currently unavailable",
        "stock",
    )
    return any(n in text for n in needles)


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
    except Exception:
        return {"pods": []}


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


def clear_state() -> None:
    write_state_atomic({"pods": []})


def current_hourly_cost() -> float:
    return sum(float(p.get("hourly_rate", 0.0)) for p in created_pods)


def print_billing_window(role_waiting: str, attempt: int, next_wait: int, elapsed: int, total_window: int) -> None:
    hourly = current_hourly_cost()
    per_min = hourly / 60.0
    for pod in created_pods:
        print_status(
            f"{pod['logical_name']} pod RUNNING (${pod['hourly_rate']:.2f}/hr) — waiting for {role_waiting} GPU..."
        )
    print_status(
        f"Currently billing: ${hourly:.2f}/hr (${per_min:.4f}/min) for {len(created_pods)} of 3 pods"
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
    _ = input()


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

    alive = []
    for row in pods:
        pod_id = str(row.get("pod_id") or "").strip()
        role = str(row.get("logical_name") or "unknown")
        if not pod_id:
            continue
        status, payload = api_request("GET", f"{REST_BASE}/pods/{pod_id}?includeMachine=true")
        if status == 200 and isinstance(payload, dict):
            desired = str(payload.get("desiredStatus") or payload.get("status") or "").upper()
            if desired and is_alive_status(desired):
                alive.append((role, pod_id, desired))
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

    if alive:
        details = ", ".join([f"{r}:{p}({s})" for r, p, s in alive])
        raise RunPodModeBError(
            role="startup",
            mode="B",
            safe_message=(
                "Found existing pods from a previous run still running: "
                f"{details}. Run ./scripts/teardown.sh first to clean up, then rerun this script."
            ),
            status=409,
            category="existing_running_state",
        )

    backup = f"{STATE_FILE}.bak-{dt.datetime.utcnow().strftime('%Y%m%d-%H%M%S')}"
    os.replace(STATE_FILE, backup)
    clear_state()
    print_status(f"Backed up prior state to {backup} and reset state/pods.json.")


def teardown_created_pods(reason: str) -> None:
    global teardown_in_progress, teardown_force_window_until
    if not created_pods:
        print_status(f"Teardown skipped: no pods created in this run ({reason}).")
        return
    print_status(f"Teardown started ({reason}).")
    teardown_in_progress = True
    teardown_force_window_until = 0.0
    failures = []
    try:
        for pod in reversed(created_pods):
            pod_id = pod["pod_id"]
            status, payload = api_request("DELETE", f"{REST_BASE}/pods/{pod_id}")
            if status not in {200, 202, 204}:
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
        clear_state()
        print_status("Teardown completed successfully; state/pods.json reset.")


def resolve_gpu_choice(role: dict) -> dict:
    fields = """
id
displayName
memoryInGb
secureCloud
securePrice
threeMonthPrice
sixMonthPrice
lowestPrice(input:{gpuCount:1,secureCloud:true}) {
  stockStatus
  uninterruptablePrice
}
"""
    out = []
    for gpu_id in role["gpu_candidates"]:
        query = f"""
query {{
  gpuTypes(input: {{id: "{gpu_id}"}}) {{
    {fields}
  }}
}}
"""
        data = graphql(query, role=f"gpu-resolve-{role['logical_name']}")
        items = (data.get("data") or {}).get("gpuTypes") or []
        if not items:
            continue
        row = items[0]
        if not row.get("secureCloud"):
            continue
        if row.get("securePrice") is None:
            continue
        out.append(row)
    if not out:
        raise RunPodModeAError(
            role=role["logical_name"],
            mode="A",
            safe_message=(
                "No acceptable Secure Cloud GPU found from candidate list. "
                f"Candidates checked: {', '.join(role['gpu_candidates'])}."
            ),
            status=409,
            category="out_of_capacity",
        )
    out.sort(key=lambda r: float(r["securePrice"]))
    return out[0]


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
    required = required_hourly * 24 * 7
    if balance < required:
        raise RunPodModeBError(
            role="balance-check",
            mode="B",
            safe_message=(
                f"Insufficient RunPod balance. Need at least ${required:.2f} for 7 days; "
                f"current balance is ${balance:.2f}. Aborting before creating any pod."
            ),
            status=402,
            category="insufficient_balance",
        )
    print_status(
        f"Balance check passed: ${balance:.2f} available; 7-day minimum required is ${required:.2f}."
    )


def create_pod_with_modes(role: dict, gpu: dict) -> dict:
    role_name = role["logical_name"]
    payload = {
        "name": f"foreman-v2-{role_name}",
        "computeType": "GPU",
        "cloudType": "SECURE",
        "imageName": VLLM_IMAGE,
        "gpuTypeIds": [gpu["id"]],
        "gpuCount": 1,
        "containerDiskInGb": 80,
        "volumeInGb": 50,
        "volumeMountPath": "/workspace",
        "ports": [f"{PROXY_PORT}/http"],
        "interruptible": False,
        "env": role["env"],
        "dataCenterPriority": "availability",
        "gpuTypePriority": "custom",
    }

    started = time.time()
    attempt = 1
    wait_seconds = 60
    while True:
        status, resp = api_request("POST", f"{REST_BASE}/pods", payload)

        if status in {200, 201} and isinstance(resp, dict) and resp.get("id"):
            return resp

        elapsed = int(time.time() - started)
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
                f"Mode E while creating {role_name}: HTTP {status}; message={msg}. Retrying in {wait_seconds}s."
            )
            time.sleep(wait_seconds)
            wait_seconds = min(wait_seconds * 2, 120)
            attempt += 1
            continue

        if is_mode_a(status, resp):
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
            print_billing_window(role_name, attempt, wait_seconds, elapsed, MODE_A_WINDOW_SECONDS)
            time.sleep(wait_seconds)
            wait_seconds = min(wait_seconds * 2, 240)
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
            print_status(
                f"Health check retry {attempt}/{HEALTH_RETRIES} failed for {role_name}. Waiting {HEALTH_RETRY_SECONDS}s."
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


def main() -> int:
    signal.signal(signal.SIGINT, on_interrupt)

    try:
        reconcile_existing_state_or_abort()

        chosen = {}
        total_hourly = 0.0
        for role in ROSTER:
            gpu = resolve_gpu_choice(role)
            chosen[role["logical_name"]] = gpu
            total_hourly += float(gpu["securePrice"])
            print_status(
                f"Selected GPU for {role['logical_name']}: {gpu['id']} (${float(gpu['securePrice']):.2f}/hr, stock={((gpu.get('lowestPrice') or {}).get('stockStatus') or 'unknown')})."
            )

        check_balance(total_hourly)
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

    for role in ROSTER:
        role_name = role["logical_name"]
        gpu = chosen[role_name]
        try:
            print_status(f"Provisioning {role_name} pod on Secure Cloud...")
            created = create_pod_with_modes(role, gpu)
            pod_id = created["id"]
            print_status(f"Created {role_name} pod: {pod_id}")

            running_pod = wait_for_running_or_mode_c(pod_id, role_name)
            base_url = health_check_with_mode_d(role, running_pod)

            machine = running_pod.get("machine") or {}
            status = str(running_pod.get("desiredStatus") or "unknown").lower()
            entry = {
                "logical_name": role_name,
                "pod_id": pod_id,
                "base_url": base_url,
                "proxy_url": base_url,
                "model_id": role["model_id"],
                "gpu_type": gpu["id"],
                "hourly_rate": float(gpu["securePrice"]),
                "region": machine.get("dataCenterId") or machine.get("location") or "unknown",
                "status": "healthy" if status == "running" else status,
                "provisioned_at": now_iso(),
            }
            created_pods.append(entry)
            save_state_incremental(entry)
            print_status(f"{role_name} healthy at {base_url} ({entry['region']}).")
        except RunPodModeAError as exc:
            return preserve_and_warn("A", role_name, exc.safe_message, exc.log_path)
        except RunPodModeEError as exc:
            return preserve_and_warn("E", role_name, exc.safe_message, exc.log_path)
        except RunPodModeBError as exc:
            print_status(f"ERROR: {exc.safe_message}")
            if exc.log_path:
                print_status(f"Debug details: {exc.log_path}")
            teardown_created_pods("mode-b-failure")
            return 1
        except RunPodModeCError as exc:
            pause_for_inspection(exc)
            teardown_created_pods("mode-c-failure")
            return 1
        except RunPodModeDError as exc:
            pause_for_inspection(exc)
            teardown_created_pods("mode-d-failure")
            return 1
        except RunPodUnclassifiedError as exc:
            print_status(f"ERROR: {exc.safe_message}")
            if exc.log_path:
                print_status(f"Debug details: {exc.log_path}")
            if created_pods:
                print_status(
                    "Unclassified error encountered after healthy pods were created. "
                    "Preserving existing pods for safety."
                )
                return preserve_and_warn("U", role_name, exc.safe_message, exc.log_path)
            return 1

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
