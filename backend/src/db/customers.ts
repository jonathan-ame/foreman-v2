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
  byok_using_fallback: boolean;
  prepaid_balance_cents: number | null;
  payment_status: string;
  paperclip_company_id: string | null;
  stripe_subscription_id?: string | null;
  stripe_product_id?: string | null;
  tokens_consumed_current_period_cents?: number | null;
  tier_allowance_cents?: number | null;
}

export interface ByokFallbackEvent {
  workspace_slug: string;
  first_fallback_at: string;
  last_fallback_at: string;
  last_email_notified_at: string | null;
  fallback_count: number;
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

export async function getCustomerByEmail(db: SupabaseClient, email: string): Promise<Customer | null> {
  const { data, error } = await db.from("customers").select("*").eq("email", email).maybeSingle();

  if (error) {
    throw new Error(`Failed to load customer by email ${email}: ${error.message}`);
  }
  return data as Customer | null;
}

export async function listActiveByokCustomers(db: SupabaseClient): Promise<Customer[]> {
  const { data, error } = await db
    .from("customers")
    .select("*")
    .eq("current_billing_mode", "byok")
    .eq("payment_status", "active")
    .not("byok_key_encrypted", "is", null);

  if (error) {
    throw new Error(`Failed to list BYOK customers: ${error.message}`);
  }
  return (data ?? []) as Customer[];
}

export async function setCustomerByokFallback(
  db: SupabaseClient,
  workspaceSlug: string,
  usingFallback: boolean
): Promise<void> {
  const { error } = await db
    .from("customers")
    .update({ byok_using_fallback: usingFallback })
    .eq("workspace_slug", workspaceSlug);
  if (error) {
    throw new Error(`Failed to set byok_using_fallback for workspace ${workspaceSlug}: ${error.message}`);
  }
}

export async function getByokFallbackEvent(
  db: SupabaseClient,
  workspaceSlug: string
): Promise<ByokFallbackEvent | null> {
  const { data, error } = await db
    .from("byok_fallback_events")
    .select("*")
    .eq("workspace_slug", workspaceSlug)
    .maybeSingle();
  if (error) {
    throw new Error(`Failed to get byok fallback event for workspace ${workspaceSlug}: ${error.message}`);
  }
  return data as ByokFallbackEvent | null;
}

export async function upsertByokFallbackEvent(
  db: SupabaseClient,
  workspaceSlug: string,
  now: string
): Promise<ByokFallbackEvent> {
  const existing = await getByokFallbackEvent(db, workspaceSlug);
  if (existing) {
    const updated = {
      last_fallback_at: now,
      fallback_count: existing.fallback_count + 1
    };
    const { data, error } = await db
      .from("byok_fallback_events")
      .update(updated)
      .eq("workspace_slug", workspaceSlug)
      .select("*")
      .single();
    if (error) {
      throw new Error(`Failed to update byok fallback event for workspace ${workspaceSlug}: ${error.message}`);
    }
    return data as ByokFallbackEvent;
  }
  const inserted = {
    workspace_slug: workspaceSlug,
    first_fallback_at: now,
    last_fallback_at: now,
    last_email_notified_at: null,
    fallback_count: 1
  };
  const { data, error } = await db
    .from("byok_fallback_events")
    .insert(inserted)
    .select("*")
    .single();
  if (error) {
    throw new Error(`Failed to insert byok fallback event for workspace ${workspaceSlug}: ${error.message}`);
  }
  return data as ByokFallbackEvent;
}

export async function markByokFallbackEmailSent(
  db: SupabaseClient,
  workspaceSlug: string,
  sentAt: string
): Promise<void> {
  const { error } = await db
    .from("byok_fallback_events")
    .update({ last_email_notified_at: sentAt })
    .eq("workspace_slug", workspaceSlug);
  if (error) {
    throw new Error(`Failed to mark email sent for workspace ${workspaceSlug}: ${error.message}`);
  }
}

export async function deleteByokFallbackEvent(db: SupabaseClient, workspaceSlug: string): Promise<void> {
  const { error } = await db
    .from("byok_fallback_events")
    .delete()
    .eq("workspace_slug", workspaceSlug);
  if (error) {
    throw new Error(`Failed to delete byok fallback event for workspace ${workspaceSlug}: ${error.message}`);
  }
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
