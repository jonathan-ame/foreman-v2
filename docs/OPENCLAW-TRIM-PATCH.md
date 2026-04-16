# OpenClaw Runtime Patch: trim TypeError

**Applied:** 2026-04-16  
**OpenClaw issue:** [openclaw/openclaw#7443](https://github.com/openclaw/openclaw/issues/7443)  
**Affects:** OpenClaw gateway runtime (agent execution path)  
**Symptom:** `TypeError: Cannot read properties of undefined (reading 'trim')` during heartbeat runs  
**Root cause:** Null-unsafe `.trim()` calls in bundled runtime code paths

## Patch locations

Backups were created before every edit with the suffix `.bak-pre-trim-fix`.

1. `/opt/homebrew/lib/node_modules/openclaw/dist/command-queue-Cssp02gj.js`  
   - `lane.trim()` -> `(lane ?? "").trim()`
2. `/opt/homebrew/lib/node_modules/openclaw/dist/pi-embedded-DWASRjxE.js`  
   - `pathValue.trim().replace(...)` -> `(pathValue ?? "").trim().replace(...)`
3. `/opt/homebrew/lib/node_modules/openclaw/dist/docker-BTC5D4nV.js`  
   - `sessionKey.trim()` and related session/scope helpers now guard nullish inputs
4. `/opt/homebrew/lib/node_modules/openclaw/dist/tool-policy-CD0rHa6E.js`  
   - `name.trim().toLowerCase()` -> `String(name ?? "").trim().toLowerCase()`

## Lifecycle

This patch must be re-applied after every OpenClaw upgrade until the upstream
fix is fully merged and released in packaged builds.

## Verification

After patching and restarting the gateway, heartbeat run
`f2a28dae-3003-44af-b1db-d72cb60d6abd` for `ceo-test-adapter` succeeded, and
issue `FOR-136` completed without trim-related errors.
