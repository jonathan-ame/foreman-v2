import { describe, expect, it, vi } from "vitest";
import { step9Verify } from "./step-9-verify.js";
import { createLogger } from "../../config/logger.js";
import type { StepContext } from "./types.js";

describe("step9Verify", () => {
  it("passes when paperclip + openclaw records match (opencode_local)", async () => {
    const getAgent = vi.fn().mockResolvedValue({
      id: "pa1",
      name: "CEO",
      role: "ceo",
      adapterType: "opencode_local",
      adapterConfig: {
        timeoutSec: 1500
      },
      companyId: "pc1"
    });
    const listAgents = vi.fn().mockResolvedValue([
      { id: "ws-ceo", workspace: "/tmp/ws", defaultAgent: false }
    ]);

    const ctx = {
      input: {
        customerId: "c1",
        agentName: "CEO",
        role: "ceo",
        modelTier: "open",
        idempotencyKey: "i1"
      },
      clients: {
        paperclip: { getAgent },
        openclaw: { listAgents },
        stripe: {} as never
      },
      db: {} as never,
      logger: createLogger("step9-test"),
      state: {
        paperclipAgent: {
          id: "pa1",
          name: "CEO",
          role: "ceo",
          adapterType: "opencode_local",
          adapterConfig: { timeoutSec: 1500 },
          companyId: "pc1"
        },
        openclawAgentId: "ws-ceo"
      }
    } as unknown as StepContext;

    const result = await step9Verify(ctx);
    expect(result.ok).toBe(true);
  });

  it("passes when paperclip agent uses openclaw_gateway with valid token", async () => {
    const getAgent = vi.fn().mockResolvedValue({
      id: "pa1",
      name: "CEO",
      role: "ceo",
      adapterType: "openclaw_gateway",
      adapterConfig: {
        gatewayUrl: "ws://x",
        headers: { "x-openclaw-token": "tok" }
      },
      companyId: "pc1"
    });
    const listAgents = vi.fn().mockResolvedValue([
      { id: "ws-ceo", workspace: "/tmp/ws", defaultAgent: false }
    ]);

    const ctx = {
      input: {
        customerId: "c1",
        agentName: "CEO",
        role: "ceo",
        modelTier: "open",
        idempotencyKey: "i1"
      },
      clients: {
        paperclip: { getAgent },
        openclaw: { listAgents },
        stripe: {} as never
      },
      db: {} as never,
      logger: createLogger("step9-test"),
      state: {
        paperclipAgent: {
          id: "pa1",
          name: "CEO",
          role: "ceo",
          adapterType: "openclaw_gateway",
          adapterConfig: { gatewayUrl: "ws://x", headers: { "x-openclaw-token": "tok" } },
          companyId: "pc1"
        },
        openclawAgentId: "ws-ceo"
      }
    } as unknown as StepContext;

    const result = await step9Verify(ctx);
    expect(result.ok).toBe(true);
  });
});
