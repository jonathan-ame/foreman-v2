"use strict";

const { readFileSync } = require("node:fs");
const { resolve } = require("node:path");

const REQUIRED_ENV_VARS = [
  "PAPERCLIP_RUN_ID",
  "PAPERCLIP_AGENT_ID",
  "PAPERCLIP_COMPANY_ID",
  "PAPERCLIP_API_URL",
  "PAPERCLIP_API_KEY",
  "OPENROUTER_API_KEY",
];

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
  return [
    "Plan actions for this heartbeat context.",
    "Use only the allowed action types.",
    "Keep actions minimal and high impact.",
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

  return { me, issues };
}

async function main() {
  const env = readEnv();
  const workspace = loadWorkspace();
  const { me, issues } = await fetchIssuesContext(env);

  const systemPrompt = buildSystemPrompt(workspace);
  const userPrompt = buildUserPrompt({
    runId: env.PAPERCLIP_RUN_ID,
    wakeReason: env.PAPERCLIP_WAKE_REASON,
    taskId: env.PAPERCLIP_TASK_ID || null,
    agent: me,
    issues,
  });

  const openRouterData = await callOpenRouter(env, systemPrompt, userPrompt);
  const content = openRouterData?.choices?.[0]?.message?.content;
  const plan = parsePlanContent(content);
  validatePlan(plan);

  const usage = openRouterData.usage || {};
  console.log(
    JSON.stringify({
      status: "plan_ready",
      reasoning: plan.reasoning,
      actions: plan.actions,
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
