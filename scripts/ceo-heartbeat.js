"use strict";

const { readFileSync } = require("node:fs");
const { resolve } = require("node:path");
const { executePlan } = require("./lib/plan-executor.js");

const REQUIRED_ENV_VARS = [
  "PAPERCLIP_RUN_ID",
  "PAPERCLIP_AGENT_ID",
  "PAPERCLIP_COMPANY_ID",
  "PAPERCLIP_API_URL",
  "PAPERCLIP_API_KEY",
  "OPENROUTER_API_KEY",
];

const ROLE_CAPABILITIES = {
  marketing_analyst:
    "Market research, competitive analysis, content strategy, campaign analysis, funnel diagnostics",
  engineer: "Code implementation, bug fixes, architecture, technical documentation, code review",
  qa: "Test planning, test execution, bug reporting, quality standards, regression testing",
  designer: "UI/UX design, visual assets, design systems, wireframes, prototyping",
};

function readEnv() {
  const env = {
    PAPERCLIP_RUN_ID: process.env.PAPERCLIP_RUN_ID,
    PAPERCLIP_AGENT_ID: process.env.PAPERCLIP_AGENT_ID,
    PAPERCLIP_COMPANY_ID: process.env.PAPERCLIP_COMPANY_ID,
    PAPERCLIP_API_URL: process.env.PAPERCLIP_API_URL,
    PAPERCLIP_API_KEY: process.env.PAPERCLIP_API_KEY,
    PAPERCLIP_TASK_ID: process.env.PAPERCLIP_TASK_ID,
    PAPERCLIP_WAKE_REASON: process.env.PAPERCLIP_WAKE_REASON || "unknown",
    OPENROUTER_API_KEY: process.env.OPENROUTER_API_KEY,
    DEEPSEEK_MODEL: process.env.DEEPSEEK_MODEL || "deepseek/deepseek-chat-v3-0324",
    FOREMAN_API_BASE: process.env.FOREMAN_API_BASE || "http://localhost:8080",
    FOREMAN_CUSTOMER_ID: process.env.FOREMAN_CUSTOMER_ID || "31c326fa-2f13-4f57-a448-127a3d3d19ec",
  };

  const missing = REQUIRED_ENV_VARS.filter((key) => !env[key] || String(env[key]).trim() === "");
  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(", ")}`);
  }

  return env;
}

async function paperclipRequest(env, path, method = "GET", body) {
  const url = `${env.PAPERCLIP_API_URL}${path}`;
  const response = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${env.PAPERCLIP_API_KEY}`,
      "Content-Type": "application/json",
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
    const detail = parsed && (parsed.error || parsed.message) ? `${parsed.error || parsed.message}` : raw.slice(0, 200);
    throw new Error(`Paperclip request failed (${response.status}) ${method} ${path}: ${detail}`);
  }

  return parsed;
}

function unwrapEntity(data, keys) {
  if (!data || typeof data !== "object") return data;
  for (const key of keys) {
    if (key in data) return data[key];
  }
  return data;
}

function normalizeIssuesResponse(data) {
  const unwrapped = unwrapEntity(data, ["issues", "data"]);
  if (Array.isArray(unwrapped)) return unwrapped;
  if (unwrapped && typeof unwrapped === "object") return [unwrapped];
  return [];
}

function normalizeAgentsResponse(data) {
  const unwrapped = unwrapEntity(data, ["agents", "data"]);
  if (Array.isArray(unwrapped)) return unwrapped;
  if (unwrapped && typeof unwrapped === "object") return [unwrapped];
  return [];
}

function normalizeDelegationRole(agent) {
  const role = String(agent?.role || "").toLowerCase().trim();
  const name = String(agent?.name || "").toLowerCase();
  const urlKey = String(agent?.urlKey || "").toLowerCase();

  if (role === "cmo") return "marketing_analyst";
  if (role === "marketing_analyst") return "marketing_analyst";
  if (
    name.includes("marketing analyst") ||
    name.includes("market research") ||
    urlKey.includes("marketing-analyst") ||
    urlKey.includes("market-research")
  ) {
    return "marketing_analyst";
  }
  if (["engineer", "qa", "designer"].includes(role)) return role;
  return role || "unknown";
}

function buildPreferredWorkerIds(agents) {
  const preferred = {};
  const usableStatuses = new Set(["active", "idle", "running"]);
  for (const role of Object.keys(ROLE_CAPABILITIES)) {
    const matches = agents.filter(
      (agent) =>
        agent.delegationRole === role && usableStatuses.has(String(agent.status || "").toLowerCase()),
    );
    if (matches.length === 0) continue;
    matches.sort((a, b) => {
      const aName = String(a.name || "").toLowerCase();
      const bName = String(b.name || "").toLowerCase();
      const aScore = aName.includes("marketing analyst") ? 0 : 1;
      const bScore = bName.includes("marketing analyst") ? 0 : 1;
      return aScore - bScore;
    });
    preferred[role] = matches[0].id;
  }
  return preferred;
}

function formatDelegationCandidates(agents) {
  if (!Array.isArray(agents) || agents.length === 0) {
    return "Available workers for delegation:\n- none";
  }

  const lines = ["Available workers for delegation:"];
  for (const agent of agents) {
    const role = agent.delegationRole || "unknown";
    const capabilities = ROLE_CAPABILITIES[role] || "General support capabilities";
    const status = String(agent.status || "unknown").toLowerCase();
    const statusNote = ["paused", "disabled", "terminated"].includes(status)
      ? "Do NOT delegate new tasks while unavailable."
      : "Eligible for delegation.";
    const guidance =
      role === "marketing_analyst"
        ? "Assign research, competitor, and go-to-market analysis tasks."
        : role === "engineer"
          ? "Assign implementation, bug-fix, and codebase change tasks."
          : role === "qa"
            ? "Assign test execution, validation, and regression tasks."
            : role === "designer"
              ? "Assign UX review, design feedback, and accessibility tasks."
              : "Match tasks carefully based on current issue scope.";
    lines.push(`- ${agent.name || "Unknown"} (id: ${agent.id || "unknown"})`);
    lines.push(`  Role: ${role}`);
    lines.push(`  Capabilities: ${capabilities}`);
    lines.push(`  Status: ${status}`);
    lines.push(`  Guidance: ${guidance} ${statusNote}`);
  }
  return lines.join("\n");
}

function loadWorkspace() {
  const wsDir = resolve(process.cwd(), "config/ceo-workspace");
  return {
    soulMd: readFileSync(resolve(wsDir, "SOUL.md"), "utf8"),
    heartbeatMd: readFileSync(resolve(wsDir, "HEARTBEAT.md"), "utf8"),
    agentsMd: readFileSync(resolve(wsDir, "AGENTS.md"), "utf8"),
  };
}

function buildSystemPrompt(workspace) {
  return [
    "You are the Foreman CEO strategic planner.",
    "Produce a strategic plan only. The deterministic executor performs API/tool operations.",
    "Output ONLY one valid JSON object. No markdown. No backticks. No prose before/after JSON.",
    "",
    "SOUL.md:",
    workspace.soulMd,
    "",
    "HEARTBEAT.md (planner-only interpretation):",
    workspace.heartbeatMd,
    "",
    "AGENTS.md:",
    workspace.agentsMd,
    "",
    "Allowed action schema:",
    JSON.stringify(
      {
        reasoning: "Brief explanation of what you assessed and decided",
        actions: [
          { type: "checkout_issue", issue_id: "issue-id" },
          { type: "comment", issue_id: "issue-id", body: "comment body" },
          {
            type: "update_status",
            issue_id: "issue-id",
            status: "todo|in_progress|blocked|done",
            comment: "why status changed",
          },
          {
            type: "create_issue",
            title: "sub-task title",
            description: "sub-task details",
            priority: "low|medium|high|urgent",
            assignee_agent_id: "optional",
            parent_id: "optional",
          },
          { type: "hire_agent", role: "marketing_analyst", display_name: "optional" },
          { type: "escalate", issue_id: "optional", message: "board escalation message" },
          { type: "no_action" },
        ],
      },
      null,
      2,
    ),
  ].join("\n");
}

function buildUserPrompt(input) {
  const delegationBlock = formatDelegationCandidates(input.availableAgents);
  const roleCapabilityBlock = JSON.stringify(ROLE_CAPABILITIES, null, 2);
  return [
    "Plan actions for this heartbeat context.",
    "Use only the allowed action types.",
    "Keep actions minimal and high impact.",
    "Delegation rules:",
    "- When creating a sub-task, assign it to the worker whose role best matches the task.",
    "- Use availableAgents to choose the correct assignee_agent_id.",
    "- Only use hire_agent if no suitable active worker exists for the role.",
    "- Never delegate new work to paused, disabled, or terminated agents.",
    "- When creating a delegated sub-task, include assignee_agent_id and parent_id.",
    "- If delegatedChildrenByParent already shows an open child task, do not create duplicates.",
    "- If a child task is done with deliverables, review child comments, synthesize findings, and close the parent.",
    "- Prefer delegating specialist work over doing specialist work in the CEO run.",
    "- For research/comparison/competitor analysis requests, create a child task assigned to marketing_analyst before any direct execution.",
    "",
    "Role capability map:",
    roleCapabilityBlock,
    "",
    delegationBlock,
    "",
    JSON.stringify(input, null, 2),
  ].join("\n");
}

function parsePlanContent(content) {
  if (typeof content !== "string" || content.trim() === "") {
    throw new Error("DeepSeek response content is empty.");
  }

  try {
    return JSON.parse(content);
  } catch (_) {
    // Minor formatting recovery: extract the first JSON object block.
    const start = content.indexOf("{");
    const end = content.lastIndexOf("}");
    if (start === -1 || end === -1 || end <= start) {
      throw new Error(`DeepSeek returned non-JSON content: ${content.slice(0, 240)}`);
    }
    const extracted = content.slice(start, end + 1);
    return JSON.parse(extracted);
  }
}

function validatePlan(plan) {
  if (!plan || typeof plan !== "object") {
    throw new Error("Plan must be a JSON object.");
  }
  if (typeof plan.reasoning !== "string") {
    throw new Error("Plan.reasoning must be a string.");
  }
  if (!Array.isArray(plan.actions)) {
    throw new Error("Plan.actions must be an array.");
  }
  for (const action of plan.actions) {
    if (!action || typeof action !== "object" || typeof action.type !== "string") {
      throw new Error("Each action must be an object with string field `type`.");
    }
  }
}

function calculateCostCents(model, promptTokens, completionTokens) {
  const pricingPerMillionUsd = {
    "deepseek/deepseek-chat-v3-0324": { input: 0.15, output: 0.75 },
    "deepseek/deepseek-chat-v3.1": { input: 0.15, output: 0.75 },
  };
  const pricing = pricingPerMillionUsd[model] || pricingPerMillionUsd["deepseek/deepseek-chat-v3-0324"];
  const inputCostUsd = (Math.max(0, Number(promptTokens) || 0) / 1_000_000) * pricing.input;
  const outputCostUsd = (Math.max(0, Number(completionTokens) || 0) / 1_000_000) * pricing.output;
  const rawCents = (inputCostUsd + outputCostUsd) * 100;
  if (rawCents <= 0) return 0;
  return Math.max(1, Math.ceil(rawCents));
}

async function reportUsage(env, usage) {
  const inputTokens = Number(usage.prompt_tokens ?? 0);
  const outputTokens = Number(usage.completion_tokens ?? 0);
  const costCents = calculateCostCents(env.DEEPSEEK_MODEL, inputTokens, outputTokens);
  const occurredAt = new Date().toISOString();

  const paperclipPromise = fetch(
    `${env.PAPERCLIP_API_URL}/api/companies/${env.PAPERCLIP_COMPANY_ID}/cost-events`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${env.PAPERCLIP_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        agentId: env.PAPERCLIP_AGENT_ID,
        provider: "openrouter",
        model: env.DEEPSEEK_MODEL,
        inputTokens,
        outputTokens,
        costCents,
        occurredAt,
      }),
    },
  );

  const foremanPromise = fetch(`${env.FOREMAN_API_BASE}/api/internal/agents/${env.PAPERCLIP_AGENT_ID}/usage`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      inputTokens,
      outputTokens,
      costCents,
      model: env.DEEPSEEK_MODEL,
      occurredAt,
      provider: "openrouter",
    }),
  });

  const results = await Promise.allSettled([paperclipPromise, foremanPromise]);
  for (const result of results) {
    if (result.status === "rejected") {
      process.stderr.write(`[ceo-metering] non-blocking metering error: ${result.reason?.message || result.reason}\n`);
    } else if (!result.value.ok) {
      const body = await result.value.text().catch(() => "");
      process.stderr.write(
        `[ceo-metering] non-blocking metering response ${result.value.status}: ${body.slice(0, 200)}\n`,
      );
    }
  }
}

async function callOpenRouter(env, systemPrompt, userPrompt) {
  const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${env.OPENROUTER_API_KEY}`,
      "HTTP-Referer": "https://foreman.us",
      "X-Title": "Foreman CEO Heartbeat",
    },
    body: JSON.stringify({
      model: env.DEEPSEEK_MODEL,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
      response_format: { type: "json_object" },
      max_tokens: 4096,
      temperature: 0.3,
    }),
  });

  const raw = await response.text();
  let parsed = null;
  try {
    parsed = JSON.parse(raw);
  } catch (error) {
    throw new Error(`OpenRouter returned non-JSON (${response.status}): ${raw.slice(0, 300)}`);
  }

  if (!response.ok) {
    const detail = parsed.error?.message || parsed.error || raw.slice(0, 300);
    throw new Error(`OpenRouter request failed (${response.status}): ${detail}`);
  }

  return parsed;
}

async function fetchIssuesContext(env) {
  let me = null;
  try {
    const meData = await paperclipRequest(env, "/api/agents/me");
    me = unwrapEntity(meData, ["agent", "data"]);
  } catch (error) {
    // Standalone tests sometimes use a board key that cannot hit /agents/me.
    if (!String(error.message).includes("(401)")) {
      throw error;
    }
    const agentData = await paperclipRequest(env, `/api/agents/${env.PAPERCLIP_AGENT_ID}`);
    me = unwrapEntity(agentData, ["agent", "data"]);
  }

  let issues = [];
  if (env.PAPERCLIP_TASK_ID) {
    const issueData = await paperclipRequest(env, `/api/issues/${env.PAPERCLIP_TASK_ID}`);
    const issue = unwrapEntity(issueData, ["issue", "data"]);
    const commentsData = await paperclipRequest(env, `/api/issues/${env.PAPERCLIP_TASK_ID}/comments`);
    const comments = normalizeIssuesResponse(commentsData);
    issues = [{ ...issue, comments }];
  } else {
    const query = new URLSearchParams({
      assigneeAgentId: env.PAPERCLIP_AGENT_ID,
      status: "todo,in_progress,blocked",
    });
    const issuesData = await paperclipRequest(env, `/api/companies/${env.PAPERCLIP_COMPANY_ID}/issues?${query.toString()}`);
    issues = normalizeIssuesResponse(issuesData);
  }

  const agentsData = await paperclipRequest(env, `/api/companies/${env.PAPERCLIP_COMPANY_ID}/agents`);
  const availableAgents = normalizeAgentsResponse(agentsData).map((agent) => ({
    id: agent.id || null,
    name: agent.name || null,
    role: agent.role || null,
    delegationRole: normalizeDelegationRole(agent),
    status: agent.status || null,
    adapterType: agent.adapterType || null,
    urlKey: agent.urlKey || null,
  }));
  const preferredWorkerIds = buildPreferredWorkerIds(availableAgents);

  const delegatedChildrenByParent = {};
  if (issues.length > 0) {
    const allIssuesData = await paperclipRequest(env, `/api/companies/${env.PAPERCLIP_COMPANY_ID}/issues`);
    const allIssues = normalizeIssuesResponse(allIssuesData);
    const parentIds = new Set(issues.map((issue) => issue.id).filter(Boolean));
    for (const child of allIssues) {
      if (!child?.parentId || !parentIds.has(child.parentId)) continue;
      if (!delegatedChildrenByParent[child.parentId]) delegatedChildrenByParent[child.parentId] = [];
      delegatedChildrenByParent[child.parentId].push({
        id: child.id || null,
        identifier: child.identifier || null,
        title: child.title || null,
        status: child.status || null,
        assigneeAgentId: child.assigneeAgentId || null,
      });
    }

    for (const parentId of Object.keys(delegatedChildrenByParent)) {
      for (const child of delegatedChildrenByParent[parentId]) {
        try {
          const commentsData = await paperclipRequest(env, `/api/issues/${child.id}/comments`);
          const comments = normalizeIssuesResponse(commentsData);
          child.comments = comments.slice(-2).map((comment) => ({
            id: comment.id || null,
            body: comment.body || comment.content || "",
            authorAgentId: comment.authorAgentId || null,
          }));
        } catch {
          child.comments = [];
        }
      }
    }
  }

  return { me, issues, availableAgents, preferredWorkerIds, delegatedChildrenByParent };
}

async function main() {
  const env = readEnv();
  const workspace = loadWorkspace();
  const { me, issues, availableAgents, preferredWorkerIds, delegatedChildrenByParent } = await fetchIssuesContext(env);

  const systemPrompt = buildSystemPrompt(workspace);
  const userPrompt = buildUserPrompt({
    runId: env.PAPERCLIP_RUN_ID,
    wakeReason: env.PAPERCLIP_WAKE_REASON,
    taskId: env.PAPERCLIP_TASK_ID || null,
    agent: me,
    issues,
    availableAgents,
    preferredWorkerIds,
    delegatedChildrenByParent,
  });

  const openRouterData = await callOpenRouter(env, systemPrompt, userPrompt);
  const content = openRouterData?.choices?.[0]?.message?.content;
  const plan = parsePlanContent(content);
  validatePlan(plan);

  const executionResults = await executePlan(plan, {
    apiUrl: env.PAPERCLIP_API_URL,
    apiKey: env.PAPERCLIP_API_KEY,
    companyId: env.PAPERCLIP_COMPANY_ID,
    agentId: env.PAPERCLIP_AGENT_ID,
    runId: env.PAPERCLIP_RUN_ID,
    taskId: env.PAPERCLIP_TASK_ID,
    foremanApiBase: env.FOREMAN_API_BASE,
    customerId: env.FOREMAN_CUSTOMER_ID,
    logger: (msg) => process.stderr.write(`[ceo-executor] ${msg}\n`),
  });

  const usage = openRouterData.usage || {};
  await reportUsage(env, usage);
  console.log(
    JSON.stringify({
      status: "completed",
      reasoning: plan.reasoning,
      actionsPlanned: plan.actions.length,
      actionsExecuted: executionResults.filter((result) => result.status === "ok").length,
      actionsFailed: executionResults.filter((result) => result.status === "error").length,
      results: executionResults,
      usage: {
        inputTokens: usage.prompt_tokens ?? 0,
        outputTokens: usage.completion_tokens ?? 0,
        model: env.DEEPSEEK_MODEL,
      },
    }),
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    process.stderr.write(`[ceo-heartbeat] ${error.message}\n`);
    process.exit(1);
  });
