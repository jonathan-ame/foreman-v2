import type { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../app-deps.js";
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
