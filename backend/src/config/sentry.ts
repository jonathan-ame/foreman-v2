import * as Sentry from "@sentry/node";

let initialized = false;

export function initSentry(dsn: string | undefined): void {
  if (!dsn || initialized) {
    return;
  }

  Sentry.init({
    dsn,
    environment: process.env.NODE_ENV ?? "development",
    tracesSampleRate: 0.1
  });

  initialized = true;
}

export function captureException(
  err: unknown,
  context?: Record<string, unknown>
): void {
  if (!initialized) {
    return;
  }

  Sentry.withScope((scope) => {
    if (context) {
      scope.setContext("foreman", context);
    }
    Sentry.captureException(err);
  });
}

export { initialized as sentryInitialized };
