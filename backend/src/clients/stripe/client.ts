import type { Logger } from "pino";
import Stripe from "stripe";
import { StripeApiError } from "./errors.js";
import type { PaymentIntentResult, PaymentStatus } from "./types.js";

export interface StripeClientConfig {
  mode: "live" | "test";
  liveApiKey: string | undefined;
  testApiKey: string | undefined;
  apiVersion?: "2026-03-25.dahlia";
  logger: Logger;
}

export class StripeClient {
  private readonly stripe: Stripe | null;
  private readonly logger: Logger;

  constructor(config: StripeClientConfig) {
    const apiKey = config.mode === "live" ? config.liveApiKey : config.testApiKey;
    if (!apiKey) {
      this.stripe = null;
      this.logger = config.logger.child({ warn: "no-api-key" });
      this.logger.warn(`Stripe API key missing for mode=${config.mode}; Stripe operations will return stub data`);
      return;
    }
    this.stripe = new Stripe(
      apiKey,
      config.apiVersion ? { apiVersion: config.apiVersion } : {}
    );
    this.logger = config.logger;
  }

  private requireStripe(): Stripe {
    if (!this.stripe) {
      throw new StripeApiError("Stripe is not configured; set STRIPE_SECRET_KEY_TEST in .env");
    }
    return this.stripe;
  }

  async getSubscriptionStatus(stripeCustomerId: string): Promise<PaymentStatus> {
    if (!this.stripe) return "pending";
    try {
      const subscriptions = await this.stripe.subscriptions.list({
        customer: stripeCustomerId,
        status: "all",
        limit: 20
      });
      const latest = subscriptions.data.sort((a, b) => b.created - a.created)[0];
      if (!latest) {
        return "pending";
      }
      return this.normalizeSubscriptionStatus(latest.status);
    } catch (error) {
      throw this.toStripeApiError("Failed to fetch subscription status", error);
    }
  }

  async hasFailedPaymentSince(stripeCustomerId: string, since: Date): Promise<boolean> {
    if (!this.stripe) return false;
    try {
      const events = await this.stripe.events.list({
        type: "invoice.payment_failed",
        created: { gte: Math.floor(since.getTime() / 1000) },
        limit: 100
      });

      return events.data.some((event) => {
        const invoice = event.data.object as Stripe.Invoice;
        return invoice.customer === stripeCustomerId;
      });
    } catch (error) {
      throw this.toStripeApiError("Failed to inspect failed payment events", error);
    }
  }

  async getPrepaidBalanceCents(stripeCustomerId: string): Promise<number> {
    if (!this.stripe) return 0;
    try {
      const customer = await this.stripe.customers.retrieve(stripeCustomerId);
      if (customer.deleted) {
        return 0;
      }
      // Stripe customer.balance is amount owed; negative means credit.
      return Math.max(0, customer.balance * -1);
    } catch (error) {
      throw this.toStripeApiError("Failed to read customer balance", error);
    }
  }

  async createSubscription(stripeCustomerId: string, productId: string): Promise<string> {
    if (!this.stripe) throw new StripeApiError("Stripe not configured");
    try {
      const prices = await this.stripe.prices.list({
        product: productId,
        active: true,
        limit: 20
      });
      const recurringMonthly = prices.data.find(
        (price) => price.recurring?.interval === "month" && price.currency === "usd"
      );
      if (!recurringMonthly) {
        throw new StripeApiError(`No active monthly USD price found for product ${productId}`);
      }

      const subscription = await this.stripe.subscriptions.create({
        customer: stripeCustomerId,
        items: [{ price: recurringMonthly.id }]
      });
      return subscription.id;
    } catch (error) {
      if (error instanceof StripeApiError) {
        throw error;
      }
      throw this.toStripeApiError("Failed to create subscription", error);
    }
  }

  async cancelSubscription(subscriptionId: string): Promise<void> {
    if (!this.stripe) throw new StripeApiError("Stripe not configured");
    try {
      await this.stripe.subscriptions.cancel(subscriptionId);
    } catch (error) {
      throw this.toStripeApiError("Failed to cancel subscription", error);
    }
  }

  async createPaymentIntent(stripeCustomerId: string, amountCents: number): Promise<PaymentIntentResult> {
    if (!this.stripe) throw new StripeApiError("Stripe not configured");
    try {
      const paymentIntent = await this.stripe.paymentIntents.create({
        customer: stripeCustomerId,
        amount: amountCents,
        currency: "usd",
        automatic_payment_methods: { enabled: true }
      });
      return {
        id: paymentIntent.id,
        status: paymentIntent.status,
        clientSecret: paymentIntent.client_secret
      };
    } catch (error) {
      throw this.toStripeApiError("Failed to create payment intent", error);
    }
  }

  async createCustomer(email: string, name: string, internalId: string): Promise<Stripe.Customer> {
    const stripe = this.requireStripe();
    try {
      return await stripe.customers.create({
        email,
        name,
        metadata: { internal_id: internalId }
      });
    } catch (error) {
      throw this.toStripeApiError("Failed to create Stripe customer", error);
    }
  }

  async createCheckoutSession(
    stripeCustomerId: string,
    priceId: string,
    successUrl: string,
    cancelUrl: string
  ): Promise<Stripe.Checkout.Session> {
    const stripe = this.requireStripe();
    try {
      return await stripe.checkout.sessions.create({
        customer: stripeCustomerId,
        mode: "subscription",
        line_items: [{ price: priceId, quantity: 1 }],
        success_url: successUrl,
        cancel_url: cancelUrl
      });
    } catch (error) {
      throw this.toStripeApiError("Failed to create checkout session", error);
    }
  }

  async createPortalSession(stripeCustomerId: string, returnUrl: string): Promise<Stripe.BillingPortal.Session> {
    const stripe = this.requireStripe();
    try {
      return await stripe.billingPortal.sessions.create({
        customer: stripeCustomerId,
        return_url: returnUrl
      });
    } catch (error) {
      throw this.toStripeApiError("Failed to create portal session", error);
    }
  }

  constructWebhookEvent(payload: string, signature: string, webhookSecret: string): Stripe.Event {
    try {
      return this.requireStripe().webhooks.constructEvent(payload, signature, webhookSecret);
    } catch (error) {
      throw this.toStripeApiError("Failed to verify Stripe webhook signature", error);
    }
  }

  private normalizeSubscriptionStatus(status: Stripe.Subscription.Status): PaymentStatus {
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
  }

  private toStripeApiError(message: string, error: unknown): StripeApiError {
    if (error instanceof Stripe.errors.StripeError) {
      const options: { statusCode?: number; errorCode?: string; requestId?: string } = {};
      if (typeof error.statusCode === "number") {
        options.statusCode = error.statusCode;
      }
      if (typeof error.code === "string") {
        options.errorCode = error.code;
      }
      if (typeof error.requestId === "string") {
        options.requestId = error.requestId;
      }
      return new StripeApiError(`${message}: ${error.message}`, options);
    }
    if (error instanceof Error) {
      return new StripeApiError(`${message}: ${error.message}`);
    }
    return new StripeApiError(message);
  }
}
