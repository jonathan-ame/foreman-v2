import type { ModelTier } from "../provisioning/types.js";
import { resolveFrontierModelForTaskType } from "../provisioning/model-tiers.js";
import type { SupabaseClient } from "./supabase.js";

export interface TaskEscalationState {
  issue_id: string;
  workspace_slug: string;
  agent_id: string;
  rejection_count: number;
  escalated_to_frontier: boolean;
  escalated_at: string | null;
  frontier_model: string | null;
  created_at: string;
  updated_at: string;
}

export interface RecordTaskRejectionInput {
  issueId: string;
  workspaceSlug: string;
  agentId: string;
  modelTier: ModelTier;
  taskType?: string;
}

export interface RecordTaskRejectionResult {
  rejectionCount: number;
  escalatedToFrontier: boolean;
  frontierModel: string | null;
}

export async function getTaskEscalationState(
  db: SupabaseClient,
  issueId: string
): Promise<TaskEscalationState | null> {
  const { data, error } = await db.from("task_escalation_state").select("*").eq("issue_id", issueId).maybeSingle();
  if (error) {
    throw new Error(`Failed to load task escalation state for ${issueId}: ${error.message}`);
  }
  return (data as TaskEscalationState | null) ?? null;
}

export async function recordTaskRejection(
  db: SupabaseClient,
  input: RecordTaskRejectionInput
): Promise<RecordTaskRejectionResult> {
  const existing = await getTaskEscalationState(db, input.issueId);
  const rejectionCount = Number(existing?.rejection_count ?? 0) + 1;
  const wasEscalated = Boolean(existing?.escalated_to_frontier);
  const mappedFrontierModel = resolveFrontierModelForTaskType(input.taskType);
  const frontierModelCandidate = mappedFrontierModel === "disabled" ? null : mappedFrontierModel;
  const shouldEscalate =
    wasEscalated || (input.modelTier === "hybrid" && rejectionCount >= 2 && Boolean(frontierModelCandidate));
  const frontierModel =
    existing?.frontier_model ??
    (shouldEscalate ? frontierModelCandidate : null);

  const patch = {
    issue_id: input.issueId,
    workspace_slug: existing?.workspace_slug ?? input.workspaceSlug,
    agent_id: existing?.agent_id ?? input.agentId,
    rejection_count: rejectionCount,
    escalated_to_frontier: shouldEscalate,
    escalated_at: !wasEscalated && shouldEscalate ? new Date().toISOString() : existing?.escalated_at ?? null,
    frontier_model: frontierModel
  };

  const { error } = await db.from("task_escalation_state").upsert(patch, { onConflict: "issue_id" });
  if (error) {
    throw new Error(`Failed to store task rejection for ${input.issueId}: ${error.message}`);
  }

  return {
    rejectionCount,
    escalatedToFrontier: shouldEscalate,
    frontierModel
  };
}

export async function escalateTaskToFrontier(
  db: SupabaseClient,
  input: Omit<RecordTaskRejectionInput, "modelTier">
): Promise<RecordTaskRejectionResult> {
  const existing = await getTaskEscalationState(db, input.issueId);
  const frontierModel = existing?.frontier_model ?? resolveFrontierModelForTaskType(input.taskType);
  const rejectionCount = Number(existing?.rejection_count ?? 0);

  const patch = {
    issue_id: input.issueId,
    workspace_slug: existing?.workspace_slug ?? input.workspaceSlug,
    agent_id: existing?.agent_id ?? input.agentId,
    rejection_count: rejectionCount,
    escalated_to_frontier: true,
    escalated_at: existing?.escalated_at ?? new Date().toISOString(),
    frontier_model: frontierModel
  };

  const { error } = await db.from("task_escalation_state").upsert(patch, { onConflict: "issue_id" });
  if (error) {
    throw new Error(`Failed to manually escalate task ${input.issueId}: ${error.message}`);
  }

  return {
    rejectionCount,
    escalatedToFrontier: true,
    frontierModel
  };
}
