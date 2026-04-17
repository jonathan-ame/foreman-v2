import { Hono } from "hono";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AppDeps } from "../app-deps.js";
import { createLogger } from "../config/logger.js";
import { registerEscalationRoutes } from "./escalation.js";

const {
  getAgentByOpenclawAgentIdMock,
  getTaskEscalationStateMock,
  recordTaskRejectionMock,
  escalateTaskToFrontierMock
} = vi.hoisted(() => ({
  getAgentByOpenclawAgentIdMock: vi.fn(),
  getTaskEscalationStateMock: vi.fn(),
  recordTaskRejectionMock: vi.fn(),
  escalateTaskToFrontierMock: vi.fn()
}));

vi.mock("../db/agents.js", () => ({
  getAgentByOpenclawAgentId: getAgentByOpenclawAgentIdMock
}));

vi.mock("../db/task-escalation.js", () => ({
  getTaskEscalationState: getTaskEscalationStateMock,
  recordTaskRejection: recordTaskRejectionMock,
  escalateTaskToFrontier: escalateTaskToFrontierMock
}));

describe("task escalation routes", () => {
  const deps = {
    db: {} as never,
    logger: createLogger("escalation-route-test"),
    clients: {} as never,
    env: { NODE_ENV: "test" } as never
  } as unknown as AppDeps;

  const app = new Hono();
  registerEscalationRoutes(app, deps);

  beforeEach(() => {
    getAgentByOpenclawAgentIdMock.mockReset();
    getTaskEscalationStateMock.mockReset();
    recordTaskRejectionMock.mockReset();
    escalateTaskToFrontierMock.mockReset();
  });

  it("escalates on second rejection for hybrid", async () => {
    getAgentByOpenclawAgentIdMock.mockResolvedValue({
      agent_id: "11111111-1111-4111-8111-111111111111",
      workspace_slug: "acme",
      model_tier: "hybrid"
    });
    recordTaskRejectionMock.mockResolvedValue({
      rejectionCount: 2,
      escalatedToFrontier: true,
      frontierModel: "openrouter/anthropic/claude-sonnet-4.6"
    });

    const response = await app.request("/api/internal/tasks/issue-123/rejection", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        openclawAgentId: "foreman-ceo",
        taskType: "code_generation"
      })
    });

    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toMatchObject({
      escalated: true,
      frontier_model: "openrouter/anthropic/claude-sonnet-4.6",
      rejection_count: 2
    });
  });

  it("returns escalated model when state is sticky frontier", async () => {
    getTaskEscalationStateMock.mockResolvedValue({
      issue_id: "issue-123",
      rejection_count: 2,
      escalated_to_frontier: true,
      frontier_model: "openrouter/openai/gpt-5"
    });

    const response = await app.request("/api/internal/tasks/issue-123/model?openclawAgentId=foreman-ceo");
    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toMatchObject({
      escalated: true,
      model: "openrouter/openai/gpt-5"
    });
  });

  it("supports manual escalation endpoint", async () => {
    getAgentByOpenclawAgentIdMock.mockResolvedValue({
      agent_id: "11111111-1111-4111-8111-111111111111",
      workspace_slug: "acme",
      model_tier: "hybrid"
    });
    escalateTaskToFrontierMock.mockResolvedValue({
      rejectionCount: 0,
      escalatedToFrontier: true,
      frontierModel: "openrouter/google/gemini-2.5-pro"
    });

    const response = await app.request("/api/internal/tasks/issue-456/escalate", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        openclawAgentId: "foreman-ceo",
        taskType: "research"
      })
    });

    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toMatchObject({
      escalated: true,
      frontier_model: "openrouter/google/gemini-2.5-pro",
      rejection_count: 0
    });
  });
});
