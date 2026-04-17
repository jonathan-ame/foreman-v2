export interface AdapterConfig {
  url?: string;
  gatewayUrl: string;
  timeoutSec?: number;
  headers: {
    "x-openclaw-token": string;
    [key: string]: string;
  };
}

export interface HeartbeatRuntimeConfig {
  enabled: boolean;
  mode: "proactive" | "reactive";
  intervalSec?: number;
}

export interface PaperclipAgent {
  id: string;
  name: string;
  role: string;
  status?: string;
  adapterType: string;
  adapterConfig: AdapterConfig;
  runtimeConfig?: {
    heartbeat?: HeartbeatRuntimeConfig;
  };
  companyId: string;
  capabilities?: string;
}

export interface PendingApproval {
  id: string;
  type: string;
  status: string;
}

export interface HireAgentRequest {
  name: string;
  role: string;
  reportsTo?: string;
  capabilities: string;
  budgetMonthlyCents: number;
  adapterType: string;
  adapterConfig: AdapterConfig;
  runtimeConfig?: {
    heartbeat?: HeartbeatRuntimeConfig;
  };
}

export interface HireAgentResponse {
  agent: PaperclipAgent;
  approval?: PendingApproval;
}

export type ApprovalAction = "approve" | "reject" | "request-revision" | "resubmit";
