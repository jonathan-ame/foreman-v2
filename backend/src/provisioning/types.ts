export type AgentRole = "ceo" | "marketing_analyst";
export type ModelTier = "open" | "frontier" | "hybrid";
export type ProvisioningOutcome = "success" | "failed" | "partial" | "partial_with_warning" | "blocked";

export interface ProvisionInput {
  customerId: string;
  agentName: string;
  role: AgentRole;
  modelTier: ModelTier;
  idempotencyKey: string;
  workspacePath?: string;
}

export interface ProvisionSuccess {
  outcome: "success" | "partial" | "partial_with_warning";
  agentId: string;
  paperclipAgentId: string;
  openclawAgentId: string;
  provisioningId: string;
  modelPrimary: string;
  modelFallbacks: string[];
  readyAt: string;
}

export interface ProvisionFailure {
  outcome: "failed" | "blocked";
  provisioningId: string;
  failedStep: string;
  errorCode: string;
  errorMessage: string;
  customerMessage: string;
  rollbackPerformed: boolean;
  technicalDetails: Record<string, unknown>;
}

export type ProvisioningResult = ProvisionSuccess | ProvisionFailure;
