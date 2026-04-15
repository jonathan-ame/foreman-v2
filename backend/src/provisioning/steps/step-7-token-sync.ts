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
  const currentAdapterConfig = paperclipAgent.adapterConfig;
  const currentHeaders = currentAdapterConfig.headers ?? {};

  const patchedAgent = await ctx.clients.paperclip.patchAgent(paperclipAgent.id, {
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
