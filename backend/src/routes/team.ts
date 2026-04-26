import type { Hono } from "hono";
import { resolveSessionCustomerId } from "../auth/session.js";
import type { AppDeps } from "../app-deps.js";

export function registerTeamRoutes(app: Hono, deps: AppDeps) {
  app.get("/api/internal/team", async (c) => {
    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    if (!sessionCustomerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const { data, error } = await deps.db
      .from("agents")
      .select("agent_id, display_name, role, model_tier, model_primary, current_status, provisioned_at, last_task_completed_at")
      .eq("customer_id", sessionCustomerId)
      .order("provisioned_at", { ascending: true });

    if (error) {
      deps.logger.error({ err: error, customerId: sessionCustomerId }, "failed to list team agents");
      return c.json({ error: "fetch_failed" }, 500);
    }

    return c.json({ agents: data ?? [] }, 200);
  });
}