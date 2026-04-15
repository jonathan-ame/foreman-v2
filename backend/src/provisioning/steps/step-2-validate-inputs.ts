import { getAgentByWorkspaceAndName } from "../../db/agents.js";
import { getCustomerById } from "../../db/customers.js";
import { resolveRoleConfig } from "../role-config.js";
import { resolveTierSpec } from "../model-tiers.js";
import { workspaceSlugFromCustomer } from "../slug.js";
import type { StepContext, StepResult } from "./types.js";

export async function step2ValidateInputs(ctx: StepContext): Promise<StepResult> {
  const customer = (ctx.state.customer as Awaited<ReturnType<typeof getCustomerById>> | undefined) ??
    (await getCustomerById(ctx.db, ctx.input.customerId));

  if (!customer) {
    return {
      ok: false,
      errorCode: "CUSTOMER_NOT_FOUND",
      errorMessage: "Customer not found"
    };
  }

  const workspaceSlug = workspaceSlugFromCustomer(customer.customer_id, customer.workspace_slug);
  const existingAgent = await getAgentByWorkspaceAndName(ctx.db, workspaceSlug, ctx.input.agentName);
  if (existingAgent) {
    return {
      ok: false,
      errorCode: "AGENT_NAME_CONFLICT",
      errorMessage: "Agent name already exists in workspace"
    };
  }

  const tierSpec = resolveTierSpec(ctx.input.modelTier);
  const roleConfig = resolveRoleConfig(ctx.input.role);

  return {
    ok: true,
    data: {
      customer,
      workspaceSlug,
      tierSpec,
      roleConfig
    }
  };
}
