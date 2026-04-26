import type { Hono } from "hono";
import { z } from "zod";
import { resolveSessionCustomerId } from "../auth/session.js";
import { KeyEncryption } from "../crypto/key-encryption.js";
import type { AppDeps } from "../app-deps.js";
import { getCustomerById } from "../db/customers.js";
import {
  byokKeyToPublic,
  countByokKeys,
  deleteByokKey,
  getByokKeyById,
  getByokKeyByProvider,
  listByokKeys,
  upsertByokKey,
  updateByokKeyValidity,
  type ByokProvider
} from "../db/byok-keys.js";
import { validateProviderKey, SUPPORTED_PROVIDERS, prefixOf } from "../clients/byok/providers.js";
import { insertNotification } from "../db/notifications.js";

const MAX_KEYS_PER_CUSTOMER = 10;

const SubmitKeySchema = z.object({
  provider: z.enum(SUPPORTED_PROVIDERS as [string, ...string[]]),
  api_key: z.string().min(1).max(2048),
  label: z.string().max(100).optional()
});

export function registerByokRoutes(app: Hono, deps: AppDeps) {
  app.get("/api/internal/byok/keys", async (c) => {
    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    if (!sessionCustomerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    try {
      const keys = await listByokKeys(deps.db, sessionCustomerId);
      return c.json({ keys: keys.map(byokKeyToPublic) });
    } catch (err) {
      deps.logger.error({ err, customerId: sessionCustomerId }, "byok: failed to list keys");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.post("/api/internal/byok/keys", async (c) => {
    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    if (!sessionCustomerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    if (!deps.env.BYOK_ENCRYPTION_KEY) {
      return c.json({ error: "byok_encryption_not_configured" }, 503);
    }

    const body = await c.req.json();
    const parsed = SubmitKeySchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 422);
    }

    const customer = await getCustomerById(deps.db, sessionCustomerId);
    if (!customer) {
      return c.json({ error: "customer_not_found" }, 404);
    }

    const currentCount = await countByokKeys(deps.db, sessionCustomerId);
    const existing = await getByokKeyByProvider(deps.db, sessionCustomerId, parsed.data.provider as ByokProvider);
    if (!existing && currentCount >= MAX_KEYS_PER_CUSTOMER) {
      return c.json({ error: "key_limit_reached", message: `Maximum ${MAX_KEYS_PER_CUSTOMER} BYOK keys allowed per customer` }, 400);
    }

    const validation = await validateProviderKey(parsed.data.provider as ByokProvider, parsed.data.api_key);
    if (!validation.valid) {
      return c.json({ error: "key_validation_failed", message: validation.error ?? "The API key could not be validated against the provider" }, 400);
    }

    const encryption = new KeyEncryption(deps.env.BYOK_ENCRYPTION_KEY);
    const encrypted = encryption.encrypt(parsed.data.api_key);
    const keyPrefix = prefixOf(parsed.data.api_key);

    try {
      const key = await upsertByokKey(deps.db, {
        customerId: sessionCustomerId,
        provider: parsed.data.provider as ByokProvider,
        keyEncrypted: encrypted,
        keyPrefix,
        ...(parsed.data.label ? { label: parsed.data.label } : {}),
        isValid: true
      });

      if (customer.current_billing_mode !== "byok") {
        await deps.db
          .from("customers")
          .update({ current_billing_mode: "byok" })
          .eq("customer_id", sessionCustomerId);
      }

      return c.json({ key: byokKeyToPublic(key) }, existing ? 200 : 201);
    } catch (err) {
      deps.logger.error({ err, customerId: sessionCustomerId }, "byok: failed to store key");
      return c.json({ error: "store_failed" }, 500);
    }
  });

  app.delete("/api/internal/byok/keys/:keyId", async (c) => {
    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    if (!sessionCustomerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const keyId = c.req.param("keyId");
    const key = await getByokKeyById(deps.db, keyId);
    if (!key) {
      return c.json({ error: "key_not_found" }, 404);
    }

    if (key.customer_id !== sessionCustomerId) {
      return c.json({ error: "forbidden" }, 403);
    }

    try {
      await deleteByokKey(deps.db, keyId);

      const remaining = await listByokKeys(deps.db, sessionCustomerId);
      if (remaining.length === 0) {
        await deps.db
          .from("customers")
          .update({ current_billing_mode: "foreman_managed_tier", byok_key_encrypted: null })
          .eq("customer_id", sessionCustomerId);
      }

      return c.json({ ok: true });
    } catch (err) {
      deps.logger.error({ err, customerId: sessionCustomerId, keyId }, "byok: failed to delete key");
      return c.json({ error: "delete_failed" }, 500);
    }
  });

  app.post("/api/internal/byok/keys/:keyId/validate", async (c) => {
    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    if (!sessionCustomerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    if (!deps.env.BYOK_ENCRYPTION_KEY) {
      return c.json({ error: "byok_encryption_not_configured" }, 503);
    }

    const keyId = c.req.param("keyId");
    const key = await getByokKeyById(deps.db, keyId);
    if (!key) {
      return c.json({ error: "key_not_found" }, 404);
    }

    if (key.customer_id !== sessionCustomerId) {
      return c.json({ error: "forbidden" }, 403);
    }

    const encryption = new KeyEncryption(deps.env.BYOK_ENCRYPTION_KEY);
    let decryptedKey: string;
    try {
      decryptedKey = encryption.decrypt(key.key_encrypted);
    } catch {
      deps.logger.error({ customerId: sessionCustomerId, keyId }, "byok: failed to decrypt key during validation");
      await updateByokKeyValidity(deps.db, keyId, false);
      return c.json({ valid: false, error: "Failed to decrypt stored key" }, 200);
    }

    const validation = await validateProviderKey(key.provider, decryptedKey);
    const isValid = validation.valid;

    await updateByokKeyValidity(deps.db, keyId, isValid);

    if (!isValid) {
      await insertNotification(deps.db, {
        workspace_slug: (await getCustomerById(deps.db, sessionCustomerId))!.workspace_slug,
        type: "byok_key_invalid",
        title: `Your ${key.provider} API key failed validation`,
        body: `Your ${key.provider} BYOK key is no longer valid: ${validation.error ?? "unknown error"}. Please update or remove it in Settings > Billing.`
      });
    }

    return c.json({
      key_id: keyId,
      provider: key.provider,
      valid: isValid,
      error: isValid ? undefined : validation.error
    });
  });
}