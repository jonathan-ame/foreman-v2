"use strict";

const { randomUUID } = require("node:crypto");

async function executePlan(plan, context) {
  const actions = Array.isArray(plan.actions) ? plan.actions : [];
  const results = [];

  for (const action of actions) {
    try {
      const result = await executeAction(action, context);
      results.push({ action: action.type, status: "ok", ...result });
      context.logger(`ok ${action.type}: ${result.summary || "done"}`);
    } catch (error) {
      results.push({ action: action?.type || "unknown", status: "error", error: error.message });
      context.logger(`error ${action?.type || "unknown"}: ${error.message}`);
    }
  }

  return results;
}

async function executeAction(action, context) {
  switch (action.type) {
    case "checkout_issue":
      return checkoutIssue(action, context);
    case "comment":
      return postComment(action, context);
    case "update_status":
      return updateIssueStatus(action, context);
    case "create_issue":
      return createIssue(action, context);
    case "hire_agent":
      return hireAgent(action, context);
    case "escalate":
      return postEscalation(action, context);
    case "no_action":
      return { summary: "No action needed this cycle" };
    default:
      throw new Error(`Unknown action type: ${action.type}`);
  }
}

async function checkoutIssue(action, ctx) {
  if (!action.issue_id) throw new Error("checkout_issue requires issue_id");
  await paperclipPost(
    ctx,
    `/api/issues/${action.issue_id}/checkout`,
    {
      agentId: ctx.agentId,
      expectedStatuses: ["todo", "backlog", "blocked"],
    },
    {
      "X-Paperclip-Run-Id": ctx.runId,
    },
  );
  return { summary: `Checked out ${action.issue_id}` };
}

async function postComment(action, ctx) {
  if (!action.issue_id) throw new Error("comment requires issue_id");
  if (!action.body || String(action.body).trim() === "") throw new Error("comment requires body");
  await paperclipPost(
    ctx,
    `/api/issues/${action.issue_id}/comments`,
    { body: action.body },
    {
      "X-Paperclip-Run-Id": ctx.runId,
    },
  );
  return { summary: `Commented on ${action.issue_id}` };
}

async function updateIssueStatus(action, ctx) {
  if (!action.issue_id) throw new Error("update_status requires issue_id");
  if (!action.status) throw new Error("update_status requires status");
  await paperclipPatch(
    ctx,
    `/api/issues/${action.issue_id}`,
    {
      status: action.status,
      comment: action.comment,
    },
    {
      "X-Paperclip-Run-Id": ctx.runId,
    },
  );
  return { summary: `${action.issue_id} -> ${action.status}` };
}

async function createIssue(action, ctx) {
  if (!action.title || !action.description) {
    throw new Error("create_issue requires title and description");
  }

  const body = {
    title: action.title,
    description: action.description,
    priority: action.priority || "medium",
  };
  if (action.assignee_agent_id) body.assigneeAgentId = action.assignee_agent_id;
  if (action.parent_id) body.parentId = action.parent_id;

  const result = await paperclipPost(
    ctx,
    `/api/companies/${ctx.companyId}/issues`,
    body,
    {
      "X-Paperclip-Run-Id": ctx.runId,
    },
  );

  const issue = unwrapEntity(result, ["issue", "data"]);
  return { summary: `Created issue: ${action.title}`, issueId: issue?.id || null };
}

async function hireAgent(action, ctx) {
  if (!action.role) throw new Error("hire_agent requires role");
  if (!ctx.customerId) throw new Error("customerId is required for hire_agent execution");

  const response = await fetch(`${ctx.foremanApiBase}/api/internal/agents/provision`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      customer_id: ctx.customerId,
      role: action.role,
      agent_name: action.display_name || action.role,
      model_tier: "hybrid",
      idempotency_key: randomUUID(),
    }),
  });

  const raw = await response.text();
  let parsed = null;
  if (raw.length > 0) {
    try {
      parsed = JSON.parse(raw);
    } catch (error) {
      throw new Error(`hire_agent returned non-JSON (${response.status}): ${raw.slice(0, 200)}`);
    }
  }

  if (!response.ok) {
    const detail =
      parsed?.customer_message ||
      parsed?.error ||
      parsed?.message ||
      raw.slice(0, 200) ||
      "Hire failed";
    throw new Error(`hire_agent failed (${response.status}): ${detail}`);
  }

  const payload = unwrapEntity(parsed, ["data", "agent"]);
  return { summary: `Hired ${action.role}`, agentId: payload?.agent_id || payload?.id || null };
}

async function postEscalation(action, ctx) {
  const issueId = action.issue_id || ctx.taskId;
  if (!issueId) throw new Error("escalate requires issue_id (or an active task context)");

  await paperclipPost(
    ctx,
    `/api/issues/${issueId}/comments`,
    {
      body: `[ESCALATION] ${action.message || "Board attention required."}`,
    },
    {
      "X-Paperclip-Run-Id": ctx.runId,
    },
  );
  return { summary: `Escalated on ${issueId}` };
}

async function paperclipPost(ctx, path, body, extraHeaders = {}) {
  return paperclipRequest(ctx, path, "POST", body, extraHeaders);
}

async function paperclipPatch(ctx, path, body, extraHeaders = {}) {
  return paperclipRequest(ctx, path, "PATCH", body, extraHeaders);
}

async function paperclipRequest(ctx, path, method, body, extraHeaders = {}) {
  const response = await fetch(`${ctx.apiUrl}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${ctx.apiKey}`,
      "Content-Type": "application/json",
      ...extraHeaders,
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  const raw = await response.text();
  let parsed = null;
  if (raw.length > 0) {
    try {
      parsed = JSON.parse(raw);
    } catch (error) {
      throw new Error(`Paperclip returned non-JSON for ${method} ${path}: ${raw.slice(0, 200)}`);
    }
  }

  if (!response.ok) {
    const detail = parsed?.error || parsed?.message || raw.slice(0, 200) || "unknown error";
    throw new Error(`Paperclip ${method} ${path} failed (${response.status}): ${detail}`);
  }

  return parsed;
}

function unwrapEntity(data, keys) {
  if (!data || typeof data !== "object") return data;
  for (const key of keys) {
    if (Object.prototype.hasOwnProperty.call(data, key)) return data[key];
  }
  return data;
}

module.exports = {
  executePlan,
};
