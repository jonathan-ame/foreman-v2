# OpenClaw Runtime Patch: trim TypeError

**Applied:** 2026-04-16  
**OpenClaw issue:** [openclaw/openclaw#7443](https://github.com/openclaw/openclaw/issues/7443)  
**Affects:** OpenClaw gateway runtime (agent execution path)  
**Symptom:** `TypeError: Cannot read properties of undefined (reading 'trim')` during heartbeat runs  
**Root cause:** Null-unsafe `.trim()` calls in bundled runtime code paths

## Patch locations (OpenClaw installed via Homebrew at /opt/homebrew/lib/node_modules/openclaw/)

Backups were created before every edit with the suffix `.bak-pre-trim-fix`.

1. `dist/command-queue-Cssp02gj.js`  
   - `lane.trim()` -> `(lane ?? "").trim()`
2. `dist/pi-embedded-DWASRjxE.js`  
   - `pathValue.trim().replace(...)` -> `(pathValue ?? "").trim().replace(...)`
3. `dist/docker-BTC5D4nV.js`  
   - added null guards for session/scope `.trim()` paths
4. `dist/tool-policy-CD0rHa6E.js`  
   - `name.trim().toLowerCase()` -> `String(name ?? "").trim().toLowerCase()`
5. `dist/content-blocks-BH1EFqze.js` (P15)  
   - `normalizeReservedToolNames`: `name.trim().toLowerCase()` -> `String(name ?? "").trim().toLowerCase()`
6. `dist/pi-embedded-DWASRjxE.js` (P15, additional patch)  
   - `buildAgentSystemPrompt`: `tool.trim()` -> `String(tool ?? "").trim()`

## Lifecycle

This patch must be re-applied after every OpenClaw upgrade until the upstream
fix is fully merged and released in packaged builds.

Filenames include content hashes and may change between OpenClaw versions. After
upgrading OpenClaw, search for unguarded `.trim()` calls:

```bash
grep -rn "\.trim()" /opt/homebrew/lib/node_modules/openclaw/dist/ | grep -v node_modules | grep -v "??" | head -30
```

Patch any instances that do not include a null guard (`??` or explicit null
check) before `.trim()`.

## Verification

After patching and restarting the gateway, heartbeat run
`f2a28dae-3003-44af-b1db-d72cb60d6abd` for `ceo-test-adapter` succeeded, and
issue `FOR-136` completed without trim-related errors.

P15 re-verification: heartbeat run `d57ae749-b428-4ad5-9217-9ffa22e98e57` for
`foreman-ceo` succeeded after patches 5-6 were applied. CEO processed issues
FOR-113 and FOR-142 with workspace file content reflected in responses.
