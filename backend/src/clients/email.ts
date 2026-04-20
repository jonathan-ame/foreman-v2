export interface SendEmailOptions {
  to: string;
  subject: string;
  html: string;
  text?: string;
}

export interface EmailClient {
  send(opts: SendEmailOptions): Promise<void>;
  readonly enabled: boolean;
}

interface ResendSuccessResponse {
  id: string;
}

interface ResendErrorResponse {
  name: string;
  message: string;
  statusCode: number;
}

export function createEmailClient(apiKey: string | undefined, from: string | undefined): EmailClient {
  const enabled = Boolean(apiKey && from);

  return {
    enabled,
    async send(opts: SendEmailOptions): Promise<void> {
      if (!enabled || !apiKey || !from) {
        return;
      }

      const body = {
        from,
        to: opts.to,
        subject: opts.subject,
        html: opts.html,
        ...(opts.text ? { text: opts.text } : {})
      };

      const response = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify(body)
      });

      if (!response.ok) {
        const err = (await response.json().catch(() => ({}))) as Partial<ResendErrorResponse>;
        throw new Error(
          `Resend API error ${response.status}: ${err.message ?? response.statusText}`
        );
      }

      const result = (await response.json()) as ResendSuccessResponse;
      if (!result.id) {
        throw new Error("Resend API returned success but no email id");
      }
    }
  };
}
