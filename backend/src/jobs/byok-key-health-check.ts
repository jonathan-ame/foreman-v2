import { KeyEncryption } from "../crypto/key-encryption.js";
import { listAllValidByokKeys, updateByokKeyValidity, getByokKeyById, listByokKeys } from "../db/byok-keys.js";
import type { ByokKey, ByokProvider } from "../db/byok-keys.js";
import { validateProviderKey } from "../clients/byok/providers.js";
import {
  deleteByokFallbackEvent,
  getByokFallbackEvent,
  getCustomerById,
  listActiveByokCustomers,
  markByokFallbackEmailSent,
  setCustomerByokFallback,
  upsertByokFallbackEvent
} from "../db/customers.js";
import { insertNotification } from "../db/notifications.js";
import type { AppDeps } from "../app-deps.js";
import type { JobResult } from "./types.js";

const EMAIL_DEDUP_WINDOW_MS = 24 * 60 * 60 * 1000;

const allCustomerProvidersInvalid = async (
  db: AppDeps["db"],
  customerId: string
): Promise<boolean> => {
  const keys = await listByokKeys(db, customerId);
  return keys.length > 0 && keys.every((k) => !k.is_valid);
};

const handleFallbackActivation = async (deps: AppDeps, customerId: string, now: string): Promise<void> => {
  const customer = await getCustomerById(deps.db, customerId);
  if (!customer) return;

  const logger = deps.logger.child({ workspace: customer.workspace_slug, customerId });

  await setCustomerByokFallback(deps.db, customer.workspace_slug, true);

  const event = await upsertByokFallbackEvent(deps.db, customer.workspace_slug, now);

  const shouldEmail =
    !event.last_email_notified_at ||
    Date.now() - new Date(event.last_email_notified_at).getTime() > EMAIL_DEDUP_WINDOW_MS;

  if (shouldEmail) {
    await insertNotification(deps.db, {
      workspace_slug: customer.workspace_slug,
      type: "byok_fallback_started",
      title: "Your API key failed — Foreman used your backup",
      body:
        `Your BYOK API key(s) failed validation. Foreman automatically switched to ` +
        `its managed key for your agents. You are being billed at standard managed rates ` +
        `(cost + 20%) during the fallback window. Fix your key in Settings > Billing to restore BYOK billing.`
    });
    await markByokFallbackEmailSent(deps.db, customer.workspace_slug, now);
    logger.info("byok fallback activated — email notification queued");
  } else {
    await insertNotification(deps.db, {
      workspace_slug: customer.workspace_slug,
      type: "byok_fallback_started",
      title: "Your API key is still failing — Foreman backup active",
      body:
        `Your BYOK API key(s) are still failing. Foreman continues using its managed key ` +
        `for your agents. Fix your key in Settings > Billing.`
    });
    logger.info("byok fallback still active — banner-only notification");
  }
};

const handleFallbackRecovery = async (deps: AppDeps, customerId: string): Promise<void> => {
  const customer = await getCustomerById(deps.db, customerId);
  if (!customer) return;

  const logger = deps.logger.child({ workspace: customer.workspace_slug, customerId });

  await setCustomerByokFallback(deps.db, customer.workspace_slug, false);
  await deleteByokFallbackEvent(deps.db, customer.workspace_slug);

  await insertNotification(deps.db, {
    workspace_slug: customer.workspace_slug,
    type: "byok_fallback_stopped",
    title: "Your API key is working again",
    body:
      `Your BYOK API key(s) are valid again. Foreman has switched your agents back to ` +
      `BYOK billing. No further managed-key charges will be applied unless your key fails again.`
  });

  logger.info("byok key recovered — fallback cleared");
};

export async function runByokKeyHealthCheckJob(deps: AppDeps): Promise<JobResult> {
  const logger = deps.logger.child({ jobName: "byok_key_health_check" });

  let allKeys: ByokKey[];
  try {
    allKeys = await listAllValidByokKeys(deps.db);
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    logger.error({ err: msg }, "failed to list BYOK keys");
    return {
      jobName: "byok_key_health_check",
      status: "error",
      message: `failed to list BYOK keys: ${msg}`
    };
  }

  if (allKeys.length === 0) {
    return {
      jobName: "byok_key_health_check",
      status: "noop",
      message: "no active BYOK keys to validate"
    };
  }

  const now = new Date().toISOString();
  let validated = 0;
  let failed = 0;
  let errors = 0;
  const failedCustomers = new Set<string>();
  const recoveredCustomerIds = new Set<string>();

  for (const key of allKeys) {
    try {
      if (!deps.env.BYOK_ENCRYPTION_KEY) {
        logger.warn({ keyId: key.id }, "BYOK_ENCRYPTION_KEY not set — skipping key validation");
        continue;
      }

      const encryption = new KeyEncryption(deps.env.BYOK_ENCRYPTION_KEY);
      let decryptedKey: string;
      try {
        decryptedKey = encryption.decrypt(key.key_encrypted);
      } catch {
        logger.error({ keyId: key.id, customerId: key.customer_id }, "failed to decrypt BYOK key");
        await updateByokKeyValidity(deps.db, key.id, false);
        failed++;
        failedCustomers.add(key.customer_id);
        continue;
      }

      const validation = await validateProviderKey(key.provider, decryptedKey);
      const isValid = validation.valid;
      await updateByokKeyValidity(deps.db, key.id, isValid);

      if (isValid) {
        validated++;
        recoveredCustomerIds.add(key.customer_id);
      } else {
        failed++;
        failedCustomers.add(key.customer_id);

        const customer = await getCustomerById(deps.db, key.customer_id);
        if (customer) {
          await insertNotification(deps.db, {
            workspace_slug: customer.workspace_slug,
            type: "byok_key_invalid",
            title: `Your ${key.provider} API key failed validation`,
            body: `Your ${key.provider} BYOK key is no longer valid: ${validation.error ?? "unknown error"}. Please update or remove it in Settings > Billing.`
          });
        }
      }
    } catch (err) {
      logger.error(
        { keyId: key.id, err: err instanceof Error ? err.message : String(err) },
        "error checking BYOK key"
      );
      errors++;
    }
  }

  for (const customerId of failedCustomers) {
    try {
      const allInvalid = await allCustomerProvidersInvalid(deps.db, customerId);
      if (allInvalid) {
        const customer = await getCustomerById(deps.db, customerId);
        if (customer && customer.byok_fallback_enabled && !customer.byok_using_fallback) {
          await handleFallbackActivation(deps, customerId, now);
        }
      }
    } catch (err) {
      logger.error({ customerId, err: err instanceof Error ? err.message : String(err) }, "error handling fallback activation");
      errors++;
    }
  }

  for (const customerId of recoveredCustomerIds) {
    if (failedCustomers.has(customerId)) continue;
    try {
      const customer = await getCustomerById(deps.db, customerId);
      if (customer && customer.byok_using_fallback) {
        const allInvalid = await allCustomerProvidersInvalid(deps.db, customerId);
        if (!allInvalid) {
          await handleFallbackRecovery(deps, customerId);
        }
      }
    } catch (err) {
      logger.error({ customerId, err: err instanceof Error ? err.message : String(err) }, "error handling fallback recovery");
      errors++;
    }
  }

  const details = { totalKeys: allKeys.length, validated, failed, errors };
  logger.info(details, "byok_key_health_check complete");

  return {
    jobName: "byok_key_health_check",
    status: errors > 0 ? "error" : "ok",
    message: `validated ${validated}/${allKeys.length} BYOK keys, ${failed} failed, ${errors} errors`,
    details
  };
}

export async function getByokFallbackStatus(
  deps: AppDeps,
  workspaceSlug: string
): Promise<{ usingFallback: boolean; since: string | null }> {
  const event = await getByokFallbackEvent(deps.db, workspaceSlug);
  if (!event) {
    return { usingFallback: false, since: null };
  }
  return { usingFallback: true, since: event.first_fallback_at };
}