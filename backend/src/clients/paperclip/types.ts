export interface AdapterConfig {
  url?: string;
  gatewayUrl: string;
  headers: {
    "x-openclaw-token": string;
    [key: string]: string;
  };
}

export interface PaperclipAgent {
  id: string;
  name: string;
  role: string;
  status?: string;
  adapterType: string;
  adapterConfig: AdapterConfig;
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
}

export interface HireAgentResponse {
  agent: PaperclipAgent;
  approval?: PendingApproval;
}

export type ApprovalAction = "approve" | "reject" | "request-revision" | "resubmit";
