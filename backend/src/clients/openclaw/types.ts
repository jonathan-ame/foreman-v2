export interface OpenClawAgentSpec {
  id: string;
  workspace: string;
  identity?: {
    name?: string;
    emoji?: string;
    avatar?: string;
  };
}

export interface OpenClawAgentRecord {
  id: string;
  workspace: string;
  defaultAgent: boolean;
  identity?: {
    name?: string;
    emoji?: string;
    avatar?: string;
  };
  bindings?: Record<string, unknown>;
}

export interface OpenClawConfigSnapshot {
  keys: string[];
  raw: Record<string, unknown>;
}
