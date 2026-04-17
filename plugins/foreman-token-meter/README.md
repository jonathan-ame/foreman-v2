# Foreman Token Meter

`foreman-token-meter` bridges OpenClaw model usage into:

- Paperclip `cost-events` (`POST /api/companies/{companyId}/cost-events`)
- Foreman backend usage counters (`POST /api/internal/agents/{agentId}/usage`)

The plugin listens to the OpenClaw `llm_output` hook for every model completion,
reads token usage totals from hook payloads, computes estimated cost from
`models.providers.<provider>.models[].cost` in active OpenClaw config, and
reports both systems asynchronously (fire-and-forget).

## Config

Under `plugins.entries."foreman-token-meter".config`:

- `enabled` (`boolean`, default `true`)
- `paperclipApiBase` (`string`, default `http://localhost:3125`)
- `paperclipApiKey` (`string`, optional fallback if env var absent)
- `paperclipCompanyId` (`string`, required)
- `foremanApiBase` (`string`, default `http://localhost:8080`)

Recommended secret source:

- `PAPERCLIP_API_KEY` environment variable

Optional context env vars:

- `PAPERCLIP_AGENT_ID` (fallback when hook context lacks agent id)
- `PAPERCLIP_ISSUE_ID` or `PAPERCLIP_TASK_ID` (optional issue linkage)
