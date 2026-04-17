# CEO Heartbeat Configuration

**Agent:** `f4d652b8-75b4-4bac-bdfd-a5b75d499ec1` (`foreman-ceo`)  
**Interval:** 30 minutes (1800 seconds)  
**Mode:** proactive (reads `HEARTBEAT.md` on every wake)  
**Timeout:** 1500 seconds (25 minutes - leaves 5-minute buffer before next heartbeat)

## Primary scheduler

Paperclip's native heartbeat scheduler (`runtimeConfig.heartbeat`).

Configured on agent record:
- `runtimeConfig.heartbeat.enabled: true`
- `runtimeConfig.heartbeat.intervalSec: 1800`
- `runtimeConfig.heartbeat.mode: proactive`
- `adapterConfig.timeoutSec: 1500`

## Backup scheduler

macOS launchd plist at `~/Library/LaunchAgents/ai.foreman.ceo-heartbeat-backup.plist`.

Runs every 30 minutes (`StartInterval=1800`) and invokes:
- `paperclipai heartbeat run --agent-id <CEO_ID> --api-base http://localhost:3125 --timeout-ms 1500000 --api-key <backup-key>`

Important details:
- Use `--timeout-ms 1500000` (25 minutes) so the CLI does not abort long OpenClaw/OpenRouter runs.
- Pass `--api-key` explicitly from `~/.foreman/ceo-heartbeat-backup-key.json` to avoid context-principal drift (`Agent can only invoke itself`).

Uses dedicated CEO API key file:
- `~/.foreman/ceo-heartbeat-backup-key.json`

Logs:
- `~/.foreman/logs/ceo-heartbeat-backup.log`
- `~/.foreman/logs/ceo-heartbeat-backup-err.log`

This is a safety net, not the primary scheduler.

## Verification (P16)

Step 4 field verification output:
- `heartbeat.enabled: True`
- `heartbeat.intervalSec: 1800`
- `heartbeat.mode: proactive`
- `adapterConfig.timeoutSec: 1500`
- `adapterConfig.gatewayUrl present: True`
- `adapterConfig.headers present: True`

Step 6 scheduled wake result:
- `lastHeartbeatAt` stayed unchanged for 30 minutes
- backup launchd log showed invoke at `2026-04-16T20:30:15.098Z`
- `lastHeartbeatAt` advanced to `2026-04-16T20:35:36.969Z`

Conclusion: heartbeat fired via backup scheduler during this validation window.

## Known issues

- `paperclipai/paperclip#1165`: scheduler may stop after server restart; backup launchd covers this
- `paperclipai/paperclip#1749`: zombie runs can block next heartbeat; `timeoutSec` mitigates this
