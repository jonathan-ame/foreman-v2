import { Hono } from "hono";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AppDeps } from "../app-deps.js";
import { createLogger } from "../config/logger.js";
import { registerUsageRoutes } from "./usage.js";

const { incrementAgentUsageByPaperclipAgentIdMock, insertAgentUsageEventMock } = vi.hoisted(() => ({
  incrementAgentUsageByPaperclipAgentIdMock: vi.fn(),
  insertAgentUsageEventMock: vi.fn()
}));

vi.mock("../db/agents.js", () => ({
  incrementAgentUsageByPaperclipAgentId: incrementAgentUsageByPaperclipAgentIdMock
}));

vi.mock("../db/agent-usage-events.js", () => ({
  insertAgentUsageEvent: insertAgentUsageEventMock
}));

describe("agent usage route", () => {
  const deps = {
    db: {} as never,
    logger: createLogger("usage-route-test"),
    clients: {} as never,
    env: { NODE_ENV: "test" } as never
  } as unknown as AppDeps;

  const app = new Hono();
  registerUsageRoutes(app, deps);

  beforeEach(() => {
    incrementAgentUsageByPaperclipAgentIdMock.mockReset();
    insertAgentUsageEventMock.mockResolvedValue(undefined);
  });

  it("records usage for a valid payload", async () => {
    incrementAgentUsageByPaperclipAgentIdMock.mockResolvedValue(true);

    const response = await app.request("/api/internal/agents/f4d652b8-75b4-4bac-bdfd-a5b75d499ec1/usage", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        inputTokens: 120,
        outputTokens: 45,
        costCents: 2,
        provider: "openrouter",
        model: "openrouter/deepseek/deepseek-chat-v3.1",
        issueId: "a2c8f2f2-b709-4e5d-96fd-e03d0a8054e4",
        occurredAt: new Date().toISOString()
      })
    });

    expect(response.status).toBe(200);
    expect(incrementAgentUsageByPaperclipAgentIdMock).toHaveBeenCalledWith(
      deps.db,
      "f4d652b8-75b4-4bac-bdfd-a5b75d499ec1",
      {
        inputTokens: 120,
        outputTokens: 45,
        costCents: 2
      }
    );
  });

  it("rejects invalid payloads", async () => {
    const response = await app.request("/api/internal/agents/f4d652b8-75b4-4bac-bdfd-a5b75d499ec1/usage", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        inputTokens: -1,
        outputTokens: 10,
        costCents: 1,
        model: "openrouter/deepseek/deepseek-chat-v3.1",
        occurredAt: new Date().toISOString()
      })
    });

    expect(response.status).toBe(400);
    expect(incrementAgentUsageByPaperclipAgentIdMock).not.toHaveBeenCalled();
  });

  it("returns 404 when no matching agent exists", async () => {
    incrementAgentUsageByPaperclipAgentIdMock.mockResolvedValue(false);

    const response = await app.request("/api/internal/agents/f4d652b8-75b4-4bac-bdfd-a5b75d499ec1/usage", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        inputTokens: 10,
        outputTokens: 10,
        costCents: 1,
        model: "openrouter/deepseek/deepseek-chat-v3.1",
        occurredAt: new Date().toISOString()
      })
    });

    expect(response.status).toBe(404);
  });
});
