export class StripeApiError extends Error {
  readonly statusCode: number | undefined;
  readonly errorCode: string | undefined;
  readonly requestId: string | undefined;

  constructor(message: string, options?: { statusCode?: number; errorCode?: string; requestId?: string }) {
    super(message);
    this.name = "StripeApiError";
    this.statusCode = options?.statusCode;
    this.errorCode = options?.errorCode;
    this.requestId = options?.requestId;
  }
}
