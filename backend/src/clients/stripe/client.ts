import type { Logger } from "pino";
import { StripeApiError } from "./errors.js";
import type { PaymentStatus } from "./types.js";

export interface StripeClientConfig {
  apiKey?: string;
  logger: Logger;
}

export class StripeClient {
  private readonly apiKey: string | undefined;
  private readonly logger: Logger;

  constructor(config: StripeClientConfig) {
    this.apiKey = config.apiKey;
    this.logger = config.logger;
  }

  async getSubscriptionStatus(_stripeCustomerId: string): Promise<PaymentStatus> {
    this.logger.warn({ stub: true, hasApiKey: Boolean(this.apiKey) }, "stripe client running in STUB mode");
    return "active";
  }

  async hasFailedPaymentSince(_stripeCustomerId: string, _since: Date): Promise<boolean> {
    this.logger.warn({ stub: true, hasApiKey: Boolean(this.apiKey) }, "stripe client running in STUB mode");
    return false;
  }

  async getPrepaidBalanceCents(_stripeCustomerId: string): Promise<number> {
    this.logger.warn({ stub: true, hasApiKey: Boolean(this.apiKey) }, "stripe client running in STUB mode");
    return 1_000_000;
  }

  async createSubscription(): Promise<never> {
    throw new StripeApiError("NotImplemented: P8 implements this");
  }

  async cancelSubscription(): Promise<never> {
    throw new StripeApiError("NotImplemented: P8 implements this");
  }

  async createPaymentIntent(): Promise<never> {
    throw new StripeApiError("NotImplemented: P8 implements this");
  }
}
