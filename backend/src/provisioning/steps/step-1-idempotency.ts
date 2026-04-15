import { getCachedResult } from "../../db/idempotency.js";
import type { StepContext, StepResult } from "./types.js";

export async function step1Idempotency(ctx: StepContext): Promise<StepResult> {
  const cachedResult = await getCachedResult(ctx.db, ctx.input.idempotencyKey, ctx.input.customerId);
  if (cachedResult) {
    return {
      ok: true,
      data: {
        cachedResult
      }
    };
  }
  return { ok: true };
}
