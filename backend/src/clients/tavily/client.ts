import type { Logger } from "pino";
import { TavilyApiError, TavilyTimeoutError } from "./errors.js";
import type {
  TavilySearchOptions,
  TavilySearchResponse,
  TavilyExtractOptions,
  TavilyExtractResponse,
  TavilyResearchOptions,
  TavilyResearchResponse
} from "./types.js";

const DEFAULT_TIMEOUT_MS = 30_000;
const SEARCH_API_URL = "https://api.tavily.com/search";
const EXTRACT_API_URL = "https://api.tavily.com/extract";
const RETRY_BACKOFF_MS = [1_000, 2_000, 4_000];

export interface TavilyClientConfig {
  apiKey: string;
  timeoutMs?: number;
  logger: Logger;
}

export class TavilyClient {
  private readonly apiKey: string;
  private readonly timeoutMs: number;
  private readonly logger: Logger;

  readonly isConfigured: boolean;

  constructor(config: TavilyClientConfig) {
    this.apiKey = config.apiKey;
    this.timeoutMs = config.timeoutMs ?? DEFAULT_TIMEOUT_MS;
    this.logger = config.logger;
    this.isConfigured = Boolean(this.apiKey);
  }

  async search(options: TavilySearchOptions): Promise<TavilySearchResponse> {
    if (!this.isConfigured) throw new TavilyApiError({ statusCode: 503, errorCode: "TAVILY_NOT_CONFIGURED", message: "Tavily API key not configured", retryable: false });

    const body: Record<string, unknown> = {
      query: options.query,
      max_results: options.maxResults ?? 5,
      search_depth: options.searchDepth ?? "basic",
      include_raw_content: options.includeRawContent ?? false,
      topic: options.topic ?? "general"
    };
    if (options.includeDomains?.length) body.include_domains = options.includeDomains;
    if (options.excludeDomains?.length) body.exclude_domains = options.excludeDomains;
    if (options.days !== undefined) body.days = options.days;

    return this.requestJson<TavilySearchResponse>("POST", SEARCH_API_URL, body);
  }

  async extract(options: TavilyExtractOptions): Promise<TavilyExtractResponse> {
    if (!this.isConfigured) throw new TavilyApiError({ statusCode: 503, errorCode: "TAVILY_NOT_CONFIGURED", message: "Tavily API key not configured", retryable: false });

    const body: Record<string, unknown> = {
      urls: options.urls,
      extract_depth: options.extractDepth ?? "basic"
    };

    return this.requestJson<TavilyExtractResponse>("POST", EXTRACT_API_URL, body);
  }

  async research(options: TavilyResearchOptions): Promise<TavilyResearchResponse> {
    if (!this.isConfigured) throw new TavilyApiError({ statusCode: 503, errorCode: "TAVILY_NOT_CONFIGURED", message: "Tavily API key not configured", retryable: false });

    const body: Record<string, unknown> = {
      query: options.query,
      max_results: options.maxResults ?? 5,
      search_depth: options.searchDepth ?? "advanced",
      include_answer: true
    };
    if (options.includeDomains?.length) body.include_domains = options.includeDomains;
    if (options.excludeDomains?.length) body.exclude_domains = options.excludeDomains;

    const result = await this.requestJson<TavilySearchResponse & { answer?: string }>("POST", SEARCH_API_URL, body);

    return {
      query: result.query,
      answer: result.answer ?? "",
      results: result.results,
      responseTime: result.responseTime
    };
  }

  async ping(): Promise<{ ok: boolean }> {
    if (!this.isConfigured) return { ok: false };
    try {
      await this.search({ query: "ping", maxResults: 1, searchDepth: "basic" });
      return { ok: true };
    } catch {
      return { ok: false };
    }
  }

  private async requestJson<T>(method: string, url: string, body?: unknown): Promise<T> {
    const maxAttempts = RETRY_BACKOFF_MS.length + 1;

    for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
      try {
        const headers: Record<string, string> = {
          "Content-Type": "application/json",
          Authorization: `Bearer ${this.apiKey}`
        };

        const init: RequestInit = { method, headers };
        if (body !== undefined) init.body = JSON.stringify(body);

        const response = await this.fetchWithTimeout(url, init);

        if (response.ok) {
          const text = await response.text();
          return text ? (JSON.parse(text) as T) : (undefined as T);
        }

        const errorBody = await response.text().catch(() => "");
        const mapped = this.mapError(response.status, errorBody);

        if (response.status >= 500 && attempt < maxAttempts - 1) {
          const backoffMs = RETRY_BACKOFF_MS[attempt];
          if (backoffMs !== undefined) await this.delay(backoffMs);
          continue;
        }

        throw mapped;
      } catch (error) {
        if (error instanceof TavilyApiError) throw error;
        if (error instanceof DOMException && error.name === "AbortError") throw new TavilyTimeoutError();
        throw new TavilyApiError({
          statusCode: 0,
          errorCode: "TAVILY_NETWORK_ERROR",
          message: error instanceof Error ? error.message : "Tavily request failed",
          retryable: true
        });
      }
    }

    throw new TavilyApiError({
      statusCode: 500,
      errorCode: "TAVILY_RETRY_EXHAUSTED",
      message: "Tavily request failed after retries",
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

  private mapError(status: number, body: string): TavilyApiError {
    let message = `Tavily API error (${status})`;
    let errorCode = "TAVILY_API_ERROR";
    try {
      const parsed = JSON.parse(body) as { detail?: string; error?: string };
      if (parsed.detail) message = parsed.detail;
      if (parsed.error) message = parsed.error;
    } catch {}

    if (status === 401 || status === 403) {
      errorCode = "TAVILY_AUTH";
      return new TavilyApiError({ statusCode: status, errorCode, message, retryable: false });
    }

    return new TavilyApiError({ statusCode: status, errorCode, message, retryable: status >= 500 });
  }

  private async delay(ms: number): Promise<void> {
    await new Promise((resolve) => setTimeout(resolve, ms));
  }
}