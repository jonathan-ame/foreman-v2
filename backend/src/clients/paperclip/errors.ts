export class PaperclipApiError extends Error {
  statusCode: number;
  errorCode: string;
  retryable: boolean;

  constructor(params: {
    statusCode: number;
    errorCode: string;
    message: string;
    retryable: boolean;
  }) {
    super(params.message);
    this.name = "PaperclipApiError";
    this.statusCode = params.statusCode;
    this.errorCode = params.errorCode;
    this.retryable = params.retryable;
  }
}

export class PaperclipTimeoutError extends PaperclipApiError {
  constructor(message = "Paperclip request timed out") {
    super({
      statusCode: 408,
      errorCode: "PAPERCLIP_TIMEOUT",
      message,
      retryable: true
    });
    this.name = "PaperclipTimeoutError";
  }
}

export class PaperclipAuthError extends PaperclipApiError {
  constructor(statusCode: number, message = "Paperclip authentication failed") {
    super({
      statusCode,
      errorCode: "PAPERCLIP_AUTH",
      message,
      retryable: false
    });
    this.name = "PaperclipAuthError";
  }
}

export class PaperclipNotFoundError extends PaperclipApiError {
  constructor(message = "Paperclip resource not found") {
    super({
      statusCode: 404,
      errorCode: "PAPERCLIP_NOT_FOUND",
      message,
      retryable: false
    });
    this.name = "PaperclipNotFoundError";
  }
}
