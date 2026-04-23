import type { Logger } from "pino";
import type { EmailClient, SendEmailOptions } from "../email.js";
import { ComposioClient } from "./client.js";
import { ComposioApiError } from "./errors.js";

const OUTLOOK_SEND_TOOL = "OUTLOOK_OUTLOOK_SEND_EMAIL";

export interface OutlookEmailConfig {
  composio: ComposioClient;
  connectedAccountId: string;
  userId: string;
  logger: Logger;
}

export class OutlookEmailClient implements EmailClient {
  private readonly composio: ComposioClient;
  private readonly connectedAccountId: string;
  private readonly userId: string;
  private readonly logger: Logger;
  readonly enabled: boolean;

  constructor(config: OutlookEmailConfig) {
    this.composio = config.composio;
    this.connectedAccountId = config.connectedAccountId;
    this.userId = config.userId;
    this.logger = config.logger;
    this.enabled = config.composio.isConfigured && config.connectedAccountId.length > 0;
  }

  async send(opts: SendEmailOptions): Promise<void> {
    if (!this.enabled) {
      return;
    }

    const args: Record<string, unknown> = {
      to_email: opts.to,
      subject: opts.subject,
      body: opts.html,
      is_html: true
    };

    try {
      const result = await this.composio.executeTool(OUTLOOK_SEND_TOOL, {
        userId: this.userId,
        arguments: args,
        connectedAccountId: this.connectedAccountId
      });

      const successful = result.successful ?? (result.success !== false);
      this.logger.info(
        { to: opts.to, subject: opts.subject, successful },
        "outlook email sent via composio"
      );

      if (!successful) {
        const errorMsg = result.error ?? "Unknown error";
        throw new Error(`Outlook email send failed: ${errorMsg}`);
      }
    } catch (error) {
      const msg = error instanceof ComposioApiError ? error.message : String(error);
      this.logger.error(
        { to: opts.to, subject: opts.subject, error: msg },
        "outlook email send failed"
      );
      throw error;
    }
  }
}