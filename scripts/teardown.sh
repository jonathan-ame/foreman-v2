#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
STATE_FILE="${ROOT_DIR}/state/pods.json"

if [[ $# -eq 0 && ! -f "${STATE_FILE}" ]]; then
  echo "No ${STATE_FILE} found; nothing to terminate."
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

python3 - "${STATE_FILE}" "$@" <<'PY'
import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request

api_key = os.environ["RUNPOD_API_KEY"]
state_path = sys.argv[1]
args = sys.argv[2:]
rest_base = "https://rest.runpod.io/v1"
verify_timeout_seconds = 180
verify_poll_interval_seconds = 10

parser = argparse.ArgumentParser(add_help=True)
parser.add_argument(
    "--guarded",
    action="store_true",
    help="Require interactive confirmation before sending DELETE calls.",
)
parser.add_argument(
    "--pod-id",
    dest="pod_ids",
    action="append",
    default=[],
    help="Pod ID to terminate. Can be passed multiple times.",
)
parser.add_argument(
    "positional_pod_ids",
    nargs="*",
    help="Pod IDs to terminate (manual override path).",
)
cli = parser.parse_args(args)

override_ids = [str(x).strip() for x in (cli.pod_ids + cli.positional_pod_ids) if str(x).strip()]
use_override = bool(override_ids)


def parse_state_file(path: str) -> tuple[list[dict], str | None]:
    if not os.path.exists(path):
        return [], None
    try:
        with open(path, "r", encoding="utf-8") as f:
            payload = json.load(f)
    except Exception as exc:
        return [], f"state/pods.json is not valid JSON: {exc}"
    if not isinstance(payload, dict):
        return [], "state/pods.json root must be an object with key 'pods'."
    pods_raw = payload.get("pods")
    if pods_raw is None:
        return [], "state/pods.json is missing required key 'pods'."
    if not isinstance(pods_raw, list):
        return [], "state/pods.json key 'pods' must be a list."
    normalized = []
    for item in pods_raw:
        if isinstance(item, dict):
            normalized.append(item)
        else:
            return [], "state/pods.json contains a non-object pod entry."
    return normalized, None


pods, state_error = parse_state_file(state_path)
if state_error and not use_override:
    print(f"ERROR: {state_error}")
    print(
        "Use manual override to terminate by ID directly, e.g. "
        "'./scripts/teardown.sh --pod-id <pod-id-1> --pod-id <pod-id-2>'."
    )
    raise SystemExit(1)
if state_error and use_override:
    print(f"WARNING: {state_error}")
    print("Proceeding with manual override pod IDs.")
    pods = []

if not use_override and not pods:
    print("state/pods.json is empty; nothing to terminate.")
    raise SystemExit(0)

targets = []
if use_override:
    seen = set()
    for pod_id in override_ids:
        if pod_id in seen:
            continue
        seen.add(pod_id)
        targets.append(
            {
                "logical_name": "manual-override",
                "pod_id": pod_id,
                "base_url": "",
                "proxy_url": "",
                "status": "unknown",
            }
        )
else:
    targets = pods

def read_guarded_confirmation() -> str:
    tty_path = "/dev/tty"
    try:
        with open(tty_path, "r", encoding="utf-8", errors="replace") as tty_in, open(
            tty_path, "w", encoding="utf-8", errors="replace"
        ) as tty_out:
            tty_out.write("Type YES to continue: ")
            tty_out.flush()
            line = tty_in.readline()
            if not line:
                raise RuntimeError("no confirmation input received from /dev/tty")
            return line.strip()
    except Exception as exc:
        raise RuntimeError(
            "Guarded mode requires an interactive terminal at /dev/tty."
        ) from exc


if cli.guarded:
    print("Guarded mode enabled.")
    print("This will send pod termination requests to RunPod.")
    print(f"Targets: {len(targets)} pod(s)")
    try:
        typed = read_guarded_confirmation()
    except Exception as exc:
        print(f"ERROR: {exc}")
        raise SystemExit(1)
    if typed != "YES":
        print("Aborted by user before sending any DELETE requests.")
        raise SystemExit(1)

headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
failures = []
successes = []
failed_entries = []


def fetch_pod_state(pod_id: str) -> tuple[int, dict | str]:
    req = urllib.request.Request(f"{rest_base}/pods/{pod_id}?includeMachine=true", headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            status = resp.getcode()
            raw = resp.read().decode("utf-8", errors="replace") or "{}"
            try:
                return status, json.loads(raw)
            except Exception:
                return status, raw
    except urllib.error.HTTPError as exc:
        raw = (exc.read() or b"").decode("utf-8", errors="replace")
        try:
            return exc.code, json.loads(raw)
        except Exception:
            return exc.code, raw
    except Exception as exc:
        return 0, str(exc)


def is_terminated_like(payload: dict | str) -> bool:
    if not isinstance(payload, dict):
        return False
    desired = str(payload.get("desiredStatus") or "").upper()
    status = str(payload.get("status") or "").upper()
    terminal = {"TERMINATED", "EXITED", "FAILED"}
    return desired in terminal or status in terminal


def verify_termination(pod_id: str) -> tuple[bool, str]:
    # Pod absent from API is treated as terminated.
    start = time.time()
    while True:
        status, payload = fetch_pod_state(pod_id)
        if status == 404:
            return True, "pod no longer exists (404)"
        if status == 200 and is_terminated_like(payload):
            return True, "pod reported terminal status"
        if status in {401, 403}:
            return False, f"verification auth error HTTP {status}"
        if status == 0:
            return False, f"verification network error: {payload}"

        elapsed = time.time() - start
        if elapsed >= verify_timeout_seconds:
            if status == 200 and isinstance(payload, dict):
                desired = payload.get("desiredStatus")
                current = payload.get("status")
                return False, (
                    f"timed out after {verify_timeout_seconds}s; "
                    f"desiredStatus={desired} status={current}"
                )
            return False, f"timed out after {verify_timeout_seconds}s; last HTTP {status}"
        time.sleep(verify_poll_interval_seconds)


def dashboard_url(pod_id: str) -> str:
    return f"https://runpod.io/console/pods/{pod_id}"

for pod in targets:
    pod_id = str(pod.get("pod_id") or "").strip()
    logical_name = str(pod.get("logical_name") or "unknown")
    base_url = str(pod.get("base_url") or "")
    if not pod_id:
        failures.append((logical_name, "<missing-id>", "missing pod_id in state file", ""))
        failed_entries.append(pod)
        continue

    req = urllib.request.Request(f"{rest_base}/pods/{pod_id}", headers=headers, method="DELETE")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            status = resp.getcode()
            if status not in {200, 202, 204}:
                failures.append((logical_name, pod_id, f"unexpected HTTP {status}", dashboard_url(pod_id)))
                failed_entries.append(pod)
            else:
                ok, reason = verify_termination(pod_id)
                if ok:
                    successes.append((logical_name, pod_id, reason, base_url))
                else:
                    failures.append((logical_name, pod_id, f"delete accepted but verification failed: {reason}", dashboard_url(pod_id)))
                    failed_entries.append(pod)
    except urllib.error.HTTPError as e:
        raw = (e.read() or b"").decode("utf-8", errors="replace")
        failures.append((logical_name, pod_id, f"HTTP {e.code}: {raw}", dashboard_url(pod_id)))
        failed_entries.append(pod)
    except Exception as e:
        failures.append((logical_name, pod_id, str(e), dashboard_url(pod_id)))
        failed_entries.append(pod)

def dedupe_by_pod_id(entries: list[dict]) -> list[dict]:
    out = []
    seen = set()
    for row in entries:
        pod_id = str(row.get("pod_id") or "").strip()
        key = pod_id or f"__row__{id(row)}"
        if key in seen:
            continue
        seen.add(key)
        out.append(row)
    return out


def write_state(entries: list[dict]) -> None:
    with open(state_path, "w", encoding="utf-8") as f:
        json.dump({"pods": entries}, f, indent=2)
        f.write("\n")


if not (use_override and state_error):
    if use_override:
        target_ids = {str(x.get("pod_id") or "").strip() for x in targets if str(x.get("pod_id") or "").strip()}
        untouched = [p for p in pods if str(p.get("pod_id") or "").strip() not in target_ids]
        merged = untouched + failed_entries
        write_state(dedupe_by_pod_id(merged))
    else:
        if failures:
            # Keep only failed targets so retries focus on still-billing risk.
            write_state(dedupe_by_pod_id(failed_entries))
        else:
            write_state([])
else:
    print("WARNING: state/pods.json was not rewritten because it is invalid JSON.")
    print("Manual override was used, so no tracked state was modified.")

print()
print("Teardown summary:")
if successes:
    print("Successfully terminated:")
    for logical_name, pod_id, reason, base_url in successes:
        line = f"- {logical_name} ({pod_id}): verified ({reason})"
        if base_url:
            line += f" base_url={base_url}"
        print(line)
else:
    print("Successfully terminated: none")

if failures:
    print("Failed to terminate:")
    for logical_name, pod_id, err, dash in failures:
        if dash:
            print(f"- {logical_name} ({pod_id}): {err} | dashboard: {dash}")
        else:
            print(f"- {logical_name} ({pod_id}): {err}")
    print()
    print(
        f"{len(successes)} of {len(targets)} pods terminated. "
        "Remaining failed pods were kept in state/pods.json for retry."
    )
    print("Billing may still be active for failed pods. Retry teardown or check dashboards above.")
    raise SystemExit(1)

print("All targeted pods terminated successfully and were verified terminal.")
if use_override:
    print("state/pods.json updated for override mode (untouched pods preserved).")
else:
    print("state/pods.json cleared.")
print("Billing for targeted pods should now be stopped.")
PY
