#!/usr/bin/env bash
# Foreman v2 integration gate: RunPod pods, OpenClaw config coherence, gateway, Paperclip.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
STATE_FILE="${ROOT_DIR}/state/pods.json"
HISTORY_FILE="${ROOT_DIR}/state/integration-check-history.jsonl"
OPENCLAW_CFG="${HOME}/.openclaw/openclaw.json"
ENV_FILE="${ROOT_DIR}/.env"

OVERALL="pass"
CRITICAL_FAIL=0
RESULT_LINES_FILE="$(mktemp)"
GW_OUT="$(mktemp)"
trap 'rm -f "${RESULT_LINES_FILE}" "${GW_OUT}"' EXIT

record() {
  local name="$1"
  local status="$2"
  local detail="$3"
  printf '%s|%s|%s\n' "${name}" "${status}" "${detail}" >> "${RESULT_LINES_FILE}"
  printf '[integration-check] %-8s %s\n' "${status}" "${name}"
  if [[ -n "${detail}" ]]; then
    printf '           %s\n' "${detail}"
  fi
  if [[ "${status}" == "FAIL" ]]; then
    OVERALL="fail"
    CRITICAL_FAIL=1
  elif [[ "${status}" == "WARN" && "${OVERALL}" == "pass" ]]; then
    OVERALL="warn"
  fi
}

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

mkdir -p "${ROOT_DIR}/state"

if [[ ! -f "${STATE_FILE}" ]]; then
  record "pod_state" "FAIL" "Missing ${STATE_FILE} (run provision.sh first)"
elif [[ -z "${RUNPOD_API_KEY:-}" ]]; then
  record "pod_liveness" "FAIL" "RUNPOD_API_KEY not set (needed for /models probes)"
else
  pod_res="$(
    python3 - "${STATE_FILE}" "${RUNPOD_API_KEY}" <<'PY'
import json
import sys
import urllib.request

state_path = sys.argv[1]
api_key = sys.argv[2]

with open(state_path, "r", encoding="utf-8") as f:
    state = json.load(f)
pods = state.get("pods") or []
if not isinstance(pods, list) or not pods:
    print("FAIL|no pods in state file")
    raise SystemExit(0)

failures = []
for pod in pods:
    role = str(pod.get("logical_name") or "")
    base = str(pod.get("base_url") or pod.get("proxy_url") or "").strip().rstrip("/")
    model_id = str(pod.get("model_id") or "").strip()
    if not role or not base or not model_id:
        failures.append(f"{role or '?'}: missing base_url or model_id")
        continue
    url = f"{base}/models"
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Accept": "application/json",
            "User-Agent": "foreman-v2/integration-check (1.0)",
        },
        method="GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            code = resp.getcode()
            body = resp.read().decode("utf-8", errors="replace")
    except Exception as exc:
        failures.append(f"{role}: GET /models error {exc}")
        continue
    if code < 200 or code >= 300:
        failures.append(f"{role}: HTTP {code} on /models")
        continue
    try:
        payload = json.loads(body) if body else {}
    except json.JSONDecodeError as exc:
        failures.append(f"{role}: invalid JSON /models ({exc})")
        continue
    rows = payload.get("data") if isinstance(payload.get("data"), list) else []
    ids = [m.get("id") for m in rows if isinstance(m, dict)]
    if model_id not in ids:
        failures.append(f"{role}: model {model_id!r} not in /models listing")

if failures:
    print("FAIL|" + "; ".join(failures[:8]))
else:
    print("OK|all roles /models healthy")
PY
  )"
  IFS='|' read -r pod_code pod_msg <<< "${pod_res}"
  if [[ "${pod_code}" == "OK" ]]; then
    record "pod_liveness" "PASS" "${pod_msg}"
  else
    record "pod_liveness" "FAIL" "${pod_msg}"
  fi
fi

if [[ ! -f "${OPENCLAW_CFG}" ]]; then
  record "config_coherence" "FAIL" "Missing ${OPENCLAW_CFG} (run scripts/configure.sh)"
else
  coh="$(
    python3 - "${STATE_FILE}" "${OPENCLAW_CFG}" "${ROOT_DIR}" <<'PY'
import json
import sys
from pathlib import Path

state_path = Path(sys.argv[1])
cfg_path = Path(sys.argv[2])
root_dir = Path(sys.argv[3])
if not state_path.is_file():
    print("FAIL|missing state file")
    raise SystemExit(0)
sys.path.insert(0, str(root_dir / "scripts" / "lib"))
from openclaw_config_helper import read_openclaw_config_atomic

state = json.loads(state_path.read_text(encoding="utf-8"))
pods = {
    str(p.get("logical_name")): str(p.get("base_url", "")).strip().rstrip("/")
    for p in state.get("pods") or []
    if isinstance(p, dict)
}

try:
    cfg, raw_cfg = read_openclaw_config_atomic(cfg_path, attempts=5, delay_seconds=0.25)
except Exception as exc:
    print(f"FAIL|openclaw.json parse/read error after retries: {exc}")
    raise SystemExit(0)

providers: dict = {}
providers = (((cfg.get("models") or {}).get("providers")) or {}) if isinstance(cfg.get("models"), dict) else {}

def bases_from_regex(text: str) -> dict[str, str]:
    import re

    found: dict[str, str] = {}
    for role in ("executor", "planner", "reviewer", "embedding"):
        m = re.search(
            rf"{role}\s*:\s*{{[^}}]*baseUrl\s*:\s*\"([^\"]+)\"",
            text,
            flags=re.S,
        )
        if m:
            found[role] = m.group(1).strip().rstrip("/")
    return found


issues = []
for role, expected in pods.items():
    got = ""
    if providers:
        block = providers.get(role) if isinstance(providers.get(role), dict) else {}
        got = str(block.get("baseUrl") or "").strip().rstrip("/")
    if not got:
        got = bases_from_regex(raw_cfg).get(role, "")
    if not expected:
        issues.append(f"{role}: missing base_url in pods.json")
        continue
    if not got:
        issues.append(f"{role}: could not read baseUrl from openclaw.json (non-strict JSON?)")
        continue
    if got != expected:
        issues.append(f"{role}: openclaw baseUrl {got!r} != pods.json {expected!r}")

if issues:
    print("FAIL|" + "; ".join(issues))
else:
    print("OK|openclaw.json base URLs match state/pods.json")
PY
  )"
  IFS='|' read -r coh_code coh_msg <<< "${coh}"
  if [[ "${coh_code}" == "OK" ]]; then
    record "config_coherence" "PASS" "${coh_msg}"
  else
    record "config_coherence" "FAIL" "${coh_msg}"
  fi
fi

if command -v openclaw >/dev/null 2>&1; then
  # Deterministic prompt; classify output without requiring an exact echo string.
  openclaw agent --session-id "integration-check-$(date +%s)" \
    -m "Integration check (deterministic): reply with one short sentence that includes the literal token IC7 and the digit 7." \
    > "${GW_OUT}" 2>&1 || true

  gw_compact="$(
    tr -d '\0' < "${GW_OUT}" | tr -s '[:space:]' ' ' | sed 's/^ *//;s/ *$//'
  )"
  gw_nonempty_compact="${gw_compact// /}"

  gw_fail=""
  while IFS= read -r marker; do
    [[ -z "${marker}" ]] && continue
    if grep -qiF -- "${marker}" "${GW_OUT}"; then
      gw_fail="${marker}"
      break
    fi
  done <<'EOF'
gateway agent failed
timed out
unauthorized
no reply from agent
llm request failed
context overflow
session history looks corrupted
error:
EOF

  if [[ -z "${gw_nonempty_compact}" ]]; then
    record "gateway_agent_ping" "FAIL" "openclaw agent returned empty output"
  elif [[ -n "${gw_fail}" ]]; then
    record "gateway_agent_ping" "FAIL" "openclaw agent output matched failure marker '${gw_fail}'; snippet: $(head -c 400 "${GW_OUT}" | tr '\n' ' ')"
  else
    gw_lower="$(printf '%s' "${gw_compact}" | tr '[:upper:]' '[:lower:]')"
    if [[ "${gw_lower}" == "completed" || "${gw_lower}" == "done" || "${gw_lower}" == "ok" || "${gw_lower}" == "success" ]]; then
      record "gateway_agent_ping" "WARN" "openclaw agent returned status-only output ('${gw_lower}'); substantive reply preferred"
    else
      record "gateway_agent_ping" "PASS" "openclaw agent returned non-empty output without failure markers"
    fi
  fi
else
  record "gateway_agent_ping" "WARN" "openclaw CLI not on PATH"
fi

if [[ -z "${RUNPOD_API_KEY:-}" ]]; then
  record "executor_api" "FAIL" "RUNPOD_API_KEY not set"
elif [[ ! -f "${STATE_FILE}" ]]; then
  record "executor_api" "WARN" "skipped (no pods.json)"
else
  ex_base="$(
    python3 - "${STATE_FILE}" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    st = json.load(f)
for p in st.get("pods") or []:
    if p.get("logical_name") == "executor":
        print(str(p.get("base_url") or p.get("proxy_url") or "").strip().rstrip("/"))
        break
PY
  )"
  if [[ -z "${ex_base}" ]]; then
    record "executor_api" "FAIL" "executor base_url missing in pods.json"
  else
    ex_code="$(curl -sS -o /dev/null -w "%{http_code}" \
      -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
      -H "Accept: application/json" \
      "${ex_base}/models" || echo "000")"
    if [[ "${ex_code}" -ge 200 && "${ex_code}" -lt 300 ]]; then
      record "executor_api" "PASS" "GET ${ex_base}/models => ${ex_code}"
    else
      record "executor_api" "FAIL" "GET ${ex_base}/models => ${ex_code}"
    fi
  fi
fi

clip_base="${PAPERCLIP_API_URL:-}"
if [[ -z "${clip_base}" && -n "${PAPERCLIP_BASE_URL:-}" ]]; then
  clip_base="${PAPERCLIP_BASE_URL%/}/api"
fi
clip_key="${PAPERCLIP_API_KEY:-}"
if [[ -z "${clip_key}" && -f "${HOME}/.paperclip/auth.json" && -n "${clip_base}" ]]; then
  clip_key="$(
    python3 - "${clip_base}" <<'PY'
import json, os, sys

api = (sys.argv[1] or "").strip()
path = os.path.expanduser("~/.paperclip/auth.json")
try:
    auth = json.loads(open(path, encoding="utf-8").read())
except Exception:
    raise SystemExit("")
creds = auth.get("credentials") or {}
origin = api.removesuffix("/api")
t = (creds.get(origin) or {}).get("token") or ""
print(str(t).strip())
PY
  )"
fi

if [[ -z "${clip_base}" ]]; then
  record "paperclip_api" "WARN" "PAPERCLIP_API_URL / PAPERCLIP_BASE_URL not set; skipped"
elif [[ -z "${clip_key}" ]]; then
  record "paperclip_api" "WARN" "No Paperclip token (set PAPERCLIP_API_KEY or ~/.paperclip/auth.json)"
else
  clip_base="${clip_base%/}"
  [[ "${clip_base}" == */api ]] || clip_base="${clip_base}/api"
  pc_code="$(curl -sS -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer ${clip_key}" \
    -H "Accept: application/json" \
    "${clip_base}/agents/me" || echo "000")"
  if [[ "${pc_code}" -ge 200 && "${pc_code}" -lt 300 ]]; then
    record "paperclip_api" "PASS" "GET ${clip_base}/agents/me => ${pc_code}"
  else
    record "paperclip_api" "FAIL" "GET ${clip_base}/agents/me => ${pc_code}"
  fi
fi

ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
python3 - "${ts}" "${OVERALL}" "${HISTORY_FILE}" "${RESULT_LINES_FILE}" <<'PY'
import json
import sys
from pathlib import Path

ts, overall, hist_path, lines_path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
checks = []
raw_lines = Path(lines_path).read_text(encoding="utf-8").splitlines()
for raw in raw_lines:
    if not raw.strip():
        continue
    parts = raw.split("|", 2)
    if len(parts) == 3:
        checks.append({"name": parts[0], "status": parts[1], "detail": parts[2]})

record = {
    "timestamp": ts,
    "overall": overall,
    "checks": checks,
}
path = Path(hist_path)
path.parent.mkdir(parents=True, exist_ok=True)
with path.open("a", encoding="utf-8") as fh:
    fh.write(json.dumps(record, ensure_ascii=True) + "\n")
PY

echo ""
echo "Summary: overall=${OVERALL}"
if [[ "${CRITICAL_FAIL}" -eq 1 ]]; then
  exit 1
fi
exit 0
