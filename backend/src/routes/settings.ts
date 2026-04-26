import type { Hono } from "hono";
import { z } from "zod";
import { resolveSessionCustomerId } from "../auth/session.js";
import { KeyEncryption } from "../crypto/key-encryption.js";
import type { AppDeps } from "../app-deps.js";
import { getCustomerById } from "../db/customers.js";

const UpdateSettingsSchema = z.object({
  display_name: z.string().min(1).max(100).optional(),
  agent_approval_mode: z.enum(["auto", "manual"]).optional(),
  model_tier: z.enum(["open", "frontier", "hybrid"]).optional()
});

export function registerSettingsRoutes(app: Hono, deps: AppDeps) {
  app.get("/api/internal/settings", async (c) => {
    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    if (!sessionCustomerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const customer = await getCustomerById(deps.db, sessionCustomerId);
    if (!customer) {
      return c.json({ error: "customer_not_found" }, 404);
    }

    return c.json({
      customer_id: customer.customer_id,
      workspace_slug: customer.workspace_slug,
      display_name: customer.display_name,
      email: customer.email,
      current_tier: customer.current_tier,
      current_billing_mode: customer.current_billing_mode,
      payment_status: customer.payment_status,
      agent_approval_mode: customer.agent_approval_mode ?? "auto",
      byok_key_set: customer.byok_key_encrypted !== null,
      onboarding_progress: customer.onboarding_progress ?? {},
      onboarding_complete: (customer.onboarding_progress as Record<string, string> | null)?.complete !== undefined
    }, 200);
  });

  app.patch("/api/internal/settings", async (c) => {
    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    if (!sessionCustomerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const body = await c.req.json();
    const parsed = UpdateSettingsSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 422);
    }

    const updates: Record<string, unknown> = {};
    if (parsed.data.display_name !== undefined) {
      updates.display_name = parsed.data.display_name;
    }
    if (parsed.data.agent_approval_mode !== undefined) {
      updates.agent_approval_mode = parsed.data.agent_approval_mode;
    }
    if (parsed.data.model_tier !== undefined) {
      updates.model_tier = parsed.data.model_tier;
    }

    if (Object.keys(updates).length === 0) {
      return c.json({ error: "no_updates_provided" }, 400);
    }

    const { data, error } = await deps.db
      .from("customers")
      .update(updates)
      .eq("customer_id", sessionCustomerId)
      .select("*")
      .single();

    if (error) {
      deps.logger.error({ err: error, customerId: sessionCustomerId }, "failed to update settings");
      return c.json({ error: "update_failed" }, 500);
    }

    const customer = data as typeof data extends infer C ? C : never;
    return c.json({
      customer_id: customer.customer_id,
      workspace_slug: customer.workspace_slug,
      display_name: customer.display_name,
      email: customer.email,
      current_tier: customer.current_tier,
      current_billing_mode: customer.current_billing_mode,
      payment_status: customer.payment_status,
      agent_approval_mode: customer.agent_approval_mode ?? "auto",
      byok_key_set: (customer as { byok_key_encrypted?: string | null }).byok_key_encrypted !== null,
      onboarding_progress: (customer as { onboarding_progress?: Record<string, string> | null }).onboarding_progress ?? {},
      onboarding_complete: ((customer as { onboarding_progress?: Record<string, string> | null }).onboarding_progress)?.complete !== undefined
    }, 200);
  });

  app.post("/api/internal/settings/byok-key", async (c) => {
    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    if (!sessionCustomerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    if (!deps.env.BYOK_ENCRYPTION_KEY) {
      return c.json({ error: "byok_encryption_not_configured" }, 503);
    }

    const body = await c.req.json();
    const parsed = z.object({ api_key: z.string().min(1) }).safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input" }, 422);
    }

    const encryption = new KeyEncryption(deps.env.BYOK_ENCRYPTION_KEY);
    const encrypted = encryption.encrypt(parsed.data.api_key);

    const { error } = await deps.db
      .from("customers")
      .update({ byok_key_encrypted: encrypted })
      .eq("customer_id", sessionCustomerId);

    if (error) {
      deps.logger.error({ err: error, customerId: sessionCustomerId }, "failed to store byok key");
      return c.json({ error: "store_failed" }, 500);
    }

    return c.json({ ok: true }, 200);
  });

  app.delete("/api/internal/settings/byok-key", async (c) => {
    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    if (!sessionCustomerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const { error } = await deps.db
      .from("customers")
      .update({ byok_key_encrypted: null })
      .eq("customer_id", sessionCustomerId);

    if (error) {
      deps.logger.error({ err: error, customerId: sessionCustomerId }, "failed to remove byok key");
      return c.json({ error: "delete_failed" }, 500);
    }

    return c.json({ ok: true }, 200);
  });
}