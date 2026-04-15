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
