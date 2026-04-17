import { randomUUID } from "node:crypto";
import path from "node:path";
import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

const DEFAULT_API_BASE_URL = "http://127.0.0.1:8080";
const DEFAULT_TIMEOUT_MS = 30_000;
const WORKSPACE_PREFIX = "workspace-";
const TASK_TYPES = ["code_generation", "code_review", "reasoning", "research", "writing"] as const;

const resolveApiBaseUrl = (pluginConfig: Record<string, unknown>): string => {
  const candidate = pluginConfig.apiBaseUrl;
  if (typeof candidate === "string" && candidate.trim().length > 0) {
    return candidate.replace(/\/+$/, "");
  }
  return DEFAULT_API_BASE_URL;
};

const resolveRequestTimeoutMs = (pluginConfig: Record<string, unknown>): number => {
  const candidate = pluginConfig.requestTimeoutMs;
  if (typeof candidate === "number" && Number.isFinite(candidate) && candidate > 0) {
    return candidate;
  }
  return DEFAULT_TIMEOUT_MS;
};

const parentOpenclawAgentIdFromAgentDir = (agentDir: string | undefined): string | null => {
  if (!agentDir) {
    return null;
  }
  const basename = path.basename(agentDir);
  if (!basename.startsWith(WORKSPACE_PREFIX)) {
    return null;
  }
  const value = basename.slice(WORKSPACE_PREFIX.length);
  return value.length > 0 ? value : null;
};

const textResult = (text: string) => ({
  content: [{ type: "text" as const, text }]
});

export default definePluginEntry({
  id: "foreman-hire-agent",
  name: "Foreman Hire Agent",
  description: "Expose hire_agent tool that provisions Foreman sub-agents via backend API.",
  register(api) {
    api.registerTool(
      (ctx) => ({
        description: "Hire a sub-agent for the current customer workspace.",
        parameters: {
          type: "object",
          additionalProperties: false,
          required: ["role"],
          properties: {
            role: {
              type: "string",
              enum: ["marketing_analyst"]
            },
            display_name: {
              type: "string",
              minLength: 1
            },
            model_tier: {
              type: "string",
              enum: ["open", "frontier", "hybrid"]
            }
          }
        },
        async execute(_toolCallId, params) {
          const safeParams =
            params && typeof params === "object"
              ? (params as {
                  role?: string;
                  display_name?: string;
                  model_tier?: string;
                })
              : {};
          if (safeParams.role !== "marketing_analyst") {
            return textResult("Unable to hire agent: role is required and must be marketing_analyst.");
          }

          const apiBaseUrl = resolveApiBaseUrl(api.pluginConfig);
          const requestTimeoutMs = resolveRequestTimeoutMs(api.pluginConfig);
          const controller = new AbortController();
          const timeout = setTimeout(() => controller.abort(), requestTimeoutMs);
          const roleLabel = "marketing analyst";
          const parentOpenclawAgentId = parentOpenclawAgentIdFromAgentDir(ctx.agentDir);

          try {
            const response = await fetch(`${apiBaseUrl}/api/internal/agents/provision`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json"
              },
              body: JSON.stringify({
                role: safeParams.role,
                agent_name: safeParams.display_name?.trim() || roleLabel,
                model_tier: safeParams.model_tier,
                idempotency_key: randomUUID(),
                parent_openclaw_agent_id: parentOpenclawAgentId
              }),
              signal: controller.signal
            });

            const payload = await response.json().catch(() => ({}));

            if (response.ok) {
              const agentId = typeof payload.agent_id === "string" ? payload.agent_id : "unknown";
              return textResult(`Hired ${roleLabel} successfully. New agent id: ${agentId}.`);
            }

            if (response.status === 422) {
              const code = typeof payload.error_code === "string" ? payload.error_code : "PROVISIONING_BLOCKED";
              const message =
                typeof payload.customer_message === "string"
                  ? payload.customer_message
                  : "Hiring was blocked. Check billing status and retry.";
              return textResult(`Unable to hire ${roleLabel} (${code}). ${message}`);
            }

            const backendError =
              typeof payload.error === "string" ? payload.error : `HTTP ${response.status} while hiring sub-agent`;
            return textResult(`Unable to hire ${roleLabel}. ${backendError}.`);
          } catch (error) {
            if (error instanceof Error && error.name === "AbortError") {
              return textResult("Unable to hire agent right now: request timed out. Try again in a moment.");
            }
            return textResult("Unable to hire agent because the Foreman backend could not be reached.");
          } finally {
            clearTimeout(timeout);
          }
        }
      }),
      { name: "hire_agent" }
    );

    api.registerTool(
      (ctx) => ({
        description: "Escalate a task to frontier model routing immediately.",
        parameters: {
          type: "object",
          additionalProperties: false,
          required: ["issue_id"],
          properties: {
            issue_id: {
              type: "string",
              minLength: 1
            },
            task_type: {
              type: "string",
              enum: [...TASK_TYPES]
            }
          }
        },
        async execute(_toolCallId, params) {
          const safeParams =
            params && typeof params === "object"
              ? (params as {
                  issue_id?: string;
                  task_type?: (typeof TASK_TYPES)[number];
                })
              : {};
          const issueId = safeParams.issue_id?.trim();
          if (!issueId) {
            return textResult("Unable to escalate task: issue_id is required.");
          }
          if (!ctx.agentId) {
            return textResult("Unable to escalate task: current OpenClaw agent id is unavailable.");
          }

          const apiBaseUrl = resolveApiBaseUrl(api.pluginConfig);
          const requestTimeoutMs = resolveRequestTimeoutMs(api.pluginConfig);
          const controller = new AbortController();
          const timeout = setTimeout(() => controller.abort(), requestTimeoutMs);

          try {
            const response = await fetch(`${apiBaseUrl}/api/internal/tasks/${encodeURIComponent(issueId)}/escalate`, {
              method: "POST",
              headers: {
                "Content-Type": "application/json"
              },
              body: JSON.stringify({
                openclawAgentId: ctx.agentId,
                taskType: safeParams.task_type
              }),
              signal: controller.signal
            });
            const payload = await response.json().catch(() => ({}));
            if (!response.ok) {
              const backendError =
                typeof payload.error === "string" ? payload.error : `HTTP ${response.status} while escalating task`;
              return textResult(`Unable to escalate task ${issueId}. ${backendError}.`);
            }

            const model =
              typeof payload.frontier_model === "string" && payload.frontier_model.length > 0
                ? payload.frontier_model
                : "frontier model";
            const rejectionCount = typeof payload.rejection_count === "number" ? payload.rejection_count : 0;
            return textResult(
              `Escalated task ${issueId} to ${model}. Escalation is now sticky for this task (rejections: ${rejectionCount}).`
            );
          } catch (error) {
            if (error instanceof Error && error.name === "AbortError") {
              return textResult("Unable to escalate task right now: request timed out. Try again in a moment.");
            }
            return textResult("Unable to escalate task because the Foreman backend could not be reached.");
          } finally {
            clearTimeout(timeout);
          }
        }
      }),
      { name: "escalate_to_frontier" }
    );
  }
});
