import type { SupabaseClient } from "./supabase.js";

export interface CustomerSession {
  session_id: string;
  customer_id: string;
  token: string;
  expires_at: string;
  created_at: string;
}

interface CreateSessionInput {
  sessionId: string;
  customerId: string;
  token: string;
  expiresAt: string;
}

export async function createSession(db: SupabaseClient, input: CreateSessionInput): Promise<CustomerSession> {
  const { data, error } = await db
    .from("customer_sessions")
    .insert({
      session_id: input.sessionId,
      customer_id: input.customerId,
      token: input.token,
      expires_at: input.expiresAt
    })
    .select("*")
    .single();

  if (error) {
    throw new Error(`Failed to create customer session for ${input.customerId}: ${error.message}`);
  }
  return data as CustomerSession;
}

export async function getSessionByToken(db: SupabaseClient, token: string): Promise<CustomerSession | null> {
  const { data, error } = await db
    .from("customer_sessions")
    .select("*")
    .eq("token", token)
    .gt("expires_at", new Date().toISOString())
    .maybeSingle();

  if (error) {
    throw new Error(`Failed to load customer session: ${error.message}`);
  }
  return data as CustomerSession | null;
}

export async function deleteSessionByToken(db: SupabaseClient, token: string): Promise<void> {
  const { error } = await db.from("customer_sessions").delete().eq("token", token);
  if (error) {
    throw new Error(`Failed to delete customer session: ${error.message}`);
  }
}
