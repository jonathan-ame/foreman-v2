import { describe, expect, it, vi } from "vitest";
import { step8ConfigReload } from "./step-8-config-reload.js";
import { createLogger } from "../../config/logger.js";
import type { StepContext } from "./types.js";

describe("step8ConfigReload", () => {
  it("reloads openclaw secrets", async () => {
    const reloadSecrets = vi.fn().mockResolvedValue(undefined);
    const restartGateway = vi.fn().mockResolvedValue(undefined);
    const ctx = {
      input: {
        customerId: "c1",
        agentName: "CEO",
        role: "ceo",
        modelTier: "open",
        idempotencyKey: "i1"
      },
      clients: {
        openclaw: { reloadSecrets, restartGateway },
        paperclip: {} as never,
        stripe: {} as never
      },
      db: {} as never,
      logger: createLogger("step8-test"),
      state: {}
    } as unknown as StepContext;

    const result = await step8ConfigReload(ctx);
    expect(result.ok).toBe(true);
    expect(reloadSecrets).toHaveBeenCalledTimes(1);
    expect(restartGateway).not.toHaveBeenCalled();
  });

  it("falls back to gateway restart when secrets reload fails", async () => {
    const reloadSecrets = vi.fn().mockRejectedValue(new Error("reload failed"));
    const restartGateway = vi.fn().mockResolvedValue(undefined);
    const ctx = {
      input: {
        customerId: "c1",
        agentName: "CEO",
        role: "ceo",
        modelTier: "open",
        idempotencyKey: "i1"
      },
      clients: {
        openclaw: { reloadSecrets, restartGateway },
        paperclip: {} as never,
        stripe: {} as never
      },
      db: {} as never,
      logger: createLogger("step8-test"),
      state: {}
    } as unknown as StepContext;

    const result = await step8ConfigReload(ctx);
    expect(result.ok).toBe(true);
    expect(reloadSecrets).toHaveBeenCalledTimes(1);
    expect(restartGateway).toHaveBeenCalledTimes(1);
  });
});
