import type { SupabaseClient } from "./supabase.js";

export interface ChatMessage {
  id: string;
  customer_id: string;
  role: "user" | "assistant";
  content: string;
  created_at: string;
}

export async function listChatMessages(
  db: SupabaseClient,
  customerId: string,
  limit = 100
): Promise<ChatMessage[]> {
  const { data, error } = await db
    .from("chat_messages")
    .select("id, customer_id, role, content, created_at")
    .eq("customer_id", customerId)
    .order("created_at", { ascending: true })
    .limit(limit);

  if (error) {
    throw new Error(`Failed to load chat messages for customer ${customerId}: ${error.message}`);
  }
  return (data ?? []) as ChatMessage[];
}

export async function insertChatMessage(
  db: SupabaseClient,
  customerId: string,
  role: "user" | "assistant",
  content: string
): Promise<ChatMessage> {
  const { data, error } = await db
    .from("chat_messages")
    .insert({ customer_id: customerId, role, content })
    .select("id, customer_id, role, content, created_at")
    .single();

  if (error) {
    throw new Error(`Failed to insert chat message for customer ${customerId}: ${error.message}`);
  }
  return data as ChatMessage;
}
