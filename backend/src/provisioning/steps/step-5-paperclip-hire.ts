import type { Customer } from "../../db/customers.js";
import type { OpenCodeLocalAdapterConfig } from "../../clients/paperclip/types.js";
import type { StepContext, StepResult } from "./types.js";

export async function step5PaperclipHire(ctx: StepContext): Promise<StepResult> {
  const customer = ctx.state.customer as Customer | undefined;
  const roleConfig = ctx.state.roleConfig as { paperclipRole: string; budgetMonthlyCents: number; capabilities: string; composioToolkits?: string[] } | undefined;

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

  let composioMcpUrl: string | undefined;
  let composioMcpHeaders: Record<string, string> | undefined;
  if (ctx.clients.composio.isConfigured) {
    try {
      const composioUserId = `foreman_${customer.customer_id}`;
      const composioSession = await ctx.clients.composio.createSession(composioUserId, {
        toolkits: roleConfig.composioToolkits ?? []
      });
      composioMcpUrl = composioSession.mcp.url;
      composioMcpHeaders = composioSession.mcp.headers;
      ctx.logger.info(
        { composioUserId, sessionId: composioSession.id, mcpUrl: composioMcpUrl },
        "composio session created for agent provisioning"
      );
    } catch (err) {
      ctx.logger.warn({ err, customerId: customer.customer_id }, "composio session creation failed — proceeding without external tool access");
    }
  }

  const adapterTimeoutSec = ctx.input.role === "ceo" ? 1500 : 300;
  const isWorkerRole = ctx.input.role !== "ceo";
  const heartbeatConfig = isWorkerRole
    ? { enabled: true, mode: "reactive" as const }
    : { enabled: true, mode: "proactive" as const, intervalSec: 1800 };

  const opencodeLocalConfig: OpenCodeLocalAdapterConfig = {
    timeoutSec: adapterTimeoutSec,
    ...(isWorkerRole ? { graceSec: 30 } : {}),
    env: {
      ...(composioMcpUrl ? { COMPOSIO_MCP_URL: composioMcpUrl } : {}),
      ...(composioMcpHeaders ? { COMPOSIO_MCP_HEADERS: JSON.stringify(composioMcpHeaders) } : {}),
    }
  };

  const hireResponse = await ctx.clients.paperclip.hireAgent(customer.paperclip_company_id, {
    name: ctx.input.agentName,
    role: roleConfig.paperclipRole,
    capabilities: roleConfig.capabilities,
    budgetMonthlyCents: roleConfig.budgetMonthlyCents,
    adapterType: "opencode_local",
    adapterConfig: opencodeLocalConfig,
    runtimeConfig: {
      heartbeat: heartbeatConfig
    }
  });

  const patchedAgent = await ctx.clients.paperclip.patchAgent(hireResponse.agent.id, {
    adapterConfig: {
      ...hireResponse.agent.adapterConfig,
      ...opencodeLocalConfig,
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
      pendingApproval: hireResponse.approval ?? null,
      composioMcpUrl: composioMcpUrl ?? null
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
