import { describe, expect, it, vi } from "vitest";
import { step7TokenSync } from "./step-7-token-sync.js";
import { createLogger } from "../../config/logger.js";
import type { StepContext } from "./types.js";

describe("step7TokenSync", () => {
  it("patches paperclip adapter token", async () => {
    const readGatewayToken = vi.fn().mockResolvedValue("token-123");
    const patchAgent = vi.fn().mockResolvedValue({
      id: "pa1",
      name: "CEO",
      role: "ceo",
      adapterType: "openclaw_gateway",
      adapterConfig: {
        gatewayUrl: "ws://x",
        headers: {
          "x-openclaw-token": "token-123"
        }
      },
      companyId: "pc1"
    });

    const ctx = {
      input: {
        customerId: "c1",
        agentName: "CEO",
        role: "ceo",
        modelTier: "open",
        idempotencyKey: "i1"
      },
      clients: {
        openclaw: { readGatewayToken },
        paperclip: { patchAgent },
        stripe: {} as never
      },
      db: {} as never,
      logger: createLogger("step7-test"),
      state: {
        paperclipAgent: {
          id: "pa1",
          name: "CEO",
          role: "ceo",
          adapterType: "openclaw_gateway",
          adapterConfig: { gatewayUrl: "ws://x", headers: {} },
          companyId: "pc1"
        }
      }
    } as unknown as StepContext;

    const result = await step7TokenSync(ctx);
    expect(result.ok).toBe(true);
    expect(patchAgent).toHaveBeenCalledWith(
      "pa1",
      expect.objectContaining({
        adapterConfig: expect.objectContaining({
          headers: expect.objectContaining({ "x-openclaw-token": "token-123" })
        })
      })
    );
  });
});
