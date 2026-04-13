#!/usr/bin/env bash
set -euo pipefail

if [[ -f ".env" ]]; then
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    if [[ "${line}" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
      key="${line%%=*}"
      value="${line#*=}"
      export "${key}=${value}"
    fi
  done < ".env"
fi

python3 - <<'PY'
import subprocess
import uuid


def openclaw_plan_timeout_sec() -> int:
    adapter_sec = 300
    inner = adapter_sec - 35
    override = (os.environ.get("FOREMAN_OPENCLAW_AGENT_TIMEOUT_SEC") or "").strip()
    if override.isdigit():
        inner = int(override)
    return max(120, min(inner, adapter_sec - 15))


import os

prompt = "Reply with the single word: ok"
sid = f"diag-planner-health-{uuid.uuid4().hex[:10]}"
timeout_sec = openclaw_plan_timeout_sec()

print(f"DIAG_SESSION_ID={sid}")
print(f"DIAG_TIMEOUT_SEC={timeout_sec}")

try:
    proc = subprocess.run(
        ["openclaw", "agent", "--session-id", sid, "-m", prompt],
        capture_output=True,
        text=True,
        timeout=timeout_sec,
        check=False,
    )
except subprocess.TimeoutExpired:
    print("TRANSPORT=openclaw-agent-subprocess")
    print("HTTP_STATUS=unavailable_via_openclaw_agent_path")
    print("EXIT_CODE=timeout")
    raise SystemExit(1)

raw_body = (proc.stdout or proc.stderr or "").strip()
raw_preview = raw_body[:500]
parsed_completion = (proc.stdout or "").strip()

print("TRANSPORT=openclaw-agent-subprocess")
print("HTTP_STATUS=unavailable_via_openclaw_agent_path")
print(f"EXIT_CODE={proc.returncode}")
print(f"RAW_RESPONSE_PREVIEW={raw_preview}")
print(f"PARSED_COMPLETION={parsed_completion}")

if proc.returncode == 0 and parsed_completion:
    raise SystemExit(0)
raise SystemExit(1)
PY
