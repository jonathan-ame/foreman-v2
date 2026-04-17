import type { ModelTier } from "./types.js";

export interface TierSpec {
  primary: string;
  fallbacks: string[];
  embedding: string;
}

export const TIER_SPECS: Record<ModelTier, TierSpec> = {
  open: {
    primary: "openrouter/deepseek/deepseek-chat-v3.1",
    fallbacks: [
      "openrouter/qwen/qwen-2.5-72b-instruct",
      "openrouter/meta-llama/llama-3.3-70b-instruct"
    ],
    embedding: "qwen_embedding/text-embedding-v4"
  },
  frontier: {
    primary: "openrouter/anthropic/claude-sonnet-4.6",
    fallbacks: ["openrouter/openai/gpt-5", "openrouter/google/gemini-2.5-pro"],
    embedding: "qwen_embedding/text-embedding-v4"
  },
  hybrid: {
    primary: "openrouter/deepseek/deepseek-chat-v3.1",
    fallbacks: [
      "openrouter/qwen/qwen-2.5-72b-instruct",
      "openrouter/meta-llama/llama-3.3-70b-instruct"
    ],
    embedding: "qwen_embedding/text-embedding-v4"
  }
};

export interface FrontierEscalationMap {
  code_generation: string;
  code_review: string;
  reasoning: string;
  research: string;
  writing: string;
  default: string;
  [key: string]: string;
}

export const FRONTIER_ESCALATION_MAP: FrontierEscalationMap = {
  code_generation: "disabled",
  code_review: "disabled",
  reasoning: "disabled",
  research: "disabled",
  writing: "disabled",
  default: "disabled"
};

export function resolveFrontierModelForTaskType(taskType?: string | null): string {
  if (!taskType) {
    return FRONTIER_ESCALATION_MAP.default;
  }
  const normalized = taskType.trim().toLowerCase();
  return FRONTIER_ESCALATION_MAP[normalized] ?? FRONTIER_ESCALATION_MAP.default;
}

export function resolveTierSpec(tier: ModelTier): TierSpec {
  return TIER_SPECS[tier];
}
