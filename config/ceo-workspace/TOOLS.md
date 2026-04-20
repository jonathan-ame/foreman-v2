# Tools Available to the CEO

Role-specific tools, plus a summary of the OpenClaw built-ins you have. This file is the authoritative tool reference — if something isn't listed here, you don't have it.

## 0. What you actually have

Your OpenClaw tool set on this agent:

- **File ops** (`read`, `write`, `edit`, list directories) — yes
- **Shell** (`exec`) — **yes, allowlist mode.** You can run `curl`, `jq`, `npx paperclipai`, `cat`, `echo`, `grep`, `head`, `tail`, `date`, `sed`, `awk`, `tr`, `wc`, `sort`, `bash` invocations of approved scripts under `~/foreman-git/foreman-v2/scripts/`. Anything else prompts the operator for approval and will likely be denied. Don't try interpreter inline-eval forms (`python -c`, `node -e`, `osascript -e`) — those always require explicit approval.
- **Web** (`web_search`, `web_fetch`) — yes, but `web_fetch` is **plain HTTP GET only**, no custom headers, no bearer auth. Not usable for Paperclip API calls. Use `curl` via `exec` for Paperclip.
- **Session primitives** (`sessions_spawn`, `sessions_yield`, `sessions_send`, `subagents`, `agents_list`) — exist in OpenClaw, but **not for Foreman delegation.** See Section 4.
- **Memory** (`memory_search`, `memory_get`) — yes
- **Plugin tools**: `paperclip_post_comment`, `paperclip_update_issue_status`, `paperclip_get_issue`, `paperclip_list_issues`, `hire_agent`, `escalate_to_frontier` — yes, details below.
- **Denied on this agent**: `browser`, `canvas`, `nodes`, `cron`, `process`. You cannot control a browser, run background processes, or schedule cron jobs from the CEO agent. If a task needs any of those, escalate to the board.

## 1. Paperclip REST API (via `exec` + `curl`)

All delegation, issue management, commenting, and approval flow through Paperclip's REST API. Use `curl` from your shell tool.

**Base URL:** `http://127.0.0.1:3100` (from your wake text `PAPERCLIP_API_URL`).
**Auth:** `Authorization: Bearer <token>` — see auth procedure below.
**Mutating calls:** `X-Paperclip-Run-Id: <run_id>` is **required** on every POST/PATCH/PUT/DELETE. Use the `PAPERCLIP_RUN_ID` value from your wake text.

### ⚠️ Auth procedure (CRITICAL — read this first)

OpenClaw's `exec` tool runs commands in a minimal shell that does **NOT** have access to config-level environment variables. `$PAPERCLIP_API_KEY`, `$PAPERCLIP_API_URL`, `$PAPERCLIP_RUN_ID`, and other `$PAPERCLIP_*` variables from your wake text are **prompt context only** — they are NOT shell env vars. If you use `$PAPERCLIP_API_KEY` in an exec curl command, it expands to empty and you get 401.

The correct auth flow on every heartbeat:

1. **Read the key file** using the `read` file tool (NOT `exec cat` — use the OpenClaw built-in `read` tool):
   - Path: `/Users/jonathanborgia/.openclaw/workspace/paperclip-claimed-api-key.json`
   - This returns JSON with a `token` field.
2. **Extract the token** from the JSON `token` field.
3. **Inline the literal token value** directly into your curl commands. No `# Tools Available to the CEO

Role-specific tools, plus a summary of the OpenClaw built-ins you have. This file is the authoritative tool reference — if something isn't listed here, you don't have it.

## 0. What you actually have

Your OpenClaw tool set on this agent:

- **File ops** (`read`, `write`, `edit`, list directories) — yes
- **Shell** (`exec`) — **yes, allowlist mode.** You can run `curl`, `jq`, `npx paperclipai`, `cat`, `echo`, `grep`, `head`, `tail`, `date`, `sed`, `awk`, `tr`, `wc`, `sort`, `bash` invocations of approved scripts under `~/foreman-git/foreman-v2/scripts/`. Anything else prompts the operator for approval and will likely be denied. Don't try interpreter inline-eval forms (`python -c`, `node -e`, `osascript -e`) — those always require explicit approval.
- **Web** (`web_search`, `web_fetch`) — yes, but `web_fetch` is **plain HTTP GET only**, no custom headers, no bearer auth. Not usable for Paperclip API calls. Use `curl` via `exec` for Paperclip.
- **Session primitives** (`sessions_spawn`, `sessions_yield`, `sessions_send`, `subagents`, `agents_list`) — exist in OpenClaw, but **not for Foreman delegation.** See Section 4.
- **Memory** (`memory_search`, `memory_get`) — yes
- **Plugin tools**: `paperclip_post_comment`, `paperclip_update_issue_status`, `paperclip_get_issue`, `paperclip_list_issues`, `hire_agent`, `escalate_to_frontier` — yes, details below.
- **Denied on this agent**: `browser`, `canvas`, `nodes`, `cron`, `process`. You cannot control a browser, run background processes, or schedule cron jobs from the CEO agent. If a task needs any of those, escalate to the board.

## 1. Paperclip REST API (via `exec` + `curl`)

All delegation, issue management, commenting, and approval flow through Paperclip's REST API. Use `curl` from your shell tool.

 variables, no `$(cat ...)` subshells.

Example with literal values (what your exec calls should look like):
```bash
curl -fsS http://127.0.0.1:3100/api/agents/me \
  -H "Authorization: Bearer pcp_4d064b02ef8eb38a07bf672b67679450ed581bd1174d84c8"
```

Do the same for `PAPERCLIP_RUN_ID`, `PAPERCLIP_AGENT_ID`, `PAPERCLIP_COMPANY_ID` — take the values from your wake text and inline them as literal strings in your exec commands. Never use `$VAR` syntax in exec.

### Canonical call shape

After reading the token via the `read` tool, your exec calls look like this (substitute your actual values):

```bash
curl -fsS http://127.0.0.1:3100/api/agents/me \
  -H "Authorization: Bearer <TOKEN>"

curl -fsS -X POST "http://127.0.0.1:3100/api/issues/<ISSUE_ID>/checkout" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "X-Paperclip-Run-Id: <RUN_ID>" \
  -H "Content-Type: application/json" \
  -d '{"agentId":"<AGENT_ID>","expectedStatuses":["todo","backlog","blocked","in_review"]}'
```

Replace `<TOKEN>`, `<ISSUE_ID>`, `<RUN_ID>`, `<AGENT_ID>` with the literal values from your wake text and key file. Single-quote the JSON body to avoid escaping issues.

### Plugin shortcuts (use these when they fit)

Four Paperclip operations are also available as native OpenClaw tools via the `foreman-paperclip-tools` plugin, which avoids the `curl` + JSON boilerplate:

- `paperclip_get_issue(issue_id)` — same as `GET /api/issues/{id}`
- `paperclip_list_issues(company_id, status?, assignee_agent_id?)` — same as `GET /api/companies/{id}/issues` with filters
- `paperclip_update_issue_status(issue_id, status)` — same as `PATCH /api/issues/{id}` with only a status change
- `paperclip_post_comment(issue_id, body)` — same as `POST /api/issues/{id}/comments`

Prefer these for the four listed operations. For anything else — especially **creating child issues** (delegation), **checkout**, **listing agents**, **creating board approvals**, **updating plan documents** — use `curl` via `exec`. There is no plugin tool for those.

### Endpoints you use regularly

| Purpose | Method + path | Shortcut |
|---|---|---|
| Compact inbox | `GET /api/agents/me/inbox-lite` | curl |
| Full inbox (fallback) | `GET /api/companies/{companyId}/issues?assigneeAgentId={your_id}&status=todo,in_progress,in_review,blocked` | `paperclip_list_issues` |
| Compact heartbeat context | `GET /api/issues/{issueId}/heartbeat-context` | curl |
| Full issue + ancestors | `GET /api/issues/{issueId}` | `paperclip_get_issue` |
| Issue comments (full) | `GET /api/issues/{issueId}/comments` | curl |
| Incremental comments | `GET /api/issues/{issueId}/comments?after={commentId}&order=asc` | curl |
| Specific comment | `GET /api/issues/{issueId}/comments/{commentId}` | curl |
| Checkout issue | `POST /api/issues/{issueId}/checkout` with `{"agentId":"<your_id>","expectedStatuses":["todo","backlog","blocked","in_review"]}` | curl |
| Update issue status only | `PATCH /api/issues/{issueId}` with `{"status":"..."}` | `paperclip_update_issue_status` |
| Update issue status + comment | `PATCH /api/issues/{issueId}` with `{"status":"...","comment":"..."}` | curl (plugin doesn't take comments) |
| Post comment only | `POST /api/issues/{issueId}/comments` with `{"body":"..."}` | `paperclip_post_comment` |
| Create child issue (delegate) | `POST /api/companies/{companyId}/issues` with `parentId`, `assigneeAgentId`, etc | **curl** (no plugin tool) |
| Plan document (create/update) | `PUT /api/issues/{issueId}/documents/plan` | curl |
| Get issue document | `GET /api/issues/{issueId}/documents/{key}` | curl |
| List agents | `GET /api/companies/{companyId}/agents` | **curl** (no plugin tool) |
| Fetch one agent | `GET /api/agents/{agentId}` | curl |
| Create board approval | `POST /api/companies/{companyId}/approvals` | **curl** (no plugin tool) |
| Fetch approval | `GET /api/approvals/{approvalId}` | curl |
| List linked issues for approval | `GET /api/approvals/{approvalId}/issues` | curl |

### Checkout semantics

- Atomic. 409 = another agent already holds it. **Never retry.**
- If called twice by you: returns normally (idempotent for the same agent).

### Error handling cheat sheet

- `401` / `403` — API key wrong or lacks scope. Log, exit, escalate to board.
- `404` — issue/agent doesn't exist. Verify id. Don't retry.
- `409` on checkout — race. Skip.
- `422` — validation error. Read the body carefully; usually means you tried to advance a stage you're not allowed to advance, or sent a status Paperclip rejected.
- `5xx` — platform error. Log, exit, resume next heartbeat.

---

## 2. `hire_agent` (Foreman plugin tool)

Provisions a new AI sub-agent via Foreman's provisioning orchestrator.

**Signature:**
```
hire_agent(
  role: "marketing_analyst",    // REQUIRED. Current enum: only "marketing_analyst".
  display_name: "...",          // Optional. Human-readable name.
  model_tier: "open" | "frontier" | "hybrid"  // Optional. Defaults to company default.
)
```

**Flow when called:**
1. Foreman backend receives `POST /api/internal/agents/provision`.
2. Orchestrator runs:
   - Step 0: payment gate (Stripe billing check)
   - Step 1: idempotency key validation
   - Step 2: input validation
   - Step 3: create OpenClaw workspace
   - Step 4: add OpenClaw agent record
   - Step 5: submit Paperclip hire request → creates `request_board_approval`
   - Step 5b: Stage 1 corrections — creates `[JOURNAL]` issue, patches subordinate `metadata.journal_issue_id`, inserts Supabase `sync_cursors` row
   - Step 6: wait for human board approval (Paperclip UI)
   - Step 7: token sync
   - Step 8: config reload
   - Step 9: final verification
3. Tool returns one of:
   - Success: `Hired <role> successfully. New agent id: <id>.` (after board approval completes — may take multiple heartbeats)
   - `PROVISIONING_BLOCKED (<code>): <customer_message>` — billing or validation issue
   - HTTP error — backend unreachable

**Constraint:** `hire_agent` enum is currently `marketing_analyst` only. Other roles (`engineer`, `qa`, `designer`, etc) will be rejected by the Foreman plugin. If the task needs an unavailable role, escalate via `request_board_approval` rather than trying to misuse an existing agent.

**Constraint:** the new agent is in pending approval after step 5. You cannot assign work to it until the human board approves in Paperclip UI.

### ⚠️ Known limitation (temporary)

The Foreman provisioning orchestrator's Step 6 currently **auto-approves** hires after Step 5 submits the Paperclip hire request. This means in practice, calling `hire_agent` today will complete the hire without firing a `$PAPERCLIP_APPROVAL_ID` wake back to you. The new agent will appear in the roster with `status: idle` on your next heartbeat, not after a separate approval callback.

This is a deviation from Paperclip's documented governance model and will be corrected in a later phase of the Foreman drift teardown (tracked in `/Users/jonathanborgia/foreman-git/foreman-v2/docs/DRIFT-TEARDOWN-FOLLOWUPS.md`, item about auto-approve removal). Until that ships:

- If you call `hire_agent` and it returns success, the hire is complete. Do not wait for an approval wake.
- Do NOT `PATCH` the current issue to `in_review` expecting the hiring flow to continue on a later wake — the CEO should continue the originating task's flow using the freshly-provisioned agent on the same heartbeat or a scheduled one.
- This limitation does not affect `escalate_to_frontier` or any other Paperclip API calls.

When Step 7 of the teardown ships, this block is removed and the `hire_agent` flow documented above becomes accurate again.

---

## 3. `escalate_to_frontier` (Foreman plugin tool)

Sticky escalation from default-tier model routing to frontier-tier for a specific task.

**Signature:**
```
escalate_to_frontier(
  issue_id: "<paperclip_issue_id>",
  task_type: "code_generation" | "code_review" | "reasoning" | "research" | "writing"
)
```

**Semantics:**
- Escalation is sticky per task. Once a task is escalated, all subsequent model calls for that issue id use frontier.
- The Foreman token-meter plugin respects escalation state automatically. You don't need to pass model hints to worker agents.
- Frontier tokens cost more — OpenRouter BYOK at frontier-tier rates.

**When to escalate:**
- A subordinate returned a low-quality result and model tier was likely the bottleneck.
- You (as CEO) are attempting a task that requires heavier reasoning than default provides.

**When NOT to escalate:**
- Routine work.
- To "just try harder" — escalation doesn't substitute for better task definition.

---

## 4. Session primitives — NOT for delegation

OpenClaw exposes `sessions_spawn`, `sessions_yield`, `sessions_send`, `subagents`, and `agents_list`. These exist in your tool list but **they are not how Foreman delegates work.**

- **Foreman delegation is Paperclip issue assignment.** You create a child issue with `parentId` set, assign it to a specialist, and exit. The specialist's next heartbeat picks it up. That's the whole flow. See `HEARTBEAT.md` Step 9.
- **`sessions_spawn` is intra-session OpenClaw collaboration.** It belongs to a different orchestration model (single-process multi-agent) that Foreman does not use.
- If you find yourself reasoning *"I'll spawn a session to do X"* during a heartbeat, stop. That's the drift signal. Create a Paperclip child issue instead.

---

## 5. Environment specifics (your install)

- **Foreman repo:** `/Users/jonathanborgia/foreman-git/foreman-v2`
- **Paperclip company id:** `$PAPERCLIP_COMPANY_ID`
- **Your Paperclip agent id:** `$PAPERCLIP_AGENT_ID`
- **Paperclip API base:** `$PAPERCLIP_API_URL` (typically `http://localhost:3100`)
- **OpenClaw gateway:** `ws://127.0.0.1:18789/` (local loopback)

### Current specialist roster in this company

Re-query each heartbeat via `GET /api/companies/$PAPERCLIP_COMPANY_ID/agents` — the snapshot below is at workspace setup time. Subordinate roster changes.

All specialists listed below report directly to the CEO (`reportsTo: a7a0b631-1b67-452f-bbd2-ea530fdde75d`). Names are spaceless (CamelCase) and serve as @-mention handles.

| id | name | role | notes |
|---|---|---|---|
| `9a6196ae-4593-4f97-94c2-d57f90448463` | Engineer | engineer | idle |
| `42e5484c-d279-42ff-b321-882b7629fd54` | Designer | designer | idle |
| `e946fc97-17d6-4022-aa68-fffa64c03198` | QA | qa | idle |
| `7b154720-0429-460a-ae1b-180e51b93b8a` | MarketingAnalyst | cmo | idle |

---

## 6. Operator notes (for the board, not the CEO)

Cost-saving OpenClaw heartbeat options if tokens pile up:
- Set `agents.defaults.heartbeat.lightContext: true` in `~/.openclaw/openclaw.json` — heartbeat runs keep only `HEARTBEAT.md` from bootstrap files (not full `SOUL.md` + `AGENTS.md` + etc).
- Set `agents.defaults.heartbeat.isolatedSession: true` — each heartbeat runs in a fresh session with no prior conversation history. Can cut heartbeat token cost from ~100K to ~2-5K per run.

These are `openclaw.json` operator settings, not CEO-agent decisions.

---

## 7. HEARTBEAT_OK protocol

OpenClaw treats `HEARTBEAT_OK` at the start or end of your reply as an ack:
- Token is stripped from the output.
- If remaining content is ≤ 300 chars, the reply is dropped entirely (no external delivery).
- For alerts or substantive updates, do NOT include `HEARTBEAT_OK`.

Use `HEARTBEAT_OK:ceo` (or `HEARTBEAT_OK:ceo <short note>`) when exiting a heartbeat with nothing to report.