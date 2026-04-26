import type { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../app-deps.js";
import { resolveSessionCustomerId } from "../auth/session.js";
import { getCustomerById } from "../db/customers.js";
import { insertChatMessage, listChatMessages } from "../db/chat-messages.js";

const SendMessageSchema = z.object({
  message: z.string().min(1).max(10_000)
});

const CreateTaskFromChatSchema = z.object({
  chatMessageIds: z.array(z.string().uuid()).min(1).max(10),
  title: z.string().min(1).max(500),
  priority: z.enum(["critical", "high", "medium", "low"]).default("medium"),
  assigneeAgentId: z.string().uuid().optional()
});

const PENDING_REPLY = "I'm reviewing your request — I'll get back to you shortly.";

export function registerChatRoutes(app: Hono, deps: AppDeps) {
  app.get("/api/internal/chat/history", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    try {
      const rows = await listChatMessages(deps.db, customerId);
      return c.json({
        messages: rows.map((m) => ({
          id: m.id,
          role: m.role,
          content: m.content,
          created_at: m.created_at
        }))
      });
    } catch (err) {
      deps.logger.error({ err, customerId }, "chat: failed to load history");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.post("/api/internal/chat/send", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const body = await c.req.json();
    const parsed = SendMessageSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    try {
      await insertChatMessage(deps.db, customerId, "user", parsed.data.message);

      const customer = await getCustomerById(deps.db, customerId);
      const companyId = customer?.paperclip_company_id;

      if (companyId) {
        try {
          const agents = await deps.clients.paperclip.listAgents(companyId);
          const ceoAgent = agents.find((a: { role?: string }) => a.role === "ceo");
          if (ceoAgent?.id) {
            const description = parsed.data.message;
            const task = await deps.clients.paperclip.createIssue(companyId, {
              title: parsed.data.message.slice(0, 200),
              description,
              priority: "medium",
              assigneeAgentId: ceoAgent.id
            });
            deps.logger.info({ customerId, companyId, taskId: (task as { id?: string })?.id }, "chat: created Paperclip issue from message");

            const reply = await insertChatMessage(
              deps.db,
              customerId,
              "assistant",
              `I've noted your request and created a task for review. I'll follow up with details.`
            );

            return c.json({
              reply: {
                id: reply.id,
                role: reply.role,
                content: reply.content,
                created_at: reply.created_at
              }
            });
          }
        } catch (paperclipErr) {
          deps.logger.warn({ err: paperclipErr, customerId }, "chat: Paperclip integration failed, falling back to stub reply");
        }
      }

      const reply = await insertChatMessage(deps.db, customerId, "assistant", PENDING_REPLY);
      return c.json({
        reply: {
          id: reply.id,
          role: reply.role,
          content: reply.content,
          created_at: reply.created_at
        }
      });
    } catch (err) {
      deps.logger.error({ err, customerId }, "chat: failed to send message");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.post("/api/internal/chat/create-task", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const body = await c.req.json();
    const parsed = CreateTaskFromChatSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    const customer = await getCustomerById(deps.db, customerId);
    const companyId = customer?.paperclip_company_id;
    if (!companyId) {
      return c.json({ error: "paperclip_not_linked", message: "No Paperclip company linked." }, 400);
    }

    try {
      const chatMessages = await listChatMessages(deps.db, customerId);
      const selectedMessages = chatMessages.filter((m) => parsed.data.chatMessageIds.includes(m.id));
      const description = selectedMessages.map((m) => `${m.role === "user" ? "You" : "Assistant"}: ${m.content}`).join("\n\n");

      const task = await deps.clients.paperclip.createIssue(companyId, {
        title: parsed.data.title,
        description,
        priority: parsed.data.priority,
        assigneeAgentId: parsed.data.assigneeAgentId
      });

      deps.logger.info({ customerId, companyId, taskId: (task as { id?: string })?.id }, "chat: created task from chat messages");

      return c.json({ task }, 201);
    } catch (err) {
      deps.logger.error({ err, customerId }, "chat: failed to create task from chat");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });
}
