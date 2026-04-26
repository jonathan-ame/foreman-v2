import { describe, expect, it, vi } from "vitest";
import { step7TokenSync } from "./step-7-token-sync.js";
import { createLogger } from "../../config/logger.js";
import type { StepContext } from "./types.js";

describe("step7TokenSync", () => {
  it("patches paperclip adapter token for openclaw_gateway", async () => {
    const readGatewayToken = vi.fn().mockResolvedValue("token-123");
    const getAgent = vi.fn().mockResolvedValue({
      id: "pa1",
      name: "CEO",
      role: "ceo",
      adapterType: "openclaw_gateway",
      adapterConfig: {
        url: "ws://x",
        gatewayUrl: "ws://x",
        headers: {
          existing: "value"
        }
      },
      companyId: "pc1"
    });
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
        paperclip: { getAgent, patchAgent },
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
    expect(getAgent).toHaveBeenCalledTimes(2);
    expect(getAgent).toHaveBeenCalledWith("pa1");
    expect(patchAgent).toHaveBeenCalledWith(
      "pa1",
      expect.objectContaining({
        adapterConfig: expect.objectContaining({
          gatewayUrl: "ws://x",
          headers: expect.objectContaining({ "x-openclaw-token": "token-123" })
        })
      })
    );
  });

  it("skips gateway token sync for opencode_local adapter", async () => {
    const getAgent = vi.fn();
    const readGatewayToken = vi.fn();

    const ctx = {
      input: {
        customerId: "c1",
        agentName: "Worker",
        role: "engineer",
        modelTier: "open",
        idempotencyKey: "i1"
      },
      clients: {
        openclaw: { readGatewayToken },
        paperclip: { getAgent },
        stripe: {} as never,
        composio: {} as never
      },
      db: {} as never,
      logger: createLogger("step7-test"),
      state: {
        paperclipAgent: {
          id: "pa2",
          name: "Engineer",
          role: "engineer",
          adapterType: "opencode_local",
          adapterConfig: { timeoutSec: 300, graceSec: 30 },
          companyId: "pc1"
        }
      }
    } as unknown as StepContext;

    const result = await step7TokenSync(ctx);
    expect(result.ok).toBe(true);
    if (!result.ok) throw new Error("expected ok");
    expect(result.data.gatewayTokenSynced).toBe(false);
    expect(readGatewayToken).not.toHaveBeenCalled();
    expect(getAgent).not.toHaveBeenCalled();
  });
});
