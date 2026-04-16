import type { SupabaseClient } from "./supabase.js";

export interface Agent {
  agent_id: string;
  customer_id: string;
  workspace_slug: string;
  paperclip_agent_id: string;
  openclaw_agent_id: string;
  display_name: string;
  role: string;
  model_tier: string;
  model_primary: string;
  model_fallbacks: string[];
  billing_mode_at_provision: string;
  current_status: string;
  last_health_check_at?: string | null;
  last_health_check_result?: string | null;
}

export interface AgentInsert {
  customer_id: string;
  workspace_slug: string;
  paperclip_agent_id: string;
  openclaw_agent_id: string;
  display_name: string;
  role: string;
  model_tier: string;
  model_primary: string;
  model_fallbacks: string[];
  billing_mode_at_provision: string;
}

export async function getAgentByWorkspaceAndName(
  db: SupabaseClient,
  workspaceSlug: string,
  name: string
): Promise<Agent | null> {
  const { data, error } = await db
    .from("agents")
    .select("*")
    .eq("workspace_slug", workspaceSlug)
    .eq("display_name", name)
    .maybeSingle();

  if (error) {
    throw new Error(`Failed to query agent ${workspaceSlug}/${name}: ${error.message}`);
  }
  return data as Agent | null;
}

export async function getAgentByOpenclawAgentId(db: SupabaseClient, openclawAgentId: string): Promise<Agent | null> {
  const { data, error } = await db.from("agents").select("*").eq("openclaw_agent_id", openclawAgentId).maybeSingle();
  if (error) {
    throw new Error(`Failed to query openclaw agent ${openclawAgentId}: ${error.message}`);
  }
  return data as Agent | null;
}

export async function insertAgent(db: SupabaseClient, agentRecord: AgentInsert): Promise<Agent> {
  const { data, error } = await db.from("agents").insert(agentRecord).select("*").single();
  if (error) {
    throw new Error(`Failed to insert agent record: ${error.message}`);
  }
  return data as Agent;
}

export async function listAgentsForHealthCheck(db: SupabaseClient): Promise<Agent[]> {
  const { data, error } = await db
    .from("agents")
    .select("*")
    .in("current_status", ["active", "paused"]);
  if (error) {
    throw new Error(`Failed to list agents for health check: ${error.message}`);
  }
  return (data ?? []) as Agent[];
}

export interface AgentHealthUpdate {
  current_status?: "active" | "paused";
  last_health_check_at: string;
  last_health_check_result: string;
}

export async function updateAgentHealth(db: SupabaseClient, agentId: string, patch: AgentHealthUpdate): Promise<void> {
  const { error } = await db.from("agents").update(patch).eq("agent_id", agentId);
  if (error) {
    throw new Error(`Failed to update health fields for agent ${agentId}: ${error.message}`);
  }
}

export async function getAgentStatusCounts(
  db: SupabaseClient
): Promise<{ active_count: number; paused_count: number }> {
  const [activeResult, pausedResult] = await Promise.all([
    db.from("agents").select("agent_id", { count: "exact", head: true }).eq("current_status", "active"),
    db.from("agents").select("agent_id", { count: "exact", head: true }).eq("current_status", "paused")
  ]);
  if (activeResult.error) {
    throw new Error(`Failed to count active agents: ${activeResult.error.message}`);
  }
  if (pausedResult.error) {
    throw new Error(`Failed to count paused agents: ${pausedResult.error.message}`);
  }
  return {
    active_count: activeResult.count ?? 0,
    paused_count: pausedResult.count ?? 0
  };
}
