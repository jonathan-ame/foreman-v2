#!/usr/bin/env bash
set -euo pipefail

# One-time Stage 1 backfill for legacy Paperclip agents.
# Creates a corrections journal issue + metadata.journal_issue_id + sync_cursors row
# for agents that do not yet have journal metadata.

python3 - <<'PY'
import json
import os
import urllib.error
import urllib.request
from urllib.parse import urlparse


def _normalize_api_base(raw: str) -> str:
    if not raw:
        raise SystemExit("ERROR: PAPERCLIP_API_URL must be set.")
    raw = raw.rstrip("/")
    return raw if raw.endswith("/api") else f"{raw}/api"


API_BASE = _normalize_api_base(os.environ.get("PAPERCLIP_API_URL", ""))
API_KEY = (os.environ.get("PAPERCLIP_API_KEY") or "").strip()
COMPANY_ID = (os.environ.get("PAPERCLIP_COMPANY_ID") or "").strip()
SUPABASE_URL = (os.environ.get("FOREMAN_CORRECTIONS_SUPABASE_URL") or "").strip().rstrip("/")
SUPABASE_KEY = (os.environ.get("FOREMAN_CORRECTIONS_SUPABASE_SERVICE_KEY") or "").strip()
WORKSPACE_SLUG = (os.environ.get("FOREMAN_CORRECTIONS_WORKSPACE_SLUG") or "foreman").strip() or "foreman"


def _is_loopback_host(host: str | None) -> bool:
    return (host or "").lower() in {"127.0.0.1", "localhost"}


def _resolve_api_key_from_auth(api_base: str) -> str:
    auth_file = os.path.expanduser("~/.paperclip/auth.json")
    with open(auth_file, "r", encoding="utf-8") as fh:
        auth = json.load(fh)
    creds = auth.get("credentials") or {}
    origin = api_base.removesuffix("/api")
    direct = (creds.get(origin) or {}).get("token", "")
    if direct:
        return direct.strip()

    target = urlparse(origin)
    strict_tokens: list[str] = []
    for key, value in creds.items():
        if not isinstance(key, str):
            continue
        parsed = urlparse(key)
        if (
            parsed.scheme == target.scheme
            and (parsed.hostname or "").lower() == (target.hostname or "").lower()
            and parsed.port == target.port
            and (parsed.path or "/") in {"", "/"}
        ):
            token = (value or {}).get("token", "")
            if token:
                strict_tokens.append(token.strip())
    uniq_strict = sorted(set(strict_tokens))
    if len(uniq_strict) == 1:
        return uniq_strict[0]
    if len(uniq_strict) > 1:
        raise RuntimeError("Multiple host-matching tokens found; set PAPERCLIP_API_KEY explicitly.")

    if _is_loopback_host(target.hostname):
        loopback_tokens: list[str] = []
        for key, value in creds.items():
            if not isinstance(key, str):
                continue
            parsed = urlparse(key)
            if parsed.scheme != target.scheme or not _is_loopback_host(parsed.hostname):
                continue
            token = ((value or {}).get("token") or "").strip()
            if token:
                loopback_tokens.append(token)
        uniq = sorted(set(loopback_tokens))
        if len(uniq) == 1:
            return uniq[0]
    return ""


if not API_KEY:
    try:
        API_KEY = _resolve_api_key_from_auth(API_BASE)
    except Exception:
        API_KEY = ""

if not API_KEY:
    raise SystemExit("ERROR: PAPERCLIP_API_KEY is required.")
if not COMPANY_ID:
    raise SystemExit("ERROR: PAPERCLIP_COMPANY_ID is required.")
if not SUPABASE_URL or not SUPABASE_KEY:
    raise SystemExit(
        "ERROR: FOREMAN_CORRECTIONS_SUPABASE_URL and FOREMAN_CORRECTIONS_SUPABASE_SERVICE_KEY are required."
    )


def req(method: str, path: str, payload=None):
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(f"{API_BASE}{path}", data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=60) as resp:
            body = resp.read().decode("utf-8")
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as exc:
        body = (exc.read() or b"").decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code} {method} {path}: {body[:500]}")


def req_supabase(method: str, path: str, payload=None):
    headers = {
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "apikey": SUPABASE_KEY,
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(f"{SUPABASE_URL}{path}", data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=60) as resp:
            body = resp.read().decode("utf-8")
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as exc:
        body = (exc.read() or b"").decode("utf-8", errors="replace")
        raise RuntimeError(f"Supabase HTTP {exc.code} {method} {path}: {body[:500]}")


def ensure_journal(agent: dict) -> bool:
    agent_id = (agent.get("id") or "").strip()
    if not agent_id:
        return False
    full_agent = req("GET", f"/agents/{agent_id}")
    metadata = full_agent.get("metadata") if isinstance(full_agent.get("metadata"), dict) else {}
    if (metadata.get("journal_issue_id") or "").strip():
        return False

    title = (full_agent.get("title") or full_agent.get("name") or agent_id).strip()
    journal_payload = {
        "title": f"[JOURNAL] {title} - Standing Corrections",
        "description": (
            "Corrections journal for this subordinate.\n\n"
            "Source of truth for correction comments consumed by Foreman corrections sync."
        ),
        "status": "backlog",
        "priority": "low",
    }
    journal_issue = req("POST", f"/companies/{COMPANY_ID}/issues", journal_payload)
    journal_issue_id = (journal_issue.get("id") or "").strip()
    if not journal_issue_id:
        raise RuntimeError(f"Failed to create journal for agent {agent_id}")

    merged_metadata = dict(metadata)
    merged_metadata["journal_issue_id"] = journal_issue_id
    req("PATCH", f"/agents/{agent_id}", {"metadata": merged_metadata})

    req_supabase(
        "POST",
        "/rest/v1/sync_cursors?on_conflict=workspace_slug,paperclip_agent_id",
        [
            {
                "workspace_slug": WORKSPACE_SLUG,
                "paperclip_agent_id": agent_id,
                "last_synced_comment_id": None,
            }
        ],
    )
    print(f"BACKFILLED {agent_id} journal={journal_issue_id}")
    return True


agents = req("GET", f"/companies/{COMPANY_ID}/agents")
items = agents.get("items", []) if isinstance(agents, dict) else agents
if not isinstance(items, list):
    raise SystemExit("ERROR: Unexpected agents payload.")

changed = 0
for agent in items:
    if not isinstance(agent, dict):
        continue
    if ensure_journal(agent):
        changed += 1

print(f"Backfill complete. updated_agents={changed}")
PY
