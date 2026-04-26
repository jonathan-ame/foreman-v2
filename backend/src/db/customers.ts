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
  auth_user_id: string | null;
  agent_approval_mode: string;
  onboarding_progress: Record<string, string> | null;
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
  const { data: keyRows, error: keyError } = await db
    .from("byok_keys")
    .select("customer_id")
    .eq("is_valid", true);

  if (keyError) {
    throw new Error(`Failed to list BYOK customer IDs: ${keyError.message}`);
  }

  const customerIds = [...new Set((keyRows ?? []).map((r: { customer_id: string }) => r.customer_id))];
  if (customerIds.length === 0) {
    return [];
  }

  const { data, error } = await db
    .from("customers")
    .select("*")
    .eq("current_billing_mode", "byok")
    .eq("payment_status", "active")
    .in("customer_id", customerIds);

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

export async function getCustomerByAuthUserId(db: SupabaseClient, authUserId: string): Promise<Customer | null> {
  const { data, error } = await db
    .from("customers")
    .select("*")
    .eq("auth_user_id", authUserId)
    .maybeSingle();

  if (error) {
    throw new Error(`Failed to load customer by auth_user_id ${authUserId}: ${error.message}`);
  }
  return data as Customer | null;
}

export async function upsertCustomerFromAuth(
  db: SupabaseClient,
  input: {
    authUserId: string;
    email: string;
    displayName: string;
  }
): Promise<Customer> {
  const existing = await getCustomerByAuthUserId(db, input.authUserId);
  if (existing) {
    return existing;
  }

  const existingByEmail = await getCustomerByEmail(db, input.email.toLowerCase());
  if (existingByEmail) {
    const { data, error } = await db
      .from("customers")
      .update({ auth_user_id: input.authUserId })
      .eq("customer_id", existingByEmail.customer_id)
      .select("*")
      .single();
    if (error) {
      throw new Error(`Failed to link auth_user_id to existing customer ${existingByEmail.customer_id}: ${error.message}`);
    }
    return data as Customer;
  }

  const workspaceSlug = input.email.toLowerCase().replace(/[^a-z0-9]/g, "-").replace(/-+/g, "-").replace(/^-|-$/g, "") + "-" + input.authUserId.slice(0, 8);
  const row = {
    customer_id: crypto.randomUUID(),
    workspace_slug: workspaceSlug,
    email: input.email.toLowerCase(),
    display_name: input.displayName,
    current_billing_mode: "trial",
    current_tier: null,
    payment_status: "trial",
    auth_user_id: input.authUserId
  };

  const { data, error } = await db.from("customers").insert(row).select("*").single();
  if (error) {
    throw new Error(`Failed to create customer from auth signup: ${error.message}`);
  }
  return data as Customer;
}
