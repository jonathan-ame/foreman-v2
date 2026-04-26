import { describe, expect, it, vi, beforeEach } from "vitest";
import type { AppDeps } from "../app-deps.js";
import { createLogger } from "../config/logger.js";
import { Hono } from "hono";
import { registerPaperclipProxyRoutes } from "./paperclip-proxy.js";

const { resolveSessionCustomerIdMock, getCustomerByIdMock } = vi.hoisted(() => ({
  resolveSessionCustomerIdMock: vi.fn(),
  getCustomerByIdMock: vi.fn()
}));

vi.mock("../auth/session.js", () => ({
  resolveSessionCustomerId: resolveSessionCustomerIdMock
}));

vi.mock("../db/customers.js", () => ({
  getCustomerById: getCustomerByIdMock
}));

const listAgentsMock = vi.fn();
const getAgentMock = vi.fn();
const triggerHeartbeatMock = vi.fn();
const getAgentInboxMock = vi.fn();
const createIssueMock = vi.fn();
const listIssuesMock = vi.fn();
const getIssueMock = vi.fn();
const updateIssueMock = vi.fn();
const listIssueCommentsMock = vi.fn();
const addIssueCommentMock = vi.fn();
const listIssueDocumentsMock = vi.fn();
const getIssueDocumentMock = vi.fn();
const listProjectsMock = vi.fn();
const createProjectMock = vi.fn();
const listPendingApprovalsMock = vi.fn();
const actOnApprovalMock = vi.fn();

const paperclipClient = {
  listAgents: listAgentsMock,
  getAgent: getAgentMock,
  triggerHeartbeat: triggerHeartbeatMock,
  getAgentInbox: getAgentInboxMock,
  createIssue: createIssueMock,
  listIssues: listIssuesMock,
  getIssue: getIssueMock,
  updateIssue: updateIssueMock,
  listIssueComments: listIssueCommentsMock,
  addIssueComment: addIssueCommentMock,
  listIssueDocuments: listIssueDocumentsMock,
  getIssueDocument: getIssueDocumentMock,
  listProjects: listProjectsMock,
  createProject: createProjectMock,
  listPendingApprovals: listPendingApprovalsMock,
  actOnApproval: actOnApprovalMock,
  hireAgent: vi.fn(),
  patchAgent: vi.fn(),
  deleteAgent: vi.fn(),
  getApproval: vi.fn(),
  ping: vi.fn()
};

const LINKED_CUSTOMER = {
  customer_id: "customer-1",
  paperclip_company_id: "pc-company-1",
  workspace_slug: "ws-test",
  email: "test@example.com",
  display_name: "Test User",
  current_billing_mode: "trial",
  payment_status: "trial"
};

const UNLINKED_CUSTOMER = {
  customer_id: "customer-2",
  paperclip_company_id: null,
  workspace_slug: "ws-unlinked",
  email: "unlinked@example.com",
  display_name: "Unlinked User",
  current_billing_mode: "trial",
  payment_status: "trial"
};

function buildApp(depsOverrides?: Partial<AppDeps>): { app: Hono; deps: AppDeps } {
  const app = new Hono();
  const logger = createLogger("test");
  const dbMock = {
    from: vi.fn(() => ({
      select: vi.fn(() => ({
        eq: vi.fn(() => ({
          order: vi.fn(async () => ({
            data: [
              {
                agent_id: "local-a1",
                display_name: "Local CEO",
                role: "ceo",
                model_tier: "hybrid",
                model_primary: "openrouter/auto",
                current_status: "active",
                paperclip_agent_id: null,
                openclaw_agent_id: "ws-test-ceo",
                provisioned_at: "2026-01-01T00:00:00Z"
              }
            ]
          }))
        }))
      }))
    }))
  };
  const deps: AppDeps = {
    clients: {
      paperclip: paperclipClient as unknown as AppDeps["clients"]["paperclip"],
      openclaw: {} as AppDeps["clients"]["openclaw"],
      stripe: {} as AppDeps["clients"]["stripe"],
      email: {} as AppDeps["clients"]["email"],
      composio: {} as AppDeps["clients"]["composio"],
      tavily: {} as AppDeps["clients"]["tavily"]
    },
    webhookDispatcher: {} as AppDeps["webhookDispatcher"],
    db: dbMock as unknown as AppDeps["db"],
    logger,
    env: {} as AppDeps["env"],
    ...depsOverrides
  };
  registerPaperclipProxyRoutes(app, deps);
  return { app, deps };
}

function authedRequest(url: string, init?: RequestInit): RequestInit & { headers: Record<string, string> } {
  return {
    ...init,
    headers: {
      ...(init?.headers as Record<string, string> ?? {}),
      Cookie: "foreman_session=test"
    }
  };
}

describe("Paperclip proxy routes — E2E integration", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    resolveSessionCustomerIdMock.mockResolvedValue("customer-1");
    getCustomerByIdMock.mockResolvedValue(LINKED_CUSTOMER);
  });

  describe("auth guard", () => {
    it("returns 401 when session is missing", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue(null);
      const { app } = buildApp();

      const res = await app.request("/api/internal/agents");

      expect(res.status).toBe(401);
    });

    it("returns 401 for POST endpoints when session is missing", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue(null);
      const { app } = buildApp();

      const res = await app.request("/api/internal/tasks", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ title: "test" })
      });

      expect(res.status).toBe(401);
    });
  });

  describe("paperclip not linked", () => {
    beforeEach(() => {
      getCustomerByIdMock.mockResolvedValue(UNLINKED_CUSTOMER);
    });

    it("GET /agents falls back to local DB agents", async () => {
      const { app } = buildApp();

      const res = await app.request("/api/internal/agents", authedRequest("/api/internal/agents"));

      expect(res.status).toBe(200);
      expect(listAgentsMock).not.toHaveBeenCalled();
      const data = await res.json() as { agents: unknown[] };
      expect(data.agents).toHaveLength(1);
    });

    it("GET /agents/:agentId returns paperclip_not_linked", async () => {
      const { app } = buildApp();

      const res = await app.request("/api/internal/agents/a1", authedRequest("/api/internal/agents/a1"));

      expect(res.status).toBe(400);
      const data = await res.json() as { error: string };
      expect(data.error).toBe("paperclip_not_linked");
    });

    it("GET /agents/:agentId/inbox returns paperclip_not_linked", async () => {
      const { app } = buildApp();

      const res = await app.request("/api/internal/agents/a1/inbox", authedRequest("/api/internal/agents/a1/inbox"));

      expect(res.status).toBe(400);
      const data = await res.json() as { error: string };
      expect(data.error).toBe("paperclip_not_linked");
    });

    it("POST /tasks returns paperclip_not_linked", async () => {
      const { app } = buildApp();

      const res = await app.request("/api/internal/tasks", {
        method: "POST",
        ...authedRequest("/api/internal/tasks", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ title: "test" })
        })
      });

      expect(res.status).toBe(400);
      const data = await res.json() as { error: string };
      expect(data.error).toBe("paperclip_not_linked");
    });

    it("GET /tasks returns paperclip_not_linked", async () => {
      const { app } = buildApp();

      const res = await app.request("/api/internal/tasks", authedRequest("/api/internal/tasks"));

      expect(res.status).toBe(400);
    });

    it("GET /projects returns paperclip_not_linked", async () => {
      const { app } = buildApp();

      const res = await app.request("/api/internal/projects", authedRequest("/api/internal/projects"));

      expect(res.status).toBe(400);
    });

    it("POST /projects returns paperclip_not_linked", async () => {
      const { app } = buildApp();

      const res = await app.request("/api/internal/projects", {
        method: "POST",
        ...authedRequest("/api/internal/projects", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ name: "test" })
        })
      });

      expect(res.status).toBe(400);
    });

    it("GET /approvals returns paperclip_not_linked", async () => {
      const { app } = buildApp();

      const res = await app.request("/api/internal/approvals", authedRequest("/api/internal/approvals"));

      expect(res.status).toBe(400);
    });
  });

  describe("GET /api/internal/agents", () => {
    it("returns agents from Paperclip when company is linked", async () => {
      const { app } = buildApp();
      listAgentsMock.mockResolvedValue([{ id: "a1", name: "CEO", role: "ceo" }]);

      const res = await app.request("/api/internal/agents", authedRequest("/api/internal/agents"));

      expect(res.status).toBe(200);
      expect(listAgentsMock).toHaveBeenCalledWith("pc-company-1");
      const data = await res.json() as { agents: unknown[] };
      expect(data.agents).toHaveLength(1);
    });

    it("falls back to local DB when Paperclip API fails", async () => {
      const { app } = buildApp();
      listAgentsMock.mockRejectedValue(new Error("Paperclip down"));

      const res = await app.request("/api/internal/agents", authedRequest("/api/internal/agents"));

      expect(res.status).toBe(200);
      const data = await res.json() as { agents: unknown[] };
      expect(data.agents).toHaveLength(1);
    });
  });

  describe("GET /api/internal/agents/:agentId", () => {
    it("returns a single agent from Paperclip", async () => {
      const { app } = buildApp();
      getAgentMock.mockResolvedValue({ id: "a1", name: "CEO", role: "ceo" });

      const res = await app.request("/api/internal/agents/a1", authedRequest("/api/internal/agents/a1"));

      expect(res.status).toBe(200);
      expect(getAgentMock).toHaveBeenCalledWith("a1");
      const data = await res.json() as { agent: { id: string } };
      expect(data.agent.id).toBe("a1");
    });

    it("returns 500 when Paperclip API fails", async () => {
      const { app } = buildApp();
      getAgentMock.mockRejectedValue(new Error("Paperclip down"));

      const res = await app.request("/api/internal/agents/a1", authedRequest("/api/internal/agents/a1"));

      expect(res.status).toBe(500);
    });
  });

  describe("POST /api/internal/agents/:agentId/heartbeat", () => {
    it("triggers a heartbeat and returns runId", async () => {
      const { app } = buildApp();
      triggerHeartbeatMock.mockResolvedValue({ ok: true, runId: "run-1" });

      const res = await app.request("/api/internal/agents/a1/heartbeat", {
        method: "POST",
        ...authedRequest("/api/internal/agents/a1/heartbeat")
      });

      expect(res.status).toBe(200);
      expect(triggerHeartbeatMock).toHaveBeenCalledWith("a1");
      const data = await res.json() as { ok: boolean; runId: string | null };
      expect(data.ok).toBe(true);
      expect(data.runId).toBe("run-1");
    });

    it("returns ok:true with null runId when Paperclip omits runId", async () => {
      const { app } = buildApp();
      triggerHeartbeatMock.mockResolvedValue({ ok: true });

      const res = await app.request("/api/internal/agents/a1/heartbeat", {
        method: "POST",
        ...authedRequest("/api/internal/agents/a1/heartbeat")
      });

      expect(res.status).toBe(200);
      const data = await res.json() as { ok: boolean; runId: string | null };
      expect(data.runId).toBeNull();
    });

    it("returns 500 when Paperclip API fails", async () => {
      const { app } = buildApp();
      triggerHeartbeatMock.mockRejectedValue(new Error("timeout"));

      const res = await app.request("/api/internal/agents/a1/heartbeat", {
        method: "POST",
        ...authedRequest("/api/internal/agents/a1/heartbeat")
      });

      expect(res.status).toBe(500);
    });
  });

  describe("GET /api/internal/agents/:agentId/inbox", () => {
    it("returns agent inbox from Paperclip", async () => {
      const { app } = buildApp();
      getAgentInboxMock.mockResolvedValue([{ id: "issue-1", title: "Inbox item" }]);

      const res = await app.request("/api/internal/agents/a1/inbox", authedRequest("/api/internal/agents/a1/inbox"));

      expect(res.status).toBe(200);
      expect(getAgentInboxMock).toHaveBeenCalledWith("a1");
      const data = await res.json() as { inbox: unknown[] };
      expect(data.inbox).toHaveLength(1);
    });

    it("returns 500 when Paperclip API fails", async () => {
      const { app } = buildApp();
      getAgentInboxMock.mockRejectedValue(new Error("down"));

      const res = await app.request("/api/internal/agents/a1/inbox", authedRequest("/api/internal/agents/a1/inbox"));

      expect(res.status).toBe(500);
    });
  });

  describe("POST /api/internal/tasks", () => {
    it("creates a task via Paperclip", async () => {
      const { app } = buildApp();
      createIssueMock.mockResolvedValue({ id: "issue-1", title: "Test task" });

      const res = await app.request("/api/internal/tasks", {
        method: "POST",
        ...authedRequest("/api/internal/tasks", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ title: "Test task", priority: "high" })
        })
      });

      expect(res.status).toBe(201);
      expect(createIssueMock).toHaveBeenCalledWith("pc-company-1", expect.objectContaining({ title: "Test task", priority: "high" }));
    });

    it("validates title is required", async () => {
      const { app } = buildApp();

      const res = await app.request("/api/internal/tasks", {
        method: "POST",
        ...authedRequest("/api/internal/tasks", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ priority: "high" })
        })
      });

      expect(res.status).toBe(400);
      const data = await res.json() as { error: string };
      expect(data.error).toBe("invalid_input");
    });

    it("validates title max length", async () => {
      const { app } = buildApp();

      const res = await app.request("/api/internal/tasks", {
        method: "POST",
        ...authedRequest("/api/internal/tasks", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ title: "x".repeat(501) })
        })
      });

      expect(res.status).toBe(400);
    });

    it("validates priority enum", async () => {
      const { app } = buildApp();

      const res = await app.request("/api/internal/tasks", {
        method: "POST",
        ...authedRequest("/api/internal/tasks", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ title: "Test", priority: "urgent" })
        })
      });

      expect(res.status).toBe(400);
    });

    it("accepts optional fields", async () => {
      const { app } = buildApp();
      createIssueMock.mockResolvedValue({ id: "issue-1" });

      const res = await app.request("/api/internal/tasks", {
        method: "POST",
        ...authedRequest("/api/internal/tasks", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ title: "Task", description: "desc", assigneeAgentId: "00000000-0000-4000-8000-000000000001", projectId: "00000000-0000-4000-8000-000000000002", goalId: "00000000-0000-4000-8000-000000000003", parentId: "00000000-0000-4000-8000-000000000004" })
        })
      });

      expect(res.status).toBe(201);
    });

    it("returns 500 when Paperclip API fails", async () => {
      const { app } = buildApp();
      createIssueMock.mockRejectedValue(new Error("down"));

      const res = await app.request("/api/internal/tasks", {
        method: "POST",
        ...authedRequest("/api/internal/tasks", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ title: "Test" })
        })
      });

      expect(res.status).toBe(500);
    });
  });

  describe("GET /api/internal/tasks", () => {
    it("lists tasks from Paperclip", async () => {
      const { app } = buildApp();
      listIssuesMock.mockResolvedValue([{ id: "t1", title: "Task 1" }]);

      const res = await app.request("/api/internal/tasks", authedRequest("/api/internal/tasks"));

      expect(res.status).toBe(200);
      expect(listIssuesMock).toHaveBeenCalledWith("pc-company-1", {});
      const data = await res.json() as { tasks: unknown[] };
      expect(data.tasks).toHaveLength(1);
    });

    it("passes status filter to Paperclip", async () => {
      const { app } = buildApp();
      listIssuesMock.mockResolvedValue([]);

      const res = await app.request("/api/internal/tasks?status=in_progress", authedRequest("/api/internal/tasks?status=in_progress"));

      expect(res.status).toBe(200);
      expect(listIssuesMock).toHaveBeenCalledWith("pc-company-1", { status: "in_progress" });
    });

    it("passes assigneeAgentId filter to Paperclip", async () => {
      const { app } = buildApp();
      listIssuesMock.mockResolvedValue([]);

      const res = await app.request("/api/internal/tasks?assigneeAgentId=a1", authedRequest("/api/internal/tasks?assigneeAgentId=a1"));

      expect(res.status).toBe(200);
      expect(listIssuesMock).toHaveBeenCalledWith("pc-company-1", { assigneeAgentId: "a1" });
    });

    it("passes both filters to Paperclip", async () => {
      const { app } = buildApp();
      listIssuesMock.mockResolvedValue([]);

      const res = await app.request("/api/internal/tasks?status=done&assigneeAgentId=a2", authedRequest("/api/internal/tasks?status=done&assigneeAgentId=a2"));

      expect(listIssuesMock).toHaveBeenCalledWith("pc-company-1", { status: "done", assigneeAgentId: "a2" });
    });

    it("returns 500 when Paperclip API fails", async () => {
      const { app } = buildApp();
      listIssuesMock.mockRejectedValue(new Error("down"));

      const res = await app.request("/api/internal/tasks", authedRequest("/api/internal/tasks"));

      expect(res.status).toBe(500);
    });
  });

  describe("GET /api/internal/tasks/:taskId", () => {
    it("returns task and comments", async () => {
      const { app } = buildApp();
      getIssueMock.mockResolvedValue({ id: "t1", title: "Task 1" });
      listIssueCommentsMock.mockResolvedValue([{ id: "c1", body: "Comment 1" }]);

      const res = await app.request("/api/internal/tasks/t1", authedRequest("/api/internal/tasks/t1"));

      expect(res.status).toBe(200);
      expect(getIssueMock).toHaveBeenCalledWith("t1");
      expect(listIssueCommentsMock).toHaveBeenCalledWith("t1");
      const data = await res.json() as { task: { id: string }; comments: unknown[] };
      expect(data.task.id).toBe("t1");
      expect(data.comments).toHaveLength(1);
    });

    it("returns 500 when Paperclip API fails", async () => {
      const { app } = buildApp();
      getIssueMock.mockRejectedValue(new Error("down"));

      const res = await app.request("/api/internal/tasks/t1", authedRequest("/api/internal/tasks/t1"));

      expect(res.status).toBe(500);
    });
  });

  describe("PATCH /api/internal/tasks/:taskId", () => {
    it("updates a task via Paperclip", async () => {
      const { app } = buildApp();
      updateIssueMock.mockResolvedValue({ id: "t1", status: "done" });

      const res = await app.request("/api/internal/tasks/t1", {
        method: "PATCH",
        ...authedRequest("/api/internal/tasks/t1", {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ status: "done" })
        })
      });

      expect(res.status).toBe(200);
      expect(updateIssueMock).toHaveBeenCalledWith("t1", { status: "done" });
    });

    it("validates status enum", async () => {
      const { app } = buildApp();

      const res = await app.request("/api/internal/tasks/t1", {
        method: "PATCH",
        ...authedRequest("/api/internal/tasks/t1", {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ status: "unknown_status" })
        })
      });

      expect(res.status).toBe(400);
    });

    it("validates title max length", async () => {
      const { app } = buildApp();

      const res = await app.request("/api/internal/tasks/t1", {
        method: "PATCH",
        ...authedRequest("/api/internal/tasks/t1", {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ title: "x".repeat(501) })
        })
      });

      expect(res.status).toBe(400);
    });

    it("validates comment max length", async () => {
      const { app } = buildApp();

      const res = await app.request("/api/internal/tasks/t1", {
        method: "PATCH",
        ...authedRequest("/api/internal/tasks/t1", {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ comment: "x".repeat(50001) })
        })
      });

      expect(res.status).toBe(400);
    });

    it("accepts nullable assigneeAgentId to unassign", async () => {
      const { app } = buildApp();
      updateIssueMock.mockResolvedValue({ id: "t1" });

      const res = await app.request("/api/internal/tasks/t1", {
        method: "PATCH",
        ...authedRequest("/api/internal/tasks/t1", {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ assigneeAgentId: null })
        })
      });

      expect(res.status).toBe(200);
    });

    it("returns 500 when Paperclip API fails", async () => {
      const { app } = buildApp();
      updateIssueMock.mockRejectedValue(new Error("down"));

      const res = await app.request("/api/internal/tasks/t1", {
        method: "PATCH",
        ...authedRequest("/api/internal/tasks/t1", {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ status: "in_progress" })
        })
      });

      expect(res.status).toBe(500);
    });
  });

  describe("GET /api/internal/tasks/:taskId/comments", () => {
    it("lists comments for a task", async () => {
      const { app } = buildApp();
      listIssueCommentsMock.mockResolvedValue([{ id: "c1", body: "First" }, { id: "c2", body: "Second" }]);

      const res = await app.request("/api/internal/tasks/t1/comments", authedRequest("/api/internal/tasks/t1/comments"));

      expect(res.status).toBe(200);
      expect(listIssueCommentsMock).toHaveBeenCalledWith("t1");
      const data = await res.json() as { comments: unknown[] };
      expect(data.comments).toHaveLength(2);
    });

    it("returns 500 when Paperclip API fails", async () => {
      const { app } = buildApp();
      listIssueCommentsMock.mockRejectedValue(new Error("down"));

      const res = await app.request("/api/internal/tasks/t1/comments", authedRequest("/api/internal/tasks/t1/comments"));

      expect(res.status).toBe(500);
    });
  });

  describe("POST /api/internal/tasks/:taskId/comments", () => {
    it("adds a comment to a task", async () => {
      const { app } = buildApp();
      addIssueCommentMock.mockResolvedValue({ id: "c1", body: "My comment" });

      const res = await app.request("/api/internal/tasks/t1/comments", {
        method: "POST",
        ...authedRequest("/api/internal/tasks/t1/comments", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ body: "My comment" })
        })
      });

      expect(res.status).toBe(201);
      expect(addIssueCommentMock).toHaveBeenCalledWith("t1", "My comment");
    });

    it("validates body is required", async () => {
      const { app } = buildApp();

      const res = await app.request("/api/internal/tasks/t1/comments", {
        method: "POST",
        ...authedRequest("/api/internal/tasks/t1/comments", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({})
        })
      });

      expect(res.status).toBe(400);
    });

    it("validates body max length", async () => {
      const { app } = buildApp();

      const res = await app.request("/api/internal/tasks/t1/comments", {
        method: "POST",
        ...authedRequest("/api/internal/tasks/t1/comments", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ body: "x".repeat(50001) })
        })
      });

      expect(res.status).toBe(400);
    });

    it("returns 500 when Paperclip API fails", async () => {
      const { app } = buildApp();
      addIssueCommentMock.mockRejectedValue(new Error("down"));

      const res = await app.request("/api/internal/tasks/t1/comments", {
        method: "POST",
        ...authedRequest("/api/internal/tasks/t1/comments", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ body: "comment" })
        })
      });

      expect(res.status).toBe(500);
    });
  });

  describe("GET /api/internal/tasks/:taskId/documents", () => {
    it("lists documents for a task", async () => {
      const { app } = buildApp();
      listIssueDocumentsMock.mockResolvedValue([{ key: "doc1", name: "file.txt" }]);

      const res = await app.request("/api/internal/tasks/t1/documents", authedRequest("/api/internal/tasks/t1/documents"));

      expect(res.status).toBe(200);
      expect(listIssueDocumentsMock).toHaveBeenCalledWith("t1");
      const data = await res.json() as { documents: unknown[] };
      expect(data.documents).toHaveLength(1);
    });

    it("returns 500 when Paperclip API fails", async () => {
      const { app } = buildApp();
      listIssueDocumentsMock.mockRejectedValue(new Error("down"));

      const res = await app.request("/api/internal/tasks/t1/documents", authedRequest("/api/internal/tasks/t1/documents"));

      expect(res.status).toBe(500);
    });
  });

  describe("GET /api/internal/tasks/:taskId/documents/:key", () => {
    it("returns a specific document", async () => {
      const { app } = buildApp();
      getIssueDocumentMock.mockResolvedValue({ key: "doc1", content: "hello" });

      const res = await app.request("/api/internal/tasks/t1/documents/doc1", authedRequest("/api/internal/tasks/t1/documents/doc1"));

      expect(res.status).toBe(200);
      expect(getIssueDocumentMock).toHaveBeenCalledWith("t1", "doc1");
      const data = await res.json() as { document: { key: string } };
      expect(data.document.key).toBe("doc1");
    });

    it("returns 500 when Paperclip API fails", async () => {
      const { app } = buildApp();
      getIssueDocumentMock.mockRejectedValue(new Error("down"));

      const res = await app.request("/api/internal/tasks/t1/documents/doc1", authedRequest("/api/internal/tasks/t1/documents/doc1"));

      expect(res.status).toBe(500);
    });
  });

  describe("GET /api/internal/projects", () => {
    it("lists projects from Paperclip", async () => {
      const { app } = buildApp();
      listProjectsMock.mockResolvedValue([{ id: "p1", name: "Project Alpha" }]);

      const res = await app.request("/api/internal/projects", authedRequest("/api/internal/projects"));

      expect(res.status).toBe(200);
      expect(listProjectsMock).toHaveBeenCalledWith("pc-company-1");
      const data = await res.json() as { projects: unknown[] };
      expect(data.projects).toHaveLength(1);
    });

    it("returns 500 when Paperclip API fails", async () => {
      const { app } = buildApp();
      listProjectsMock.mockRejectedValue(new Error("down"));

      const res = await app.request("/api/internal/projects", authedRequest("/api/internal/projects"));

      expect(res.status).toBe(500);
    });
  });

  describe("POST /api/internal/projects", () => {
    it("creates a project via Paperclip", async () => {
      const { app } = buildApp();
      createProjectMock.mockResolvedValue({ id: "p1", name: "New Project" });

      const res = await app.request("/api/internal/projects", {
        method: "POST",
        ...authedRequest("/api/internal/projects", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ name: "New Project" })
        })
      });

      expect(res.status).toBe(201);
      expect(createProjectMock).toHaveBeenCalledWith("pc-company-1", { name: "New Project" });
    });

    it("returns 500 when Paperclip API fails", async () => {
      const { app } = buildApp();
      createProjectMock.mockRejectedValue(new Error("down"));

      const res = await app.request("/api/internal/projects", {
        method: "POST",
        ...authedRequest("/api/internal/projects", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ name: "New" })
        })
      });

      expect(res.status).toBe(500);
    });
  });

  describe("GET /api/internal/approvals", () => {
    it("lists pending approvals from Paperclip", async () => {
      const { app } = buildApp();
      listPendingApprovalsMock.mockResolvedValue([{ id: "ap1", type: "agent_hire" }]);

      const res = await app.request("/api/internal/approvals", authedRequest("/api/internal/approvals"));

      expect(res.status).toBe(200);
      expect(listPendingApprovalsMock).toHaveBeenCalledWith("pc-company-1");
      const data = await res.json() as { approvals: unknown[] };
      expect(data.approvals).toHaveLength(1);
    });

    it("returns 500 when Paperclip API fails", async () => {
      const { app } = buildApp();
      listPendingApprovalsMock.mockRejectedValue(new Error("down"));

      const res = await app.request("/api/internal/approvals", authedRequest("/api/internal/approvals"));

      expect(res.status).toBe(500);
    });
  });

  describe("POST /api/internal/approvals/:approvalId/approve", () => {
    it("approves an approval", async () => {
      const { app } = buildApp();
      actOnApprovalMock.mockResolvedValue(undefined);

      const res = await app.request("/api/internal/approvals/ap-1/approve", {
        method: "POST",
        ...authedRequest("/api/internal/approvals/ap-1/approve")
      });

      expect(res.status).toBe(200);
      expect(actOnApprovalMock).toHaveBeenCalledWith("ap-1", "approve");
      const data = await res.json() as { ok: boolean };
      expect(data.ok).toBe(true);
    });

    it("returns 500 when Paperclip API fails", async () => {
      const { app } = buildApp();
      actOnApprovalMock.mockRejectedValue(new Error("down"));

      const res = await app.request("/api/internal/approvals/ap-1/approve", {
        method: "POST",
        ...authedRequest("/api/internal/approvals/ap-1/approve")
      });

      expect(res.status).toBe(500);
    });
  });

  describe("POST /api/internal/approvals/:approvalId/reject", () => {
    it("rejects an approval", async () => {
      const { app } = buildApp();
      actOnApprovalMock.mockResolvedValue(undefined);

      const res = await app.request("/api/internal/approvals/ap-1/reject", {
        method: "POST",
        ...authedRequest("/api/internal/approvals/ap-1/reject")
      });

      expect(res.status).toBe(200);
      expect(actOnApprovalMock).toHaveBeenCalledWith("ap-1", "reject");
      const data = await res.json() as { ok: boolean };
      expect(data.ok).toBe(true);
    });

    it("returns 500 when Paperclip API fails", async () => {
      const { app } = buildApp();
      actOnApprovalMock.mockRejectedValue(new Error("down"));

      const res = await app.request("/api/internal/approvals/ap-1/reject", {
        method: "POST",
        ...authedRequest("/api/internal/approvals/ap-1/reject")
      });

      expect(res.status).toBe(500);
    });
  });
});