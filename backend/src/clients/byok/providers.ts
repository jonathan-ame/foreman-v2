import type { ByokProvider } from "../../db/byok-keys.js";

export interface ProviderValidationResult {
  valid: boolean;
  error?: string;
}

const VALIDATION_TIMEOUT_MS = 10_000;

async function fetchWithTimeout(url: string, options: RequestInit, timeoutMs: number): Promise<Response> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
}

function prefixOf(key: string): string {
  if (key.length <= 8) return "****";
  return key.slice(0, 4) + "****" + key.slice(-4);
}

export { prefixOf };

const PROVIDER_VALIDATORS: Record<ByokProvider, (key: string) => Promise<ProviderValidationResult>> = {
  openrouter: async (key: string) => {
    try {
      const res = await fetchWithTimeout(
        "https://openrouter.ai/api/v1/models",
        { method: "GET", headers: { Authorization: `Bearer ${key}` } },
        VALIDATION_TIMEOUT_MS
      );
      if (res.ok) return { valid: true };
      if (res.status === 401 || res.status === 403) return { valid: false, error: "Invalid API key" };
      return { valid: false, error: `OpenRouter returned status ${res.status}` };
    } catch (err) {
      return { valid: false, error: err instanceof Error ? err.message : "Validation request failed" };
    }
  },
  together: async (key: string) => {
    try {
      const res = await fetchWithTimeout(
        "https://api.together.xyz/v1/models",
        { method: "GET", headers: { Authorization: `Bearer ${key}` } },
        VALIDATION_TIMEOUT_MS
      );
      if (res.ok) return { valid: true };
      if (res.status === 401 || res.status === 403) return { valid: false, error: "Invalid API key" };
      return { valid: false, error: `Together returned status ${res.status}` };
    } catch (err) {
      return { valid: false, error: err instanceof Error ? err.message : "Validation request failed" };
    }
  },
  deepinfra: async (key: string) => {
    try {
      const res = await fetchWithTimeout(
        "https://api.deepinfra.com/v1/openai/models",
        { method: "GET", headers: { Authorization: `Bearer ${key}` } },
        VALIDATION_TIMEOUT_MS
      );
      if (res.ok) return { valid: true };
      if (res.status === 401 || res.status === 403) return { valid: false, error: "Invalid API key" };
      return { valid: false, error: `DeepInfra returned status ${res.status}` };
    } catch (err) {
      return { valid: false, error: err instanceof Error ? err.message : "Validation request failed" };
    }
  },
  openai: async (key: string) => {
    try {
      const res = await fetchWithTimeout(
        "https://api.openai.com/v1/models",
        { method: "GET", headers: { Authorization: `Bearer ${key}` } },
        VALIDATION_TIMEOUT_MS
      );
      if (res.ok) return { valid: true };
      if (res.status === 401 || res.status === 403) return { valid: false, error: "Invalid API key" };
      return { valid: false, error: `OpenAI returned status ${res.status}` };
    } catch (err) {
      return { valid: false, error: err instanceof Error ? err.message : "Validation request failed" };
    }
  },
  dashscope: async (key: string) => {
    try {
      const res = await fetchWithTimeout(
        "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${key}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            model: "qwen-turbo",
            input: { messages: [{ role: "user", content: "ping" }] },
            parameters: { max_tokens: 1 }
          })
        },
        VALIDATION_TIMEOUT_MS
      );
      if (res.ok || res.status === 400) return { valid: true };
      if (res.status === 401 || res.status === 403) return { valid: false, error: "Invalid API key" };
      return { valid: false, error: `DashScope returned status ${res.status}` };
    } catch (err) {
      return { valid: false, error: err instanceof Error ? err.message : "Validation request failed" };
    }
  }
};

export async function validateProviderKey(
  provider: ByokProvider,
  key: string
): Promise<ProviderValidationResult> {
  const validator = PROVIDER_VALIDATORS[provider];
  if (!validator) {
    return { valid: false, error: `Unknown provider: ${provider}` };
  }
  return validator(key);
}

export const SUPPORTED_PROVIDERS: ByokProvider[] = ["openrouter", "together", "deepinfra", "dashscope", "openai"];