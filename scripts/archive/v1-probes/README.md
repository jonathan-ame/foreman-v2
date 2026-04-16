# Archived v1 probe scripts

These scripts were used by the legacy probe-driven `scripts/integration-check.sh` flow.

They are archived because Foreman v2 now exposes backend-native integration health at:

- `GET /api/internal/health/integration`

This endpoint replaces ad-hoc probe scripts that depended on deprecated process-adapter agent behavior.

Archived here for historical/debug reference:

- `ceo-agent-auth-probe.sh`
- `runid-injection-probe.sh`
- `ensure-ceo-auth-probe-schedule.sh`
- `ensure-runid-injection-probe-schedule.sh`
