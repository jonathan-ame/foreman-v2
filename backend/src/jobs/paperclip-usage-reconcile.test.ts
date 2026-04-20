import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AppDeps } from "../app-deps.js";
import { createLogger } from "../config/logger.js";
import { runPaperclipUsageReconcileJob } from "./paperclip-usage-reconcile.js";

const { getAgentUsageTotalsSinceMock } = vi.hoisted(() => ({
  getAgentUsageTotalsSinceMock: vi.fn()
}));

vi.mock("../db/agent-usage-events.js", () => ({
  getAgentUsageTotalsSince: getAgentUsageTotalsSinceMock
}));

const makeDbWithAgents = (agents: Record<string, unknown>[]) => ({
  from: vi.fn((table: string) => {
    if (table === "agents") {
      return {
        select: vi.fn(() => ({
          in: vi.fn(async () => ({ data: agents, error: null }))
        })),
        update: vi.fn(() => ({
          eq: vi.fn(async () => ({ error: null }))
        }))
      };
    }
    return {} as never;
  })
});

const makeDeps = (db: unknown): AppDeps =>
  ({
    db,
    logger: createLogger("reconcile-test"),
    clients: {} as never,
    env: {} as never
  }) as unknown as AppDeps;

describe("paperclip_usage_reconcile job", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("returns noop when no usage events in window", async () => {
    getAgentUsageTotalsSinceMock.mockResolvedValue([]);
    const result = await runPaperclipUsageReconcileJob(makeDeps({}));
    expect(result.status).toBe("noop");
  });

  it("returns ok with no patches when counters match", async () => {
    getAgentUsageTotalsSinceMock.mockResolvedValue([
      {
        paperclip_agent_id: "agent-1",
        total_input_tokens: 1000,
        total_output_tokens: 500,
        total_cost_cents: 100
      }
    ]);

    const db = makeDbWithAgents([
      {
        agent_id: "db-agent-1",
        paperclip_agent_id: "agent-1",
        surcharge_accrued_current_period_cents: 100
      }
    ]);

    const result = await runPaperclipUsageReconcileJob(makeDeps(db));
    expect(result.status).toBe("ok");
    expect((result.details as { agents_drifted: number }).agents_drifted).toBe(0);
  });

  it("patches agent when drift exceeds 1%", async () => {
    getAgentUsageTotalsSinceMock.mockResolvedValue([
      {
        paperclip_agent_id: "agent-1",
        total_input_tokens: 1000,
        total_output_tokens: 500,
        total_cost_cents: 110
      }
    ]);

    const updateEqMock = vi.fn(async () => ({ error: null }));
    const db = {
      from: vi.fn((table: string) => {
        if (table === "agents") {
          return {
            select: vi.fn(() => ({
              in: vi.fn(async () => ({
                data: [
                  {
                    agent_id: "db-agent-1",
                    paperclip_agent_id: "agent-1",
                    surcharge_accrued_current_period_cents: 100
                  }
                ],
                error: null
              }))
            })),
            update: vi.fn(() => ({ eq: updateEqMock }))
          };
        }
        return {} as never;
      })
    };

    const result = await runPaperclipUsageReconcileJob(makeDeps(db));
    expect(result.status).toBe("ok");
    expect((result.details as { agents_drifted: number }).agents_drifted).toBe(1);
    expect(updateEqMock).toHaveBeenCalled();
  });

  it("returns error when agent query fails", async () => {
    getAgentUsageTotalsSinceMock.mockResolvedValue([
      {
        paperclip_agent_id: "agent-1",
        total_input_tokens: 100,
        total_output_tokens: 50,
        total_cost_cents: 10
      }
    ]);

    const db = {
      from: vi.fn(() => ({
        select: vi.fn(() => ({
          in: vi.fn(async () => ({ data: null, error: { message: "query failed" } }))
        }))
      }))
    };

    const result = await runPaperclipUsageReconcileJob(makeDeps(db));
    expect(result.status).toBe("error");
  });
});
