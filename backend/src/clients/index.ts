import type { Logger } from "pino";
import { ComposioClient } from "./composio/client.js";
import { OutlookEmailClient } from "./composio/outlook-email.js";
import { createEmailClient } from "./email.js";
import { OpenClawClient } from "./openclaw/client.js";
import { PaperclipClient } from "./paperclip/client.js";
import { StripeClient } from "./stripe/client.js";
import { TavilyClient } from "./tavily/client.js";

export interface ClientFactoryEnv {
  PAPERCLIP_API_BASE: string;
  PAPERCLIP_API_KEY: string | undefined;
  PAPERCLIP_RUN_ID: string | undefined;
  OPENCLAW_BIN: string;
  OPENCLAW_CONFIG_PATH: string;
  OPENCLAW_INCLUDE_PATH: string;
  STRIPE_MODE: "live" | "test";
  STRIPE_SECRET_KEY: string | undefined;
  STRIPE_SECRET_KEY_TEST: string | undefined;
  RESEND_API_KEY: string | undefined;
  EMAIL_FROM: string | undefined;
  COMPOSIO_API_KEY: string | undefined;
  COMPOSIO_API_BASE: string;
  COMPOSIO_CONNECTED_ACCOUNT_ID_OUTLOOK: string | undefined;
  COMPOSIO_USER_ID: string;
  TAVILY_API_KEY: string | undefined;
}

export const createClients = (env: ClientFactoryEnv, logger: Logger) => {
  const stripeConfig = {
    logger: logger.child({ name: "stripe-client" }),
    mode: env.STRIPE_MODE,
    liveApiKey: env.STRIPE_SECRET_KEY,
    testApiKey: env.STRIPE_SECRET_KEY_TEST
  };

  const composio = new ComposioClient({
    apiBase: env.COMPOSIO_API_BASE,
    apiKey: env.COMPOSIO_API_KEY ?? "",
    logger: logger.child({ name: "composio-client" })
  });

  const outlookConnectedAccountId = env.COMPOSIO_CONNECTED_ACCOUNT_ID_OUTLOOK;
  const composioUserId = env.COMPOSIO_USER_ID;

  const useOutlook = composio.isConfigured && Boolean(outlookConnectedAccountId);

  const email = useOutlook
    ? new OutlookEmailClient({
        composio,
        connectedAccountId: outlookConnectedAccountId!,
        userId: composioUserId,
        logger: logger.child({ name: "outlook-email-client" })
      })
    : createEmailClient(env.RESEND_API_KEY, env.EMAIL_FROM);

  return {
    paperclip: new PaperclipClient({
      apiBase: env.PAPERCLIP_API_BASE,
      apiKey: env.PAPERCLIP_API_KEY ?? "",
      runId: env.PAPERCLIP_RUN_ID,
      logger: logger.child({ name: "paperclip-client" })
    }),
    openclaw: new OpenClawClient({
      binPath: env.OPENCLAW_BIN,
      configPath: env.OPENCLAW_CONFIG_PATH,
      includePath: env.OPENCLAW_INCLUDE_PATH,
      logger: logger.child({ name: "openclaw-client" })
    }),
    stripe: new StripeClient(stripeConfig),
    email,
    composio,
    tavily: new TavilyClient({
      apiKey: env.TAVILY_API_KEY ?? "",
      logger: logger.child({ name: "tavily-client" })
    })
  };
};
