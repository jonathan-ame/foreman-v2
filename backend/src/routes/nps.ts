import type { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../app-deps.js";
import { recordNpsResponse } from "../db/nps.js";

const NpsResponseSchema = z.object({
  survey_id: z.string().uuid(),
  score: z.number().int().min(0).max(10),
  comment: z.string().max(2000).optional()
});

export function registerNpsRoutes(app: Hono, deps: AppDeps) {
  app.post("/api/internal/nps/response", async (c) => {
    const body = await c.req.json();
    const parsed = NpsResponseSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    // Verify the survey exists and hasn't been responded to
    const { data: survey, error: fetchError } = await deps.db
      .from("nps_responses")
      .select("id, responded_at")
      .eq("id", parsed.data.survey_id)
      .maybeSingle();

    if (fetchError) {
      deps.logger.error({ err: fetchError }, "nps: failed to fetch survey");
      return c.json({ error: "database_error" }, 500);
    }
    if (!survey) {
      return c.json({ error: "survey_not_found" }, 404);
    }
    if ((survey as { responded_at: string | null }).responded_at) {
      return c.json({ error: "already_responded" }, 409);
    }

    await recordNpsResponse(
      deps.db,
      parsed.data.survey_id,
      parsed.data.score,
      parsed.data.comment ?? null,
      new Date().toISOString()
    );

    deps.logger.info(
      { surveyId: parsed.data.survey_id, score: parsed.data.score },
      "nps response recorded"
    );

    return c.json({ ok: true }, 200);
  });
}
