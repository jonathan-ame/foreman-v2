import type { PaperclipAgent } from "../../clients/paperclip/types.js";
import { safePatchAgent } from "../../clients/paperclip/safe-patch.js";
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

  if (paperclipAgent.adapterType === "opencode_local") {
    ctx.logger.info(
      { paperclipAgentId: paperclipAgent.id, adapterType: paperclipAgent.adapterType },
      "skipping gateway token sync for opencode_local adapter"
    );
    return {
      ok: true,
      data: {
        paperclipAgent,
        gatewayTokenSynced: false
      }
    };
  }

  const token = await ctx.clients.openclaw.readGatewayToken();
  await safePatchAgent(ctx.clients.paperclip, paperclipAgent.companyId, paperclipAgent.id, {
    adapterConfig: {
      headers: {
        "x-openclaw-token": token
      }
    }
  }, ctx.logger);

  const patchedAgent = await ctx.clients.paperclip.getAgent(paperclipAgent.id);

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
