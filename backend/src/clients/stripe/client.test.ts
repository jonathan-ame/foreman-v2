import { beforeEach, describe, expect, it, vi } from "vitest";
import { createLogger } from "../../config/logger.js";
import { StripeClient } from "./client.js";
import { StripeApiError } from "./errors.js";

const {
  subscriptionsListMock,
  subscriptionsCreateMock,
  subscriptionsCancelMock,
  eventsListMock,
  customersRetrieveMock,
  pricesListMock,
  paymentIntentsCreateMock,
  constructEventMock,
  stripeCtorMock
} = vi.hoisted(() => ({
  subscriptionsListMock: vi.fn(),
  subscriptionsCreateMock: vi.fn(),
  subscriptionsCancelMock: vi.fn(),
  eventsListMock: vi.fn(),
  customersRetrieveMock: vi.fn(),
  pricesListMock: vi.fn(),
  paymentIntentsCreateMock: vi.fn(),
  constructEventMock: vi.fn(),
  stripeCtorMock: vi.fn()
}));

vi.mock("stripe", () => {
  class StripeError extends Error {
    statusCode?: number;
    code?: string;
    requestId?: string;
  }

  class StripeMock {
    static errors = { StripeError };

    subscriptions = {
      list: subscriptionsListMock,
      create: subscriptionsCreateMock,
      cancel: subscriptionsCancelMock
    };

    events = {
      list: eventsListMock
    };

    customers = {
      retrieve: customersRetrieveMock
    };

    prices = {
      list: pricesListMock
    };

    paymentIntents = {
      create: paymentIntentsCreateMock
    };

    webhooks = {
      constructEvent: constructEventMock
    };

    constructor(apiKey: string, _opts: unknown) {
      stripeCtorMock(apiKey);
    }
  }

  return { default: StripeMock };
});

describe("StripeClient", () => {
  const logger = createLogger("stripe-client-test");

  beforeEach(() => {
    subscriptionsListMock.mockReset();
    subscriptionsCreateMock.mockReset();
    subscriptionsCancelMock.mockReset();
    eventsListMock.mockReset();
    customersRetrieveMock.mockReset();
    pricesListMock.mockReset();
    paymentIntentsCreateMock.mockReset();
    constructEventMock.mockReset();
    stripeCtorMock.mockReset();
  });

  it("uses live key when mode is live", async () => {
    subscriptionsListMock.mockResolvedValue({ data: [] });
    const client = new StripeClient({
      logger,
      mode: "live",
      liveApiKey: "sk_live_123",
      testApiKey: undefined
    });

    await client.getSubscriptionStatus("cus_live");
    expect(stripeCtorMock).toHaveBeenCalledWith("sk_live_123");
  });

  it("uses test key when mode is test", async () => {
    subscriptionsListMock.mockResolvedValue({ data: [] });
    const client = new StripeClient({
      logger,
      mode: "test",
      liveApiKey: undefined,
      testApiKey: "sk_test_123"
    });

    await client.getSubscriptionStatus("cus_test");
    expect(stripeCtorMock).toHaveBeenCalledWith("sk_test_123");
  });

  it("returns latest subscription status", async () => {
    subscriptionsListMock.mockResolvedValue({
      data: [
        { id: "sub_old", created: 1, status: "canceled" },
        { id: "sub_new", created: 3, status: "active" }
      ]
    });
    const client = new StripeClient({ logger, mode: "test", liveApiKey: undefined, testApiKey: "sk_test_123" });

    await expect(client.getSubscriptionStatus("cus_1")).resolves.toBe("active");
  });

  it("returns failed payment state based on invoice events", async () => {
    eventsListMock.mockResolvedValue({
      data: [
        { data: { object: { customer: "cus_1" } } },
        { data: { object: { customer: "cus_2" } } }
      ]
    });
    const client = new StripeClient({ logger, mode: "test", liveApiKey: undefined, testApiKey: "sk_test_123" });

    await expect(client.hasFailedPaymentSince("cus_1", new Date())).resolves.toBe(true);
  });

  it("returns prepaid balance in cents", async () => {
    customersRetrieveMock.mockResolvedValue({ deleted: false, balance: -4500 });
    const client = new StripeClient({ logger, mode: "test", liveApiKey: undefined, testApiKey: "sk_test_123" });

    await expect(client.getPrepaidBalanceCents("cus_1")).resolves.toBe(4500);
  });

  it("creates subscription from product recurring price", async () => {
    pricesListMock.mockResolvedValue({
      data: [{ id: "price_1", recurring: { interval: "month" }, currency: "usd" }]
    });
    subscriptionsCreateMock.mockResolvedValue({ id: "sub_123" });
    const client = new StripeClient({ logger, mode: "test", liveApiKey: undefined, testApiKey: "sk_test_123" });

    await expect(client.createSubscription("cus_1", "prod_1")).resolves.toBe("sub_123");
  });

  it("throws if no monthly USD price exists for subscription", async () => {
    pricesListMock.mockResolvedValue({ data: [] });
    const client = new StripeClient({ logger, mode: "test", liveApiKey: undefined, testApiKey: "sk_test_123" });

    await expect(client.createSubscription("cus_1", "prod_1")).rejects.toBeInstanceOf(StripeApiError);
  });

  it("cancels subscriptions and creates payment intents", async () => {
    subscriptionsCancelMock.mockResolvedValue({});
    paymentIntentsCreateMock.mockResolvedValue({
      id: "pi_1",
      status: "requires_payment_method",
      client_secret: "secret_123"
    });
    const client = new StripeClient({ logger, mode: "test", liveApiKey: undefined, testApiKey: "sk_test_123" });

    await expect(client.cancelSubscription("sub_1")).resolves.toBeUndefined();
    await expect(client.createPaymentIntent("cus_1", 1200)).resolves.toEqual({
      id: "pi_1",
      status: "requires_payment_method",
      clientSecret: "secret_123"
    });
  });

  it("constructs and returns webhook events", () => {
    constructEventMock.mockReturnValue({ id: "evt_1", type: "invoice.payment_succeeded" });
    const client = new StripeClient({ logger, mode: "test", liveApiKey: undefined, testApiKey: "sk_test_123" });

    expect(client.constructWebhookEvent("{}", "sig", "whsec_1")).toEqual({
      id: "evt_1",
      type: "invoice.payment_succeeded"
    });
  });
});
