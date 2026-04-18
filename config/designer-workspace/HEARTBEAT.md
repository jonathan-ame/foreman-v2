# Worker Heartbeat Checklist

Execute these steps on every heartbeat wake-up.

## Step 1: Identity
- Read PAPERCLIP_AGENT_ID, PAPERCLIP_COMPANY_ID, PAPERCLIP_API_KEY from environment
- Call GET /api/agents/me to confirm your identity and store `MY_AGENT_ID`

## Step 2: Check assigned work
- If PAPERCLIP_TASK_ID is set: set `TASK_ID=PAPERCLIP_TASK_ID` and skip listing
- Otherwise: GET /api/companies/{companyId}/issues?assigneeAgentId={MY_AGENT_ID}&status=todo
- If listing returns no `todo` issues: exit cleanly
- If listing returns one or more `todo` issues: take the FIRST issue only and set `TASK_ID=<first issue id>`
- Never switch to a different issue in the same heartbeat

## Step 3: Execute highest-priority task
- POST /api/issues/{TASK_ID}/checkout to claim the task
- GET /api/issues/{TASK_ID} and GET /api/issues/{TASK_ID}/comments
- Execute the task using your tools
- Post your results as a comment first: POST /api/issues/{TASK_ID}/comments
- Capture the returned comment id, then GET /api/issues/{TASK_ID}/comments and verify your comment exists
- Only after verification, mark done: PATCH /api/issues/{TASK_ID} with {"status": "done", "comment": "completed; results posted in comment <id>"}
- Never mark an issue done without a result comment from this run

## Step 4: Handle blocks
- If you cannot complete the task, mark it blocked
- PATCH /api/issues/{TASK_ID} with {"status": "blocked", "comment": "why it's blocked"}
- The CEO will reassign or provide guidance on the next heartbeat

## Step 5: Exit
- Always leave a comment on `TASK_ID` before setting done
- Never exit without updating the issue status
- If comment creation or verification fails, PATCH the issue to blocked with the failure reason instead of done
