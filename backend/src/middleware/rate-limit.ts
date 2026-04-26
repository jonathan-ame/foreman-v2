import type { Context, Next } from "hono";
import { createLogger } from "../config/logger.js";

const logger = createLogger("rate-limit");

export interface RateLimitOptions {
  windowMs: number;
  maxRequests: number;
  keyFn?: (c: Context) => string;
  excludedPaths?: string[];
  enabled?: boolean;
}

interface RateLimitEntry {
  timestamps: number[];
}

const store = new Map<string, RateLimitEntry>();

const DEFAULT_WINDOW_MS = 60_000;
const DEFAULT_MAX_REQUESTS = 100;
const CLEANUP_INTERVAL_MS = 5 * 60_000;
const MAX_STORE_SIZE = 50_000;

let lastCleanup = Date.now();

function cleanupExpired(now: number, windowMs: number): void {
  if (store.size > MAX_STORE_SIZE) {
    const oldest = new Map(
      [...store.entries()].sort(([, a], [, b]) => {
        const aOldest = a.timestamps[0] ?? now;
        const bOldest = b.timestamps[0] ?? now;
        return aOldest - bOldest;
      })
    );
   const keysToRemove = [...oldest.keys()].slice(0, Math.floor(MAX_STORE_SIZE / 2));
    for (const key of keysToRemove) {
      store.delete(key);
    }
  }

  if (now - lastCleanup < CLEANUP_INTERVAL_MS) {
    return;
  }
  lastCleanup = now;
  for (const [key, entry] of store) {
    entry.timestamps = entry.timestamps.filter((ts) => now - ts < windowMs);
    if (entry.timestamps.length === 0) {
      store.delete(key);
    }
  }
}

function defaultKeyFn(c: Context): string {
  const forwarded = c.req.header("x-forwarded-for");
  if (forwarded) {
    return (forwarded.split(",")[0] ?? "").trim();
  }
  const realIp = c.req.header("x-real-ip");
  if (realIp) {
    return realIp.trim();
  }
  return "unknown";
}

export function slidingWindowRateLimit(options: Partial<RateLimitOptions> = {}) {
  const windowMs = options.windowMs ?? DEFAULT_WINDOW_MS;
  const maxRequests = options.maxRequests ?? DEFAULT_MAX_REQUESTS;
  const keyFn = options.keyFn ?? defaultKeyFn;
  const excludedPaths = options.excludedPaths ?? [];
  const enabled = options.enabled ?? true;

  return async (c: Context, next: Next) => {
    if (!enabled) {
      return next();
    }

    const requestPath = c.req.path;

    for (const excluded of excludedPaths) {
      if (requestPath === excluded || requestPath.startsWith(excluded + "/")) {
        return next();
      }
    }

    const key = `rl:${windowMs}:${keyFn(c)}`;
    const now = Date.now();

    cleanupExpired(now, windowMs);

    const entry = store.get(key) ?? { timestamps: [] };
    entry.timestamps = entry.timestamps.filter((ts) => now - ts < windowMs);

    const remaining = maxRequests - entry.timestamps.length;

    c.header("X-RateLimit-Limit", String(maxRequests));
    c.header("X-RateLimit-Remaining", String(Math.max(0, remaining - 1)));
    c.header("X-RateLimit-Reset", String(Math.ceil((entry.timestamps[0] ?? now + windowMs) / 1000)));

    if (entry.timestamps.length >= maxRequests) {
      const oldestInWindow = entry.timestamps[0] ?? now;
      const retryAfterMs = oldestInWindow + windowMs - now;
      c.header("Retry-After", String(Math.ceil(retryAfterMs / 1000)));

      logger.warn(
        {
          key: keyFn(c),
          path: requestPath,
          method: c.req.method,
          limit: maxRequests,
          windowMs
        },
        "rate limit exceeded"
      );

      return c.json(
        {
          error: "rate_limit_exceeded",
          message: "Too many requests. Please try again later."
        },
        429
      );
    }

    entry.timestamps.push(now);
    store.set(key, entry);

    return next();
  };
}

export const rateLimitPresets = {
  strict: { windowMs: 60_000, maxRequests: 20 },
  standard: { windowMs: 60_000, maxRequests: 100 },
  lenient: { windowMs: 60_000, maxRequests: 300 },
  auth: { windowMs: 15 * 60_000, maxRequests: 10 }
} as const;

export function resetRateLimitStore(): void {
  store.clear();
  lastCleanup = Date.now();
}

export function getRateLimitStoreSize(): number {
  return store.size;
}

export function getRateLimitStore(): Map<string, RateLimitEntry> {
  return store;
}