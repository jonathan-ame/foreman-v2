import type { Context, Hono } from "hono";
import { z } from "zod";
import { resolveSessionCustomerId } from "../auth/session.js";
import type { AppDeps } from "../app-deps.js";
import { getCustomerById } from "../db/customers.js";

const CreateTaskSchema = z.object({
  title: z.string().min(1).max(500),
  description: z.string().min(1).max(50000).optional(),
  priority: z.enum(["critical", "high", "medium", "low"]).default("medium"),
  assigneeAgentId: z.string().uuid().optional(),
  projectId: z.string().uuid().optional(),
  goalId: z.string().uuid().optional(),
  parentId: z.string().uuid().optional()
});

const UpdateTaskSchema = z.object({
  status: z.enum(["backlog", "todo", "in_progress", "in_review", "done", "blocked", "cancelled"]).optional(),
  title: z.string().min(1).max(500).optional(),
  description: z.string().min(1).max(50000).optional(),
  priority: z.enum(["critical", "high", "medium", "low"]).optional(),
  assigneeAgentId: z.string().uuid().nullable().optional(),
  comment: z.string().max(50000).optional()
});

const AddCommentSchema = z.object({
  body: z.string().min(1).max(50000)
});

async function getPaperclipCompanyId(deps: AppDeps, customerId: string): Promise<string | null> {
  const customer = await getCustomerById(deps.db, customerId);
  return customer?.paperclip_company_id ?? null;
}

function paperclipNotLinked(c: Context) {
  return c.json({ error: "paperclip_not_linked", message: "No Paperclip company linked to this account. Complete onboarding first." }, 400);
}

export function registerPaperclipProxyRoutes(app: Hono, deps: AppDeps) {
  app.get("/api/internal/agents", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const companyId = await getPaperclipCompanyId(deps, customerId);
    if (!companyId) {
      const localAgents = await deps.db
        .from("agents")
        .select("agent_id, display_name, role, model_tier, model_primary, current_status, paperclip_agent_id, openclaw_agent_id, provisioned_at")
        .eq("customer_id", customerId)
        .order("provisioned_at", { ascending: true });
      return c.json({ agents: localAgents.data ?? [] });
    }

    try {
      const agents = await deps.clients.paperclip.listAgents(companyId);
      return c.json({ agents });
    } catch (err) {
      deps.logger.error({ err, customerId }, "paperclip-proxy: failed to list agents");
      const localAgents = await deps.db
        .from("agents")
        .select("agent_id, display_name, role, model_tier, model_primary, current_status, paperclip_agent_id, openclaw_agent_id, provisioned_at")
        .eq("customer_id", customerId)
        .order("provisioned_at", { ascending: true });
      return c.json({ agents: localAgents.data ?? [] });
    }
  });

  app.get("/api/internal/agents/:agentId", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const companyId = await getPaperclipCompanyId(deps, customerId);
    if (!companyId) return paperclipNotLinked(c);

    const agentId = c.req.param("agentId");
    try {
      const agent = await deps.clients.paperclip.getAgent(agentId);
      return c.json({ agent });
    } catch (err) {
      deps.logger.error({ err, customerId, agentId }, "paperclip-proxy: failed to get agent");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.post("/api/internal/agents/:agentId/heartbeat", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const agentId = c.req.param("agentId");
    try {
      const result = await deps.clients.paperclip.triggerHeartbeat(agentId);
      return c.json({ ok: true, runId: result.runId ?? null });
    } catch (err) {
      deps.logger.error({ err, customerId, agentId }, "paperclip-proxy: failed to trigger heartbeat");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.get("/api/internal/agents/:agentId/inbox", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const companyId = await getPaperclipCompanyId(deps, customerId);
    if (!companyId) return paperclipNotLinked(c);

    const agentId = c.req.param("agentId");
    try {
      const inbox = await deps.clients.paperclip.getAgentInbox(agentId);
      return c.json({ inbox });
    } catch (err) {
      deps.logger.error({ err, customerId, agentId }, "paperclip-proxy: failed to get agent inbox");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.post("/api/internal/tasks", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const companyId = await getPaperclipCompanyId(deps, customerId);
    if (!companyId) return paperclipNotLinked(c);

    const body = await c.req.json();
    const parsed = CreateTaskSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    try {
      const task = await deps.clients.paperclip.createIssue(companyId, parsed.data);
      return c.json({ task }, 201);
    } catch (err) {
      deps.logger.error({ err, customerId }, "paperclip-proxy: failed to create task");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.get("/api/internal/tasks", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const companyId = await getPaperclipCompanyId(deps, customerId);
    if (!companyId) return paperclipNotLinked(c);

    const status = c.req.query("status");
    const assigneeAgentId = c.req.query("assigneeAgentId");
    try {
      const filters: { status?: string; assigneeAgentId?: string } = {};
      if (status) filters.status = status;
      if (assigneeAgentId) filters.assigneeAgentId = assigneeAgentId;
      const issues = await deps.clients.paperclip.listIssues(companyId, filters);
      return c.json({ tasks: issues });
    } catch (err) {
      deps.logger.error({ err, customerId }, "paperclip-proxy: failed to list tasks");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.get("/api/internal/tasks/:taskId", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const taskId = c.req.param("taskId");
    try {
      const [task, comments] = await Promise.all([
        deps.clients.paperclip.getIssue(taskId),
        deps.clients.paperclip.listIssueComments(taskId)
      ]);
      return c.json({ task, comments });
    } catch (err) {
      deps.logger.error({ err, customerId, taskId }, "paperclip-proxy: failed to get task");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.patch("/api/internal/tasks/:taskId", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const taskId = c.req.param("taskId");
    const body = await c.req.json();
    const parsed = UpdateTaskSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    try {
      const task = await deps.clients.paperclip.updateIssue(taskId, parsed.data);
      return c.json({ task });
    } catch (err) {
      deps.logger.error({ err, customerId, taskId }, "paperclip-proxy: failed to update task");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.get("/api/internal/tasks/:taskId/comments", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const taskId = c.req.param("taskId");
    try {
      const comments = await deps.clients.paperclip.listIssueComments(taskId);
      return c.json({ comments });
    } catch (err) {
      deps.logger.error({ err, customerId, taskId }, "paperclip-proxy: failed to list task comments");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.post("/api/internal/tasks/:taskId/comments", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const taskId = c.req.param("taskId");
    const body = await c.req.json();
    const parsed = AddCommentSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    try {
      const comment = await deps.clients.paperclip.addIssueComment(taskId, parsed.data.body);
      return c.json({ comment }, 201);
    } catch (err) {
      deps.logger.error({ err, customerId, taskId }, "paperclip-proxy: failed to add task comment");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.get("/api/internal/tasks/:taskId/documents", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const taskId = c.req.param("taskId");
    try {
      const documents = await deps.clients.paperclip.listIssueDocuments(taskId);
      return c.json({ documents });
    } catch (err) {
      deps.logger.error({ err, customerId, taskId }, "paperclip-proxy: failed to list task documents");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.get("/api/internal/tasks/:taskId/documents/:key", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const taskId = c.req.param("taskId");
    const key = c.req.param("key");
    try {
      const document = await deps.clients.paperclip.getIssueDocument(taskId, key);
      return c.json({ document });
    } catch (err) {
      deps.logger.error({ err, customerId, taskId }, "paperclip-proxy: failed to get task document");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.get("/api/internal/projects", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const companyId = await getPaperclipCompanyId(deps, customerId);
    if (!companyId) return paperclipNotLinked(c);

    try {
      const projects = await deps.clients.paperclip.listProjects(companyId);
      return c.json({ projects });
    } catch (err) {
      deps.logger.error({ err, customerId }, "paperclip-proxy: failed to list projects");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.post("/api/internal/projects", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const companyId = await getPaperclipCompanyId(deps, customerId);
    if (!companyId) return paperclipNotLinked(c);

    const body = await c.req.json();
    try {
      const project = await deps.clients.paperclip.createProject(companyId, body);
      return c.json({ project }, 201);
    } catch (err) {
      deps.logger.error({ err, customerId }, "paperclip-proxy: failed to create project");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.get("/api/internal/approvals", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const companyId = await getPaperclipCompanyId(deps, customerId);
    if (!companyId) return paperclipNotLinked(c);

    try {
      const approvals = await deps.clients.paperclip.listPendingApprovals(companyId);
      return c.json({ approvals });
    } catch (err) {
      deps.logger.error({ err, customerId }, "paperclip-proxy: failed to list approvals");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.post("/api/internal/approvals/:approvalId/approve", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const approvalId = c.req.param("approvalId");
    try {
      await deps.clients.paperclip.actOnApproval(approvalId, "approve");
      return c.json({ ok: true });
    } catch (err) {
      deps.logger.error({ err, customerId, approvalId }, "paperclip-proxy: failed to approve");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.post("/api/internal/approvals/:approvalId/reject", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) return c.json({ error: "unauthorized" }, 401);

    const approvalId = c.req.param("approvalId");
    try {
      await deps.clients.paperclip.actOnApproval(approvalId, "reject");
      return c.json({ ok: true });
    } catch (err) {
      deps.logger.error({ err, customerId, approvalId }, "paperclip-proxy: failed to reject");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });
}