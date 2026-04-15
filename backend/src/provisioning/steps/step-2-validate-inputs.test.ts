import { describe, expect, it, vi } from "vitest";
import { step2ValidateInputs } from "./step-2-validate-inputs.js";
import { createLogger } from "../../config/logger.js";
import type { StepContext } from "./types.js";

const getCustomerByIdMock = vi.hoisted(() => vi.fn());
const getAgentByWorkspaceAndNameMock = vi.hoisted(() => vi.fn());

vi.mock("../../db/customers.js", () => ({
  getCustomerById: getCustomerByIdMock
}));

vi.mock("../../db/agents.js", () => ({
  getAgentByWorkspaceAndName: getAgentByWorkspaceAndNameMock
}));

const ctx = (): StepContext =>
  ({
    input: {
      customerId: "c1",
      agentName: "CEO",
      role: "ceo",
      modelTier: "open",
      idempotencyKey: "i1"
    },
    clients: {} as never,
    db: {} as never,
    logger: createLogger("step2-test"),
    state: {}
  }) as unknown as StepContext;

describe("step2ValidateInputs", () => {
  it("passes and returns resolved configs", async () => {
    getCustomerByIdMock.mockResolvedValue({
      customer_id: "c1",
      workspace_slug: "ws-1"
    });
    getAgentByWorkspaceAndNameMock.mockResolvedValue(null);

    const result = await step2ValidateInputs(ctx());
    expect(result.ok).toBe(true);
    expect(result.data?.workspaceSlug).toBe("ws-1");
  });

  it("fails when agent name already exists", async () => {
    getCustomerByIdMock.mockResolvedValue({
      customer_id: "c1",
      workspace_slug: "ws-1"
    });
    getAgentByWorkspaceAndNameMock.mockResolvedValue({ agent_id: "existing" });

    const result = await step2ValidateInputs(ctx());
    expect(result.ok).toBe(false);
    expect(result.errorCode).toBe("AGENT_NAME_CONFLICT");
  });
});
