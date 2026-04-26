import type { AgentRole } from "./types.js";

export interface RoleConfig {
  toolsAllow: string[];
  toolsDeny: string[];
  paperclipRole: string;
  budgetMonthlyCents: number;
  capabilities: string;
  systemPromptTemplate: string;
  composioToolkits: string[];
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
    systemPromptTemplate: "CEO_TEMPLATE_V1",
    composioToolkits: []
  },
  marketing_analyst: {
    toolsAllow: ["read", "write", "edit", "exec", "process", "sessions_spawn", "sessions_list", "sessions_history"],
    toolsDeny: ["browser", "canvas", "nodes", "cron", "hire_agent"],
    paperclipRole: "cmo",
    budgetMonthlyCents: 20_000,
    capabilities: "Market research, campaign analysis, funnel diagnostics, and growth recommendations",
    systemPromptTemplate: "MARKETING_ANALYST_TEMPLATE_V1",
    composioToolkits: ["google_analytics", "slack", "hubspot", "mailchimp"]
  },
  engineer: {
    toolsAllow: ["read", "write", "edit", "exec", "process", "sessions_spawn", "sessions_list", "sessions_history"],
    toolsDeny: ["browser", "canvas", "nodes", "cron", "hire_agent"],
    paperclipRole: "engineer",
    budgetMonthlyCents: 30_000,
    capabilities:
      "Code implementation, bug fixes, architecture design, technical documentation, code review, shell commands",
    systemPromptTemplate: "ENGINEER_TEMPLATE_V1",
    composioToolkits: ["github", "linear", "slack", "jira"]
  },
  qa: {
    toolsAllow: ["read", "write", "edit", "exec", "process", "sessions_spawn", "sessions_list", "sessions_history"],
    toolsDeny: ["browser", "canvas", "nodes", "cron", "hire_agent"],
    paperclipRole: "qa",
    budgetMonthlyCents: 20_000,
    capabilities:
      "Test planning, test execution, bug reporting, regression testing, quality standards enforcement",
    systemPromptTemplate: "QA_TEMPLATE_V1",
    composioToolkits: ["github", "jira", "linear", "slack"]
  },
  designer: {
    toolsAllow: ["read", "write", "edit", "exec", "process", "sessions_spawn", "sessions_list", "sessions_history"],
    toolsDeny: ["browser", "canvas", "nodes", "cron", "hire_agent"],
    paperclipRole: "designer",
    budgetMonthlyCents: 20_000,
    capabilities:
      "UI/UX analysis, design system review, wireframe descriptions, accessibility audits, visual design feedback",
    systemPromptTemplate: "DESIGNER_TEMPLATE_V1",
    composioToolkits: ["figma", "slack", "notion"]
  }
};

export function resolveRoleConfig(role: AgentRole): RoleConfig {
  return ROLE_CONFIGS[role];
}
