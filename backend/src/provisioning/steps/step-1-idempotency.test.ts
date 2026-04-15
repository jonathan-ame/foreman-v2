import { describe, expect, it, vi } from "vitest";
import { step1Idempotency } from "./step-1-idempotency.js";
import { createLogger } from "../../config/logger.js";
import type { StepContext } from "./types.js";

const getCachedResultMock = vi.hoisted(() => vi.fn());

vi.mock("../../db/idempotency.js", () => ({
  getCachedResult: getCachedResultMock
}));

describe("step1Idempotency", () => {
  it("returns cached result when present", async () => {
    getCachedResultMock.mockResolvedValue({
      outcome: "success",
      agentId: "a1",
      paperclipAgentId: "p1",
      openclawAgentId: "o1",
      provisioningId: "prov-1",
      modelPrimary: "model",
      modelFallbacks: [],
      readyAt: new Date().toISOString()
    });

    const ctx = {
      input: {
        customerId: "c1",
        agentName: "CEO",
        role: "ceo",
        modelTier: "open",
        idempotencyKey: "i1"
      },
      clients: {} as never,
      db: {} as never,
      logger: createLogger("step1-test"),
      state: {}
    } as unknown as StepContext;

    const result = await step1Idempotency(ctx);
    expect(result.ok).toBe(true);
    expect(result.data?.cachedResult).toBeTruthy();
  });
});
