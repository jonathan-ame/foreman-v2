import type { StepContext, StepResult } from "./types.js";

export async function step8ConfigReload(ctx: StepContext): Promise<StepResult> {
  await ctx.clients.openclaw.reloadSecrets();
  return {
    ok: true,
    data: {
      configReloaded: true
    }
  };
}
