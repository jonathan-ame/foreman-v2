import type { SupabaseClient } from "./supabase.js";

export interface Customer {
  customer_id: string;
  workspace_slug: string;
  email: string;
  display_name: string;
  stripe_customer_id: string | null;
  current_billing_mode: string;
  current_tier: string | null;
  byok_key_encrypted: string | null;
  byok_fallback_enabled: boolean;
  prepaid_balance_cents: number | null;
  payment_status: string;
  paperclip_company_id: string | null;
  stripe_subscription_id?: string | null;
  stripe_product_id?: string | null;
  tokens_consumed_current_period_cents?: number | null;
  tier_allowance_cents?: number | null;
}

export interface CustomerStripeBillingUpdate {
  payment_status?: string;
  current_tier?: string | null;
  stripe_subscription_id?: string | null;
  stripe_product_id?: string | null;
}

export async function getCustomerById(db: SupabaseClient, customerId: string): Promise<Customer | null> {
  const { data, error } = await db
    .from("customers")
    .select("*")
    .eq("customer_id", customerId)
    .maybeSingle();

  if (error) {
    throw new Error(`Failed to load customer ${customerId}: ${error.message}`);
  }
  return data as Customer | null;
}

export async function updateCustomerByStripeCustomerId(
  db: SupabaseClient,
  stripeCustomerId: string,
  updates: CustomerStripeBillingUpdate
): Promise<Customer | null> {
  const { data, error } = await db
    .from("customers")
    .update(updates)
    .eq("stripe_customer_id", stripeCustomerId)
    .select("*")
    .maybeSingle();

  if (error) {
    throw new Error(`Failed to update customer by stripe_customer_id ${stripeCustomerId}: ${error.message}`);
  }
  return data as Customer | null;
}
