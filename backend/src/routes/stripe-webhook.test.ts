import { Hono } from "hono";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AppDeps } from "../app-deps.js";
import { createLogger } from "../config/logger.js";
import { registerStripeWebhookRoutes } from "./stripe-webhook.js";

const { updateCustomerByStripeCustomerIdMock } = vi.hoisted(() => ({
  updateCustomerByStripeCustomerIdMock: vi.fn()
}));

vi.mock("../db/customers.js", () => ({
  updateCustomerByStripeCustomerId: updateCustomerByStripeCustomerIdMock
}));

describe("Stripe webhook route", () => {
  const constructWebhookEventMock = vi.fn();
  const logger = createLogger("stripe-webhook-test");

  const deps = {
    clients: {
      stripe: {
        constructWebhookEvent: constructWebhookEventMock
      },
      paperclip: {},
      openclaw: {}
    },
    db: {},
    logger,
    env: {
      stripeMode: "test",
      STRIPE_WEBHOOK_SECRET: "whsec_test",
      STRIPE_WEBHOOK_SECRET_ACTIVE: "whsec_test",
      STRIPE_PRICE_TIER_1: "price_tier_1",
      STRIPE_PRICE_TIER_2: "price_tier_2",
      STRIPE_PRICE_TIER_3: "price_tier_3",
      STRIPE_PRICE_BYOK_PLATFORM: "price_byok",
      STRIPE_PRICE_TIER_1_ACTIVE: "price_tier_1",
      STRIPE_PRICE_TIER_2_ACTIVE: "price_tier_2",
      STRIPE_PRICE_TIER_3_ACTIVE: "price_tier_3",
      STRIPE_PRICE_BYOK_PLATFORM_ACTIVE: "price_byok"
    }
  } as unknown as AppDeps;

  const app = new Hono();
  registerStripeWebhookRoutes(app, deps);

  beforeEach(() => {
    constructWebhookEventMock.mockReset();
    updateCustomerByStripeCustomerIdMock.mockReset();
    updateCustomerByStripeCustomerIdMock.mockResolvedValue({ customer_id: "c1" });
  });

  it("rejects missing signature", async () => {
    const response = await app.request("/api/internal/webhooks/stripe", {
      method: "POST",
      body: "{}"
    });

    expect(response.status).toBe(400);
  });

  it("rejects invalid signatures", async () => {
    constructWebhookEventMock.mockImplementation(() => {
      throw new Error("bad signature");
    });

    const response = await app.request("/api/internal/webhooks/stripe", {
      method: "POST",
      headers: {
        "stripe-signature": "t=1,v1=bad"
      },
      body: JSON.stringify({ any: "payload" })
    });

    expect(response.status).toBe(400);
  });

  it("processes customer.subscription.updated", async () => {
    constructWebhookEventMock.mockReturnValue({
      id: "evt_1",
      type: "customer.subscription.updated",
      livemode: true,
      data: {
        object: {
          id: "sub_1",
          customer: "cus_1",
          status: "active",
          items: {
            data: [
              {
                price: {
                  id: "price_tier_2",
                  product: "prod_growth"
                }
              }
            ]
          }
        }
      }
    });

    const response = await app.request("/api/internal/webhooks/stripe", {
      method: "POST",
      headers: {
        "stripe-signature": "t=1,v1=abc"
      },
      body: JSON.stringify({ any: "payload" })
    });

    expect(response.status).toBe(200);
    expect(updateCustomerByStripeCustomerIdMock).toHaveBeenCalledWith(
      deps.db,
      "cus_1",
      expect.objectContaining({
        payment_status: "active",
        current_tier: "tier_2",
        stripe_subscription_id: "sub_1",
        stripe_product_id: "prod_growth"
      })
    );
  });

  it("processes invoice.payment_failed", async () => {
    constructWebhookEventMock.mockReturnValue({
      id: "evt_2",
      type: "invoice.payment_failed",
      livemode: true,
      data: {
        object: {
          customer: "cus_2",
          subscription: "sub_2",
          lines: {
            data: [
              {
                price: {
                  id: "price_tier_1",
                  product: "prod_starter"
                }
              }
            ]
          }
        }
      }
    });

    const response = await app.request("/api/internal/webhooks/stripe", {
      method: "POST",
      headers: {
        "stripe-signature": "t=1,v1=abc"
      },
      body: JSON.stringify({ any: "payload" })
    });

    expect(response.status).toBe(200);
    expect(updateCustomerByStripeCustomerIdMock).toHaveBeenCalledWith(
      deps.db,
      "cus_2",
      expect.objectContaining({
        payment_status: "past_due",
        current_tier: "tier_1",
        stripe_product_id: "prod_starter"
      })
    );
  });
});
