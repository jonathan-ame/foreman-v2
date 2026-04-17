import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";
import { calculateCostUsd, resolveModelCostRates } from "./pricing.js";

type UsageTotals = {
  input?: number;
  output?: number;
  cacheRead?: number;
  cacheWrite?: number;
  total?: number;
};
const DEFAULT_PAPERCLIP_API_BASE = "http://localhost:3125";
const DEFAULT_FOREMAN_API_BASE = "http://localhost:8080";
const DEFAULT_TIMEOUT_MS = 5_000;

const toRecord = (value: unknown): Record<string, unknown> =>
  value && typeof value === "object" ? (value as Record<string, unknown>) : {};

const normalizeBaseUrl = (value: unknown, fallback: string): string => {
  if (typeof value !== "string") {
    return fallback;
  }
  const trimmed = value.trim();
  if (!trimmed) {
    return fallback;
  }
  return trimmed.replace(/\/+$/, "");
};

const numberOrZero = (value: unknown): number =>
  typeof value === "number" && Number.isFinite(value) ? value : 0;

const nonEmptyString = (value: unknown): string | null => {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
};

const postJson = async (url: string, headers: Record<string, string>, payload: unknown): Promise<void> => {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), DEFAULT_TIMEOUT_MS);
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...headers
      },
      body: JSON.stringify(payload),
      signal: controller.signal
    });
    if (!response.ok) {
      const body = await response.text().catch(() => "");
      throw new Error(`HTTP ${response.status}${body ? `: ${body.slice(0, 300)}` : ""}`);
    }
  } finally {
    clearTimeout(timeout);
  }
};

export default definePluginEntry({
  id: "foreman-token-meter",
  name: "Foreman Token Meter",
  description: "Bridge OpenClaw usage to Paperclip cost-events.",
  register(api) {
    api.on("llm_output", (event, ctx) => {
      try {
        const pluginConfig = toRecord(api.pluginConfig);
        const enabled = pluginConfig.enabled !== false;
        if (!enabled) {
          return;
        }

        const usage = toRecord(event.usage) as UsageTotals;
        const inputTokens = Math.max(0, Math.round(numberOrZero(usage.input)));
        const outputTokens = Math.max(0, Math.round(numberOrZero(usage.output)));
        if (inputTokens === 0 && outputTokens === 0) {
          return;
        }

        const paperclipApiBase = normalizeBaseUrl(pluginConfig.paperclipApiBase, DEFAULT_PAPERCLIP_API_BASE);
        const foremanApiBase = normalizeBaseUrl(pluginConfig.foremanApiBase, DEFAULT_FOREMAN_API_BASE);
        const paperclipCompanyId = nonEmptyString(pluginConfig.paperclipCompanyId);
        const paperclipApiKey =
          nonEmptyString(process.env.PAPERCLIP_API_KEY) ?? nonEmptyString(pluginConfig.paperclipApiKey);
        const currentAgentId = nonEmptyString(ctx.agentId) ?? nonEmptyString(process.env.PAPERCLIP_AGENT_ID);
        const currentIssueId =
          nonEmptyString(process.env.PAPERCLIP_ISSUE_ID) ?? nonEmptyString(process.env.PAPERCLIP_TASK_ID);

        if (!paperclipCompanyId || !paperclipApiKey || !currentAgentId) {
          api.logger.warn("foreman-token-meter skipped usage event due to missing required config/context", {
            missingCompanyId: !paperclipCompanyId,
            missingApiKey: !paperclipApiKey,
            missingAgentId: !currentAgentId
          });
          return;
        }

        const providerLabel =
          typeof event.provider === "string" ? event.provider : String(event.provider ?? "");
        const modelLabel = typeof event.model === "string" ? event.model : String(event.model ?? "");

        const rates = resolveModelCostRates(api.config, event.provider, event.model);
        const costUsd = calculateCostUsd(usage, rates);
        const costCents = Math.max(0, Math.round(costUsd * 100));
        const occurredAt = new Date().toISOString();

        const paperclipPayload: Record<string, unknown> = {
          agentId: currentAgentId,
          provider: providerLabel,
          model: modelLabel,
          inputTokens,
          outputTokens,
          costCents,
          occurredAt
        };
        if (currentIssueId) {
          paperclipPayload.issueId = currentIssueId;
        }

        const usagePayload = {
          inputTokens,
          outputTokens,
          costCents,
          provider: providerLabel,
          model: modelLabel,
          issueId: currentIssueId ?? undefined,
          occurredAt
        };

        // Fire-and-forget reporting so metering never blocks model execution.
        void Promise.allSettled([
          postJson(
            `${paperclipApiBase}/api/companies/${paperclipCompanyId}/cost-events`,
            { Authorization: `Bearer ${paperclipApiKey}` },
            paperclipPayload
          ),
          postJson(`${foremanApiBase}/api/internal/agents/${currentAgentId}/usage`, {}, usagePayload)
        ]).then((results) => {
          const rejected = results.filter((result) => result.status === "rejected");
          if (rejected.length > 0) {
            for (const result of rejected) {
              api.logger.warn("foreman-token-meter reporting failed", {
                error: result.reason instanceof Error ? result.reason.message : String(result.reason)
              });
            }
            return;
          }
          api.logger.info("foreman-token-meter reported usage successfully", {
            runId: event.runId,
            sessionId: event.sessionId,
            provider: providerLabel,
            model: modelLabel,
            inputTokens,
            outputTokens,
            costCents
          });
        });
      } catch (err) {
        api.logger.warn("foreman-token-meter llm_output handler failed", {
          err: err instanceof Error ? err.message : String(err)
        });
      }
    });
  }
});
