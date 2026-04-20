import type { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../app-deps.js";
import { insertAgentUsageEvent } from "../db/agent-usage-events.js";
import { incrementAgentUsageByPaperclipAgentId } from "../db/agents.js";

const UsageUpdateSchema = z.object({
  inputTokens: z.number().int().min(0),
  outputTokens: z.number().int().min(0),
  costCents: z.number().int().min(0),
  model: z.string().min(1),
  occurredAt: z.string().datetime(),
  issueId: z.string().min(1).optional(),
  provider: z.string().min(1).optional()
});

export function registerUsageRoutes(app: Hono, deps: AppDeps) {
  app.post("/api/internal/agents/:agentId/usage", async (c) => {
    const { agentId } = c.req.param();
    const body = await c.req.json();
    const parsed = UsageUpdateSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    const found = await incrementAgentUsageByPaperclipAgentId(deps.db, agentId, {
      inputTokens: parsed.data.inputTokens,
      outputTokens: parsed.data.outputTokens,
      costCents: parsed.data.costCents
    });
    if (!found) {
      return c.json({ error: "agent_not_found" }, 404);
    }

    // Append-only event log for reconciliation (best-effort; never fails the request)
    void insertAgentUsageEvent(deps.db, {
      paperclip_agent_id: agentId,
      input_tokens: parsed.data.inputTokens,
      output_tokens: parsed.data.outputTokens,
      cost_cents: parsed.data.costCents,
      model: parsed.data.model,
      provider: parsed.data.provider ?? null,
      issue_id: parsed.data.issueId ?? null,
      occurred_at: parsed.data.occurredAt
    }).catch((err: unknown) => {
      deps.logger.warn(
        { err: err instanceof Error ? err.message : String(err), paperclipAgentId: agentId },
        "failed to append agent usage event"
      );
    });

    deps.logger.info(
      {
        paperclipAgentId: agentId,
        issueId: parsed.data.issueId,
        provider: parsed.data.provider,
        model: parsed.data.model,
        occurredAt: parsed.data.occurredAt,
        inputTokens: parsed.data.inputTokens,
        outputTokens: parsed.data.outputTokens,
        costCents: parsed.data.costCents
      },
      "recorded agent usage"
    );

    return c.json({ ok: true }, 200);
  });
}
