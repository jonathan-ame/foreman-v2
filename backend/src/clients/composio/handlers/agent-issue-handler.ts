import type { Logger } from "pino";
import type { DispatcherContext, HandlerResult, WebhookHandler } from "../webhook-dispatcher.js";

const ISSUE_TRIGGER_TYPES = new Set([
  "github_on_issue_opened",
  "jira_on_issue_created",
  "linear_on_issue_created",
  "trello_on_card_created",
  "zendesk_on_ticket_created"
]);

export interface AgentIssueHandlerDeps {
  logger: Logger;
  onAgentIssueCreate?: (companyId: string, input: Record<string, unknown>) => Promise<unknown>;
}

export class AgentIssueHandler implements WebhookHandler {
  readonly name = "agent_issue";

  private readonly logger: Logger;
  private readonly onAgentIssueCreate?: (companyId: string, input: Record<string, unknown>) => Promise<unknown>;

  constructor(deps: AgentIssueHandlerDeps) {
    this.logger = deps.logger.child({ handler: "agent_issue" });
    this.onAgentIssueCreate = deps.onAgentIssueCreate;
  }

  canHandle(ctx: DispatcherContext): boolean {
    if (!ctx.triggerRow?.customer_id) {
      this.logger.debug("skipping agent issue: no customer_id on trigger row");
      return false;
    }

    const triggerType = ctx.triggerRow.trigger_type;
    if (!ISSUE_TRIGGER_TYPES.has(triggerType)) {
      this.logger.debug({ triggerType }, "skipping agent issue: trigger type not an issue type");
      return false;
    }

    return true;
  }

  async handle(ctx: DispatcherContext): Promise<HandlerResult> {
    const customerId = ctx.triggerRow!.customer_id;
    const triggerType = ctx.triggerRow!.trigger_type;
    const rawPayload = ctx.rawPayload;

    const payload = (rawPayload.payload ?? rawPayload) as Record<string, unknown>;

    const issueInput = this.extractIssueInput(triggerType, payload);

    if (this.onAgentIssueCreate) {
      try {
        const result = await this.onAgentIssueCreate(customerId, issueInput);
        this.logger.info({ customerId, triggerType }, "agent issue handler: issue created via callback");
        return {
          delivered: true,
          data: { customerId, triggerType, issue: result as Record<string, unknown> }
        };
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        this.logger.error({ err, customerId, triggerType }, "agent issue handler: callback failed");
        return { delivered: false, message: msg };
      }
    }

    this.logger.info({ customerId, triggerType, issueInput }, "agent issue handler: no callback configured, logging issue for manual review");
    return {
      delivered: true,
      data: { customerId, triggerType, issueInput, note: "no callback configured - logged for review" }
    };
  }

  private extractIssueInput(triggerType: string, payload: Record<string, unknown>): Record<string, unknown> {
    switch (triggerType) {
      case "github_on_issue_opened":
        return {
          source: "github",
          title: (payload.title ?? payload.subject ?? "Untitled issue") as string,
          body: (payload.body ?? payload.description ?? "") as string,
          url: (payload.html_url ?? payload.url ?? null) as string | null,
          repository: (payload.repository ?? payload.repo ?? null) as string | null,
          sender: (payload.sender ?? payload.user ?? null) as string | null,
          labels: Array.isArray(payload.labels) ? payload.labels : [],
          number: payload.number as number | null
        };
      case "jira_on_issue_created":
        return {
          source: "jira",
          title: (payload.summary ?? payload.title ?? "Untitled issue") as string,
          body: (payload.description ?? payload.body ?? "") as string,
          url: (payload.self ?? payload.url ?? null) as string | null,
          project: (payload.project ?? null) as string | null,
          priority: (payload.priority ?? null) as string | null,
          issueType: (payload.issue_type ?? payload.issuetype ?? null) as string | null,
          key: (payload.key ?? null) as string | null
        };
      case "linear_on_issue_created":
        return {
          source: "linear",
          title: (payload.title ?? payload.name ?? "Untitled issue") as string,
          body: (payload.description ?? payload.body ?? "") as string,
          url: (payload.url ?? null) as string | null,
          team: (payload.team ?? null) as string | null,
          priority: (payload.priority ?? null) as string | null,
          identifier: (payload.identifier ?? null) as string | null
        };
      case "trello_on_card_created":
        return {
          source: "trello",
          title: (payload.name ?? payload.title ?? "Untitled card") as string,
          body: (payload.desc ?? payload.description ?? "") as string,
          url: (payload.shortUrl ?? payload.url ?? null) as string | null,
          board: (payload.board ?? null) as string | null,
          list: (payload.list ?? null) as string | null
        };
      case "zendesk_on_ticket_created":
        return {
          source: "zendesk",
          title: (payload.subject ?? payload.title ?? "Untitled ticket") as string,
          body: (payload.description ?? payload.body ?? "") as string,
          url: (payload.url ?? null) as string | null,
          priority: (payload.priority ?? null) as string | null,
          ticketId: (payload.id ?? null) as number | null,
          requester: (payload.requester ?? null) as string | null
        };
      default:
        return {
          source: triggerType.split("_on_")[0] ?? "unknown",
          title: (payload.title ?? payload.subject ?? "Untitled") as string,
          body: (payload.body ?? payload.description ?? "") as string,
          rawPayload: payload
        };
    }
  }
}

export { ISSUE_TRIGGER_TYPES };