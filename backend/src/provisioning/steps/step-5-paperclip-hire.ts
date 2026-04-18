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

  const isWorkerRole = ctx.input.role !== "ceo";
  const adapterTimeoutSec = isWorkerRole ? 300 : 1500;
  const heartbeatConfig = isWorkerRole
    ? { enabled: true, mode: "reactive" as const }
    : { enabled: true, mode: "proactive" as const, intervalSec: 1800 };
  const workerProcessConfig = isWorkerRole
    ? {
        command: "/Users/jonathanborgia/foreman-git/foreman-v2/scripts/paperclip-openclaw-executor.sh",
        cwd: "/Users/jonathanborgia/foreman-git/foreman-v2",
        timeoutSec: adapterTimeoutSec
      }
    : null;
  const openclawGatewayConfig = {
    url: env.OPENCLAW_GATEWAY_URL,
    gatewayUrl: env.OPENCLAW_GATEWAY_URL,
    timeoutSec: adapterTimeoutSec,
    headers: {
      "x-openclaw-token": "pending-sync"
    }
  };

  const hireResponse = await ctx.clients.paperclip.hireAgent(customer.paperclip_company_id, {
    name: ctx.input.agentName,
    role: roleConfig.paperclipRole,
    capabilities: roleConfig.capabilities,
    budgetMonthlyCents: roleConfig.budgetMonthlyCents,
    adapterType: isWorkerRole ? "process" : "openclaw_gateway",
    adapterConfig: isWorkerRole ? workerProcessConfig! : openclawGatewayConfig,
    runtimeConfig: {
      heartbeat: heartbeatConfig
    }
  });

  const patchedAgent = await ctx.clients.paperclip.patchAgent(hireResponse.agent.id, {
    ...(isWorkerRole ? { adapterType: "process" } : {}),
    adapterConfig: {
      ...hireResponse.agent.adapterConfig,
      ...(isWorkerRole ? workerProcessConfig! : openclawGatewayConfig),
      timeoutSec: adapterTimeoutSec
    },
    runtimeConfig: {
      heartbeat: heartbeatConfig
    }
  });

  return {
    ok: true,
    data: {
      paperclipAgent: patchedAgent,
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
