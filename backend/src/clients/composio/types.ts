export interface ComposioSession {
  id: string;
  userId: string;
  mcp: {
    url: string;
    headers: Record<string, string>;
  };
  toolkits: string[];
  createdAt: string;
}

export interface ComposioToolkit {
  slug: string;
  name: string;
  logo?: string;
  categories?: string[];
}

export interface ComposioConnectedAccount {
  id: string;
  toolkitSlug: string;
  toolkitName: string;
  status: string;
  createdAt: string;
  updatedAt: string;
}

export interface ComposioConnectionRequest {
  connectUrl: string;
  connectedAccountId?: string;
  redirectUrl?: string;
}

export interface ComposioTrigger {
  id: string;
  triggerType: string;
  toolkitSlug: string;
  status: string;
  config: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

export interface ComposioCreateTriggerRequest {
  triggerType: string;
  toolkitSlug: string;
  config: Record<string, unknown>;
  connectedAccountId?: string | undefined;
}

export interface ComposioWebhookEvent {
  triggerId: string;
  triggerType: string;
  toolkitSlug: string;
  payload: Record<string, unknown>;
  timestamp: string;
}

export interface ComposioToolExecutionResult {
  success: boolean;
  data?: Record<string, unknown>;
  error?: string;
}
