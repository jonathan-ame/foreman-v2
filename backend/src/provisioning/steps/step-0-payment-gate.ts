import { getCustomerById } from "../../db/customers.js";
import type { StepContext, StepResult } from "./types.js";

const ACTIVE_STATUSES = new Set(["active", "trialing"]);
const DELINQUENT_STATUSES = new Set(["past_due", "canceled", "unpaid"]);
const FAILED_PAYMENT_LOOKBACK_DAYS = 7;

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
        new Date(Date.now() - FAILED_PAYMENT_LOOKBACK_DAYS * 24 * 60 * 60 * 1000)
      )
    : false;
  const prepaidBalanceCents = stripeCustomerId
    ? await ctx.clients.stripe.getPrepaidBalanceCents(stripeCustomerId)
    : (customer.prepaid_balance_cents ?? 0);

  const billingMode = customer.current_billing_mode;
  const activeSubscription = ACTIVE_STATUSES.has(subscriptionStatus);
  const isDelinquent = DELINQUENT_STATUSES.has(subscriptionStatus) || hasFailedPayment;
  const hasBalance = prepaidBalanceCents > 0;

  const tokensConsumedCurrentPeriodCents =
    typeof customer.tokens_consumed_current_period_cents === "number"
      ? customer.tokens_consumed_current_period_cents
      : null;
  const tierAllowanceCents =
    typeof customer.tier_allowance_cents === "number" ? customer.tier_allowance_cents : null;
  const overTierAllowance =
    billingMode === "foreman_managed_tier" &&
    tierAllowanceCents !== null &&
    tokensConsumedCurrentPeriodCents !== null &&
    tokensConsumedCurrentPeriodCents >= tierAllowanceCents;

  let paymentModePasses = false;
  if (billingMode === "foreman_managed_tier") {
    paymentModePasses = activeSubscription;
  } else if (billingMode === "foreman_managed_usage") {
    paymentModePasses = hasBalance;
  } else if (billingMode === "byok") {
    paymentModePasses = activeSubscription;
  }

  if (overTierAllowance) {
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
  if (!paymentModePasses) {
    const reason =
      billingMode === "foreman_managed_usage"
        ? "Insufficient prepaid balance for usage billing mode"
        : "No active platform subscription for current billing mode";
    return {
      ok: false,
      errorCode: "PAYMENT_REQUIRED",
      errorMessage: reason
    };
  }

  return {
    ok: true,
    data: {
      customer,
      payment: {
        billingMode,
        subscriptionStatus,
        hasFailedPayment,
        prepaidBalanceCents,
        activeSubscription,
        tokensConsumedCurrentPeriodCents,
        tierAllowanceCents
      }
    }
  };
}

export async function rollbackStep0PaymentGate(ctx: StepContext): Promise<void> {
  ctx.logger.info("rolling back step_0_payment_gate: no state to rollback");
}
