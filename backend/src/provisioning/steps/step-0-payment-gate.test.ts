import { describe, expect, it, vi } from "vitest";
import { step0PaymentGate } from "./step-0-payment-gate.js";
import { createLogger } from "../../config/logger.js";
import type { StepContext } from "./types.js";

const getCustomerByIdMock = vi.hoisted(() => vi.fn());

vi.mock("../../db/customers.js", () => ({
  getCustomerById: getCustomerByIdMock
}));

const baseCtx = (): StepContext =>
  ({
    input: {
      customerId: "c1",
      agentName: "CEO",
      role: "ceo",
      modelTier: "open",
      idempotencyKey: "i1"
    },
    clients: {
      stripe: {
        getSubscriptionStatus: vi.fn().mockResolvedValue("active"),
        hasFailedPaymentSince: vi.fn().mockResolvedValue(false),
        getPrepaidBalanceCents: vi.fn().mockResolvedValue(0)
      },
      paperclip: {} as never,
      openclaw: {} as never
    },
    db: {} as never,
    logger: createLogger("step0-test"),
    state: {}
  }) as unknown as StepContext;

describe("step0PaymentGate", () => {
  it("passes with active subscription", async () => {
    getCustomerByIdMock.mockResolvedValue({
      customer_id: "c1",
      workspace_slug: "ws",
      prepaid_balance_cents: 0,
      stripe_customer_id: "cus_1"
    });

    const result = await step0PaymentGate(baseCtx());
    expect(result.ok).toBe(true);
  });

  it("blocks when no subscription and no balance", async () => {
    getCustomerByIdMock.mockResolvedValue({
      customer_id: "c1",
      workspace_slug: "ws",
      prepaid_balance_cents: 0,
      stripe_customer_id: null
    });

    const result = await step0PaymentGate(baseCtx());
    expect(result.ok).toBe(false);
    expect(result.errorCode).toBe("PAYMENT_REQUIRED");
  });
});
