import type { SupabaseClient } from "./supabase.js";

export interface NotificationInsert {
  workspace_slug: string;
  type: "agent_hired" | "agent_paused_health" | "agent_recovered_health";
  title: string;
  body: string;
  reference_id?: string | null;
  reference_type?: string | null;
}

export async function insertNotification(db: SupabaseClient, notification: NotificationInsert): Promise<void> {
  const payload = {
    workspace_slug: notification.workspace_slug,
    type: notification.type,
    title: notification.title,
    body: notification.body,
    read: false,
    reference_id: notification.reference_id ?? null,
    reference_type: notification.reference_type ?? null
  };

  const { error } = await db.from("notifications").insert(payload);
  if (error) {
    throw new Error(`Failed to insert notification for workspace ${notification.workspace_slug}: ${error.message}`);
  }
}
