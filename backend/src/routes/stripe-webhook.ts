import type { Hono } from "hono";
import type Stripe from "stripe";
import type { AppDeps } from "../app-deps.js";
import { updateCustomerByStripeCustomerId, type CustomerStripeBillingUpdate } from "../db/customers.js";

const toStripeCustomerId = (value: string | Stripe.Customer | Stripe.DeletedCustomer | null): string | null => {
  if (!value) {
    return null;
  }
  return typeof value === "string" ? value : value.id;
};

const normalizeSubscriptionStatus = (status: Stripe.Subscription.Status): string => {
  if (status === "active") {
    return "active";
  }
  if (status === "trialing") {
    return "trialing";
  }
  if (status === "past_due" || status === "unpaid") {
    return "past_due";
  }
  if (status === "canceled" || status === "incomplete_expired") {
    return "canceled";
  }
  return "pending";
};

const resolvePriceIdFromInvoice = (invoice: Stripe.Invoice): string | null => {
  const firstLine = invoice.lines.data[0] as
    | {
        price?: { id?: string };
        pricing?: { price_details?: { price?: string } };
      }
    | undefined;
  if (!firstLine) {
    return null;
  }
  if (typeof firstLine.price?.id === "string") {
    return firstLine.price.id;
  }
  const pricingPriceId = firstLine.pricing?.price_details?.price;
  return typeof pricingPriceId === "string" ? pricingPriceId : null;
};

const resolveProductIdFromInvoice = (invoice: Stripe.Invoice): string | null => {
  const firstLine = invoice.lines.data[0] as
    | {
        price?: { product?: string | { id?: string } };
      }
    | undefined;
  const price = firstLine?.price;
  if (!price) {
    return null;
  }
  return typeof price.product === "string" ? price.product : (price.product?.id ?? null);
};

const resolveTierFromPriceId = (priceId: string | null, deps: AppDeps): string | null => {
  if (!priceId) {
    return null;
  }
  const priceToTier: Record<string, string> = {
    [deps.env.STRIPE_PRICE_TIER_1_ACTIVE]: "tier_1",
    [deps.env.STRIPE_PRICE_TIER_2_ACTIVE]: "tier_2",
    [deps.env.STRIPE_PRICE_TIER_3_ACTIVE]: "tier_3",
    [deps.env.STRIPE_PRICE_BYOK_PLATFORM_ACTIVE]: "byok_platform"
  };
  return priceToTier[priceId] ?? null;
};

async function applyCustomerUpdate(
  deps: AppDeps,
  stripeCustomerId: string,
  updates: CustomerStripeBillingUpdate,
  event: Stripe.Event
): Promise<void> {
  const cleanUpdates = Object.fromEntries(
    Object.entries(updates).filter(([, value]) => value !== undefined)
  ) as CustomerStripeBillingUpdate;
  const updated = await updateCustomerByStripeCustomerId(deps.db, stripeCustomerId, cleanUpdates);
  if (!updated) {
    deps.logger.warn(
      { stripeCustomerId, updates: cleanUpdates, eventId: event.id, eventType: event.type },
      "stripe webhook event ignored because no matching customer was found"
    );
  }
}

async function markStripeEventProcessed(
  deps: AppDeps,
  eventId: string,
  eventType: string,
  livemode: boolean
): Promise<void> {
  await deps.db.from("stripe_webhook_events").insert({
    stripe_event_id: eventId,
    event_type: eventType,
    livemode
  });
}

async function isStripeEventAlreadyProcessed(deps: AppDeps, eventId: string): Promise<boolean> {
  const { data } = await deps.db
    .from("stripe_webhook_events")
    .select("stripe_event_id")
    .eq("stripe_event_id", eventId)
    .maybeSingle();
  return data !== null;
}

export function registerStripeWebhookRoutes(app: Hono, deps: AppDeps) {
  app.post("/api/internal/webhooks/stripe", async (c) => {
    const signature = c.req.header("stripe-signature");
    if (!signature) {
      return c.json({ error: "missing_stripe_signature" }, 400);
    }

    const payload = await c.req.text();
    let event: Stripe.Event;
    try {
      event = deps.clients.stripe.constructWebhookEvent(
        payload,
        signature,
        deps.env.STRIPE_WEBHOOK_SECRET_ACTIVE
      );
    } catch (error) {
      deps.logger.error({ err: error }, "failed to verify stripe webhook signature");
      return c.json({ error: "invalid_signature" }, 400);
    }

    // In production, reject test-mode events to prevent accidental test data pollution.
    if (deps.env.NODE_ENV === "production" && !event.livemode) {
      deps.logger.warn(
        { eventId: event.id, eventType: event.type },
        "rejecting test-mode stripe event in production"
      );
      return c.json({ error: "test_mode_event_rejected" }, 400);
    }

    // Idempotency: skip events we have already processed.
    const alreadyProcessed = await isStripeEventAlreadyProcessed(deps, event.id);
    if (alreadyProcessed) {
      deps.logger.info(
        { eventId: event.id, eventType: event.type },
        "stripe event already processed — skipping"
      );
      return c.json({ received: true, duplicate: true }, 200);
    }

    deps.logger.info(
      { eventId: event.id, eventType: event.type, livemode: event.livemode },
      "received stripe webhook event"
    );

    switch (event.type) {
      case "customer.subscription.created":
      case "customer.subscription.updated":
      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription;
        const stripeCustomerId = toStripeCustomerId(subscription.customer);
        if (!stripeCustomerId) {
          break;
        }
        const item = subscription.items.data[0];
        const priceId = item?.price?.id ?? null;
        const productId = item?.price
          ? (typeof item.price.product === "string" ? item.price.product : (item.price.product?.id ?? null))
          : null;
        await applyCustomerUpdate(
          deps,
          stripeCustomerId,
          {
            payment_status: normalizeSubscriptionStatus(subscription.status),
            current_tier: resolveTierFromPriceId(priceId, deps),
            stripe_subscription_id: subscription.id,
            stripe_product_id: productId
          },
          event
        );
        break;
      }
      case "invoice.payment_failed":
      case "invoice.payment_succeeded": {
        const invoice = event.data.object as Stripe.Invoice;
        const stripeCustomerId = toStripeCustomerId(invoice.customer);
        if (!stripeCustomerId) {
          break;
        }
        const priceId = resolvePriceIdFromInvoice(invoice);
        await applyCustomerUpdate(
          deps,
          stripeCustomerId,
          {
            payment_status: event.type === "invoice.payment_succeeded" ? "active" : "past_due",
            current_tier: resolveTierFromPriceId(priceId, deps),
            stripe_product_id: resolveProductIdFromInvoice(invoice)
          },
          event
        );
        break;
      }
      case "payment_intent.succeeded": {
        const paymentIntent = event.data.object as Stripe.PaymentIntent;
        const stripeCustomerId = toStripeCustomerId(paymentIntent.customer);
        if (!stripeCustomerId) {
          break;
        }
        await applyCustomerUpdate(
          deps,
          stripeCustomerId,
          {
            payment_status: "active"
          },
          event
        );
        break;
      }
      default:
        break;
    }

    // Record as processed so retries are deduplicated.
    await markStripeEventProcessed(deps, event.id, event.type, event.livemode);

    return c.json({ received: true }, 200);
  });
}
