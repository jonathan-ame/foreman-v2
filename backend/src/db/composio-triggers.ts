import type { SupabaseClient } from "./supabase.js";

export async function getComposioTriggerByComposioId(
  db: SupabaseClient,
  composioTriggerId: string
): Promise<{ customer_id: string; trigger_type: string; toolkit_slug: string; config: Record<string, unknown> } | null> {
  const { data, error } = await db
    .from("composio_triggers")
    .select("customer_id, trigger_type, toolkit_slug, config")
    .eq("composio_trigger_id", composioTriggerId)
    .eq("status", "active")
    .maybeSingle();
  if (error) {
    throw new Error(`Failed to look up composio trigger ${composioTriggerId}: ${error.message}`);
  }
  return data as { customer_id: string; trigger_type: string; toolkit_slug: string; config: Record<string, unknown> } | null;
}