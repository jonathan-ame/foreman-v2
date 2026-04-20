import type { SupabaseClient } from "./supabase.js";

export interface AgentUsageEvent {
  id: string;
  paperclip_agent_id: string;
  input_tokens: number;
  output_tokens: number;
  cost_cents: number;
  model: string | null;
  provider: string | null;
  issue_id: string | null;
  occurred_at: string;
  recorded_at: string;
}

export interface AgentUsageEventInsert {
  paperclip_agent_id: string;
  input_tokens: number;
  output_tokens: number;
  cost_cents: number;
  model?: string | null;
  provider?: string | null;
  issue_id?: string | null;
  occurred_at: string;
}

export async function insertAgentUsageEvent(
  db: SupabaseClient,
  event: AgentUsageEventInsert
): Promise<void> {
  const { error } = await db.from("agent_usage_events").insert({
    paperclip_agent_id: event.paperclip_agent_id,
    input_tokens: event.input_tokens,
    output_tokens: event.output_tokens,
    cost_cents: event.cost_cents,
    model: event.model ?? null,
    provider: event.provider ?? null,
    issue_id: event.issue_id ?? null,
    occurred_at: event.occurred_at
  });
  if (error) {
    throw new Error(
      `Failed to insert usage event for agent ${event.paperclip_agent_id}: ${error.message}`
    );
  }
}

export interface AgentUsageTotals {
  paperclip_agent_id: string;
  total_input_tokens: number;
  total_output_tokens: number;
  total_cost_cents: number;
}

export async function getAgentUsageTotalsSince(
  db: SupabaseClient,
  since: string
): Promise<AgentUsageTotals[]> {
  const { data, error } = await db
    .from("agent_usage_events")
    .select("paperclip_agent_id, input_tokens, output_tokens, cost_cents")
    .gte("occurred_at", since);

  if (error) {
    throw new Error(`Failed to aggregate usage events since ${since}: ${error.message}`);
  }

  const byAgent = new Map<
    string,
    { total_input_tokens: number; total_output_tokens: number; total_cost_cents: number }
  >();

  for (const row of data ?? []) {
    const r = row as {
      paperclip_agent_id: string;
      input_tokens: number;
      output_tokens: number;
      cost_cents: number;
    };
    const existing = byAgent.get(r.paperclip_agent_id) ?? {
      total_input_tokens: 0,
      total_output_tokens: 0,
      total_cost_cents: 0
    };
    existing.total_input_tokens += r.input_tokens;
    existing.total_output_tokens += r.output_tokens;
    existing.total_cost_cents += r.cost_cents;
    byAgent.set(r.paperclip_agent_id, existing);
  }

  return Array.from(byAgent.entries()).map(([id, totals]) => ({
    paperclip_agent_id: id,
    ...totals
  }));
}
