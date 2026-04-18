import type { StepContext, StepResult } from "./types.js";
import { OpenClawAgentExistsError } from "../../clients/openclaw/errors.js";

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

  let openclawAgent;
  try {
    openclawAgent = await ctx.clients.openclaw.addAgent({
      id: openclawAgentId,
      workspace: workspacePath,
      identity: {
        name: ctx.input.agentName
      }
    });
  } catch (error) {
    if (!(error instanceof OpenClawAgentExistsError)) {
      throw error;
    }

    const existing = await ctx.clients.openclaw.getAgent(openclawAgentId);
    if (!existing) {
      throw error;
    }
    openclawAgent = existing;
  }

  return {
    ok: true,
    data: {
      openclawAgent
    }
  };
}

export async function rollbackStep4OpenClawAdd(ctx: StepContext): Promise<void> {
  const openclawAgentId = ctx.state.openclawAgentId as string | undefined;
  if (!openclawAgentId) {
    ctx.logger.info("rolling back step_4_openclaw_add: no agent id recorded");
    return;
  }
  ctx.logger.info({ openclawAgentId }, "rolling back step_4_openclaw_add: deleting openclaw agent");
  await ctx.clients.openclaw.deleteAgent(openclawAgentId);
}
