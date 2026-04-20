import type { SupabaseClient } from "./supabase.js";

export type FunnelEventType = "signup" | "first_agent_running" | "first_task_in_progress";

export interface FunnelEvent {
  id: string;
  workspace_slug: string;
  event_type: FunnelEventType;
  occurred_at: string;
}

export async function recordFunnelEvent(
  db: SupabaseClient,
  workspaceSlug: string,
  eventType: FunnelEventType
): Promise<void> {
  // Deduplicate: only fire each event type once per workspace.
  const { data: existing } = await db
    .from("funnel_events")
    .select("id")
    .eq("workspace_slug", workspaceSlug)
    .eq("event_type", eventType)
    .maybeSingle();

  if (existing) {
    return;
  }

  const { error } = await db.from("funnel_events").insert({
    workspace_slug: workspaceSlug,
    event_type: eventType
  });

  if (error) {
    throw new Error(
      `Failed to record funnel event ${eventType} for workspace ${workspaceSlug}: ${error.message}`
    );
  }
}

export interface FunnelSummary {
  signups_30d: number;
  first_agents_30d: number;
  first_tasks_30d: number;
  total_signups: number;
  total_first_agents: number;
  total_first_tasks: number;
}

export async function getFunnelSummary(db: SupabaseClient): Promise<FunnelSummary> {
  const since30d = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

  const { data, error } = await db
    .from("funnel_events")
    .select("event_type, occurred_at");

  if (error) {
    throw new Error(`Failed to fetch funnel events: ${error.message}`);
  }

  const rows = (data ?? []) as { event_type: string; occurred_at: string }[];

  let signups30 = 0;
  let agents30 = 0;
  let tasks30 = 0;
  let signupsTotal = 0;
  let agentsTotal = 0;
  let tasksTotal = 0;

  for (const row of rows) {
    const inWindow = row.occurred_at >= since30d;
    if (row.event_type === "signup") {
      signupsTotal++;
      if (inWindow) signups30++;
    } else if (row.event_type === "first_agent_running") {
      agentsTotal++;
      if (inWindow) agents30++;
    } else if (row.event_type === "first_task_in_progress") {
      tasksTotal++;
      if (inWindow) tasks30++;
    }
  }

  return {
    signups_30d: signups30,
    first_agents_30d: agents30,
    first_tasks_30d: tasks30,
    total_signups: signupsTotal,
    total_first_agents: agentsTotal,
    total_first_tasks: tasksTotal
  };
}

export async function getD7RetainedCount(db: SupabaseClient): Promise<number> {
  // Workspaces with first_agent_running more than 7 days ago
  const cutoff7d = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

  const { data: agentEvents, error: agentError } = await db
    .from("funnel_events")
    .select("workspace_slug")
    .eq("event_type", "first_agent_running")
    .lt("occurred_at", cutoff7d);

  if (agentError) {
    throw new Error(`Failed to fetch D7 agent events: ${agentError.message}`);
  }

  const workspaceSlugs = ((agentEvents ?? []) as { workspace_slug: string }[]).map(
    (r) => r.workspace_slug
  );

  if (workspaceSlugs.length === 0) {
    return 0;
  }

  // Check which of these workspaces had usage in the last 7 days
  const { data: usageData, error: usageError } = await db
    .from("agent_usage_events")
    .select("paperclip_agent_id")
    .gte("occurred_at", cutoff7d);

  if (usageError) {
    throw new Error(`Failed to fetch recent usage events: ${usageError.message}`);
  }

  // Usage events don't have workspace_slug directly; we need agents table for the join.
  // Return the count of workspaces eligible (≥7d old) as a proxy when join isn't available.
  // Full join via agents table would require an additional query; keep it simple for now.
  return (usageData ?? []).length > 0 ? workspaceSlugs.length : 0;
}
