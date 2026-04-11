#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

APPLY=0
TARGET_PREFIX="${RUNPOD_VOLUME_CLEANUP_PREFIX:-foreman-models-}"
KEEP_NAMES_CSV="${RUNPOD_VOLUME_KEEP_NAMES:-}"
MAX_DELETE="${RUNPOD_VOLUME_CLEANUP_MAX_DELETE:-50}"

for arg in "$@"; do
  case "${arg}" in
    --apply) APPLY=1 ;;
    --dry-run) APPLY=0 ;;
    --prefix=*) TARGET_PREFIX="${arg#--prefix=}" ;;
    --keep-names=*) KEEP_NAMES_CSV="${arg#--keep-names=}" ;;
    --max-delete=*) MAX_DELETE="${arg#--max-delete=}" ;;
    *)
      echo "ERROR: Unknown argument: ${arg}" >&2
      echo "Usage: $0 [--dry-run|--apply] [--prefix=foreman-models-] [--keep-names=name1,name2] [--max-delete=50]" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "ERROR: Missing ${ENV_FILE}" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

if [[ -z "${RUNPOD_API_KEY:-}" ]]; then
  echo "ERROR: RUNPOD_API_KEY is required in ${ENV_FILE}" >&2
  exit 1
fi

python3 - "${APPLY}" "${TARGET_PREFIX}" "${KEEP_NAMES_CSV}" "${MAX_DELETE}" <<'PY'
import json
import os
import sys
import urllib.error
import urllib.request

APPLY = sys.argv[1] == "1"
TARGET_PREFIX = sys.argv[2]
KEEP_NAMES_RAW = sys.argv[3]
MAX_DELETE = int(sys.argv[4])

API_KEY = os.environ["RUNPOD_API_KEY"]
BASE = "https://rest.runpod.io/v1"

def req(method: str, path: str):
    request = urllib.request.Request(
        f"{BASE}{path}",
        headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
        method=method,
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as resp:
            body = resp.read().decode()
            return resp.getcode(), (json.loads(body) if body else None)
    except urllib.error.HTTPError as exc:
        body = (exc.read() or b"").decode(errors="replace")
        parsed = body
        try:
            parsed = json.loads(body)
        except Exception:
            pass
        return exc.code, parsed

keep_names = {x.strip() for x in KEEP_NAMES_RAW.split(",") if x.strip()}

status, pods = req("GET", "/pods")
if status != 200 or not isinstance(pods, list):
    raise SystemExit(f"ERROR: failed to list pods (HTTP {status}): {pods}")

def is_alive_status(value: str) -> bool:
    return value.upper() not in {"TERMINATED", "EXITED", "FAILED"}

def extract_network_volume_id(pod: dict):
    direct = str(pod.get("networkVolumeId") or "").strip()
    if direct:
        return direct
    nested = pod.get("networkVolume")
    if isinstance(nested, dict):
        nested_id = str(nested.get("id") or "").strip()
        if nested_id:
            return nested_id
    return None

attached_volume_ids = set()
for pod in pods:
    if not isinstance(pod, dict):
        continue
    desired = str(pod.get("desiredStatus") or pod.get("status") or "").upper()
    if desired and not is_alive_status(desired):
        continue
    vol_id = extract_network_volume_id(pod)
    if vol_id:
        attached_volume_ids.add(vol_id)

status, volumes = req("GET", "/networkvolumes")
if status != 200 or not isinstance(volumes, list):
    raise SystemExit(f"ERROR: failed to list network volumes (HTTP {status}): {volumes}")

attached = []
unattached = []
for vol in volumes:
    if not isinstance(vol, dict):
        continue
    name = str(vol.get("name") or "")
    if not name.startswith(TARGET_PREFIX):
        continue
    if name in keep_names:
        continue
    vol_id = str(vol.get("id") or "").strip()
    if vol_id and vol_id in attached_volume_ids:
        attached.append(vol)
    else:
        unattached.append(vol)

print(f"[vol-cleanup] Mode: {'APPLY' if APPLY else 'DRY-RUN'}")
print(f"[vol-cleanup] Prefix filter: {TARGET_PREFIX!r}")
print(f"[vol-cleanup] Keep-names: {sorted(keep_names) if keep_names else []}")
print(f"[vol-cleanup] Matching volumes: {len(attached) + len(unattached)}")
print(f"[vol-cleanup] Attached (skipped): {len(attached)}")
print(f"[vol-cleanup] Unattached (deletion candidates): {len(unattached)}")

if not attached and not unattached:
    print("[vol-cleanup] No stale volumes matched. Nothing to do.")
    raise SystemExit(0)

for vol in attached:
    print(
        f"  = {vol.get('id')}  name={vol.get('name')}  size={vol.get('size')}GB  "
        f"dc={vol.get('dataCenterId')}  state=ATTACHED_SKIP"
    )

for vol in unattached:
    print(
        f"  - {vol.get('id')}  name={vol.get('name')}  size={vol.get('size')}GB  "
        f"dc={vol.get('dataCenterId')}  state=UNATTACHED"
    )

if not APPLY:
    print("[vol-cleanup] Dry-run only. Re-run with --apply to delete unattached volumes.")
    raise SystemExit(0)

to_delete = unattached[:MAX_DELETE]
if len(unattached) > MAX_DELETE:
    print(
        f"[vol-cleanup] Capping deletions at max-delete={MAX_DELETE}; "
        f"{len(unattached) - MAX_DELETE} will remain for next run."
    )

deleted = 0
failed = []
for vol in to_delete:
    vol_id = str(vol.get("id"))
    status, payload = req("DELETE", f"/networkvolumes/{vol_id}")
    if status in (200, 202, 204):
        deleted += 1
        print(f"[vol-cleanup] Deleted {vol_id} ({vol.get('name')})")
    else:
        failed.append((vol_id, status, payload))
        print(f"[vol-cleanup] ERROR deleting {vol_id}: HTTP {status} payload={payload}")

print(f"[vol-cleanup] Deleted: {deleted}")
if failed:
    print(f"[vol-cleanup] Failed: {len(failed)}")
    raise SystemExit(1)
print("[vol-cleanup] Completed successfully.")
PY
