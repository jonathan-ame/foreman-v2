# Launch Readiness - Foreman v2

**Last updated:** 2026-04-17  
**Assessment:** Local autonomous operation is fully functional.

## Capability Status

| Capability | Status | Notes |
|---|---|---|
| provisionForemanAgent core | ✅ Ready | P4-P6 |
| 3-tier subscription billing | ✅ Ready | P8-P9 |
| BYOK billing | ✅ Ready | P14 dogfood |
| BYOK fallback | ⚠️ Designed, not built | P19 skipped - scope doc complete |
| Health checks | ✅ Ready | P12 |
| Scheduled heartbeats | ✅ Ready | P16 (30-min proactive + backup cron) |
| Token metering | ✅ Ready | P17 (OpenClaw -> Paperclip cost-events) |
| Budget enforcement | ✅ Ready | P18 ($100 company / $50 CEO) |
| Hybrid tier escalation | ✅ Ready | P20 (2-rejection rule + manual tool) |
| CEO workspace files | ✅ Ready | P15 |
| CEO hire_agent tool | ✅ Ready | P11 |
| Full autonomous cycle | ✅ Verified | P21 (3/3 tasks done, cost tracked) |
| Foreman DB token sync | ⚠️ Partial | Paperclip tracks costs; Foreman DB counters need backend running |
| Customer dashboard UI | ❌ Not started | Separate scope doc needed |
| Task assignment UI (web) | ❌ Not started | Separate scope doc needed |
| Railway deployment | ❌ Not started | Local-only for now |
| Email notifications | ❌ Not started | DB rows written, no email sending |

## Operational requirements (local)

- Paperclip server running at localhost:3125
- OpenClaw gateway running at localhost:18789
- Foreman backend running at localhost:8080 (for DB token tracking)
- After any `openclaw gateway restart`: run `./scripts/sync-gateway-token.sh`
- After any OpenClaw upgrade: re-apply trim patches per `docs/OPENCLAW-TRIM-PATCH.md`
