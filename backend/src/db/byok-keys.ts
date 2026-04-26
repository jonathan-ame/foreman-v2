import type { SupabaseClient } from "./supabase.js";

export type ByokProvider = "openrouter" | "together" | "deepinfra" | "dashscope" | "openai";

export interface ByokKey {
  id: string;
  customer_id: string;
  provider: ByokProvider;
  key_encrypted: string;
  key_prefix: string;
  label: string | null;
  is_valid: boolean;
  last_validated_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface ByokKeyPublic {
  id: string;
  provider: ByokProvider;
  key_prefix: string;
  label: string | null;
  is_valid: boolean;
  last_validated_at: string | null;
  created_at: string;
  updated_at: string;
}

export function byokKeyToPublic(key: ByokKey): ByokKeyPublic {
  return {
    id: key.id,
    provider: key.provider,
    key_prefix: key.key_prefix,
    label: key.label,
    is_valid: key.is_valid,
    last_validated_at: key.last_validated_at,
    created_at: key.created_at,
    updated_at: key.updated_at
  };
}

export async function listByokKeys(db: SupabaseClient, customerId: string): Promise<ByokKey[]> {
  const { data, error } = await db
    .from("byok_keys")
    .select("*")
    .eq("customer_id", customerId)
    .order("created_at", { ascending: true });

  if (error) {
    throw new Error(`Failed to list BYOK keys for customer ${customerId}: ${error.message}`);
  }
  return (data ?? []) as ByokKey[];
}

export async function getByokKeyById(db: SupabaseClient, keyId: string): Promise<ByokKey | null> {
  const { data, error } = await db
    .from("byok_keys")
    .select("*")
    .eq("id", keyId)
    .maybeSingle();

  if (error) {
    throw new Error(`Failed to get BYOK key ${keyId}: ${error.message}`);
  }
  return data as ByokKey | null;
}

export async function getByokKeyByProvider(
  db: SupabaseClient,
  customerId: string,
  provider: ByokProvider
): Promise<ByokKey | null> {
  const { data, error } = await db
    .from("byok_keys")
    .select("*")
    .eq("customer_id", customerId)
    .eq("provider", provider)
    .maybeSingle();

  if (error) {
    throw new Error(`Failed to get BYOK key for customer ${customerId} provider ${provider}: ${error.message}`);
  }
  return data as ByokKey | null;
}

export async function upsertByokKey(
  db: SupabaseClient,
  input: {
    customerId: string;
    provider: ByokProvider;
    keyEncrypted: string;
    keyPrefix: string;
    label?: string;
    isValid?: boolean;
  }
): Promise<ByokKey> {
  const row = {
    customer_id: input.customerId,
    provider: input.provider,
    key_encrypted: input.keyEncrypted,
    key_prefix: input.keyPrefix,
    label: input.label ?? null,
    is_valid: input.isValid ?? true,
    last_validated_at: new Date().toISOString()
  };

  const { data, error } = await db
    .from("byok_keys")
    .upsert(row, { onConflict: "customer_id,provider" })
    .select("*")
    .single();

  if (error) {
    throw new Error(`Failed to upsert BYOK key for customer ${input.customerId} provider ${input.provider}: ${error.message}`);
  }
  return data as ByokKey;
}

export async function deleteByokKey(db: SupabaseClient, keyId: string): Promise<void> {
  const { error } = await db
    .from("byok_keys")
    .delete()
    .eq("id", keyId);

  if (error) {
    throw new Error(`Failed to delete BYOK key ${keyId}: ${error.message}`);
  }
}

export async function updateByokKeyValidity(
  db: SupabaseClient,
  keyId: string,
  isValid: boolean
): Promise<ByokKey | null> {
  const { data, error } = await db
    .from("byok_keys")
    .update({
      is_valid: isValid,
      last_validated_at: new Date().toISOString()
    })
    .eq("id", keyId)
    .select("*")
    .maybeSingle();

  if (error) {
    throw new Error(`Failed to update BYOK key validity for ${keyId}: ${error.message}`);
  }
  return data as ByokKey | null;
}

export async function listAllValidByokKeys(db: SupabaseClient): Promise<ByokKey[]> {
  const { data, error } = await db
    .from("byok_keys")
    .select("*")
    .eq("is_valid", true);

  if (error) {
    throw new Error(`Failed to list all valid BYOK keys: ${error.message}`);
  }
  return (data ?? []) as ByokKey[];
}

export async function countByokKeys(db: SupabaseClient, customerId: string): Promise<number> {
  const { count, error } = await db
    .from("byok_keys")
    .select("*", { count: "exact", head: true })
    .eq("customer_id", customerId);

  if (error) {
    throw new Error(`Failed to count BYOK keys for customer ${customerId}: ${error.message}`);
  }
  return count ?? 0;
}