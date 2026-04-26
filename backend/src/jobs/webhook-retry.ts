import type { AppDeps } from "../app-deps.js";
import type { JobResult } from "./types.js";
import { getPendingWebhookEvents } from "../db/webhook-events.js";

const MAX_RETRY_ATTEMPTS = 3;

export async function runWebhookRetryJob(deps: AppDeps): Promise<JobResult> {
  const logger = deps.logger.child({ jobName: "webhook_retry" });

  logger.info("starting webhook retry job");

  const pendingEvents = await getPendingWebhookEvents(deps.db, 50);
  if (pendingEvents.length === 0) {
    logger.info("no pending webhook events to retry");
    return { jobName: "webhook_retry", status: "noop", message: "no pending webhook events" };
  }

  logger.info({ count: pendingEvents.length }, "found pending webhook events");

  let retried = 0;
  let skipped = 0;
  let errored = 0;

  for (const event of pendingEvents) {
    try {
      const { data: deliveries, error: deliveryError } = await deps.db
        .from("composio_webhook_deliveries")
        .select("attempts")
        .eq("webhook_event_id", event.id);

      if (deliveryError) {
        logger.warn({ err: deliveryError, eventId: event.id }, "failed to fetch deliveries, skipping");
        skipped++;
        continue;
      }

      const maxAttempts = Math.max(...(deliveries?.map((d: { attempts: number }) => d.attempts) || [0]), 0);
      if (maxAttempts >= MAX_RETRY_ATTEMPTS) {
        logger.info({ eventId: event.id, attempts: maxAttempts }, "event exceeded max retry attempts, skipping");
        skipped++;
        continue;
      }

      const payload = {
        trigger_id: event.trigger_id,
        trigger_type: event.trigger_type,
        toolkit: event.toolkit ?? undefined,
        payload: event.payload,
        timestamp: event.received_at
      };

      await deps.webhookDispatcher.dispatch(payload);
      retried++;
      logger.info({ eventId: event.id }, "webhook event retried successfully");
    } catch (err) {
      errored++;
      logger.error({ err, eventId: event.id }, "webhook retry failed for event");
    }
  }

  const message = `retried=${retried} skipped=${skipped} errored=${errored}`;
  logger.info({ retried, skipped, errored }, message);

  return {
    jobName: "webhook_retry",
    status: retried > 0 ? "ok" : "noop",
    message,
    details: { retried, skipped, errored }
  };
}