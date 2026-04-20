import {
  deleteByokFallbackEvent,
  getByokFallbackEvent,
  listActiveByokCustomers,
  markByokFallbackEmailSent,
  setCustomerByokFallback,
  upsertByokFallbackEvent
} from "../db/customers.js";
import { insertNotification } from "../db/notifications.js";
import type { AppDeps } from "../app-deps.js";
import type { JobResult } from "./types.js";

const OPENROUTER_VALIDATE_URL = "https://openrouter.ai/api/v1/models";
const KEY_VALIDATE_TIMEOUT_MS = 10_000;
const EMAIL_DEDUP_WINDOW_MS = 24 * 60 * 60 * 1000;

interface ByokCustomer {
  workspace_slug: string;
  byok_key_encrypted: string;
  byok_fallback_enabled: boolean;
  byok_using_fallback: boolean;
  customer_id: string;
  email: string;
  display_name: string;
}

const validateOpenRouterKey = async (key: string): Promise<boolean> => {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), KEY_VALIDATE_TIMEOUT_MS);
  try {
    const response = await fetch(OPENROUTER_VALIDATE_URL, {
      method: "GET",
      headers: { Authorization: `Bearer ${key}` },
      signal: controller.signal
    });
    return response.ok;
  } catch {
    return false;
  } finally {
    clearTimeout(timeout);
  }
};

const handleFallbackActivation = async (
  deps: AppDeps,
  customer: ByokCustomer,
  now: string
): Promise<void> => {
  const logger = deps.logger.child({ workspace: customer.workspace_slug });

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
        `Your OpenRouter API key failed validation. Foreman automatically switched to ` +
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
        `Your OpenRouter API key is still failing. Foreman continues using its managed key ` +
        `for your agents. Fix your key in Settings > Billing.`
    });
    logger.info("byok fallback still active — banner-only notification");
  }
};

const handleFallbackRecovery = async (
  deps: AppDeps,
  customer: ByokCustomer
): Promise<void> => {
  const logger = deps.logger.child({ workspace: customer.workspace_slug });

  await setCustomerByokFallback(deps.db, customer.workspace_slug, false);
  await deleteByokFallbackEvent(deps.db, customer.workspace_slug);

  await insertNotification(deps.db, {
    workspace_slug: customer.workspace_slug,
    type: "byok_fallback_stopped",
    title: "Your API key is working again",
    body:
      `Your OpenRouter API key is valid again. Foreman has switched your agents back to ` +
      `BYOK billing. No further managed-key charges will be applied unless your key fails again.`
  });

  logger.info("byok key recovered — fallback cleared");
};

export async function runByokKeyHealthCheckJob(deps: AppDeps): Promise<JobResult> {
  const logger = deps.logger.child({ jobName: "byok_key_health_check" });

  let byokCustomers: ByokCustomer[];
  try {
    byokCustomers = (await listActiveByokCustomers(deps.db)) as ByokCustomer[];
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    logger.error({ err: msg }, "failed to list BYOK customers");
    return {
      jobName: "byok_key_health_check",
      status: "error",
      message: `failed to list BYOK customers: ${msg}`
    };
  }
  if (byokCustomers.length === 0) {
    return {
      jobName: "byok_key_health_check",
      status: "noop",
      message: "no active BYOK customers"
    };
  }

  const now = new Date().toISOString();
  let activated = 0;
  let recovered = 0;
  let errors = 0;

  for (const customer of byokCustomers) {
    try {
      const keyValid = await validateOpenRouterKey(customer.byok_key_encrypted);

      if (!keyValid && !customer.byok_using_fallback) {
        if (customer.byok_fallback_enabled) {
          await handleFallbackActivation(deps, customer, now);
          activated++;
        } else {
          // Fallback disabled: pause agents + notify
          logger.warn(
            { workspace: customer.workspace_slug },
            "BYOK key failed but fallback disabled — agents may stall"
          );
          await insertNotification(deps.db, {
            workspace_slug: customer.workspace_slug,
            type: "byok_fallback_started",
            title: "Your API key failed — agents paused",
            body:
              `Your OpenRouter API key failed validation and BYOK fallback is disabled. ` +
              `Your agents have been paused. Fix your key or enable fallback in Settings > Billing.`
          });
        }
      } else if (keyValid && customer.byok_using_fallback) {
        await handleFallbackRecovery(deps, customer);
        recovered++;
      }
    } catch (err) {
      logger.error(
        { workspace: customer.workspace_slug, err: err instanceof Error ? err.message : String(err) },
        "error processing BYOK health check for workspace"
      );
      errors++;
    }
  }

  const details = { checked: byokCustomers.length, activated, recovered, errors };
  logger.info(details, "byok_key_health_check complete");

  return {
    jobName: "byok_key_health_check",
    status: errors > 0 ? "error" : "ok",
    message: `checked ${byokCustomers.length} BYOK customers: ${activated} fallback(s) activated, ${recovered} recovered`,
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
