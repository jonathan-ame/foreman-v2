import type { Logger } from "pino";
import { OpenClawClient } from "./openclaw/client.js";
import { PaperclipClient } from "./paperclip/client.js";
import { StripeClient } from "./stripe/client.js";

export interface ClientFactoryEnv {
  PAPERCLIP_API_BASE: string;
  PAPERCLIP_API_KEY: string;
  OPENCLAW_BIN: string;
  OPENCLAW_CONFIG_PATH: string;
  OPENCLAW_INCLUDE_PATH: string;
  STRIPE_SECRET_KEY: string;
}

export const createClients = (env: ClientFactoryEnv, logger: Logger) => {
  const stripeConfig = {
    logger: logger.child({ name: "stripe-client" }),
    apiKey: env.STRIPE_SECRET_KEY
  };

  return {
    paperclip: new PaperclipClient({
      apiBase: env.PAPERCLIP_API_BASE,
      apiKey: env.PAPERCLIP_API_KEY,
      logger: logger.child({ name: "paperclip-client" })
    }),
    openclaw: new OpenClawClient({
      binPath: env.OPENCLAW_BIN,
      configPath: env.OPENCLAW_CONFIG_PATH,
      includePath: env.OPENCLAW_INCLUDE_PATH,
      logger: logger.child({ name: "openclaw-client" })
    }),
    stripe: new StripeClient(stripeConfig)
  };
};
