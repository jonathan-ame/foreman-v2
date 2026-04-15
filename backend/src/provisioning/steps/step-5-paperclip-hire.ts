import { env } from "../../config/env.js";
import type { Customer } from "../../db/customers.js";
import type { StepContext, StepResult } from "./types.js";

export async function step5PaperclipHire(ctx: StepContext): Promise<StepResult> {
  const customer = ctx.state.customer as Customer | undefined;
  const roleConfig = ctx.state.roleConfig as { paperclipRole: string; budgetMonthlyCents: number; capabilities: string } | undefined;

  if (!customer || !roleConfig) {
    return {
      ok: false,
      errorCode: "PAPERCLIP_INPUT_MISSING",
      errorMessage: "customer or role configuration missing"
    };
  }

  if (!customer.paperclip_company_id) {
    return {
      ok: false,
      errorCode: "PAPERCLIP_COMPANY_ID_MISSING",
      errorMessage: "customer.paperclip_company_id is required for hire flow"
    };
  }

  const openclawAgentId = ctx.state.openclawAgentId as string | undefined;
  if (!openclawAgentId) {
    return {
      ok: false,
      errorCode: "OPENCLAW_AGENT_ID_MISSING",
      errorMessage: "openclaw agent id missing"
    };
  }

  const hireResponse = await ctx.clients.paperclip.hireAgent(customer.paperclip_company_id, {
    name: ctx.input.agentName,
    role: roleConfig.paperclipRole,
    reportsTo: "board",
    capabilities: [roleConfig.capabilities],
    budgetMonthlyCents: roleConfig.budgetMonthlyCents,
    adapterType: "openclaw_gateway",
    adapterConfig: {
      gatewayUrl: env.OPENCLAW_GATEWAY_URL,
      headers: {
        "x-openclaw-token": "pending-sync"
      }
    }
  });

  return {
    ok: true,
    data: {
      paperclipAgent: hireResponse.agent,
      pendingApproval: hireResponse.approval ?? null
    }
  };
}

export async function rollbackStep5PaperclipHire(ctx: StepContext): Promise<void> {
  const paperclipAgent = ctx.state.paperclipAgent as { id: string } | undefined;
  if (!paperclipAgent?.id) {
    ctx.logger.info("rolling back step_5_paperclip_hire: no paperclip agent id recorded");
    return;
  }
  ctx.logger.info(
    { paperclipAgentId: paperclipAgent.id },
    "rolling back step_5_paperclip_hire: deleting paperclip agent"
  );
  await ctx.clients.paperclip.deleteAgent(paperclipAgent.id);
}
