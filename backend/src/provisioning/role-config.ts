import type { AgentRole } from "./types.js";

export interface RoleConfig {
  toolsAllow: string[];
  toolsDeny: string[];
  paperclipRole: string;
  budgetMonthlyCents: number;
  capabilities: string;
  systemPromptTemplate: string;
}

export const ROLE_CONFIGS: Record<AgentRole, RoleConfig> = {
  ceo: {
    toolsAllow: [
      "read",
      "write",
      "edit",
      "exec",
      "process",
      "sessions_spawn",
      "sessions_list",
      "sessions_history",
      "hire_agent"
    ],
    toolsDeny: ["browser", "canvas", "nodes", "cron"],
    paperclipRole: "ceo",
    budgetMonthlyCents: 50_000,
    capabilities: "Strategic planning, delegation, hiring, board reporting",
    systemPromptTemplate: "CEO_TEMPLATE_V1"
  }
};

export function resolveRoleConfig(role: AgentRole): RoleConfig {
  return ROLE_CONFIGS[role];
}
