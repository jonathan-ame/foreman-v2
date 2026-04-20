import type { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../app-deps.js";
import { resolveSessionCustomerId } from "../auth/session.js";
import { insertChatMessage, listChatMessages } from "../db/chat-messages.js";

const SendMessageSchema = z.object({
  message: z.string().min(1).max(10_000)
});

// V1 stub reply until CEO agent chat API is wired
const STUB_REPLY = "I'm reviewing your request — I'll get back to you shortly.";

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

      // TODO: forward to CEO agent via OpenClaw/Paperclip chat API when available
      const reply = await insertChatMessage(deps.db, customerId, "assistant", STUB_REPLY);

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
}
