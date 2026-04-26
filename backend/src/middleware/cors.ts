import type { Context, Next } from "hono";
import { createLogger } from "../config/logger.js";

const logger = createLogger("cors");

export interface CorsOptions {
  allowedOrigins: string[];
  allowedMethods: string[];
  allowedHeaders: string[];
  exposedHeaders: string[];
  allowCredentials: boolean;
  maxAge: number;
}

const DEFAULT_OPTIONS: CorsOptions = {
  allowedOrigins: [],
  allowedMethods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "X-Request-Id", "X-Api-Key"],
  exposedHeaders: ["X-RateLimit-Limit", "X-RateLimit-Remaining", "X-RateLimit-Reset", "Retry-After"],
  allowCredentials: true,
  maxAge: 86400
};

function matchesOrigin(requestOrigin: string | undefined, allowedOrigins: string[]): string | null {
  if (!requestOrigin) {
    return null;
  }

  for (const pattern of allowedOrigins) {
    if (pattern === "*") {
      return "*";
    }
    if (pattern === requestOrigin) {
      return requestOrigin;
    }
    if (pattern.startsWith("*.") && requestOrigin.includes("://")) {
      const parts = requestOrigin.split("://");
      const requestHost = parts[1];
      const domainSuffix = pattern.slice(2);
      if (requestHost && requestHost.endsWith(`.${domainSuffix}`)) {
        return requestOrigin;
      }
    }
  }

  return null;
}

export function cors(options: Partial<CorsOptions> = {}) {
  const opts: CorsOptions = {
    allowedOrigins: options.allowedOrigins ?? DEFAULT_OPTIONS.allowedOrigins,
    allowedMethods: options.allowedMethods ?? DEFAULT_OPTIONS.allowedMethods,
    allowedHeaders: options.allowedHeaders ?? DEFAULT_OPTIONS.allowedHeaders,
    exposedHeaders: options.exposedHeaders ?? DEFAULT_OPTIONS.exposedHeaders,
    allowCredentials: options.allowCredentials ?? DEFAULT_OPTIONS.allowCredentials,
    maxAge: options.maxAge ?? DEFAULT_OPTIONS.maxAge
  };

  return async (c: Context, next: Next) => {
    const requestOrigin = c.req.header("Origin");

    if (c.req.method === "OPTIONS") {
      const matchedOrigin = matchesOrigin(requestOrigin, opts.allowedOrigins);

      if (!matchedOrigin) {
        logger.debug({ origin: requestOrigin, method: c.req.method, path: c.req.path }, "CORS preflight rejected");
        return c.json({ error: "cors_forbidden", message: "Origin not allowed" }, 403);
      }

      const responseHeaders: Record<string, string> = {
        "Access-Control-Allow-Origin": matchedOrigin === "*" ? "*" : matchedOrigin,
        "Access-Control-Allow-Methods": opts.allowedMethods.join(", "),
        "Access-Control-Allow-Headers": opts.allowedHeaders.join(", "),
        "Access-Control-Max-Age": String(opts.maxAge)
      };

      if (opts.allowCredentials && matchedOrigin !== "*") {
        responseHeaders["Access-Control-Allow-Credentials"] = "true";
      }

      if (opts.exposedHeaders.length > 0) {
        responseHeaders["Access-Control-Expose-Headers"] = opts.exposedHeaders.join(", ");
      }

      logger.debug({ origin: matchedOrigin, method: "OPTIONS", path: c.req.path }, "CORS preflight allowed");
      return new Response(null, { status: 204, headers: responseHeaders });
    }

    await next();

    const matchedOrigin = matchesOrigin(requestOrigin, opts.allowedOrigins);
    if (matchedOrigin) {
      c.header("Access-Control-Allow-Origin", matchedOrigin === "*" ? "*" : matchedOrigin);
      if (opts.allowCredentials && matchedOrigin !== "*") {
        c.header("Access-Control-Allow-Credentials", "true");
      }
      if (opts.exposedHeaders.length > 0) {
        c.header("Access-Control-Expose-Headers", opts.exposedHeaders.join(", "));
      }
    }
  };
}