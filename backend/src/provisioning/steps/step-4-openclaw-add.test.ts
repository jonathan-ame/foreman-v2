import { describe, expect, it, vi } from "vitest";
import { step4OpenClawAdd } from "./step-4-openclaw-add.js";
import { createLogger } from "../../config/logger.js";
import type { StepContext } from "./types.js";

describe("step4OpenClawAdd", () => {
  it("calls openclaw add with expected spec", async () => {
    const addAgent = vi.fn().mockResolvedValue({ id: "ws-ceo", workspace: "/tmp/ws", defaultAgent: false });
    const ctx = {
      input: {
        customerId: "c1",
        agentName: "CEO",
        role: "ceo",
        modelTier: "open",
        idempotencyKey: "i1"
      },
      clients: {
        openclaw: {
          addAgent
        },
        paperclip: {} as never,
        stripe: {} as never
      },
      db: {} as never,
      logger: createLogger("step4-test"),
      state: {
        openclawAgentId: "ws-ceo",
        workspacePath: "/tmp/ws"
      }
    } as unknown as StepContext;

    const result = await step4OpenClawAdd(ctx);
    expect(result.ok).toBe(true);
    expect(addAgent).toHaveBeenCalledWith(
      expect.objectContaining({
        id: "ws-ceo",
        workspace: "/tmp/ws"
      })
    );
  });
});
