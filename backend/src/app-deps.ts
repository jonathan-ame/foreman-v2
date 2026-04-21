import type { Logger } from "pino";
import { createClients } from "./clients/index.js";
import type { EmailClient } from "./clients/email.js";
import { env, type Env } from "./config/env.js";
import { createLogger } from "./config/logger.js";
import { createSupabaseClient, type SupabaseClient } from "./db/supabase.js";
import type { OpenClawClientLike, PaperclipClientLike, StripeClientLike } from "./provisioning/steps/types.js";

export interface AppDeps {
  clients: {
    paperclip: PaperclipClientLike;
    openclaw: OpenClawClientLike;
    stripe: StripeClientLike;
    email: EmailClient;
  };
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
    EMAIL_FROM: env.EMAIL_FROM
  };
  return {
    clients: createClients(clientEnv, logger),
    db: createSupabaseClient(env),
    logger,
    env
  };
}
