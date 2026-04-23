import { createHmac } from "node:crypto";
import type { Logger } from "pino";
import {
  ComposioApiError,
  ComposioAuthError,
  ComposioNotFoundError
} from "./errors.js";
import type {
  ComposioConnectedAccount,
  ComposioConnectionRequest,
  ComposioCreateTriggerRequest,
  ComposioSession,
  ComposioToolkit,
  ComposioTrigger,
  ComposioWebhookEvent
} from "./types.js";

const DEFAULT_TIMEOUT_MS = 30_000;
const RETRY_BACKOFF_MS = [1_000, 2_000, 4_000];

interface ErrorPayload {
  message?: string;
  error?: string;
  code?: string;
  errorCode?: string;
}

export interface ComposioClientConfig {
  apiBase: string;
  apiKey: string;
  timeoutMs?: number;
  logger: Logger;
}

export class ComposioClient {
  private readonly apiBase: string;
  private readonly apiKey: string;
  private readonly timeoutMs: number;
  private readonly logger: Logger;

  constructor(config: ComposioClientConfig) {
    this.apiBase = config.apiBase.replace(/\/+$/, "");
    this.apiKey = config.apiKey;
    this.timeoutMs = config.timeoutMs ?? DEFAULT_TIMEOUT_MS;
    this.logger = config.logger;
  }

  get isConfigured(): boolean {
    return this.apiKey.length > 0;
  }

  async executeTool(
    toolSlug: string,
    opts: {
      userId: string;
      arguments: Record<string, unknown>;
      connectedAccountId?: string;
    }
  ): Promise<Record<string, unknown>> {
    const body: Record<string, unknown> = {
      user_id: opts.userId,
      arguments: opts.arguments
    };
    if (opts.connectedAccountId) {
      body.connected_account_id = opts.connectedAccountId;
    }
    return this.requestJson<Record<string, unknown>>("POST", `/api/v3/tools/execute/${toolSlug}`, body);
  }

  async createSession(
    userId: string,
    options?: { toolkits?: string[] }
  ): Promise<ComposioSession> {
    const body: Record<string, unknown> = { user_id: userId };
    if (options?.toolkits && options.toolkits.length > 0) {
      body.toolkits = options.toolkits;
    }
    return this.requestJson<ComposioSession>("POST", "/api/v3/sessions", body);
  }

  async getSession(sessionId: string): Promise<ComposioSession> {
    return this.requestJson<ComposioSession>("GET", `/api/v3/sessions/${sessionId}`);
  }

  async listToolkits(): Promise<ComposioToolkit[]> {
    const result = await this.requestJson<{ toolkits: ComposioToolkit[] }>(
      "GET",
      "/api/v3/toolkits"
    );
    return result.toolkits ?? [];
  }

  async authorizeToolkit(
    userId: string,
    toolkitSlug: string,
    redirectUrl?: string
  ): Promise<ComposioConnectionRequest> {
    const body: Record<string, unknown> = {
      user_id: userId,
      toolkit: toolkitSlug
    };
    if (redirectUrl) {
      body.redirect_url = redirectUrl;
    }
    return this.requestJson<ComposioConnectionRequest>(
      "POST",
      "/api/v3/connections/authorize",
      body
    );
  }

  async listConnectedAccounts(userId: string): Promise<ComposioConnectedAccount[]> {
    const result = await this.requestJson<{ connections: ComposioConnectedAccount[] }>(
      "GET",
      `/api/v3/connections?user_id=${encodeURIComponent(userId)}`
    );
    return result.connections ?? [];
  }

  async deleteConnectedAccount(connectedAccountId: string): Promise<void> {
    await this.requestJson("DELETE", `/api/v3/connections/${connectedAccountId}`);
  }

  async createTrigger(
    userId: string,
    request: ComposioCreateTriggerRequest
  ): Promise<ComposioTrigger> {
    const body: Record<string, unknown> = {
      user_id: userId,
      trigger_type: request.triggerType,
      toolkit: request.toolkitSlug,
      config: request.config
    };
    if (request.connectedAccountId) {
      body.connected_account_id = request.connectedAccountId;
    }
    return this.requestJson<ComposioTrigger>("POST", "/api/v3/triggers", body);
  }

  async listTriggers(userId: string): Promise<ComposioTrigger[]> {
    const result = await this.requestJson<{ triggers: ComposioTrigger[] }>(
      "GET",
      `/api/v3/triggers?user_id=${encodeURIComponent(userId)}`
    );
    return result.triggers ?? [];
  }

  async deleteTrigger(triggerId: string): Promise<void> {
    await this.requestJson("DELETE", `/api/v3/triggers/${triggerId}`);
  }

  async ping(): Promise<{ ok: boolean }> {
    try {
      await this.requestJson("GET", "/api/v3/health");
      return { ok: true };
    } catch (error) {
      this.logger.warn({ err: error }, "composio ping failed");
      return { ok: false };
    }
  }

  verifyWebhookSignature(payload: string, signature: string, secret: string): boolean {
    if (!secret) {
      return false;
    }
    const expected = createHmac("sha256", secret).update(payload).digest("hex");
    if (signature.length !== expected.length) {
      return false;
    }
    let mismatch = 0;
    for (let i = 0; i < expected.length; i += 1) {
      mismatch |= (expected.charCodeAt(i) ?? 0) ^ (signature.charCodeAt(i) ?? 0);
    }
    return mismatch === 0;
  }

  private async requestJson<T>(
    method: string,
    path: string,
    body?: unknown
  ): Promise<T> {
    const url = `${this.apiBase}${path}`;
    const maxAttempts = RETRY_BACKOFF_MS.length + 1;

    for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
      const startedAt = Date.now();
      try {
        const headers: Record<string, string> = {
          "x-api-key": this.apiKey,
          "Content-Type": "application/json"
        };

        const init: RequestInit = { method, headers };
        if (body !== undefined) {
          init.body = JSON.stringify(body);
        }

        const response = await this.fetchWithTimeout(url, init);
        const durationMs = Date.now() - startedAt;

        this.logger.debug(
          { method, path, attempt: attempt + 1, statusCode: response.status, durationMs },
          "composio request complete"
        );

        if (response.ok) {
          if (response.status === 204) {
            return undefined as T;
          }
          const text = await response.text();
          return text ? (JSON.parse(text) as T) : (undefined as T);
        }

        const mappedError = await this.mapError(response);
        if (response.status >= 500 && attempt < maxAttempts - 1) {
          const backoffMs = RETRY_BACKOFF_MS[attempt];
          if (backoffMs !== undefined) {
            await this.delay(backoffMs);
          }
          continue;
        }
        throw mappedError;
      } catch (error) {
        const durationMs = Date.now() - startedAt;
        if (this.isAbortError(error)) {
          this.logger.debug({ method, path, attempt: attempt + 1, durationMs }, "composio timeout");
          throw new ComposioApiError({
            statusCode: 0,
            errorCode: "COMPOSIO_TIMEOUT",
            message: "Composio request timed out",
            retryable: true
          });
        }
        if (error instanceof ComposioApiError) {
          throw error;
        }
        throw new ComposioApiError({
          statusCode: 0,
          errorCode: "COMPOSIO_NETWORK_ERROR",
          message: error instanceof Error ? error.message : "Composio request failed",
          retryable: true
        });
      }
    }

    throw new ComposioApiError({
      statusCode: 500,
      errorCode: "COMPOSIO_RETRY_EXHAUSTED",
      message: "Composio request failed after retries",
      retryable: true
    });
  }

  private async fetchWithTimeout(url: string, init: RequestInit): Promise<Response> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      return await fetch(url, { ...init, signal: controller.signal });
    } finally {
      clearTimeout(timeout);
    }
  }

  private async mapError(response: Response): Promise<ComposioApiError> {
    const payload = this.tryParseError(await response.text());
    const message = payload.message ?? payload.error ?? `Composio API error (${response.status})`;
    const errorCode = payload.errorCode ?? payload.code ?? "COMPOSIO_API_ERROR";

    if (response.status === 401 || response.status === 403) {
      return new ComposioAuthError(response.status, message);
    }
    if (response.status === 404) {
      return new ComposioNotFoundError(message);
    }
    return new ComposioApiError({
      statusCode: response.status,
      errorCode,
      message,
      retryable: response.status >= 500
    });
  }

  private tryParseError(raw: string): ErrorPayload {
    if (!raw) {
      return {};
    }
    try {
      return JSON.parse(raw) as ErrorPayload;
    } catch {
      return { message: raw };
    }
  }

  private isAbortError(error: unknown): boolean {
    return error instanceof DOMException && error.name === "AbortError";
  }

  private async delay(ms: number): Promise<void> {
    await new Promise((resolve) => setTimeout(resolve, ms));
  }
}
