import type { Logger } from "pino";
import type { SupabaseClient } from "../../db/supabase.js";
import {
  insertWebhookEvent,
  updateWebhookEventStatus,
  insertWebhookDelivery,
  updateWebhookDeliveryStatus,
  type WebhookEventRow,
  type WebhookEventInsert
} from "../../db/webhook-events.js";
import { getComposioTriggerByComposioId } from "../../db/composio-triggers.js";

export interface WebhookEventPayload {
  trigger_id?: string;
  trigger_type?: string;
  toolkit?: string;
  payload?: Record<string, unknown>;
  timestamp?: string;
  [key: string]: unknown;
}

export interface DispatcherContext {
  db: SupabaseClient;
  logger: Logger;
  webhookEvent: WebhookEventRow;
  triggerRow: { customer_id: string; trigger_type: string; toolkit_slug: string; config: Record<string, unknown> } | null;
  rawPayload: Record<string, unknown>;
}

export interface HandlerResult {
  delivered: boolean;
  message?: string;
  data?: Record<string, unknown>;
}

export interface WebhookHandler {
  name: string;
  canHandle(ctx: DispatcherContext): boolean;
  handle(ctx: DispatcherContext): Promise<HandlerResult>;
}

export interface DispatcherDeps {
  db: SupabaseClient;
  logger: Logger;
  handlers: WebhookHandler[];
  onAgentIssueCreate?: (companyId: string, input: Record<string, unknown>) => Promise<unknown>;
  onNotificationInsert?: (notification: {
    workspace_slug: string;
    type: string;
    title: string;
    body: string;
    reference_id?: string | null;
    reference_type?: string | null;
  }) => Promise<void>;
  onCustomerLookup?: (customerId: string) => Promise<{ workspace_slug: string; paperclip_company_id: string | null } | null>;
}

export class WebhookEventDispatcher {
  private readonly db: SupabaseClient;
  private readonly logger: Logger;
  private readonly handlers: WebhookHandler[];
  private readonly onAgentIssueCreate?: (companyId: string, input: Record<string, unknown>) => Promise<unknown>;

  constructor(deps: DispatcherDeps) {
    this.db = deps.db;
    this.logger = deps.logger.child({ subsystem: "webhook-dispatcher" });
    this.handlers = deps.handlers;
    this.onAgentIssueCreate = deps.onAgentIssueCreate;
  }

  async dispatch(payload: WebhookEventPayload): Promise<{ eventId: string; delivered: number; failed: number }> {
    const triggerId = payload.trigger_id ?? "";
    const triggerType = payload.trigger_type ?? "unknown";
    const toolkit = payload.toolkit ?? null;
    const eventData = payload.payload ?? {};

    this.logger.info({ triggerId, triggerType, toolkit }, "webhook dispatcher: received event");

    const eventRow = await this.persistEvent({
      trigger_id: triggerId,
      trigger_type: triggerType,
      toolkit,
      payload: { ...eventData, ...payload },
      processing_status: "pending"
    });

    let triggerRow: { customer_id: string; trigger_type: string; toolkit_slug: string; config: Record<string, unknown> } | null = null;
    if (triggerId) {
      try {
        triggerRow = await getComposioTriggerByComposioId(this.db, triggerId);
      } catch (err) {
        this.logger.warn({ err, triggerId }, "webhook dispatcher: failed to look up trigger row, continuing without customer context");
      }
    }

    const customerId = triggerRow?.customer_id ?? null;

    if (customerId) {
      await this.linkEventToCustomer(eventRow.id, customerId);
    }

    await updateWebhookEventStatus(this.db, eventRow.id, "processing");

    const ctx: DispatcherContext = {
      db: this.db,
      logger: this.logger,
      webhookEvent: eventRow,
      triggerRow,
      rawPayload: payload as Record<string, unknown>
    };

    let delivered = 0;
    let failed = 0;

    const matchingHandlers = this.handlers.filter((h) => h.canHandle(ctx));
    this.logger.info(
      { eventId: eventRow.id, triggerType, matchingCount: matchingHandlers.length, handlerNames: matchingHandlers.map((h) => h.name) },
      "webhook dispatcher: matching handlers"
    );

    for (const handler of matchingHandlers) {
        const delivery = await insertWebhookDelivery(this.db, {
          webhook_event_id: eventRow.id,
          handler_type: handler.name,
          status: "pending"
        });

        try {
          const result = await handler.handle(ctx);
          const deliveryOpts: { errorMessage?: string; result?: Record<string, unknown> } = {};
          if (!result.delivered && result.message) deliveryOpts.errorMessage = result.message;
          if (result.data) deliveryOpts.result = result.data;
          await updateWebhookDeliveryStatus(this.db, delivery.id, result.delivered ? "delivered" : "failed", deliveryOpts);
        if (result.delivered) {
          delivered++;
        } else {
          failed++;
        }
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        this.logger.error({ err, handler: handler.name, eventId: eventRow.id }, "webhook dispatcher: handler failed");
        await updateWebhookDeliveryStatus(this.db, delivery.id, "failed", {
          errorMessage: msg
        });
        failed++;
      }
    }

    const finalStatus = failed === 0 ? "completed" : delivered > 0 ? "completed" : "failed";
    const eventStatusOpts = finalStatus === "failed" ? { errorMessage: "All handlers failed" as string } : undefined;
    await updateWebhookEventStatus(this.db, eventRow.id, finalStatus as "completed" | "failed", eventStatusOpts);

    this.logger.info({ eventId: eventRow.id, finalStatus, delivered, failed }, "webhook dispatcher: event processed");

    return { eventId: eventRow.id, delivered, failed };
  }

  async reprocessEvent(eventRow: WebhookEventRow): Promise<{ eventId: string; delivered: number; failed: number }> {
    const triggerId = eventRow.trigger_id;
    const triggerType = eventRow.trigger_type;

    this.logger.info({ eventId: eventRow.id, triggerType }, "webhook dispatcher: reprocessing event");

    let triggerRow: { customer_id: string; trigger_type: string; toolkit_slug: string; config: Record<string, unknown> } | null = null;
    if (triggerId) {
      try {
        triggerRow = await getComposioTriggerByComposioId(this.db, triggerId);
      } catch (err) {
        this.logger.warn({ err, triggerId }, "webhook dispatcher: failed to look up trigger row during reprocess, continuing without customer context");
      }
    }

    await updateWebhookEventStatus(this.db, eventRow.id, "processing");

    const ctx: DispatcherContext = {
      db: this.db,
      logger: this.logger,
      webhookEvent: eventRow,
      triggerRow,
      rawPayload: eventRow.payload as Record<string, unknown>
    };

    let delivered = 0;
    let failed = 0;

    const matchingHandlers = this.handlers.filter((h) => h.canHandle(ctx));
    this.logger.info(
      { eventId: eventRow.id, triggerType, matchingCount: matchingHandlers.length, handlerNames: matchingHandlers.map((h) => h.name) },
      "webhook dispatcher: reprocessing matching handlers"
    );

    for (const handler of matchingHandlers) {
      const delivery = await insertWebhookDelivery(this.db, {
        webhook_event_id: eventRow.id,
        handler_type: handler.name,
        status: "pending"
      });

      try {
        const result = await handler.handle(ctx);
        const deliveryOpts: { errorMessage?: string; result?: Record<string, unknown> } = {};
        if (!result.delivered && result.message) deliveryOpts.errorMessage = result.message;
        if (result.data) deliveryOpts.result = result.data;
        await updateWebhookDeliveryStatus(this.db, delivery.id, result.delivered ? "delivered" : "failed", deliveryOpts);
        if (result.delivered) {
          delivered++;
        } else {
          failed++;
        }
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        this.logger.error({ err, handler: handler.name, eventId: eventRow.id }, "webhook dispatcher: handler failed during reprocess");
        await updateWebhookDeliveryStatus(this.db, delivery.id, "failed", {
          errorMessage: msg
        });
        failed++;
      }
    }

    const finalStatus = failed === 0 ? "completed" : delivered > 0 ? "completed" : "failed";
    const eventStatusOpts = finalStatus === "failed" ? { errorMessage: "All handlers failed" as string } : undefined;
    await updateWebhookEventStatus(this.db, eventRow.id, finalStatus as "completed" | "failed", eventStatusOpts);

    this.logger.info({ eventId: eventRow.id, finalStatus, delivered, failed }, "webhook dispatcher: event reprocessed");

    return { eventId: eventRow.id, delivered, failed };
  }

  private async persistEvent(insert: WebhookEventInsert): Promise<WebhookEventRow> {
    return insertWebhookEvent(this.db, insert);
  }

  private async linkEventToCustomer(eventId: string, customerId: string): Promise<void> {
    const { error } = await this.db
      .from("composio_webhook_events")
      .update({ customer_id: customerId })
      .eq("id", eventId);
    if (error) {
      this.logger.warn({ err: error, eventId, customerId }, "webhook dispatcher: failed to link event to customer");
    }
  }
}