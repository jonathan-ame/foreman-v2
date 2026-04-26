import type { SupabaseClient } from "./supabase.js";

export interface ComposioSessionRow {
  id: string;
  customer_id: string;
  composio_user_id: string;
  composio_session_id: string;
  mcp_url: string;
  mcp_headers: Record<string, string>;
  toolkits: string[];
  created_at: string;
}

export interface ComposioSessionInsert {
  customer_id: string;
  composio_user_id: string;
  composio_session_id: string;
  mcp_url: string;
  mcp_headers: Record<string, string>;
  toolkits: string[];
}

export interface ComposioConnectionRow {
  id: string;
  customer_id: string;
  composio_connected_account_id: string;
  toolkit_slug: string;
  toolkit_name: string | null;
  status: string;
  created_at: string;
  updated_at: string;
}

export interface ComposioConnectionInsert {
  customer_id: string;
  composio_connected_account_id: string;
  toolkit_slug: string;
  toolkit_name?: string;
  status?: string;
}

export interface ComposioTriggerRow {
  id: string;
  customer_id: string;
  composio_trigger_id: string;
  trigger_type: string;
  toolkit_slug: string;
  config: Record<string, unknown>;
  status: string;
  created_at: string;
  updated_at: string;
}

export interface ComposioTriggerInsert {
  customer_id: string;
  composio_trigger_id: string;
  trigger_type: string;
  toolkit_slug: string;
  config: Record<string, unknown>;
  status?: string;
}

export async function insertComposioSession(
  db: SupabaseClient,
  record: ComposioSessionInsert
): Promise<ComposioSessionRow> {
  const { data, error } = await db
    .from("composio_sessions")
    .insert(record)
    .select("*")
    .single();
  if (error) {
    throw new Error(`Failed to insert composio session: ${error.message}`);
  }
  return data as ComposioSessionRow;
}

export async function getComposioSessionByCustomer(
  db: SupabaseClient,
  customerId: string
): Promise<ComposioSessionRow | null> {
  const { data, error } = await db
    .from("composio_sessions")
    .select("*")
    .eq("customer_id", customerId)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) {
    throw new Error(`Failed to query composio session: ${error.message}`);
  }
  return data as ComposioSessionRow | null;
}

export async function insertComposioConnection(
  db: SupabaseClient,
  record: ComposioConnectionInsert
): Promise<ComposioConnectionRow> {
  const { data, error } = await db
    .from("composio_connections")
    .insert(record)
    .select("*")
    .single();
  if (error) {
    throw new Error(`Failed to insert composio connection: ${error.message}`);
  }
  return data as ComposioConnectionRow;
}

export async function listComposioConnections(
  db: SupabaseClient,
  customerId: string
): Promise<ComposioConnectionRow[]> {
  const { data, error } = await db
    .from("composio_connections")
    .select("*")
    .eq("customer_id", customerId)
    .eq("status", "active")
    .order("created_at", { ascending: false });
  if (error) {
    throw new Error(`Failed to list composio connections: ${error.message}`);
  }
  return (data ?? []) as ComposioConnectionRow[];
}

export async function deleteComposioConnection(
  db: SupabaseClient,
  customerId: string,
  connectedAccountId: string
): Promise<void> {
  const { error } = await db
    .from("composio_connections")
    .update({ status: "disconnected", updated_at: new Date().toISOString() })
    .eq("customer_id", customerId)
    .eq("composio_connected_account_id", connectedAccountId);
  if (error) {
    throw new Error(`Failed to delete composio connection: ${error.message}`);
  }
}

export async function insertComposioTrigger(
  db: SupabaseClient,
  record: ComposioTriggerInsert
): Promise<ComposioTriggerRow> {
  const { data, error } = await db
    .from("composio_triggers")
    .insert(record)
    .select("*")
    .single();
  if (error) {
    throw new Error(`Failed to insert composio trigger: ${error.message}`);
  }
  return data as ComposioTriggerRow;
}

export async function listComposioTriggers(
  db: SupabaseClient,
  customerId: string
): Promise<ComposioTriggerRow[]> {
  const { data, error } = await db
    .from("composio_triggers")
    .select("*")
    .eq("customer_id", customerId)
    .eq("status", "active")
    .order("created_at", { ascending: false });
  if (error) {
    throw new Error(`Failed to list composio triggers: ${error.message}`);
  }
  return (data ?? []) as ComposioTriggerRow[];
}

export async function deleteComposioTrigger(
  db: SupabaseClient,
  customerId: string,
  triggerId: string
): Promise<void> {
  const { error } = await db
    .from("composio_triggers")
    .update({ status: "deleted", updated_at: new Date().toISOString() })
    .eq("customer_id", customerId)
    .eq("composio_trigger_id", triggerId);
  if (error) {
    throw new Error(`Failed to delete composio trigger: ${error.message}`);
  }
}
