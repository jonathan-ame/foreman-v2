import type { Logger } from "pino";
import type { SupabaseClient } from "../../db/supabase.js";
import { WebhookEventDispatcher, type DispatcherDeps } from "./webhook-dispatcher.js";
import { NotificationHandler } from "./handlers/notification-handler.js";
import { LoggingHandler } from "./handlers/logging-handler.js";
import { AgentIssueHandler } from "./handlers/agent-issue-handler.js";

export interface WebhookDispatcherFactoryDeps {
  db: SupabaseClient;
  logger: Logger;
  onAgentIssueCreate?: (companyId: string, input: Record<string, unknown>) => Promise<unknown>;
}

export function createWebhookDispatcher(deps: WebhookDispatcherFactoryDeps): WebhookEventDispatcher {
  const notificationHandler = new NotificationHandler({
    db: deps.db,
    logger: deps.logger
  });

  const agentIssueHandler = new AgentIssueHandler({
    logger: deps.logger,
    onAgentIssueCreate: deps.onAgentIssueCreate
  });

  const loggingHandler = new LoggingHandler({
    logger: deps.logger
  });

  const dispatcherDeps: DispatcherDeps = {
    db: deps.db,
    logger: deps.logger,
    handlers: [notificationHandler, agentIssueHandler, loggingHandler]
  };

  return new WebhookEventDispatcher(dispatcherDeps);
}