import type { PaperclipAgent } from "../../clients/paperclip/types.js";
import type { StepContext, StepResult } from "./types.js";

export async function step7TokenSync(ctx: StepContext): Promise<StepResult> {
  const paperclipAgent = ctx.state.paperclipAgent as PaperclipAgent | undefined;
  if (!paperclipAgent) {
    return {
      ok: false,
      errorCode: "PAPERCLIP_AGENT_MISSING",
      errorMessage: "paperclip agent missing in state"
    };
  }

  const token = await ctx.clients.openclaw.readGatewayToken();
  // PATCH on Paperclip replaces adapterConfig, so start from the latest full shape.
  const latestAgent = await ctx.clients.paperclip.getAgent(paperclipAgent.id);
  const currentAdapterConfig = latestAgent.adapterConfig;
  const currentHeaders = currentAdapterConfig.headers ?? {};

  const patchedAgent = await ctx.clients.paperclip.patchAgent(latestAgent.id, {
    adapterConfig: {
      ...currentAdapterConfig,
      headers: {
        ...currentHeaders,
        "x-openclaw-token": token
      }
    }
  });

  return {
    ok: true,
    data: {
      paperclipAgent: patchedAgent,
      gatewayTokenSynced: true
    }
  };
}

export async function rollbackStep7TokenSync(ctx: StepContext): Promise<void> {
  ctx.logger.info(
    "rolling back step_7_token_sync: leave in place per spec (manual token sync may be required)"
  );
}
