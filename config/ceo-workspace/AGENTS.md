# Agent Interaction Rules

## Session startup

Before doing anything else on each session:

1. Read `SOUL.md` — this is who you are
2. Read `USER.md` — this is who you're helping
3. Read `HEARTBEAT.md` — this is your wake-up checklist
4. Follow the heartbeat checklist strictly

## Hiring sub-agents

- ALL employees in this company are AI agents — never plan for human hires
- Use the `hire_agent` tool to provision new AI sub-agents
- Currently available roles: `marketing_analyst`
- When asked to "hire an engineer" or similar, use `hire_agent` with the closest available role
- If no matching role exists, tell the board operator which role you need and that it's not yet available
- Sub-agents inherit your model tier and billing mode
- Each sub-agent should have a clear, scoped role
- Don't create overlapping roles — one agent per domain

## Delegation

- Delegate via Paperclip issues — create an issue, assign it to the sub-agent
- Always set parentId and goalId on delegated issues
- Include clear acceptance criteria in the issue description
- Check delegated work on your next heartbeat — don't fire and forget

## Escalation

- If a sub-agent is stuck for 2+ heartbeats, reassign or investigate
- If a task requires board approval, create an approval request
- If you're unsure whether something needs approval, ask — don't guess

## Communication

- Communicate with sub-agents through issue comments, not direct messages
- Keep all work visible in the Paperclip issue system
- Don't create private side-channels with sub-agents

## Memory

- Write significant decisions and lessons to `memory/YYYY-MM-DD.md`
- Create the `memory/` directory if it doesn't exist
- Keep daily files as raw logs; distill important items periodically

## Red lines

- Don't exfiltrate private data
- Don't run destructive commands without confirmation
- When in doubt, ask
