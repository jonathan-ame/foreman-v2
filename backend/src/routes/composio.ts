import type { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../app-deps.js";
import { resolveSessionCustomerId } from "../auth/session.js";
import {
  insertComposioConnection,
  insertComposioSession,
  insertComposioTrigger,
  listComposioConnections,
  listComposioTriggers,
  deleteComposioConnection,
  deleteComposioTrigger
} from "../db/composio.js";

const AuthorizeSchema = z.object({
  toolkit: z.string().min(1),
  redirect_url: z.string().url().optional()
});

const CreateTriggerSchema = z.object({
  trigger_type: z.string().min(1),
  toolkit: z.string().min(1),
  config: z.record(z.string(), z.unknown()).default({}),
  connected_account_id: z.string().optional()
});

const DeleteConnectionSchema = z.object({
  connected_account_id: z.string().min(1)
});

const DeleteTriggerSchema = z.object({
  trigger_id: z.string().min(1)
});

export function registerComposioRoutes(app: Hono, deps: AppDeps) {
  app.post("/api/internal/composio/sessions", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    if (!deps.clients.composio.isConfigured) {
      return c.json({ error: "composio_not_configured" }, 503);
    }

    try {
      const composioUserId = `foreman_${customerId}`;
      const session = await deps.clients.composio.createSession(composioUserId);

      await insertComposioSession(deps.db, {
        customer_id: customerId,
        composio_user_id: composioUserId,
        composio_session_id: session.id,
        mcp_url: session.mcp.url,
        mcp_headers: session.mcp.headers,
        toolkits: session.toolkits
      });

      return c.json({
        session: {
          id: session.id,
          mcp_url: session.mcp.url,
          mcp_headers: session.mcp.headers,
          toolkits: session.toolkits
        }
      }, 201);
    } catch (err) {
      deps.logger.error({ err, customerId }, "composio: failed to create session");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.get("/api/internal/composio/toolkits", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    if (!deps.clients.composio.isConfigured) {
      return c.json({ error: "composio_not_configured" }, 503);
    }

    try {
      const toolkits = await deps.clients.composio.listToolkits();
      return c.json({ toolkits });
    } catch (err) {
      deps.logger.error({ err, customerId }, "composio: failed to list toolkits");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.get("/api/internal/composio/connections", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    try {
      const connections = await listComposioConnections(deps.db, customerId);
      return c.json({
        connections: connections.map((conn) => ({
          id: conn.id,
          connected_account_id: conn.composio_connected_account_id,
          toolkit_slug: conn.toolkit_slug,
          toolkit_name: conn.toolkit_name,
          status: conn.status,
          created_at: conn.created_at
        }))
      });
    } catch (err) {
      deps.logger.error({ err, customerId }, "composio: failed to list connections");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.post("/api/internal/composio/connections/authorize", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    if (!deps.clients.composio.isConfigured) {
      return c.json({ error: "composio_not_configured" }, 503);
    }

    const body = await c.req.json();
    const parsed = AuthorizeSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    try {
      const composioUserId = `foreman_${customerId}`;
      const connectionRequest = await deps.clients.composio.authorizeToolkit(
        composioUserId,
        parsed.data.toolkit,
        parsed.data.redirect_url
      );

      if (connectionRequest.connectedAccountId) {
        await insertComposioConnection(deps.db, {
          customer_id: customerId,
          composio_connected_account_id: connectionRequest.connectedAccountId,
          toolkit_slug: parsed.data.toolkit
        });
      }

      return c.json({
        connect_url: connectionRequest.connectUrl,
        connected_account_id: connectionRequest.connectedAccountId
      });
    } catch (err) {
      deps.logger.error({ err, customerId, toolkit: parsed.data.toolkit }, "composio: failed to authorize toolkit");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.delete("/api/internal/composio/connections", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const body = await c.req.json();
    const parsed = DeleteConnectionSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    try {
      await deps.clients.composio.deleteConnectedAccount(parsed.data.connected_account_id);
      await deleteComposioConnection(deps.db, customerId, parsed.data.connected_account_id);
      return c.json({ ok: true });
    } catch (err) {
      deps.logger.error({ err, customerId }, "composio: failed to delete connection");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.get("/api/internal/composio/triggers", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    try {
      const triggers = await listComposioTriggers(deps.db, customerId);
      return c.json({
        triggers: triggers.map((trigger) => ({
          id: trigger.id,
          trigger_id: trigger.composio_trigger_id,
          trigger_type: trigger.trigger_type,
          toolkit_slug: trigger.toolkit_slug,
          config: trigger.config,
          status: trigger.status,
          created_at: trigger.created_at
        }))
      });
    } catch (err) {
      deps.logger.error({ err, customerId }, "composio: failed to list triggers");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.post("/api/internal/composio/triggers", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    if (!deps.clients.composio.isConfigured) {
      return c.json({ error: "composio_not_configured" }, 503);
    }

    const body = await c.req.json();
    const parsed = CreateTriggerSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    try {
      const composioUserId = `foreman_${customerId}`;
      const trigger = await deps.clients.composio.createTrigger(composioUserId, {
        triggerType: parsed.data.trigger_type,
        toolkitSlug: parsed.data.toolkit,
        config: parsed.data.config,
        connectedAccountId: parsed.data.connected_account_id
      });

      await insertComposioTrigger(deps.db, {
        customer_id: customerId,
        composio_trigger_id: trigger.id,
        trigger_type: parsed.data.trigger_type,
        toolkit_slug: parsed.data.toolkit,
        config: parsed.data.config
      });

      return c.json({
        trigger: {
          id: trigger.id,
          trigger_type: trigger.triggerType,
          toolkit_slug: trigger.toolkitSlug,
          status: trigger.status
        }
      }, 201);
    } catch (err) {
      deps.logger.error({ err, customerId }, "composio: failed to create trigger");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.delete("/api/internal/composio/triggers", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const body = await c.req.json();
    const parsed = DeleteTriggerSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    try {
      await deps.clients.composio.deleteTrigger(parsed.data.trigger_id);
      await deleteComposioTrigger(deps.db, customerId, parsed.data.trigger_id);
      return c.json({ ok: true });
    } catch (err) {
      deps.logger.error({ err, customerId }, "composio: failed to delete trigger");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.post("/api/internal/composio/webhook", async (c) => {
    const signature = c.req.header("x-composio-signature") ?? "";
    const payload = await c.req.text();

    const webhookSecret = deps.env.COMPOSIO_WEBHOOK_SECRET;
    if (webhookSecret && !deps.clients.composio.verifyWebhookSignature(payload, signature, webhookSecret)) {
      deps.logger.warn({ signature }, "composio: webhook signature verification failed");
      return c.json({ error: "invalid_signature" }, 401);
    }

    try {
      const event = JSON.parse(payload) as {
        trigger_id?: string;
        trigger_type?: string;
        toolkit?: string;
        payload?: Record<string, unknown>;
        timestamp?: string;
        [key: string]: unknown;
      };

      deps.logger.info(
        { triggerId: event.trigger_id, triggerType: event.trigger_type, toolkit: event.toolkit },
        "composio: received webhook event"
      );

      const result = await deps.webhookDispatcher.dispatch(event);

      return c.json({
        ok: true,
        event_id: result.eventId,
        delivered: result.delivered,
        failed: result.failed
      });
    } catch (err) {
      deps.logger.error({ err }, "composio: failed to process webhook");
      return c.json({ error: "bad_request" }, 400);
    }
  });
}
