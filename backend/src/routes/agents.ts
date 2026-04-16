import type { Hono } from "hono";
import { z } from "zod";
import { resolveSessionCustomerId } from "../auth/session.js";
import type { AppDeps } from "../app-deps.js";
import { getAgentByOpenclawAgentId } from "../db/agents.js";
import { insertNotification } from "../db/notifications.js";
import { provisionForemanAgent } from "../provisioning/orchestrator.js";
import type { ProvisionFailure, ProvisionSuccess } from "../provisioning/types.js";

const ProvisionInputSchema = z.object({
  customer_id: z.string().uuid().optional(),
  agent_name: z.string().min(1),
  role: z.enum(["ceo", "marketing_analyst"]),
  model_tier: z.enum(["open", "frontier", "hybrid"]).optional(),
  idempotency_key: z.string().uuid(),
  workspace_path: z.string().optional(),
  parent_openclaw_agent_id: z.string().min(1).optional()
});

const toInput = (
  payload: Omit<z.infer<typeof ProvisionInputSchema>, "customer_id" | "model_tier" | "parent_openclaw_agent_id"> & {
    customer_id: string;
    model_tier: "open" | "frontier" | "hybrid";
  }
) => ({
  customerId: payload.customer_id,
  agentName: payload.agent_name,
  role: payload.role,
  modelTier: payload.model_tier,
  idempotencyKey: payload.idempotency_key,
  ...(payload.workspace_path ? { workspacePath: payload.workspace_path } : {})
});

const formatSuccessResponse = (result: ProvisionSuccess) => ({
  outcome: result.outcome,
  agent_id: result.agentId,
  paperclip_agent_id: result.paperclipAgentId,
  openclaw_agent_id: result.openclawAgentId,
  provisioning_id: result.provisioningId,
  model_primary: result.modelPrimary,
  model_fallbacks: result.modelFallbacks,
  ready_at: result.readyAt
});

const formatFailureResponse = (result: ProvisionFailure) => ({
  outcome: result.outcome,
  provisioning_id: result.provisioningId,
  failed_step: result.failedStep,
  error_code: result.errorCode,
  error_message: result.errorMessage,
  customer_message: result.customerMessage,
  rollback_performed: result.rollbackPerformed,
  technical_details: result.technicalDetails
});

const isFailure = (result: ProvisionSuccess | ProvisionFailure): result is ProvisionFailure =>
  result.outcome === "blocked" || result.outcome === "failed";

export function registerAgentRoutes(app: Hono, deps: AppDeps) {
  app.post("/api/internal/agents/provision", async (c) => {
    const body = await c.req.json();
    const parsed = ProvisionInputSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }
    if (!parsed.data.idempotency_key) {
      return c.json({ error: "idempotency_key_required" }, 400);
    }

    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    let inheritedModelTier: "open" | "frontier" | "hybrid" | null = null;
    let notificationCustomerId: string | null = null;
    let notificationWorkspaceSlug: string | null = null;
    let shouldWriteHireNotification = false;

    if (parsed.data.parent_openclaw_agent_id) {
      const parentAgent = await getAgentByOpenclawAgentId(deps.db, parsed.data.parent_openclaw_agent_id);
      if (!parentAgent) {
        return c.json({ error: "parent_agent_not_found" }, 404);
      }
      if (parentAgent.role !== "ceo") {
        return c.json({ error: "parent_agent_must_be_ceo" }, 403);
      }

      notificationCustomerId = parentAgent.customer_id;
      notificationWorkspaceSlug = parentAgent.workspace_slug;
      inheritedModelTier = parentAgent.model_tier as "open" | "frontier" | "hybrid";
      shouldWriteHireNotification = parsed.data.role !== "ceo";

      if (parsed.data.customer_id && parsed.data.customer_id !== parentAgent.customer_id) {
        return c.json({ error: "customer_parent_mismatch" }, 400);
      }
    }

    const customerId = parsed.data.customer_id ?? sessionCustomerId ?? notificationCustomerId;
    if (!customerId) {
      return c.json({ error: "customer_id_required_or_login_required" }, 401);
    }
    const modelTier = parsed.data.model_tier ?? inheritedModelTier;
    if (!modelTier) {
      return c.json({ error: "model_tier_required" }, 400);
    }

    const result = await provisionForemanAgent(
      toInput({
        ...parsed.data,
        customer_id: customerId,
        model_tier: modelTier
      }),
      deps
    );
    if (isFailure(result)) {
      return c.json(formatFailureResponse(result), 422);
    }

    if (shouldWriteHireNotification) {
      if (!notificationWorkspaceSlug) {
        return c.json({ error: "workspace_slug_missing_for_notification" }, 500);
      }
      await insertNotification(deps.db, {
        workspace_slug: notificationWorkspaceSlug,
        type: "agent_hired",
        title: "New sub-agent hired",
        body: `Your CEO hired a ${parsed.data.agent_name} agent.`,
        reference_id: result.agentId,
        reference_type: "agent"
      });
    }

    return c.json(formatSuccessResponse(result), 200);
  });
}
