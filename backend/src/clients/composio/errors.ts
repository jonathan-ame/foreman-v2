export interface ComposioApiErrorOptions {
  statusCode?: number;
  errorCode?: string;
  message: string;
  retryable?: boolean;
}

export class ComposioApiError extends Error {
  readonly statusCode?: number | undefined;
  readonly errorCode?: string | undefined;
  readonly retryable: boolean;

  constructor(options: ComposioApiErrorOptions) {
    super(options.message);
    this.name = "ComposioApiError";
    this.statusCode = options.statusCode;
    this.errorCode = options.errorCode;
    this.retryable = options.retryable ?? false;
  }
}

export class ComposioAuthError extends ComposioApiError {
  constructor(statusCode: number, message: string) {
    super({ statusCode, errorCode: "COMPOSIO_AUTH_ERROR", message });
    this.name = "ComposioAuthError";
  }
}

export class ComposioNotFoundError extends ComposioApiError {
  constructor(message: string) {
    super({ statusCode: 404, errorCode: "COMPOSIO_NOT_FOUND", message });
    this.name = "ComposioNotFoundError";
  }
}
