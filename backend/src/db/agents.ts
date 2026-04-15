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

export async function insertAgent(db: SupabaseClient, agentRecord: AgentInsert): Promise<Agent> {
  const { data, error } = await db.from("agents").insert(agentRecord).select("*").single();
  if (error) {
    throw new Error(`Failed to insert agent record: ${error.message}`);
  }
  return data as Agent;
}
