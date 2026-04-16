# P14 Migration Notes — Jonathan as Customer 1

**Date:** 2026-04-16  
**Customer ID:** 31c326fa-2f13-4f57-a448-127a3d3d19ec  
**New CEO Paperclip Agent ID:** f4d652b8-75b4-4bac-bdfd-a5b75d499ec1  
**New CEO OpenClaw Agent ID:** foreman-ceo

## What happened

- Jonathan's customer record created in `customers` table (BYOK mode, fallback enabled)
- Stripe customer created in live mode (`cus_ULbuQddUpejxHS`) with founder 100% coupon
- BYOK platform subscription active (`sub_1TMuo0LIeTmtbHlGXCOunHrx`)
- New CEO agent provisioned via `provisionForemanAgent` (hybrid tier)
- `ceo-test-adapter` (`080d7809-...`) disabled in Paperclip (adapterConfig zeroed)
- Legacy `ceo` (`a81ff4a7-...`) disabled in Paperclip (adapterConfig zeroed)
- OpenClaw `ceo` slug deleted; no dedicated `ceo-test-adapter` OpenClaw slug remains

## Active agents after migration

- `f4d652b8-75b4-4bac-bdfd-a5b75d499ec1` — Jonathan's production CEO (`foreman-ceo` in OpenClaw)

## Retired agents

- `080d7809-f561-4158-bcf3-12526961a1d5` — ceo-test-adapter (DISABLED in Paperclip, OpenClaw route removed)
- `a81ff4a7-5d8b-4a0f-a610-5fcf4cc8a5af` — legacy ceo (DISABLED in Paperclip, OpenClaw `ceo` slug deleted)

## Notes

- Paperclip CLI does not support `agent delete`; agents were disabled via REST `PATCH`
  (`gatewayUrl`/`url` zeroed, `headers` cleared) rather than deleted
- Disabled agents remain in Paperclip's database for audit trail but cannot receive heartbeats
- `STRIPE_MODE=live` was set in `.env` for this migration; decide whether to keep live
  or switch back to test for day-to-day development
