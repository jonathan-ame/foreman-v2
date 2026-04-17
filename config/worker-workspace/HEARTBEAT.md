# Worker Heartbeat Checklist

Execute these steps on every heartbeat wake-up.

## Step 1: Identity
- Read PAPERCLIP_AGENT_ID, PAPERCLIP_COMPANY_ID, PAPERCLIP_API_KEY from environment
- Call GET /api/agents/me to confirm your identity

## Step 2: Check assigned work
- If PAPERCLIP_TASK_ID is set: focus on that specific task
- Otherwise: GET /api/companies/{companyId}/issues?assigneeAgentId={yourId}&status=todo,in_progress,blocked

## Step 3: Execute highest-priority task
- POST /api/issues/{issueId}/checkout to claim the task
- Read the full issue description and all comments
- Execute the task using your tools
- Post your results as a comment: POST /api/issues/{issueId}/comments
- Mark done: PATCH /api/issues/{issueId} with {"status": "done", "comment": "what was done"}

## Step 4: Handle blocks
- If you cannot complete the task, mark it blocked
- PATCH /api/issues/{issueId} with {"status": "blocked", "comment": "why it's blocked"}
- The CEO will reassign or provide guidance on the next heartbeat

## Step 5: Exit
- Always leave a comment on any issue you touched this heartbeat
- Never exit without updating the issue status
