import { describe, expect, it, vi } from "vitest";
import { step3CreateWorkspace } from "./step-3-create-workspace.js";
import { createLogger } from "../../config/logger.js";
import type { StepContext } from "./types.js";

const mkdirMock = vi.hoisted(() => vi.fn());

vi.mock("node:fs/promises", () => ({
  mkdir: mkdirMock
}));

describe("step3CreateWorkspace", () => {
  it("creates workspace directory and returns ids", async () => {
    mkdirMock.mockResolvedValue(undefined);
    const ctx = {
      input: {
        customerId: "c1",
        agentName: "Chief Exec",
        role: "ceo",
        modelTier: "open",
        idempotencyKey: "i1"
      },
      clients: {} as never,
      db: {} as never,
      logger: createLogger("step3-test"),
      state: {
        workspaceSlug: "workspace"
      }
    } as unknown as StepContext;

    const result = await step3CreateWorkspace(ctx);
    expect(result.ok).toBe(true);
    expect(result.data?.openclawAgentId).toBe("workspace-chief-exec");
    expect(mkdirMock).toHaveBeenCalled();
  });
});
