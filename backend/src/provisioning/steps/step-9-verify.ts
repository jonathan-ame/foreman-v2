import type { PaperclipAgent } from "../../clients/paperclip/types.js";
import type { StepContext, StepResult } from "./types.js";

export async function step9Verify(ctx: StepContext): Promise<StepResult> {
  const paperclipAgent = ctx.state.paperclipAgent as PaperclipAgent | undefined;
  const openclawAgentId = ctx.state.openclawAgentId as string | undefined;

  if (!paperclipAgent || !openclawAgentId) {
    return {
      ok: false,
      errorCode: "VERIFY_INPUT_MISSING",
      errorMessage: "verification inputs missing"
    };
  }

  const freshPaperclipAgent = await ctx.clients.paperclip.getAgent(paperclipAgent.id);
  const openclawAgents = await ctx.clients.openclaw.listAgents();
  const openclawMatch = openclawAgents.find((item) => item.id === openclawAgentId);

  const token = freshPaperclipAgent.adapterConfig.headers["x-openclaw-token"];
  if (!token) {
    return {
      ok: false,
      errorCode: "VERIFY_TOKEN_MISSING",
      errorMessage: "Paperclip agent is missing gateway token in adapter config"
    };
  }

  if (!openclawMatch) {
    return {
      ok: false,
      errorCode: "VERIFY_OPENCLAW_AGENT_MISSING",
      errorMessage: "OpenClaw list does not include provisioned agent"
    };
  }

  return {
    ok: true,
    data: {
      verifiedPaperclipAgent: freshPaperclipAgent,
      verifiedOpenclawAgent: openclawMatch
    }
  };
}
