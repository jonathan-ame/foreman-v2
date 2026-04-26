export class TavilyApiError extends Error {
  readonly statusCode: number;
  readonly errorCode: string;
  readonly retryable: boolean;

  constructor(params: { statusCode: number; errorCode: string; message: string; retryable: boolean }) {
    super(params.message);
    this.name = "TavilyApiError";
    this.statusCode = params.statusCode;
    this.errorCode = params.errorCode;
    this.retryable = params.retryable;
  }
}

export class TavilyTimeoutError extends TavilyApiError {
  constructor(message = "Tavily request timed out") {
    super({ statusCode: 408, errorCode: "TAVILY_TIMEOUT", message, retryable: true });
    this.name = "TavilyTimeoutError";
  }
}

export class TavilyAuthError extends TavilyApiError {
  constructor(message = "Tavily authentication failed") {
    super({ statusCode: 401, errorCode: "TAVILY_AUTH", message, retryable: false });
    this.name = "TavilyAuthError";
  }
}