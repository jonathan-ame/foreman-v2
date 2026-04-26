import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AppDeps } from "../app-deps.js";
import { createLogger } from "../config/logger.js";
import { runAgentHealthCheckJob } from "./agent-health-check.js";

const {
  listAgentsForHealthCheckMock,
  updateAgentHealthMock,
  getAgentStatusCountsMock,
  insertNotificationMock
} = vi.hoisted(() => ({
  listAgentsForHealthCheckMock: vi.fn(),
  updateAgentHealthMock: vi.fn(),
  getAgentStatusCountsMock: vi.fn(),
  insertNotificationMock: vi.fn()
}));

vi.mock("../db/agents.js", () => ({
  listAgentsForHealthCheck: listAgentsForHealthCheckMock,
  updateAgentHealth: updateAgentHealthMock,
  getAgentStatusCounts: getAgentStatusCountsMock
}));

vi.mock("../db/notifications.js", () => ({
  insertNotification: insertNotificationMock
}));

describe("runAgentHealthCheckJob", () => {
  const makeDeps = (statusByPaperclipId: Record<string, { status?: string; adapterType?: string }>) =>
    ({
      logger: createLogger("agent-health-check-test"),
      db: {} as never,
      clients: {
        paperclip: {
          getAgent: vi.fn(async (agentId: string) => ({
            id: agentId,
            name: "Agent",
            role: "cmo",
            adapterType: statusByPaperclipId[agentId]?.adapterType ?? "opencode_local",
            adapterConfig: { timeoutSec: 1500 },
            companyId: "company-1",
            status: statusByPaperclipId[agentId]?.status
          }))
        },
        openclaw: {} as never,
        stripe: {} as never
      }
    }) as unknown as AppDeps;

  beforeEach(() => {
    listAgentsForHealthCheckMock.mockReset();
    updateAgentHealthMock.mockReset();
    getAgentStatusCountsMock.mockReset();
    insertNotificationMock.mockReset();
    getAgentStatusCountsMock.mockResolvedValue({ active_count: 1, paused_count: 0 });
  });

  it("keeps agent active for repeated healthy checks", async () => {
    listAgentsForHealthCheckMock.mockResolvedValue([
      {
        agent_id: "agent-1",
        paperclip_agent_id: "pc-1",
        openclaw_agent_id: "oc-1",
        workspace_slug: "acme",
        customer_id: "cust-1",
        display_name: "Agent One",
        role: "ceo",
        model_tier: "hybrid",
        model_primary: "m",
        model_fallbacks: [],
        billing_mode_at_provision: "byok",
        current_status: "active",
        last_health_check_result: JSON.stringify({ failure_streak: 0 })
      }
    ]);
    const deps = makeDeps({ "pc-1": { status: "idle" } });

    for (let i = 0; i < 5; i += 1) {
      await runAgentHealthCheckJob(deps);
    }

    expect(updateAgentHealthMock).toHaveBeenCalled();
    const statuses = updateAgentHealthMock.mock.calls.map((call) => call[2].current_status);
    expect(statuses.every((status) => status === "active")).toBe(true);
    expect(insertNotificationMock).not.toHaveBeenCalled();
  });

  it("pauses an active agent on third consecutive failure and writes notification", async () => {
    const baseAgent = {
      agent_id: "agent-1",
      paperclip_agent_id: "pc-1",
      openclaw_agent_id: "oc-1",
      workspace_slug: "acme",
      customer_id: "cust-1",
      display_name: "Agent One",
      role: "ceo",
      model_tier: "hybrid",
      model_primary: "m",
      model_fallbacks: [],
      billing_mode_at_provision: "byok"
    };

    listAgentsForHealthCheckMock
      .mockResolvedValueOnce([
        { ...baseAgent, current_status: "active", last_health_check_result: JSON.stringify({ failure_streak: 0 }) }
      ])
      .mockResolvedValueOnce([
        { ...baseAgent, current_status: "active", last_health_check_result: JSON.stringify({ failure_streak: 1 }) }
      ])
      .mockResolvedValueOnce([
        { ...baseAgent, current_status: "active", last_health_check_result: JSON.stringify({ failure_streak: 2 }) }
      ]);
    const deps = makeDeps({ "pc-1": { status: "error" } });

    await runAgentHealthCheckJob(deps);
    await runAgentHealthCheckJob(deps);
    await runAgentHealthCheckJob(deps);

    expect(updateAgentHealthMock.mock.calls[2]?.[2]?.current_status).toBe("paused");
    expect(insertNotificationMock).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ type: "agent_paused_health" })
    );
  });

  it("recovers a paused agent after successful check and writes notification", async () => {
    listAgentsForHealthCheckMock.mockResolvedValue([
      {
        agent_id: "agent-1",
        paperclip_agent_id: "pc-1",
        openclaw_agent_id: "oc-1",
        workspace_slug: "acme",
        customer_id: "cust-1",
        display_name: "Agent One",
        role: "ceo",
        model_tier: "hybrid",
        model_primary: "m",
        model_fallbacks: [],
        billing_mode_at_provision: "byok",
        current_status: "paused",
        last_health_check_result: JSON.stringify({ failure_streak: 3 })
      }
    ]);
    const deps = makeDeps({ "pc-1": { status: "idle" } });

    await runAgentHealthCheckJob(deps);

    expect(updateAgentHealthMock).toHaveBeenCalledWith(
      expect.anything(),
      "agent-1",
      expect.objectContaining({ current_status: "active" })
    );
    expect(insertNotificationMock).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ type: "agent_recovered_health" })
    );
  });
});
