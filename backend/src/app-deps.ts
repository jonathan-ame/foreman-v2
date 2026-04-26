import type { Logger } from "pino";
import { createClients } from "./clients/index.js";
import type { EmailClient } from "./clients/email.js";
import type { ComposioClient } from "./clients/composio/client.js";
import type { WebhookEventDispatcher } from "./clients/composio/webhook-dispatcher.js";
import type { TavilyClient } from "./clients/tavily/client.js";
import { env, type Env } from "./config/env.js";
import { createLogger } from "./config/logger.js";
import { createSupabaseClient, type SupabaseClient } from "./db/supabase.js";
import type { OpenClawClientLike, PaperclipClientLike, StripeClientLike } from "./provisioning/steps/types.js";
import { createWebhookDispatcher } from "./clients/composio/webhook-dispatcher-factory.js";

export interface AppDeps {
  clients: {
    paperclip: PaperclipClientLike;
    openclaw: OpenClawClientLike;
    stripe: StripeClientLike;
    email: EmailClient;
    composio: ComposioClient;
    tavily: TavilyClient;
  };
  webhookDispatcher: WebhookEventDispatcher;
  db: SupabaseClient;
  logger: Logger;
  env: Env;
}

export function createAppDeps(baseLogger?: Logger): AppDeps {
  const logger = baseLogger ?? createLogger("app");
  const clientEnv = {
    PAPERCLIP_API_BASE: env.PAPERCLIP_API_BASE,
    PAPERCLIP_API_KEY: env.PAPERCLIP_API_KEY,
    PAPERCLIP_RUN_ID: env.PAPERCLIP_RUN_ID,
    OPENCLAW_BIN: env.OPENCLAW_BIN,
    OPENCLAW_CONFIG_PATH: env.OPENCLAW_CONFIG_PATH,
    OPENCLAW_INCLUDE_PATH: env.OPENCLAW_INCLUDE_PATH,
    STRIPE_MODE: env.stripeMode,
    STRIPE_SECRET_KEY: env.STRIPE_SECRET_KEY,
    STRIPE_SECRET_KEY_TEST: env.STRIPE_SECRET_KEY_TEST,
    RESEND_API_KEY: env.RESEND_API_KEY,
    EMAIL_FROM: env.EMAIL_FROM,
    COMPOSIO_API_KEY: env.COMPOSIO_API_KEY,
    COMPOSIO_API_BASE: env.COMPOSIO_API_BASE,
    COMPOSIO_CONNECTED_ACCOUNT_ID_OUTLOOK: env.COMPOSIO_CONNECTED_ACCOUNT_ID_OUTLOOK,
    COMPOSIO_USER_ID: env.COMPOSIO_USER_ID,
    TAVILY_API_KEY: env.TAVILY_API_KEY
  };
  const clients = createClients(clientEnv, logger);
  const db = createSupabaseClient(env);
  const webhookDispatcher = createWebhookDispatcher({ db, logger: logger.child({ name: "webhook-dispatcher" }) });
  return {
    clients,
    webhookDispatcher,
    db,
    logger,
    env
  };
}
