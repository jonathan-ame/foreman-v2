import type { Logger } from "pino";
import {
  PaperclipApiError,
  PaperclipAuthError,
  PaperclipNotFoundError,
  PaperclipTimeoutError
} from "./errors.js";
import type {
  ApprovalAction,
  HireAgentRequest,
  HireAgentResponse,
  PaperclipAgent,
  PendingApproval
} from "./types.js";

const DEFAULT_TIMEOUT_MS = 30_000;
const RETRY_BACKOFF_MS = [1_000, 2_000, 4_000];

interface ErrorPayload {
  message?: string;
  error?: string;
  code?: string;
  errorCode?: string;
}

export interface PaperclipClientConfig {
  apiBase: string;
  apiKey: string;
  runId?: string | undefined;
  timeoutMs?: number;
  logger: Logger;
}

export class PaperclipClient {
  private readonly apiBase: string;
  private readonly apiKey: string;
  private readonly runId?: string | undefined;
  private readonly timeoutMs: number;
  private readonly logger: Logger;

  constructor(config: PaperclipClientConfig) {
    this.apiBase = config.apiBase.replace(/\/+$/, "");
    this.apiKey = config.apiKey;
    this.runId = config.runId?.trim() || undefined;
    this.timeoutMs = config.timeoutMs ?? DEFAULT_TIMEOUT_MS;
    this.logger = config.logger;
  }

  async hireAgent(companyId: string, request: HireAgentRequest): Promise<HireAgentResponse> {
    return this.requestJson<HireAgentResponse>("POST", `/api/companies/${companyId}/agent-hires`, request);
  }

  async getAgent(agentId: string): Promise<PaperclipAgent> {
    return this.requestJson<PaperclipAgent>("GET", `/api/agents/${agentId}`);
  }

  async patchAgent(agentId: string, patch: Partial<PaperclipAgent>): Promise<PaperclipAgent> {
    return this.requestJson<PaperclipAgent>("PATCH", `/api/agents/${agentId}`, patch);
  }

  async deleteAgent(agentId: string): Promise<void> {
    await this.requestJson("DELETE", `/api/agents/${agentId}`);
  }

  async listPendingApprovals(companyId: string): Promise<PendingApproval[]> {
    return this.requestJson<PendingApproval[]>(
      "GET",
      `/api/companies/${companyId}/approvals?status=pending`
    );
  }

  async getApproval(approvalId: string): Promise<PendingApproval> {
    return this.requestJson<PendingApproval>("GET", `/api/approvals/${approvalId}`);
  }

  async actOnApproval(approvalId: string, action: ApprovalAction, body?: Record<string, unknown>): Promise<void> {
    await this.requestJson("POST", `/api/approvals/${approvalId}/${action}`, body);
  }

  async listAgents(companyId: string): Promise<PaperclipAgent[]> {
    const result = await this.requestJson<{ agents: PaperclipAgent[] } | PaperclipAgent[]>(
      "GET",
      `/api/companies/${companyId}/agents`
    );
    return Array.isArray(result) ? result : result.agents ?? [];
  }

  async triggerHeartbeat(agentId: string): Promise<{ ok: boolean; runId?: string }> {
    return this.requestJson<{ ok: boolean; runId?: string }>(
      "POST",
      `/api/agents/${agentId}/heartbeat`
    );
  }

  async getAgentInbox(agentId: string): Promise<unknown[]> {
    const result = await this.requestJson<{ issues?: unknown[]; items?: unknown[] }>(
      "GET",
      `/api/agents/${agentId}/inbox-lite`
    );
    return (result as { issues?: unknown[]; items?: unknown[] }).issues ?? (result as { items?: unknown[] }).items ?? [];
  }

  async createIssue(companyId: string, input: Record<string, unknown>): Promise<unknown> {
    return this.requestJson("POST", `/api/companies/${companyId}/issues`, input);
  }

  async listIssues(companyId: string, filters?: { status?: string; assigneeAgentId?: string }): Promise<unknown[]> {
    const params = new URLSearchParams();
    if (filters?.status) params.set("status", filters.status);
    if (filters?.assigneeAgentId) params.set("assigneeAgentId", filters.assigneeAgentId);
    const qs = params.toString();
    const path = qs ? `/api/companies/${companyId}/issues?${qs}` : `/api/companies/${companyId}/issues`;
    const result = await this.requestJson<{ issues?: unknown[] } | unknown[]>("GET", path);
    return Array.isArray(result) ? result : (result as { issues?: unknown[] }).issues ?? [];
  }

  async getIssue(issueId: string): Promise<unknown> {
    return this.requestJson("GET", `/api/issues/${issueId}`);
  }

  async updateIssue(issueId: string, patch: Record<string, unknown>): Promise<unknown> {
    return this.requestJson("PATCH", `/api/issues/${issueId}`, patch);
  }

  async listIssueComments(issueId: string): Promise<unknown[]> {
    const result = await this.requestJson<{ comments?: unknown[] } | unknown[]>(
      "GET",
      `/api/issues/${issueId}/comments`
    );
    return Array.isArray(result) ? result : (result as { comments?: unknown[] }).comments ?? [];
  }

  async addIssueComment(issueId: string, body: string): Promise<unknown> {
    return this.requestJson("POST", `/api/issues/${issueId}/comments`, { body });
  }

  async listIssueDocuments(issueId: string): Promise<unknown[]> {
    const result = await this.requestJson<{ documents?: unknown[] } | unknown[]>(
      "GET",
      `/api/issues/${issueId}/documents`
    );
    return Array.isArray(result) ? result : (result as { documents?: unknown[] }).documents ?? [];
  }

  async getIssueDocument(issueId: string, key: string): Promise<unknown> {
    return this.requestJson("GET", `/api/issues/${issueId}/documents/${key}`);
  }

  async listProjects(companyId: string): Promise<unknown[]> {
    const result = await this.requestJson<{ projects?: unknown[] } | unknown[]>(
      "GET",
      `/api/companies/${companyId}/projects`
    );
    return Array.isArray(result) ? result : (result as { projects?: unknown[] }).projects ?? [];
  }

  async createProject(companyId: string, input: Record<string, unknown>): Promise<unknown> {
    return this.requestJson("POST", `/api/companies/${companyId}/projects`, input);
  }

  async ping(): Promise<{ ok: boolean; version?: string }> {
    try {
      const response = await this.requestJson<{ version?: string }>("GET", "/api/health");
      if (response.version) {
        return { ok: true, version: response.version };
      }
      return { ok: true };
    } catch (error) {
      this.logger.warn({ err: error }, "paperclip ping failed");
      return { ok: false };
    }
  }

  private async requestJson<T>(method: string, path: string, body?: unknown): Promise<T> {
    const url = `${this.apiBase}${path}`;
    const maxAttempts = RETRY_BACKOFF_MS.length + 1;

    for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
      const startedAt = Date.now();
      try {
        const headers: Record<string, string> = {
          Authorization: `Bearer ${this.apiKey}`,
          "Content-Type": "application/json"
        };
        if (this.runId && this.isMutatingMethod(method)) {
          headers["X-Paperclip-Run-Id"] = this.runId;
        }
        const init: RequestInit = {
          method,
          headers
        };
        if (body !== undefined) {
          init.body = JSON.stringify(body);
        }

        const response = await this.fetchWithTimeout(url, {
          ...init
        });
        const durationMs = Date.now() - startedAt;

        this.logger.debug(
          { method, path, attempt: attempt + 1, statusCode: response.status, durationMs },
          "paperclip request complete"
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
          this.logger.debug({ method, path, attempt: attempt + 1, durationMs }, "paperclip timeout");
          throw new PaperclipTimeoutError();
        }
        if (error instanceof PaperclipApiError) {
          throw error;
        }
        throw new PaperclipApiError({
          statusCode: 0,
          errorCode: "PAPERCLIP_NETWORK_ERROR",
          message: error instanceof Error ? error.message : "Paperclip request failed",
          retryable: true
        });
      }
    }

    throw new PaperclipApiError({
      statusCode: 500,
      errorCode: "PAPERCLIP_RETRY_EXHAUSTED",
      message: "Paperclip request failed after retries",
      retryable: true
    });
  }

  private async fetchWithTimeout(url: string, init: RequestInit): Promise<Response> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      return await fetch(url, {
        ...init,
        signal: controller.signal
      });
    } finally {
      clearTimeout(timeout);
    }
  }

  private async mapError(response: Response): Promise<PaperclipApiError> {
    const payload = this.tryParseError(await response.text());
    const message = payload.message ?? payload.error ?? `Paperclip API error (${response.status})`;
    const errorCode = payload.errorCode ?? payload.code ?? "PAPERCLIP_API_ERROR";

    if (response.status === 401 || response.status === 403) {
      return new PaperclipAuthError(response.status, message);
    }
    if (response.status === 404) {
      return new PaperclipNotFoundError(message);
    }
    return new PaperclipApiError({
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

  private isMutatingMethod(method: string): boolean {
    return ["POST", "PATCH", "PUT", "DELETE"].includes(method.toUpperCase());
  }

  private async delay(ms: number): Promise<void> {
    await new Promise((resolve) => setTimeout(resolve, ms));
  }
}
