# CEO Heartbeat Checklist (OpenClaw-Native)

Run this flow on every CEO heartbeat.

## 1) Parse task context

- Read the assigned issue title, description, and current status.
- Read recent issue comments.
- Check whether child issues already exist and whether any are still active.
- Confirm whether this heartbeat is actionable or waiting on prior delegation.

## 2) Terminal-state guard

- If issue status is already `in_review` or `done`, exit immediately.

## 3) Existing-child guard

- If child issues already exist and are still in progress, do not re-delegate.
- Wait for current work to complete and update only when new signal arrives.

## 4) Delegate via sessions_spawn

- If delegation is needed, choose the right specialist(s):
  - `foreman-engineer`
  - `foreman-marketing-analyst`
  - `foreman-qa`
  - `foreman-designer`
- For each specialist, call:
  - `sessions_spawn(agentId: "<specialist>", task: "<specific actionable instruction>")`
- Make tasks concrete, scoped, and verifiable.

## 5) Yield for announces

- After all `sessions_spawn` calls return runIds, call `sessions_yield`.
- Do not poll for completion in loops. Announce messages are the completion
  signal.

## 6) Synthesize and update board

- When announce messages arrive, synthesize the specialist outputs.
- Post one consolidated board update using `paperclip_post_comment`.
- Update status using `paperclip_update_issue_status`:
  - `in_review` when waiting for human review
  - `done` when execution is complete
  - `blocked` if progress is impossible

## 7) Blocked-path behavior

- If a required dependency fails, post a concise blocker report with evidence.
- Prefix blocker summaries with `[BLOCKED]`.
- Avoid partial success framing when critical deliverables cannot be completed.

## Example delegation flow

User issue:
"Evaluate launch readiness for a new feature. Include quality risks, UX risks,
and implementation constraints."

CEO reasoning:
- This requires three specialists: engineer, qa, designer.
- I should split into scoped tasks and gather announces before posting.

Tool call 1:
`sessions_spawn(agentId: "foreman-engineer", task: "Review implementation constraints for feature launch. Identify top 3 engineering risks, required mitigations, and a go/no-go recommendation.")`

Tool call 2:
`sessions_spawn(agentId: "foreman-qa", task: "Review launch quality risk. Provide high-priority test scenarios, likely regressions, and release-blocking test gaps.")`

Tool call 3:
`sessions_spawn(agentId: "foreman-designer", task: "Review UX launch risk. Identify usability hazards, accessibility concerns, and top design fixes required before launch.")`

Then:
`sessions_yield()`

After announces arrive:
- Synthesize the three outputs into one board-ready summary.
- Post one comment with conclusions, risk table, and recommendation.
- Set issue to `in_review` (or `done` if fully complete).
