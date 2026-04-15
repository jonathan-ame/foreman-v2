import type { ProvisioningResult } from "../provisioning/types.js";
import type { SupabaseClient } from "./supabase.js";

export async function getCachedResult(
  db: SupabaseClient,
  idempotencyKey: string,
  customerId: string
): Promise<ProvisioningResult | null> {
  const { data, error } = await db
    .from("provisioning_idempotency")
    .select("result, expires_at")
    .eq("idempotency_key", idempotencyKey)
    .eq("customer_id", customerId)
    .maybeSingle();

  if (error) {
    throw new Error(`Failed to read idempotency cache: ${error.message}`);
  }
  if (!data) {
    return null;
  }

  const expiresAt = new Date(data.expires_at as string);
  if (Number.isNaN(expiresAt.getTime()) || expiresAt <= new Date()) {
    return null;
  }
  return data.result as ProvisioningResult;
}

export async function cacheResult(
  db: SupabaseClient,
  idempotencyKey: string,
  customerId: string,
  result: ProvisioningResult
): Promise<void> {
  const { error } = await db.from("provisioning_idempotency").upsert(
    {
      idempotency_key: idempotencyKey,
      customer_id: customerId,
      result
    },
    {
      onConflict: "idempotency_key,customer_id"
    }
  );

  if (error) {
    throw new Error(`Failed to write idempotency cache: ${error.message}`);
  }
}
