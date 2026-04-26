import type { Hono } from "hono";
import { z } from "zod";
import { resolveSessionCustomerId } from "../auth/session.js";
import type { AppDeps } from "../app-deps.js";
import { getCustomerById } from "../db/customers.js";

const CheckoutSchema = z.object({
  priceId: z.string().min(1),
  tier: z.enum(["tier_1", "tier_2", "tier_3", "byok_platform"])
});

const PORTAL_RETURN_URL = "/dashboard/settings";

export function registerBillingRoutes(app: Hono, deps: AppDeps) {
  app.post("/api/internal/billing/checkout", async (c) => {
    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    if (!sessionCustomerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const body = await c.req.json();
    const parsed = CheckoutSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 422);
    }

    const customer = await getCustomerById(deps.db, sessionCustomerId);
    if (!customer) {
      return c.json({ error: "customer_not_found" }, 404);
    }

    let stripeCustomerId = customer.stripe_customer_id;
    if (!stripeCustomerId) {
      const stripeCustomer = await deps.clients.stripe.createCustomer(
        customer.email,
        customer.display_name,
        customer.customer_id
      );
      stripeCustomerId = stripeCustomer.id;
      await deps.db
        .from("customers")
        .update({ stripe_customer_id: stripeCustomerId })
        .eq("customer_id", customer.customer_id);
    }

    const priceMapping: Record<string, string> = {
      tier_1: deps.env.STRIPE_PRICE_TIER_1_ACTIVE,
      tier_2: deps.env.STRIPE_PRICE_TIER_2_ACTIVE,
      tier_3: deps.env.STRIPE_PRICE_TIER_3_ACTIVE,
      byok_platform: deps.env.STRIPE_PRICE_BYOK_PLATFORM_ACTIVE
    };

    const priceIdFromTier = priceMapping[parsed.data.tier];
    const effectivePriceId = parsed.data.priceId || priceIdFromTier;
    if (!effectivePriceId) {
      return c.json({ error: "price_not_configured", tier: parsed.data.tier }, 400);
    }

    const baseUrl = deps.env.FOREMAN_BASE_URL || "https://foreman.company";
    const session = await deps.clients.stripe.createCheckoutSession(
      stripeCustomerId,
      effectivePriceId,
      `${baseUrl}/dashboard?checkout=success`,
      `${baseUrl}/pricing?checkout=canceled`
    );

    return c.json({ url: session.url }, 200);
  });

  app.get("/api/internal/billing/portal", async (c) => {
    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    if (!sessionCustomerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const customer = await getCustomerById(deps.db, sessionCustomerId);
    if (!customer || !customer.stripe_customer_id) {
      return c.json({ error: "no_stripe_customer" }, 404);
    }

    const baseUrl = deps.env.FOREMAN_BASE_URL || "https://foreman.company";
    const session = await deps.clients.stripe.createPortalSession(
      customer.stripe_customer_id,
      `${baseUrl}${PORTAL_RETURN_URL}`
    );

    return c.json({ url: session.url }, 200);
  });
}