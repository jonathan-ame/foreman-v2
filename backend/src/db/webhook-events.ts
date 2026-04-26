import type { SupabaseClient } from "./supabase.js";

export type WebhookEventStatus = "pending" | "processing" | "completed" | "failed";
export type DeliveryStatus = "pending" | "sent" | "delivered" | "failed";

export interface WebhookEventRow {
  id: string;
  trigger_id: string;
  trigger_type: string;
  toolkit: string | null;
  payload: Record<string, unknown>;
  customer_id: string | null;
  received_at: string;
  processed_at: string | null;
  processing_status: WebhookEventStatus;
  error_message: string | null;
  created_at: string;
}

export interface WebhookEventInsert {
  trigger_id: string;
  trigger_type: string;
  toolkit?: string | null;
  payload: Record<string, unknown>;
  customer_id?: string | null;
  processing_status?: WebhookEventStatus;
}

export interface WebhookDeliveryRow {
  id: string;
  webhook_event_id: string;
  handler_type: string;
  status: DeliveryStatus;
  attempts: number;
  last_attempt_at: string | null;
  error_message: string | null;
  result: Record<string, unknown> | null;
  created_at: string;
}

export interface WebhookDeliveryInsert {
  webhook_event_id: string;
  handler_type: string;
  status?: DeliveryStatus;
  result?: Record<string, unknown> | null;
  error_message?: string | null;
}

export async function insertWebhookEvent(
  db: SupabaseClient,
  record: WebhookEventInsert
): Promise<WebhookEventRow> {
  const { data, error } = await db
    .from("composio_webhook_events")
    .insert(record)
    .select("*")
    .single();
  if (error) {
    throw new Error(`Failed to insert webhook event: ${error.message}`);
  }
  return data as WebhookEventRow;
}

export async function getWebhookEventByTriggerId(
  db: SupabaseClient,
  triggerId: string
): Promise<WebhookEventRow | null> {
  const { data, error } = await db
    .from("composio_webhook_events")
    .select("*")
    .eq("trigger_id", triggerId)
    .order("received_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) {
    throw new Error(`Failed to query webhook event by trigger_id: ${error.message}`);
  }
  return data as WebhookEventRow | null;
}

export async function updateWebhookEventStatus(
  db: SupabaseClient,
  eventId: string,
  status: WebhookEventStatus,
  opts?: { errorMessage?: string }
): Promise<void> {
  const patch: Record<string, unknown> = {
    processing_status: status,
    ...(status === "completed" || status === "failed"
      ? { processed_at: new Date().toISOString() }
      : {}),
    ...(opts?.errorMessage ? { error_message: opts.errorMessage } : {})
  };
  const { error } = await db
    .from("composio_webhook_events")
    .update(patch)
    .eq("id", eventId);
  if (error) {
    throw new Error(`Failed to update webhook event status: ${error.message}`);
  }
}

export async function insertWebhookDelivery(
  db: SupabaseClient,
  record: WebhookDeliveryInsert
): Promise<WebhookDeliveryRow> {
  const { data, error } = await db
    .from("composio_webhook_deliveries")
    .insert(record)
    .select("*")
    .single();
  if (error) {
    throw new Error(`Failed to insert webhook delivery: ${error.message}`);
  }
  return data as WebhookDeliveryRow;
}

export async function updateWebhookDeliveryStatus(
  db: SupabaseClient,
  deliveryId: string,
  status: DeliveryStatus,
  opts?: { errorMessage?: string; result?: Record<string, unknown> }
): Promise<void> {
  const patch: Record<string, unknown> = {
    status,
    last_attempt_at: new Date().toISOString(),
    attempts: 1,
    ...(opts?.errorMessage ? { error_message: opts.errorMessage } : {}),
    ...(opts?.result ? { result: opts.result } : {})
  };

  const { error } = await db
    .from("composio_webhook_deliveries")
    .update(patch)
    .eq("id", deliveryId);
  if (error) {
    throw new Error(`Failed to update webhook delivery status: ${error.message}`);
  }
}

export async function incrementWebhookDeliveryAttempts(
  db: SupabaseClient,
  deliveryId: string,
  status: DeliveryStatus,
  opts?: { errorMessage?: string; result?: Record<string, unknown> }
): Promise<void> {
  const { data: existing, error: fetchError } = await db
    .from("composio_webhook_deliveries")
    .select("attempts")
    .eq("id", deliveryId)
    .single();
  if (fetchError) {
    throw new Error(`Failed to fetch delivery for retry increment: ${fetchError.message}`);
  }

  const patch: Record<string, unknown> = {
    status,
    attempts: (existing?.attempts ?? 0) + 1,
    last_attempt_at: new Date().toISOString(),
    ...(opts?.errorMessage ? { error_message: opts.errorMessage } : {}),
    ...(opts?.result ? { result: opts.result } : {})
  };

  const { error } = await db
    .from("composio_webhook_deliveries")
    .update(patch)
    .eq("id", deliveryId);
  if (error) {
    throw new Error(`Failed to increment webhook delivery attempts: ${error.message}`);
  }
}

export async function getPendingWebhookEvents(
  db: SupabaseClient,
  limit: number = 50
): Promise<WebhookEventRow[]> {
  const { data, error } = await db
    .from("composio_webhook_events")
    .select("*")
    .in("processing_status", ["pending", "failed"])
    .order("received_at", { ascending: true })
    .limit(limit);
  if (error) {
    throw new Error(`Failed to get pending webhook events: ${error.message}`);
  }
  return (data ?? []) as WebhookEventRow[];
}