import { describe, expect, it, vi } from "vitest";
import { step5PaperclipHire } from "./step-5-paperclip-hire.js";
import { createLogger } from "../../config/logger.js";
import type { StepContext } from "./types.js";

describe("step5PaperclipHire", () => {
  it("calls hireAgent using paperclip company id", async () => {
    const patchAgent = vi.fn().mockResolvedValue({
      id: "pa1",
      name: "CEO",
      role: "ceo",
      adapterType: "opencode_local",
      adapterConfig: {
        timeoutSec: 1500
      },
      runtimeConfig: {
        heartbeat: { enabled: true, mode: "proactive", intervalSec: 1800 }
      },
      companyId: "pc1"
    });
    const hireAgent = vi.fn().mockResolvedValue({
      agent: {
        id: "pa1",
        name: "CEO",
        role: "ceo",
        adapterType: "opencode_local",
        adapterConfig: { timeoutSec: 1500 },
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
          hireAgent,
          patchAgent
        },
        openclaw: {
          setMcpServer: vi.fn().mockResolvedValue(undefined)
        } as never,
        stripe: {} as never,
        composio: {
          isConfigured: false,
          createSession: vi.fn().mockResolvedValue({
            id: "cs1",
            userId: "foreman_c1",
            mcp: { url: "https://mcp.composio.dev/cs1", headers: {} },
            toolkits: [],
            createdAt: "2026-04-22T00:00:00Z"
          }),
          ping: vi.fn().mockResolvedValue({ ok: true })
        }
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
    expect(hireAgent).toHaveBeenCalledWith("pc1", expect.objectContaining({ name: "CEO", adapterType: "opencode_local" }));
    expect(patchAgent).toHaveBeenCalledWith(
      "pa1",
      expect.objectContaining({
        runtimeConfig: expect.objectContaining({
          heartbeat: expect.objectContaining({ mode: "proactive" })
        })
      })
    );
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
          hireAgent: vi.fn(),
          patchAgent: vi.fn()
        },
        openclaw: {} as never,
        stripe: {} as never,
        composio: {
          isConfigured: false,
          createSession: vi.fn(),
          ping: vi.fn()
        }
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
