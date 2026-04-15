import { describe, expect, it, vi, beforeEach } from "vitest";
import { createLogger } from "../config/logger.js";
import { PaperclipTimeoutError } from "../clients/paperclip/errors.js";
import { provisionForemanAgent } from "./orchestrator.js";
import type { ProvisionInput, ProvisioningResult } from "./types.js";

const getCustomerByIdMock = vi.hoisted(() => vi.fn());
const getAgentByWorkspaceAndNameMock = vi.hoisted(() => vi.fn());
const insertAgentMock = vi.hoisted(() => vi.fn());
const getCachedResultMock = vi.hoisted(() => vi.fn());
const cacheResultMock = vi.hoisted(() => vi.fn());
const writeLogEntryMock = vi.hoisted(() => vi.fn());
const appendLogEntryToFileMock = vi.hoisted(() => vi.fn());

vi.mock("../db/customers.js", () => ({
  getCustomerById: getCustomerByIdMock
}));
vi.mock("../db/agents.js", () => ({
  getAgentByWorkspaceAndName: getAgentByWorkspaceAndNameMock,
  insertAgent: insertAgentMock
}));
vi.mock("../db/idempotency.js", () => ({
  getCachedResult: getCachedResultMock,
  cacheResult: cacheResultMock
}));
vi.mock("../db/provisioning-log.js", () => ({
  writeLogEntry: writeLogEntryMock,
  appendLogEntryToFile: appendLogEntryToFileMock
}));

const baseInput: ProvisionInput = {
  customerId: "c1",
  agentName: "CEO",
  role: "ceo",
  modelTier: "open",
  idempotencyKey: "idempo-1"
};

const buildDeps = () => {
  const paperclipAgent = {
    id: "paper-1",
    name: "CEO",
    role: "ceo",
    adapterType: "openclaw_gateway",
    adapterConfig: {
      gatewayUrl: "ws://127.0.0.1:18789",
      headers: {
        "x-openclaw-token": "tok"
      }
    },
    companyId: "pc-1"
  };

  return {
    env: {} as never,
    db: {} as never,
    logger: createLogger("orchestrator-test"),
    clients: {
      stripe: {
        getSubscriptionStatus: vi.fn().mockResolvedValue("active"),
        hasFailedPaymentSince: vi.fn().mockResolvedValue(false),
        getPrepaidBalanceCents: vi.fn().mockResolvedValue(100),
        createSubscription: vi.fn().mockResolvedValue("sub_1"),
        cancelSubscription: vi.fn().mockResolvedValue(undefined),
        createPaymentIntent: vi
          .fn()
          .mockResolvedValue({ id: "pi_1", status: "requires_payment_method", clientSecret: "secret_1" }),
        constructWebhookEvent: vi.fn()
      },
      openclaw: {
        addAgent: vi.fn().mockResolvedValue({ id: "ws-ceo", workspace: "/tmp/ws", defaultAgent: false }),
        deleteAgent: vi.fn().mockResolvedValue(undefined),
        readGatewayToken: vi.fn().mockResolvedValue("tok"),
        reloadSecrets: vi.fn().mockResolvedValue(undefined),
        listAgents: vi.fn().mockResolvedValue([{ id: "ws-ceo", workspace: "/tmp/ws", defaultAgent: false }]),
        getAgent: vi.fn().mockResolvedValue({ id: "ws-ceo", workspace: "/tmp/ws", defaultAgent: false }),
        restartGateway: vi.fn().mockResolvedValue(undefined),
        gatewayStatus: vi.fn().mockResolvedValue({ running: true, pid: 123, listening: "127.0.0.1:18789" })
      },
      paperclip: {
        hireAgent: vi.fn().mockResolvedValue({ agent: paperclipAgent }),
        listPendingApprovals: vi
          .fn()
          .mockResolvedValue([{ id: "approval-1", type: "hire_agent", status: "pending" }]),
        getApproval: vi.fn().mockResolvedValue({ id: "approval-1", type: "hire_agent", status: "pending" }),
        actOnApproval: vi.fn().mockResolvedValue(undefined),
        patchAgent: vi.fn().mockResolvedValue(paperclipAgent),
        getAgent: vi.fn().mockResolvedValue(paperclipAgent),
        deleteAgent: vi.fn().mockResolvedValue(undefined),
        ping: vi.fn().mockResolvedValue({ ok: true })
      }
    }
  };
};

describe("provisionForemanAgent", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    getCustomerByIdMock.mockResolvedValue({
      customer_id: "c1",
      workspace_slug: "ws",
      display_name: "Customer",
      email: "x@y.z",
      stripe_customer_id: "cus_1",
      current_billing_mode: "foreman_managed_tier",
      current_tier: "tier_1",
      byok_key_encrypted: null,
      byok_fallback_enabled: true,
      prepaid_balance_cents: 100,
      payment_status: "active",
      paperclip_company_id: "pc-1"
    });
    getAgentByWorkspaceAndNameMock.mockResolvedValue(null);
    getCachedResultMock.mockResolvedValue(null);
    insertAgentMock.mockImplementation(async (_db, agentRecord) => ({
      ...agentRecord,
      agent_id: "db-agent-1",
      current_status: "active"
    }));
    cacheResultMock.mockResolvedValue(undefined);
    writeLogEntryMock.mockResolvedValue(undefined);
    appendLogEntryToFileMock.mockResolvedValue(undefined);
  });

  it("happy path returns success, writes log, and caches result", async () => {
    const deps = buildDeps();
    const result = await provisionForemanAgent(baseInput, deps);

    expect(result.outcome).toBe("success");
    if (result.outcome === "failed" || result.outcome === "blocked") {
      throw new Error("Expected success outcome");
    }
    expect(writeLogEntryMock).toHaveBeenCalledTimes(1);
    expect(appendLogEntryToFileMock).toHaveBeenCalledTimes(1);
    expect(cacheResultMock).toHaveBeenCalledTimes(1);
  });

  it("returns cached result and skips downstream steps", async () => {
    const deps = buildDeps();
    const cachedResult: ProvisioningResult = {
      outcome: "success",
      agentId: "cached-a",
      paperclipAgentId: "cached-p",
      openclawAgentId: "cached-o",
      provisioningId: "cached-prov",
      modelPrimary: "cached-primary",
      modelFallbacks: [],
      readyAt: new Date().toISOString()
    };
    getCachedResultMock.mockResolvedValue(cachedResult);

    const result = await provisionForemanAgent(baseInput, deps);
    expect(result).toEqual(cachedResult);
    expect(deps.clients.openclaw.addAgent).not.toHaveBeenCalled();
    expect(writeLogEntryMock).not.toHaveBeenCalled();
  });

  it("returns blocked when payment gate fails", async () => {
    const deps = buildDeps();
    getCustomerByIdMock.mockResolvedValue({
      customer_id: "c1",
      workspace_slug: "ws",
      prepaid_balance_cents: 0,
      stripe_customer_id: null
    });

    const result = await provisionForemanAgent(baseInput, deps);
    expect(result.outcome).toBe("blocked");
    if (result.outcome === "blocked" || result.outcome === "failed") {
      expect(result.failedStep).toBe("step_0_payment_gate");
    }
  });

  it("returns failed when duplicate name exists", async () => {
    const deps = buildDeps();
    getAgentByWorkspaceAndNameMock.mockResolvedValue({ agent_id: "existing" });

    const result = await provisionForemanAgent(baseInput, deps);
    expect(result.outcome).toBe("failed");
    if (result.outcome === "blocked" || result.outcome === "failed") {
      expect(result.failedStep).toBe("step_2_validate_inputs");
    }
  });

  it("returns failed when paperclip hire times out", async () => {
    const deps = buildDeps();
    deps.clients.paperclip.hireAgent = vi
      .fn()
      .mockRejectedValue(new PaperclipTimeoutError("timeout"));

    const result = await provisionForemanAgent(baseInput, deps);
    expect(result.outcome).toBe("failed");
    if (result.outcome === "blocked" || result.outcome === "failed") {
      expect(result.failedStep).toBe("step_5_paperclip_hire");
    }
  });

  it("resolves tier mapping for open, frontier, hybrid", async () => {
    const deps = buildDeps();
    for (const tier of ["open", "frontier", "hybrid"] as const) {
      const result = await provisionForemanAgent(
        {
          ...baseInput,
          modelTier: tier,
          idempotencyKey: `idempo-${tier}`
        },
        deps
      );
      if (result.outcome !== "success") {
        throw new Error(`Expected success outcome for ${tier}`);
      }
      if (tier === "frontier") {
        expect(result.modelPrimary).toBe("openrouter/anthropic/claude-sonnet-4.6");
      } else {
        expect(result.modelPrimary).toBe("openrouter/deepseek/deepseek-chat-v3.1");
      }
      expect(result.modelFallbacks).toHaveLength(2);
    }
  });
});
