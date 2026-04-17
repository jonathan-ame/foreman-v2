# P21 Autonomous Smoke Results

Date: 2026-04-17
Spec: `docs/specs/provision-foreman-agent-scope.md`

## Scope

Validate end-to-end autonomous loop over scheduled heartbeat cycles:

- CEO wakes on schedule
- CEO processes assigned issues
- task progress/comments are written
- Paperclip spend and budget tracking are non-zero
- Foreman token counters reflect usage
- system remains stable (no `trim` TypeError, integration checks green)

## Workload

Issues created:

- `FOR-154` (`bb7b3ec1-860c-4774-8fb3-039efd174f55`) - P21 Task 1: Status report
- `FOR-155` (`76cdf0a7-d681-4550-8b91-ebe72ea18fd1`) - P21 Task 2: Market research
- `FOR-156` (`f2a378e5-d372-4139-80f0-28bf8d75b884`) - P21 Task 3: Draft outreach email

All three were set to `todo` and assigned to CEO `f4d652b8-75b4-4bac-bdfd-a5b75d499ec1`.

## Heartbeat Evidence

Baseline before autonomous window:

- `lastHeartbeatAt=2026-04-17T04:55:45.546Z`

Observed in passive scheduler monitor:

- `2026-04-17T05:11:10Z -> lastHeartbeatAt=2026-04-17T05:09:54.953Z`
- `2026-04-17T05:16:10Z -> lastHeartbeatAt=2026-04-17T05:14:50.724Z`

Post-window snapshot:

- `lastHeartbeatAt=2026-04-17T05:52:10.982Z`

Result: autonomous scheduled wakeups confirmed.

## Issue Outcomes

After autonomous run:

- `FOR-154`: `done`
- `FOR-155`: `done`
- `FOR-156`: `done`

Agent progress comments present:

- `FOR-154`: 4 agent-authored comments
- `FOR-155`: 5 agent-authored comments
- `FOR-156`: 4 agent-authored comments

## Cost and Budget Signals

Paperclip company cost summary:

- `spendCents=76`
- `budgetCents=10000`
- `utilizationPercent=0.76`

CEO budget snapshot:

- `budgetMonthlyCents=5000`
- `spentMonthlyCents=75`
- derived utilization: `1.5%`

Result: Paperclip metering + budget utilization are non-zero.

## Foreman DB + Notifications

Agents table (`backend` Supabase query):

- all rows still show `total_tokens_input=0`, `total_tokens_output=0`

Notifications table (latest 20):

- existing `agent_hired` notification found from prior run (`workspace_slug=smoke-provisioning`)
- no new sub-agent hire notification during this P21 window

## Stability Checks

- `trim` TypeError during this window: not observed (`2026-04-17T05:*` search returned no matches)
- `./scripts/integration-check.sh`: PASS

## Checklist

- [x] CEO woke automatically
- [x] At least one issue moved to done (all three did)
- [x] CEO left progress comments on touched issues
- [x] Paperclip token cost data non-zero
- [ ] Foreman agents table token counters non-zero
- [x] Budget utilization non-zero
- [ ] New sub-agent hire occurred in this run (not observed)
- [x] No `trim` TypeError in window
- [x] Integration check passes

## Conclusion

Autonomous scheduling, issue execution, completion, comments, and Paperclip cost/budget tracking are working.
Foreman DB token counters remain zero despite Paperclip spend increasing; this indicates a remaining sync gap between metering events and Foreman `agents` token counter updates.
