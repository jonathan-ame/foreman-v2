# Launch Readiness (P13)

| Capability | Status | Blocker / Notes |
| --- | --- | --- |
| `provisionForemanAgent` core | ✅ Ready | Step orchestration, rollback, logging, idempotency, and verification implemented and covered by unit tests plus P13 e2e smoke. |
| 3-tier subscription billing | ✅ Ready | Stripe client + webhook + payment gate are implemented; tier-mode subscription checks are active in `step-0-payment-gate`. |
| Usage-based billing | ⚠️ Partial | Balance checks are implemented in `step-0-payment-gate`, but customer-facing top-up and metering reconciliation workflows are not complete end-to-end. |
| BYOK | ✅ Ready | BYOK mode exists in onboarding and payment gate; OpenRouter key validation endpoint is wired for onboarding flow. |
| BYOK fallback | ❌ Blocking | `byok_fallback_enabled` exists on `customers`, but no completed runtime fallback path is wired for production behavior. |
| Health checks | ✅ Ready | 5-minute `agent_health_check` job pauses agents after 3 failures and auto-recovers on success with notifications. |
| Token metering | ❌ Blocking | Explicitly still a separate workstream; allowance fields exist, but authoritative token metering pipeline is not complete. |
| Customer dashboard | ⏸ Out of P0-P13 scope | Separate spec/workstream required. |
| Task assignment UI | ⏸ Out of P0-P13 scope | Separate spec/workstream required. |
| Marketing site | ⏸ Out of scope | Not part of backend launch criteria. |

## Current Launch Blockers

- Token metering pipeline is not production-ready.
- BYOK fallback behavior is not fully implemented.

## P13 Validation Notes

- E2E smoke test added at `backend/test/e2e/full-customer-journey.test.ts`.
- The e2e path validates signup/login, onboarding submission, CEO provisioning, Paperclip issue assignment, heartbeat invocation, and response verification.
