import type { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../app-deps.js";
import { getAgentByOpenclawAgentId } from "../db/agents.js";
import {
  escalateTaskToFrontier,
  getTaskEscalationState,
  recordTaskRejection
} from "../db/task-escalation.js";
import { resolveTierSpec } from "../provisioning/model-tiers.js";

const TaskBodySchema = z.object({
  openclawAgentId: z.string().min(1),
  workspaceSlug: z.string().min(1).optional(),
  taskType: z.string().min(1).optional()
});

const TaskModelQuerySchema = z.object({
  openclawAgentId: z.string().min(1).optional(),
  taskType: z.string().min(1).optional()
});

export function registerEscalationRoutes(app: Hono, deps: AppDeps) {
  app.post("/api/internal/tasks/:issueId/rejection", async (c) => {
    const { issueId } = c.req.param();
    const body = await c.req.json();
    const parsed = TaskBodySchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    const agent = await getAgentByOpenclawAgentId(deps.db, parsed.data.openclawAgentId);
    if (!agent) {
      return c.json({ error: "agent_not_found" }, 404);
    }

    const state = await recordTaskRejection(deps.db, {
      issueId,
      workspaceSlug: parsed.data.workspaceSlug ?? agent.workspace_slug,
      agentId: agent.agent_id,
      modelTier: agent.model_tier as "open" | "frontier" | "hybrid",
      ...(parsed.data.taskType ? { taskType: parsed.data.taskType } : {})
    });

    return c.json(
      {
        escalated: state.escalatedToFrontier,
        frontier_model: state.frontierModel ?? undefined,
        rejection_count: state.rejectionCount
      },
      200
    );
  });

  app.get("/api/internal/tasks/:issueId/model", async (c) => {
    const { issueId } = c.req.param();
    const parsed = TaskModelQuerySchema.safeParse(c.req.query());
    if (!parsed.success) {
      return c.json({ error: "invalid_query", details: parsed.error.flatten() }, 400);
    }

    const state = await getTaskEscalationState(deps.db, issueId);
    if (state?.escalated_to_frontier && state.frontier_model) {
      return c.json(
        {
          issue_id: issueId,
          escalated: true,
          model: state.frontier_model,
          rejection_count: state.rejection_count,
          frontier_model: state.frontier_model
        },
        200
      );
    }

    if (!parsed.data.openclawAgentId) {
      return c.json({ error: "openclawAgentId_required_for_non_escalated_model_lookup" }, 400);
    }
    const agent = await getAgentByOpenclawAgentId(deps.db, parsed.data.openclawAgentId);
    if (!agent) {
      return c.json({ error: "agent_not_found" }, 404);
    }

    const tier = agent.model_tier as "open" | "frontier" | "hybrid";
    const defaultModel = tier === "frontier" ? resolveTierSpec("frontier").primary : resolveTierSpec("open").primary;
    return c.json(
      {
        issue_id: issueId,
        escalated: false,
        model: defaultModel,
        rejection_count: state?.rejection_count ?? 0
      },
      200
    );
  });

  app.post("/api/internal/tasks/:issueId/escalate", async (c) => {
    const { issueId } = c.req.param();
    const body = await c.req.json();
    const parsed = TaskBodySchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    const agent = await getAgentByOpenclawAgentId(deps.db, parsed.data.openclawAgentId);
    if (!agent) {
      return c.json({ error: "agent_not_found" }, 404);
    }

    const state = await escalateTaskToFrontier(deps.db, {
      issueId,
      workspaceSlug: parsed.data.workspaceSlug ?? agent.workspace_slug,
      agentId: agent.agent_id,
      ...(parsed.data.taskType ? { taskType: parsed.data.taskType } : {})
    });

    return c.json(
      {
        escalated: true,
        frontier_model: state.frontierModel ?? undefined,
        rejection_count: state.rejectionCount
      },
      200
    );
  });
}
