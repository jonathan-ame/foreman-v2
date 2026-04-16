import { Hono } from "hono";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { AppDeps } from "../app-deps.js";
import { createLogger } from "../config/logger.js";
import { registerHealthRoutes } from "./health.js";

const { getAgentStatusCountsMock } = vi.hoisted(() => ({
  getAgentStatusCountsMock: vi.fn()
}));

vi.mock("../db/agents.js", () => ({
  getAgentStatusCounts: getAgentStatusCountsMock
}));

describe("integration health route", () => {
  const originalFetch = global.fetch;

  beforeEach(() => {
    getAgentStatusCountsMock.mockReset();
  });

  afterEach(() => {
    global.fetch = originalFetch;
  });

  it("returns ok when all checks pass", async () => {
    getAgentStatusCountsMock.mockResolvedValue({ active_count: 1, paused_count: 0 });
    global.fetch = vi.fn(async () => new Response(JSON.stringify({ data: [{ id: "m1" }, { id: "m2" }] }), { status: 200 }));

    const app = new Hono();
    const deps = {
      db: {
        from: vi.fn(() => ({
          select: vi.fn(() => ({
            limit: vi.fn(async () => ({ error: null }))
          }))
        }))
      },
      clients: {
        paperclip: { ping: vi.fn(async () => ({ ok: true, version: "2026.403.0" })) },
        openclaw: { gatewayStatus: vi.fn(async () => ({ running: true, pid: 12345, listening: "127.0.0.1:18789" })) },
        stripe: {} as never
      },
      logger: createLogger("health-route-test"),
      env: { OPENROUTER_API_KEY: "or-key" } as never
    } as unknown as AppDeps;

    registerHealthRoutes(app, deps);
    const response = await app.request("/api/internal/health/integration");
    expect(response.status).toBe(200);
    const body = (await response.json()) as {
      status: string;
      checks: { openrouter: { ok: boolean; models_available: number } };
    };
    expect(body.status).toBe("ok");
    expect(body.checks.openrouter.models_available).toBe(2);
  });

  it("returns down when a core dependency fails", async () => {
    getAgentStatusCountsMock.mockResolvedValue({ active_count: 1, paused_count: 0 });
    global.fetch = vi.fn(async () => new Response(JSON.stringify({ data: [] }), { status: 200 }));

    const app = new Hono();
    const deps = {
      db: {
        from: vi.fn(() => ({
          select: vi.fn(() => ({
            limit: vi.fn(async () => ({ error: { message: "db down" } }))
          }))
        }))
      },
      clients: {
        paperclip: { ping: vi.fn(async () => ({ ok: true, version: "2026.403.0" })) },
        openclaw: { gatewayStatus: vi.fn(async () => ({ running: true, pid: 12345, listening: "127.0.0.1:18789" })) },
        stripe: {} as never
      },
      logger: createLogger("health-route-test"),
      env: { OPENROUTER_API_KEY: "or-key" } as never
    } as unknown as AppDeps;

    registerHealthRoutes(app, deps);
    const response = await app.request("/api/internal/health/integration");
    const body = (await response.json()) as { status: string; checks: { supabase: { ok: boolean } } };
    expect(body.status).toBe("down");
    expect(body.checks.supabase.ok).toBe(false);
  });
});
