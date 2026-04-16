import { Hono } from "hono";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AppDeps } from "../app-deps.js";
import { createLogger } from "../config/logger.js";
import { registerAgentRoutes } from "./agents.js";

const { provisionForemanAgentMock, getAgentByOpenclawAgentIdMock, insertNotificationMock } = vi.hoisted(() => ({
  provisionForemanAgentMock: vi.fn(),
  getAgentByOpenclawAgentIdMock: vi.fn(),
  insertNotificationMock: vi.fn()
}));

vi.mock("../provisioning/orchestrator.js", () => ({
  provisionForemanAgent: provisionForemanAgentMock
}));

vi.mock("../db/agents.js", () => ({
  getAgentByOpenclawAgentId: getAgentByOpenclawAgentIdMock
}));

vi.mock("../db/notifications.js", () => ({
  insertNotification: insertNotificationMock
}));

describe("agent provision route", () => {
  const deps = {
    db: {} as never,
    logger: createLogger("agents-route-test"),
    clients: {} as never,
    env: { NODE_ENV: "test" } as never
  } as unknown as AppDeps;

  const app = new Hono();
  registerAgentRoutes(app, deps);

  beforeEach(() => {
    provisionForemanAgentMock.mockReset();
    getAgentByOpenclawAgentIdMock.mockReset();
    insertNotificationMock.mockReset();
  });

  it("inherits customer and tier from parent ceo and writes notification", async () => {
    getAgentByOpenclawAgentIdMock.mockResolvedValue({
      customer_id: "11111111-1111-4111-8111-111111111111",
      workspace_slug: "acme-co",
      role: "ceo",
      model_tier: "hybrid"
    });
    provisionForemanAgentMock.mockResolvedValue({
      outcome: "success",
      agentId: "22222222-2222-4222-8222-222222222222",
      paperclipAgentId: "33333333-3333-4333-8333-333333333333",
      openclawAgentId: "ws-marketing",
      provisioningId: "44444444-4444-4444-8444-444444444444",
      modelPrimary: "openrouter/deepseek/deepseek-chat-v3.1",
      modelFallbacks: [],
      readyAt: new Date().toISOString()
    });

    const response = await app.request("/api/internal/agents/provision", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        role: "marketing_analyst",
        agent_name: "Marketing Analyst",
        parent_openclaw_agent_id: "workspace-ceo",
        idempotency_key: "55555555-5555-4555-8555-555555555555"
      })
    });

    expect(response.status).toBe(200);
    expect(provisionForemanAgentMock).toHaveBeenCalledWith(
      expect.objectContaining({
        customerId: "11111111-1111-4111-8111-111111111111",
        modelTier: "hybrid",
        role: "marketing_analyst"
      }),
      deps
    );
    expect(insertNotificationMock).toHaveBeenCalledWith(
      deps.db,
      expect.objectContaining({
        workspace_slug: "acme-co",
        type: "agent_hired"
      })
    );
  });

  it("rejects sub-agent provisioning when parent is not ceo", async () => {
    getAgentByOpenclawAgentIdMock.mockResolvedValue({
      customer_id: "11111111-1111-4111-8111-111111111111",
      workspace_slug: "acme-co",
      role: "marketing_analyst",
      model_tier: "hybrid"
    });

    const response = await app.request("/api/internal/agents/provision", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        role: "marketing_analyst",
        agent_name: "Marketing Analyst",
        parent_openclaw_agent_id: "workspace-marketing",
        idempotency_key: "55555555-5555-4555-8555-555555555555"
      })
    });

    expect(response.status).toBe(403);
    expect(provisionForemanAgentMock).not.toHaveBeenCalled();
    expect(insertNotificationMock).not.toHaveBeenCalled();
  });
});
