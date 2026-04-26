import { describe, expect, it, vi } from "vitest";
import { createLogger } from "../../../config/logger.js";
import { AgentIssueHandler, ISSUE_TRIGGER_TYPES } from "./agent-issue-handler.js";
import type { DispatcherContext, HandlerResult } from "../webhook-dispatcher.js";
import type { WebhookEventRow } from "../../../db/webhook-events.js";

function makeCtx(overrides: Partial<DispatcherContext> = {}): DispatcherContext {
  const db = {
    from: vi.fn().mockReturnValue({
      select: vi.fn().mockReturnValue({ eq: vi.fn() }),
      insert: vi.fn().mockReturnValue({ select: vi.fn().mockReturnValue({ single: vi.fn() }) }),
      update: vi.fn().mockReturnValue({ eq: vi.fn() })
    })
  } as unknown as DispatcherContext["db"];

  return {
    db,
    logger: createLogger("test"),
    webhookEvent: {
      id: "evt_test",
      trigger_id: "trg_test",
      trigger_type: "github_on_issue_opened",
      toolkit: "github",
      payload: { title: "Test issue" },
      customer_id: "cust_1",
      received_at: "2026-04-25T00:00:00Z",
      processed_at: null,
      processing_status: "pending" as const,
      error_message: null,
      created_at: "2026-04-25T00:00:00Z"
    } as WebhookEventRow,
    triggerRow: {
      customer_id: "cust_1",
      trigger_type: "github_on_issue_opened",
      toolkit_slug: "github",
      config: {}
    },
    rawPayload: {
      trigger_id: "trg_test",
      trigger_type: "github_on_issue_opened",
      payload: { title: "Test issue", body: "Issue body", html_url: "https://github.com/org/repo/issues/1" }
    },
    ...overrides
  };
}

describe("AgentIssueHandler", () => {
  const logger = createLogger("agent-issue-handler-test");

  describe("canHandle", () => {
    it("returns true for github_on_issue_opened with customer_id", () => {
      const handler = new AgentIssueHandler({ logger });
      const ctx = makeCtx();
      expect(handler.canHandle(ctx)).toBe(true);
    });

    it("returns true for all ISSUE_TRIGGER_TYPES", () => {
      const handler = new AgentIssueHandler({ logger });
      for (const triggerType of ISSUE_TRIGGER_TYPES) {
        const ctx = makeCtx({
          triggerRow: { customer_id: "cust_1", trigger_type: triggerType, toolkit_slug: triggerType.split("_")[0] ?? "", config: {} },
          webhookEvent: { ...makeCtx().webhookEvent, trigger_type: triggerType }
        });
        expect(handler.canHandle(ctx)).toBe(true);
      }
    });

    it("returns false when no customer_id on trigger row", () => {
      const handler = new AgentIssueHandler({ logger });
      const ctx = makeCtx({ triggerRow: null });
      expect(handler.canHandle(ctx)).toBe(false);
    });

    it("returns false for non-issue trigger types", () => {
      const handler = new AgentIssueHandler({ logger });
      const ctx = makeCtx({
        triggerRow: { customer_id: "cust_1", trigger_type: "gmail_on_new_message", toolkit_slug: "gmail", config: {} },
        webhookEvent: { ...makeCtx().webhookEvent, trigger_type: "gmail_on_new_message" }
      });
      expect(handler.canHandle(ctx)).toBe(false);
    });
  });

  describe("handle", () => {
    it("calls onAgentIssueCreate callback when provided", async () => {
      const onAgentIssueCreate = vi.fn().mockResolvedValue({ id: "issue_1" });
      const handler = new AgentIssueHandler({ logger, onAgentIssueCreate });
      const ctx = makeCtx();

      const result = await handler.handle(ctx);

      expect(onAgentIssueCreate).toHaveBeenCalledWith("cust_1", expect.objectContaining({ source: "github" }));
      expect(result.delivered).toBe(true);
      expect(result.data?.customerId).toBe("cust_1");
    });

    it("returns delivered=true with review note when no callback configured", async () => {
      const handler = new AgentIssueHandler({ logger });
      const ctx = makeCtx();

      const result = await handler.handle(ctx);

      expect(result.delivered).toBe(true);
      expect(result.data?.note).toBe("no callback configured - logged for review");
    });

    it("returns delivered=false when callback throws", async () => {
      const onAgentIssueCreate = vi.fn().mockRejectedValue(new Error("callback failed"));
      const handler = new AgentIssueHandler({ logger, onAgentIssueCreate });
      const ctx = makeCtx();

      const result = await handler.handle(ctx);

      expect(result.delivered).toBe(false);
      expect(result.message).toBe("callback failed");
    });

    it("extracts jira issue fields from payload", async () => {
      const onAgentIssueCreate = vi.fn().mockResolvedValue({});
      const handler = new AgentIssueHandler({ logger, onAgentIssueCreate });
      const ctx = makeCtx({
        triggerRow: { customer_id: "cust_1", trigger_type: "jira_on_issue_created", toolkit_slug: "jira", config: {} },
        webhookEvent: { ...makeCtx().webhookEvent, trigger_type: "jira_on_issue_created" },
        rawPayload: {
          trigger_type: "jira_on_issue_created",
          payload: { summary: "Jira ticket", description: "Details", key: "PROJ-123", priority: "high" }
        }
      });

      await handler.handle(ctx);

      expect(onAgentIssueCreate).toHaveBeenCalledWith("cust_1", expect.objectContaining({
        source: "jira",
        title: "Jira ticket",
        key: "PROJ-123"
      }));
    });
  });
});