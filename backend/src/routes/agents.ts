import type { Hono } from "hono";
import { z } from "zod";
import { resolveSessionCustomerId } from "../auth/session.js";
import type { AppDeps } from "../app-deps.js";
import { provisionForemanAgent } from "../provisioning/orchestrator.js";
import type { ProvisionFailure, ProvisionSuccess } from "../provisioning/types.js";

const ProvisionInputSchema = z.object({
  customer_id: z.string().uuid().optional(),
  agent_name: z.string().min(1),
  role: z.literal("ceo"),
  model_tier: z.enum(["open", "frontier", "hybrid"]),
  idempotency_key: z.string().uuid(),
  workspace_path: z.string().optional()
});

const toInput = (
  payload: Omit<z.infer<typeof ProvisionInputSchema>, "customer_id"> & {
    customer_id: string;
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
    const customerId = parsed.data.customer_id ?? sessionCustomerId;
    if (!customerId) {
      return c.json({ error: "customer_id_required_or_login_required" }, 401);
    }

    const result = await provisionForemanAgent(
      toInput({
        ...parsed.data,
        customer_id: customerId
      }),
      deps
    );
    if (isFailure(result)) {
      return c.json(formatFailureResponse(result), 422);
    }
    return c.json(formatSuccessResponse(result), 200);
  });
}
