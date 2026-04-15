import type { StepContext, StepResult } from "./types.js";

export async function step4OpenClawAdd(ctx: StepContext): Promise<StepResult> {
  const openclawAgentId = ctx.state.openclawAgentId as string | undefined;
  const workspacePath = ctx.state.workspacePath as string | undefined;

  if (!openclawAgentId || !workspacePath) {
    return {
      ok: false,
      errorCode: "OPENCLAW_INPUT_MISSING",
      errorMessage: "openclaw agent id or workspace path missing"
    };
  }

  const openclawAgent = await ctx.clients.openclaw.addAgent({
    id: openclawAgentId,
    workspace: workspacePath,
    identity: {
      name: ctx.input.agentName
    }
  });

  return {
    ok: true,
    data: {
      openclawAgent
    }
  };
}
