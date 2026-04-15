import { getCustomerById } from "../../db/customers.js";
import type { StepContext, StepResult } from "./types.js";

const ACTIVE_STATUSES = new Set(["active", "trialing"]);
const DELINQUENT_STATUSES = new Set(["past_due", "canceled"]);

export async function step0PaymentGate(ctx: StepContext): Promise<StepResult> {
  const customer = await getCustomerById(ctx.db, ctx.input.customerId);
  if (!customer) {
    return {
      ok: false,
      errorCode: "CUSTOMER_NOT_FOUND",
      errorMessage: "Customer not found during payment gate"
    };
  }

  const stripeCustomerId = customer.stripe_customer_id;
  const subscriptionStatus = stripeCustomerId
    ? await ctx.clients.stripe.getSubscriptionStatus(stripeCustomerId)
    : "pending";
  const hasFailedPayment = stripeCustomerId
    ? await ctx.clients.stripe.hasFailedPaymentSince(
        stripeCustomerId,
        new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
      )
    : false;
  const prepaidBalanceCents = stripeCustomerId
    ? await ctx.clients.stripe.getPrepaidBalanceCents(stripeCustomerId)
    : (customer.prepaid_balance_cents ?? 0);

  const activeSubscription = ACTIVE_STATUSES.has(subscriptionStatus);
  const hasBalance = prepaidBalanceCents > 0;
  const isDelinquent = DELINQUENT_STATUSES.has(subscriptionStatus) || hasFailedPayment;
  const withinTierAllowance = true;

  if (!withinTierAllowance) {
    return {
      ok: false,
      errorCode: "PAYMENT_TIER_LIMIT",
      errorMessage: "Tier allowance exceeded"
    };
  }
  if (isDelinquent) {
    return {
      ok: false,
      errorCode: "PAYMENT_DELINQUENT",
      errorMessage: "Customer payment status is delinquent"
    };
  }
  if (!activeSubscription && !hasBalance) {
    return {
      ok: false,
      errorCode: "PAYMENT_REQUIRED",
      errorMessage: "No active subscription and no prepaid balance"
    };
  }

  return {
    ok: true,
    data: {
      customer,
      payment: {
        subscriptionStatus,
        hasFailedPayment,
        prepaidBalanceCents,
        activeSubscription
      }
    }
  };
}

export async function rollbackStep0PaymentGate(ctx: StepContext): Promise<void> {
  ctx.logger.info("rolling back step_0_payment_gate: no state to rollback");
}
