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

const baseCustomer = {
  customer_id: "c1",
  workspace_slug: "ws",
  prepaid_balance_cents: 0,
  stripe_customer_id: "cus_1",
  current_billing_mode: "foreman_managed_tier",
  tokens_consumed_current_period_cents: 100,
  tier_allowance_cents: 1_000
};

describe("step0PaymentGate", () => {
  it("passes for tier customer with active subscription", async () => {
    getCustomerByIdMock.mockResolvedValue(baseCustomer);

    const result = await step0PaymentGate(baseCtx());
    expect(result.ok).toBe(true);
  });

  it("blocks tier customer with canceled subscription", async () => {
    getCustomerByIdMock.mockResolvedValue(baseCustomer);
    const ctx = baseCtx();
    ctx.clients.stripe.getSubscriptionStatus = vi.fn().mockResolvedValue("canceled");

    const result = await step0PaymentGate(ctx);
    expect(result.ok).toBe(false);
    expect(result.errorCode).toBe("PAYMENT_DELINQUENT");
  });

  it("blocks usage-based customer with zero balance", async () => {
    getCustomerByIdMock.mockResolvedValue({
      ...baseCustomer,
      current_billing_mode: "foreman_managed_usage"
    });
    const ctx = baseCtx();
    ctx.clients.stripe.getPrepaidBalanceCents = vi.fn().mockResolvedValue(0);

    const result = await step0PaymentGate(ctx);
    expect(result.ok).toBe(false);
    expect(result.errorCode).toBe("PAYMENT_REQUIRED");
  });

  it("passes usage-based customer with positive balance", async () => {
    getCustomerByIdMock.mockResolvedValue({
      ...baseCustomer,
      current_billing_mode: "foreman_managed_usage"
    });
    const ctx = baseCtx();
    ctx.clients.stripe.getPrepaidBalanceCents = vi.fn().mockResolvedValue(5_000);

    const result = await step0PaymentGate(ctx);
    expect(result.ok).toBe(true);
  });

  it("passes BYOK customer with active platform subscription", async () => {
    getCustomerByIdMock.mockResolvedValue({
      ...baseCustomer,
      current_billing_mode: "byok"
    });

    const result = await step0PaymentGate(baseCtx());
    expect(result.ok).toBe(true);
  });

  it("blocks customer with failed payment in the last 7 days", async () => {
    getCustomerByIdMock.mockResolvedValue(baseCustomer);
    const ctx = baseCtx();
    ctx.clients.stripe.hasFailedPaymentSince = vi.fn().mockResolvedValue(true);

    const result = await step0PaymentGate(ctx);
    expect(result.ok).toBe(false);
    expect(result.errorCode).toBe("PAYMENT_DELINQUENT");
  });

  it("blocks customer over tier allowance", async () => {
    getCustomerByIdMock.mockResolvedValue({
      ...baseCustomer,
      tokens_consumed_current_period_cents: 5_001,
      tier_allowance_cents: 5_000
    });

    const result = await step0PaymentGate(baseCtx());
    expect(result.ok).toBe(false);
    expect(result.errorCode).toBe("PAYMENT_TIER_LIMIT");
  });
});
