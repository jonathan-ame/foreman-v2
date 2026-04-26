import type { Logger } from "pino";
import type { DispatcherContext, HandlerResult, WebhookHandler } from "../webhook-dispatcher.js";

export interface LoggingHandlerDeps {
  logger: Logger;
}

export class LoggingHandler implements WebhookHandler {
  readonly name = "logging";

  private readonly logger: Logger;

  constructor(deps: LoggingHandlerDeps) {
    this.logger = deps.logger.child({ handler: "logging" });
  }

  canHandle(_ctx: DispatcherContext): boolean {
    return true;
  }

  async handle(ctx: DispatcherContext): Promise<HandlerResult> {
    this.logger.info(
      {
        eventId: ctx.webhookEvent.id,
        triggerId: ctx.webhookEvent.trigger_id,
        triggerType: ctx.webhookEvent.trigger_type,
        customerId: ctx.triggerRow?.customer_id ?? null,
        toolkit: ctx.webhookEvent.toolkit
      },
      "logging handler: event recorded"
    );

    return {
      delivered: true,
      data: {
        logged: true,
        eventId: ctx.webhookEvent.id,
        triggerType: ctx.webhookEvent.trigger_type
      }
    };
  }
}