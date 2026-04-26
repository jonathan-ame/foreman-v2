import type { Logger } from "pino";
import type { SupabaseClient } from "../../../db/supabase.js";
import { insertNotification, type NotificationInsert } from "../../../db/notifications.js";
import { getCustomerById } from "../../../db/customers.js";
import type { DispatcherContext, HandlerResult, WebhookHandler } from "../webhook-dispatcher.js";

const KNOWN_TRIGGER_TYPES = new Set([
  "gmail_on_new_message",
  "outlook_on_new_email",
  "slack_on_message_received",
  "github_on_star_added",
  "github_on_issue_opened",
  "github_on_pull_request_opened",
  "google_calendar_on_event_created",
  "hubspot_on_deal_created",
  "jira_on_issue_created",
  "linear_on_issue_created",
  "notion_on_page_updated",
  "salesforce_on_opportunity_created",
  "trello_on_card_created",
  "zendesk_on_ticket_created"
]);

function notificationTypeForTrigger(_triggerType: string): NotificationInsert["type"] {
  return "integration_event";
}

function deriveTitleAndBody(
  triggerType: string,
  toolkit: string | null,
  rawPayload: Record<string, unknown>
): { title: string; body: string } {
  const payload = (rawPayload.payload ?? rawPayload) as Record<string, unknown>;

  switch (triggerType) {
    case "gmail_on_new_message":
    case "outlook_on_new_email": {
      const from = (payload.from ?? payload.sender ?? "Unknown") as string;
      const subject = (payload.subject ?? payload.snippet ?? "No subject") as string;
      return {
        title: `New email from ${from}`,
        body: String(subject).slice(0, 200)
      };
    }
    case "slack_on_message_received": {
      const channel = (payload.channel_name ?? payload.channel ?? "a channel") as string;
      const user = (payload.user_name ?? payload.user ?? "Someone") as string;
      const text = (payload.text ?? "") as string;
      return {
        title: `Slack message in #${channel}`,
        body: `${user}: ${String(text).slice(0, 180)}`
      };
    }
    case "github_on_star_added":
    case "github_on_issue_opened":
    case "github_on_pull_request_opened": {
      const repo = (payload.repository ?? payload.repo ?? "repository") as string;
      const action = triggerType.includes("star") ? "starred" : triggerType.includes("issue") ? "new issue" : "new PR";
      return {
        title: `GitHub ${action} on ${repo}`,
        body: `GitHub event: ${action} on ${repo}`
      };
    }
    default: {
      const toolkitLabel = toolkit ?? "unknown";
      return {
        title: `${toolkitLabel} event: ${triggerType}`,
        body: `Received ${toolkitLabel} trigger event: ${triggerType}`
      };
    }
  }
}

export interface NotificationHandlerDeps {
  db: SupabaseClient;
  logger: Logger;
}

export class NotificationHandler implements WebhookHandler {
  readonly name = "notification";

  private readonly db: SupabaseClient;
  private readonly logger: Logger;

  constructor(deps: NotificationHandlerDeps) {
    this.db = deps.db;
    this.logger = deps.logger.child({ handler: "notification" });
  }

  canHandle(ctx: DispatcherContext): boolean {
    if (!ctx.triggerRow?.customer_id) {
      this.logger.debug("skipping notification: no customer_id on trigger row");
      return false;
    }
    return true;
  }

  async handle(ctx: DispatcherContext): Promise<HandlerResult> {
    const customerId = ctx.triggerRow!.customer_id;
    const triggerType = ctx.triggerRow!.trigger_type;

    const customer = await getCustomerById(this.db, customerId);
    if (!customer) {
      this.logger.warn({ customerId }, "notification handler: customer not found");
      return { delivered: false, message: `Customer ${customerId} not found` };
    }

    if (!customer.workspace_slug) {
      this.logger.warn({ customerId }, "notification handler: customer has no workspace_slug");
      return { delivered: false, message: `Customer ${customerId} has no workspace_slug` };
    }

    const { title, body } = deriveTitleAndBody(triggerType, ctx.triggerRow!.toolkit_slug, ctx.rawPayload);
    const type = notificationTypeForTrigger(triggerType);

    try {
      await insertNotification(this.db, {
        workspace_slug: customer.workspace_slug,
        type,
        title,
        body,
        reference_id: ctx.webhookEvent.id,
        reference_type: "composio_webhook_event"
      });

      this.logger.info({ customerId, triggerType, type }, "notification handler: notification inserted");
      return { delivered: true, data: { workspace_slug: customer.workspace_slug, type, title } };
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      this.logger.error({ err, customerId, triggerType }, "notification handler: failed to insert notification");
      return { delivered: false, message: msg };
    }
  }
}

export { KNOWN_TRIGGER_TYPES };