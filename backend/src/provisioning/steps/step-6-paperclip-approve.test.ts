import { describe, expect, it, vi } from "vitest";
import { step6PaperclipApprove } from "./step-6-paperclip-approve.js";
import { createLogger } from "../../config/logger.js";
import type { StepContext } from "./types.js";

describe("step6PaperclipApprove", () => {
  it("approves pending hire approval", async () => {
    const actOnApproval = vi.fn().mockResolvedValue(undefined);
    const listPendingApprovals = vi.fn().mockResolvedValue([
      { id: "ap1", type: "hire_agent", status: "pending" }
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
        paperclip: {
          listPendingApprovals,
          actOnApproval
        },
        openclaw: {} as never,
        stripe: {} as never
      },
      db: {} as never,
      logger: createLogger("step6-test"),
      state: {
        customer: { paperclip_company_id: "pc1" }
      }
    } as unknown as StepContext;

    const result = await step6PaperclipApprove(ctx);
    expect(result.ok).toBe(true);
    expect(actOnApproval).toHaveBeenCalledWith("ap1", "approve");
  });
});
