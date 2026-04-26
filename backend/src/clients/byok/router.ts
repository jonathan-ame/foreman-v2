import { KeyEncryption } from "../../crypto/key-encryption.js";
import type { ByokKey, ByokProvider } from "../../db/byok-keys.js";
import { getByokKeyByProvider } from "../../db/byok-keys.js";
import type { SupabaseClient } from "../../db/supabase.js";
import type { Logger } from "pino";

export interface PassthroughResult {
  success: boolean;
  provider: ByokProvider;
  usedByok: boolean;
  error?: string;
}

export interface LlmRequest {
  provider: ByokProvider;
  model: string;
  messages: Array<{ role: string; content: string }>;
  maxTokens?: number;
  temperature?: number;
}

export class ByokRouter {
  private encryption: KeyEncryption;
  private db: SupabaseClient;
  private logger: Logger;
  private managedKeys: Record<string, string | undefined>;

  constructor(deps: {
    encryptionKey: string;
    db: SupabaseClient;
    logger: Logger;
    openrouterKey?: string;
    togetherKey?: string;
    deepinfraKey?: string;
    dashscopeKey?: string;
    openaiKey?: string;
  }) {
    this.encryption = new KeyEncryption(deps.encryptionKey);
    this.db = deps.db;
    this.logger = deps.logger.child({ name: "byok-router" });
    this.managedKeys = {
      openrouter: deps.openrouterKey,
      together: deps.togetherKey,
      deepinfra: deps.deepinfraKey,
      dashscope: deps.dashscopeKey,
      openai: deps.openaiKey
    };
  }

  async resolveApiKey(customerId: string, provider: ByokProvider): Promise<{
    apiKey: string;
    isByok: boolean;
  } | null> {
    try {
      const byokKey = await getByokKeyByProvider(this.db, customerId, provider);
      if (byokKey && byokKey.is_valid) {
        const apiKey = this.encryption.decrypt(byokKey.key_encrypted);
        return { apiKey, isByok: true };
      }
    } catch (err) {
      this.logger.warn({ err, customerId, provider }, "failed to resolve BYOK key, falling back to managed");
    }

    const managedKey = this.managedKeys[provider];
    if (managedKey) {
      return { apiKey: managedKey, isByok: false };
    }

    return null;
  }

  async passthroughLlmRequest(
    customerId: string,
    request: LlmRequest
  ): Promise<PassthroughResult> {
    const resolved = await this.resolveApiKey(customerId, request.provider);

    if (!resolved) {
      return {
        success: false,
        provider: request.provider,
        usedByok: false,
        error: `No API key available for provider ${request.provider}`
      };
    }

    const providerUrls: Record<ByokProvider, string> = {
      openrouter: "https://openrouter.ai/api/v1/chat/completions",
      together: "https://api.together.xyz/v1/chat/completions",
      deepinfra: "https://api.deepinfra.com/v1/openai/chat/completions",
      openai: "https://api.openai.com/v1/chat/completions",
      dashscope: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    };

    const url = providerUrls[request.provider];
    if (!url) {
      return {
        success: false,
        provider: request.provider,
        usedByok: resolved.isByok,
        error: `No passthrough URL for provider ${request.provider}`
      };
    }

    try {
      const headers: Record<string, string> = {
        Authorization: `Bearer ${resolved.apiKey}`,
        "Content-Type": "application/json"
      };

      if (request.provider === "openrouter") {
        headers["HTTP-Referer"] = "https://foreman.company";
        headers["X-Title"] = "Foreman";
      }

      const body: Record<string, unknown> = {
        model: request.model,
        messages: request.messages
      };
      if (request.maxTokens !== undefined) body.max_tokens = request.maxTokens;
      if (request.temperature !== undefined) body.temperature = request.temperature;

      const response = await fetch(url, {
        method: "POST",
        headers,
        body: JSON.stringify(body)
      });

      if (!response.ok) {
        const text = await response.text().catch(() => "");
        return {
          success: false,
          provider: request.provider,
          usedByok: resolved.isByok,
          error: `Provider returned ${response.status}: ${text.slice(0, 200)}`
        };
      }

      return {
        success: true,
        provider: request.provider,
        usedByok: resolved.isByok
      };
    } catch (err) {
      return {
        success: false,
        provider: request.provider,
        usedByok: resolved.isByok,
        error: err instanceof Error ? err.message : "Request failed"
      };
    }
  }

  decryptKey(byokKey: ByokKey): string {
    return this.encryption.decrypt(byokKey.key_encrypted);
  }
}