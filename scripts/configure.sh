#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
TEMPLATE_FILE="${ROOT_DIR}/config/openclaw.foreman.json5"
TARGET_INCLUDE="${HOME}/.openclaw/foreman.json5"
PLUGIN_SOURCE_DIR="${ROOT_DIR}/plugins/foreman-hire-agent"
PLUGIN_TARGET_DIR="${HOME}/.openclaw/plugins/foreman-hire-agent"

[[ -f "${ENV_FILE}" ]] || { echo "ERROR: Missing ${ENV_FILE}. Copy .env.example to .env first." >&2; exit 1; }
[[ -f "${TEMPLATE_FILE}" ]] || { echo "ERROR: Missing template ${TEMPLATE_FILE}." >&2; exit 1; }
[[ -f "${PLUGIN_SOURCE_DIR}/openclaw.plugin.json" ]] || {
  echo "ERROR: Missing OpenClaw plugin manifest in ${PLUGIN_SOURCE_DIR}." >&2
  exit 1
}

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

for key in TOGETHER_API_KEY DASHSCOPE_US_KEY DASHSCOPE_SG_KEY; do
  [[ -n "${!key:-}" ]] || { echo "ERROR: Missing ${key} in .env" >&2; exit 1; }
done

mkdir -p "$(dirname "${TARGET_INCLUDE}")"
mkdir -p "$(dirname "${PLUGIN_TARGET_DIR}")"

if [[ -f "${TARGET_INCLUDE}" ]]; then
  cp "${TARGET_INCLUDE}" "${TARGET_INCLUDE}.bak-$(date +%Y%m%d-%H%M%S)"
fi

python3 - "${TEMPLATE_FILE}" "${TARGET_INCLUDE}" <<'PY'
import json
import os
import re
import sys
from pathlib import Path

src, dst = sys.argv[1], sys.argv[2]
with open(src) as f:
    content = f.read()

def sub(match):
    var = match.group(1)
    val = os.environ.get(var, "")
    if not val:
        raise SystemExit(f"ERROR: template references ${{{var}}} but not set in env")
    return val

content = re.sub(r"\$\{([A-Z_][A-Z0-9_]*)\}", sub, content)

# Preserve live provisioned agents by merging unknown agents.list entries from openclaw.json.
cfg_path = Path.home() / ".openclaw" / "openclaw.json"
if cfg_path.exists():
    try:
        with cfg_path.open() as f:
            live_cfg = json.load(f)
    except Exception as exc:
        raise SystemExit(f"ERROR: failed to parse {cfg_path}: {exc}")

    live_agents = live_cfg.get("agents", {}).get("list", [])
    if isinstance(live_agents, dict):
        live_agents = list(live_agents.values())
    if not isinstance(live_agents, list):
        live_agents = []

    agents_anchor = content.find("agents:")
    list_anchor = content.find("list:", agents_anchor if agents_anchor >= 0 else 0)
    if list_anchor >= 0:
        bracket_start = content.find("[", list_anchor)
        if bracket_start >= 0:
            depth = 0
            bracket_end = -1
            for idx in range(bracket_start, len(content)):
                ch = content[idx]
                if ch == "[":
                    depth += 1
                elif ch == "]":
                    depth -= 1
                    if depth == 0:
                        bracket_end = idx
                        break
            if bracket_end >= 0:
                list_body = content[bracket_start + 1 : bracket_end]
                template_ids = set(re.findall(r'\bid\s*:\s*"([^"]+)"', list_body))
                extra_agents = []
                for agent in live_agents:
                    if not isinstance(agent, dict):
                        continue
                    aid = agent.get("id")
                    if isinstance(aid, str) and aid and aid not in template_ids:
                        extra_agents.append(agent)

                if extra_agents:
                    rendered = list_body.rstrip()
                    if rendered.strip() and not rendered.rstrip().endswith(","):
                        rendered = rendered.rstrip() + ","
                    extra_chunks = []
                    for agent in extra_agents:
                        block = json.dumps(agent, indent=2)
                        block = "\n".join("      " + line for line in block.splitlines())
                        extra_chunks.append(block)
                    rendered += "\n" + ",\n".join(extra_chunks) + "\n    "
                    content = content[: bracket_start + 1] + rendered + content[bracket_end:]

with open(dst, "w") as f:
    f.write(content)
os.chmod(dst, 0o600)
PY

python3 - <<'PY'
import json
import os
from pathlib import Path

cfg_path = Path.home() / ".openclaw" / "openclaw.json"
if not cfg_path.exists():
    raise SystemExit("ERROR: missing ~/.openclaw/openclaw.json")

with cfg_path.open() as f:
    cfg = json.load(f)

models = cfg.setdefault("models", {})
providers = models.setdefault("providers", {})
openrouter_key = os.environ.get("OPENROUTER_API_KEY", "").strip()
if not openrouter_key:
    raise SystemExit("ERROR: Missing OPENROUTER_API_KEY in .env")

providers["executor"] = {
    "baseUrl": "https://openrouter.ai/api/v1",
    "apiKey": openrouter_key,
    "api": "openai-completions",
    "models": [
        {
            "id": "qwen/qwen3-coder",
            "name": "Qwen3 Coder (OpenRouter)",
            "reasoning": True,
            "input": ["text"],
            "cost": {"input": 0.30, "output": 1.20, "cacheRead": 0, "cacheWrite": 0},
            "contextWindow": 262144,
            "maxTokens": 8192,
        }
    ],
}

with cfg_path.open("w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")

os.chmod(cfg_path, 0o600)
print("Synced executor provider into ~/.openclaw/openclaw.json")
PY

rm -rf "${PLUGIN_TARGET_DIR}"
cp -R "${PLUGIN_SOURCE_DIR}" "${PLUGIN_TARGET_DIR}"
chmod -R go-rwx "${PLUGIN_TARGET_DIR}"

echo "Wrote ${TARGET_INCLUDE} (mode 600)"
echo "Installed plugin to ${PLUGIN_TARGET_DIR}"
echo "OpenClaw will pick up the new include on next gateway start or 'openclaw secrets reload'."
