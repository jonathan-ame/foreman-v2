import type { StepContext, StepResult } from "./types.js";

export async function step8ConfigReload(ctx: StepContext): Promise<StepResult> {
  try {
    await ctx.clients.openclaw.reloadSecrets();
  } catch (error) {
    ctx.logger.warn({ err: error }, "openclaw secrets reload failed; attempting gateway restart fallback");
    await ctx.clients.openclaw.restartGateway();
  }
  return {
    ok: true,
    data: {
      configReloaded: true
    }
  };
}

export async function rollbackStep8ConfigReload(ctx: StepContext): Promise<void> {
  ctx.logger.info(
    "rolling back step_8_config_reload: leave config and agent in place per spec"
  );
}
