import { describe, expect, it, vi } from "vitest";
import { step5PaperclipHire } from "./step-5-paperclip-hire.js";
import { createLogger } from "../../config/logger.js";
import type { StepContext } from "./types.js";

describe("step5PaperclipHire", () => {
  it("calls hireAgent using paperclip company id", async () => {
    const hireAgent = vi.fn().mockResolvedValue({
      agent: {
        id: "pa1",
        name: "CEO",
        role: "ceo",
        adapterType: "openclaw_gateway",
        adapterConfig: { url: "ws://", gatewayUrl: "ws://", headers: { "x-openclaw-token": "pending-sync" } },
        companyId: "pc1"
      }
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
        paperclip: {
          hireAgent
        },
        openclaw: {} as never,
        stripe: {} as never
      },
      db: {} as never,
      logger: createLogger("step5-test"),
      state: {
        customer: {
          paperclip_company_id: "pc1"
        },
        roleConfig: {
          paperclipRole: "ceo",
          budgetMonthlyCents: 50000,
          capabilities: "capabilities"
        },
        openclawAgentId: "ws-ceo"
      }
    } as unknown as StepContext;

    const result = await step5PaperclipHire(ctx);
    expect(result.ok).toBe(true);
    expect(hireAgent).toHaveBeenCalledWith("pc1", expect.objectContaining({ name: "CEO" }));
  });

  it("fails if paperclip_company_id is missing", async () => {
    const ctx = {
      input: {
        customerId: "c1",
        agentName: "CEO",
        role: "ceo",
        modelTier: "open",
        idempotencyKey: "i1"
      },
      clients: {
        paperclip: {
          hireAgent: vi.fn()
        },
        openclaw: {} as never,
        stripe: {} as never
      },
      db: {} as never,
      logger: createLogger("step5-test"),
      state: {
        customer: {
          paperclip_company_id: null
        },
        roleConfig: {
          paperclipRole: "ceo",
          budgetMonthlyCents: 50000,
          capabilities: "capabilities"
        }
      }
    } as unknown as StepContext;

    const result = await step5PaperclipHire(ctx);
    expect(result.ok).toBe(false);
    expect(result.errorCode).toBe("PAPERCLIP_COMPANY_ID_MISSING");
  });
});
