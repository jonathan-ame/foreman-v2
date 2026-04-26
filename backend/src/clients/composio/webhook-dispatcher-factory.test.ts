import { describe, expect, it, vi } from "vitest";
import { createLogger } from "../../config/logger.js";
import { createWebhookDispatcher } from "./webhook-dispatcher-factory.js";

describe("createWebhookDispatcher", () => {
  const logger = createLogger("factory-test");

  const fromMock = vi.fn().mockReturnValue({
    select: vi.fn().mockReturnValue({
      eq: vi.fn().mockReturnValue({
        maybeSingle: vi.fn().mockResolvedValue({ data: null })
      })
    }),
    insert: vi.fn().mockReturnValue({
      select: vi.fn().mockReturnValue({
        single: vi.fn().mockResolvedValue({
          data: {
            id: "evt_test",
            trigger_id: "trg_test",
            trigger_type: "github_on_issue_opened",
            toolkit: "github",
            payload: {},
            customer_id: null,
            received_at: new Date().toISOString(),
            processed_at: null,
            processing_status: "pending",
            error_message: null,
            created_at: new Date().toISOString()
          }
        })
      })
    }),
    update: vi.fn().mockReturnValue({
      eq: vi.fn().mockResolvedValue({ error: null })
    })
  });

  const db = { from: fromMock } as unknown as import("../../db/supabase.js").SupabaseClient;

  it("creates a dispatcher with notification, agent_issue, and logging handlers", () => {
    const dispatcher = createWebhookDispatcher({ db, logger });

    const handlerNames = (dispatcher as unknown as { handlers: { name: string }[] }).handlers.map((h) => h.name);

    expect(handlerNames).toContain("notification");
    expect(handlerNames).toContain("agent_issue");
    expect(handlerNames).toContain("logging");
    expect(handlerNames).toHaveLength(3);
  });

  it("creates a dispatcher with onAgentIssueCreate callback when provided", () => {
    const callback = vi.fn();
    const dispatcher = createWebhookDispatcher({ db, logger, onAgentIssueCreate: callback });

    expect(dispatcher).toBeDefined();
  });

  it("creates a dispatcher without onAgentIssueCreate callback", () => {
    const dispatcher = createWebhookDispatcher({ db, logger });

    expect(dispatcher).toBeDefined();
  });
});