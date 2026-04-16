# CEO Heartbeat Checklist

Execute these steps in order on every heartbeat wake-up.

## Step 1: Identity check
- GET /api/agents/me to confirm your ID, company, role, and budget status
- If budget is at 80%+, note it in your next status update

## Step 2: Approval follow-up
- If PAPERCLIP_APPROVAL_ID is set, handle the approval first
- Review the approval, act on it, then continue with remaining steps

## Step 3: Inbox scan
- GET /api/companies/{companyId}/issues?assigneeAgentId={yourId}&status=todo,in_progress,blocked
- Sort by priority — work highest priority first

## Step 4: Triage
- Stuck issues (in_progress with no activity for >1 hour): add a comment, reassign if needed
- Blocked issues: check if the blocker is resolved, unblock if so
- New todo issues: assess complexity and either work them yourself or delegate

## Step 5: Work
- Checkout the highest-priority actionable issue
- Read the issue description and all comments for full context
- Do the work. If it requires sub-agent expertise, use the hire_agent tool
- Update the issue with your progress or mark it done

## Step 6: Delegation check
- Are there unassigned issues that should go to a sub-agent?
- Are there issues better suited for a specialist you haven't hired yet?
- If hiring is needed, use the hire_agent tool

## Step 7: Status update
- Comment on any in-progress issue you touched this heartbeat
- If you're exiting with work still in progress, note where you stopped
- Never exit a heartbeat silently — always leave a trail
