# ai.foreman.stack-health — disabled during Phase 3

Disabled on 2026-04-14T15:02:51-06:00 as part of Phase 3 substrate migration.

## Why

The `ai.foreman.stack-health` launchd job ran `scripts/foreman-stack-health.sh`
on a 120-second interval. When it detected drift in `~/.openclaw/openclaw.json`
(comparing sha256 against `state/openclaw-config-checksum.txt`), it invoked
`scripts/configure.sh` to "restore" the file.

In Phase 3 we restructured OpenClaw config to use the native `$include`
mechanism (commit `b129dd3`). OpenClaw now owns `~/.openclaw/openclaw.json`
directly and writes its own `meta` fields on startup. The stack-health
watchdog was fighting this: every 120s it detected OpenClaw's meta-enriched
file as "drift" from the pre-include baseline and rewrote it, which
triggered OpenClaw to re-observe missing meta and write again. Infinite loop.

## What was disabled

- `launchctl bootout` + `launchctl disable` for `gui/<uid>/ai.foreman.stack-health`
- `~/Library/LaunchAgents/ai.foreman.stack-health.plist` moved to
  `ai.foreman.stack-health.plist.disabled-phase3-*`
- Script `scripts/foreman-stack-health.sh` remains in repo (no changes)
  but no longer runs on any schedule

## When this changes

Phase 6 retires the shell-script layer (`configure.sh`,
`foreman-stack-health.sh`, `paperclip-role-dispatch.sh`, etc.) in favor
of Paperclip-native orchestration. Until then, stack-health stays disabled.

If someone needs the drift-detection behavior back, the plist file in
LaunchAgents can be restored by removing the `.disabled-phase3-*` suffix
and running `launchctl load ~/Library/LaunchAgents/ai.foreman.stack-health.plist`.
But this will re-introduce the Phase 3 anomaly loop unless the script
is also updated to understand the `$include` structure.
