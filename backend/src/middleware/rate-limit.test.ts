import { Hono } from "hono";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { resetRateLimitStore, slidingWindowRateLimit } from "./rate-limit.js";

describe("rate-limit middleware", () => {
  beforeEach(() => {
    resetRateLimitStore();
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("allows requests within the limit", async () => {
    const app = new Hono();
    app.use("/*", slidingWindowRateLimit({ windowMs: 60_000, maxRequests: 5 }));
    app.get("/api/test", (c) => c.json({ ok: true }));

    for (let i = 0; i < 5; i++) {
      const res = await app.request("/api/test", {
        headers: { "x-forwarded-for": "1.2.3.4" }
      });
      expect(res.status).toBe(200);
    }
  });

  it("returns 429 when rate limit is exceeded", async () => {
    const app = new Hono();
    app.use("/*", slidingWindowRateLimit({ windowMs: 60_000, maxRequests: 3 }));
    app.get("/api/test", (c) => c.json({ ok: true }));

    for (let i = 0; i < 3; i++) {
      await app.request("/api/test", {
        headers: { "x-forwarded-for": "1.2.3.4" }
      });
    }

    const res = await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(res.status).toBe(429);
    const body = await res.json();
    expect(body).toHaveProperty("error", "rate_limit_exceeded");
  });

  it("sets rate limit response headers", async () => {
    const app = new Hono();
    app.use("/*", slidingWindowRateLimit({ windowMs: 60_000, maxRequests: 10 }));
    app.get("/api/test", (c) => c.json({ ok: true }));

    const res = await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(res.headers.get("X-RateLimit-Limit")).toBe("10");
    expect(res.headers.get("X-RateLimit-Remaining")).not.toBeNull();
  });

  it("sets Retry-After header when rate limited", async () => {
    const app = new Hono();
    app.use("/*", slidingWindowRateLimit({ windowMs: 60_000, maxRequests: 2 }));
    app.get("/api/test", (c) => c.json({ ok: true }));

    for (let i = 0; i < 2; i++) {
      await app.request("/api/test", {
        headers: { "x-forwarded-for": "1.2.3.4" }
      });
    }

    const res = await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(res.headers.get("Retry-After")).not.toBeNull();
  });

  it("allows requests again after the window expires", async () => {
    const app = new Hono();
    app.use("/*", slidingWindowRateLimit({ windowMs: 60_000, maxRequests: 2 }));
    app.get("/api/test", (c) => c.json({ ok: true }));

    await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });

    const res429 = await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(res429.status).toBe(429);

    vi.advanceTimersByTime(61_000);
    resetRateLimitStore();

    const resOk = await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(resOk.status).toBe(200);
  });

  it("tracks separate counters per IP", async () => {
    const app = new Hono();
    app.use("/*", slidingWindowRateLimit({ windowMs: 60_000, maxRequests: 2 }));
    app.get("/api/test", (c) => c.json({ ok: true }));

    await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });

    const res429 = await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(res429.status).toBe(429);

    const resOtherIp = await app.request("/api/test", {
      headers: { "x-forwarded-for": "5.6.7.8" }
    });
    expect(resOtherIp.status).toBe(200);
  });

  it("uses x-real-ip when x-forwarded-for is absent", async () => {
    const app = new Hono();
    app.use("/*", slidingWindowRateLimit({ windowMs: 60_000, maxRequests: 2 }));
    app.get("/api/test", (c) => c.json({ ok: true }));

    await app.request("/api/test", {
      headers: { "x-real-ip": "10.0.0.1" }
    });
    await app.request("/api/test", {
      headers: { "x-real-ip": "10.0.0.1" }
    });

    const res = await app.request("/api/test", {
      headers: { "x-real-ip": "10.0.0.1" }
    });
    expect(res.status).toBe(429);
  });

  it("skips excluded paths", async () => {
    const app = new Hono();
    app.use(
      "/*",
      slidingWindowRateLimit({
        windowMs: 60_000,
        maxRequests: 1,
        excludedPaths: ["/health"]
      })
    );
    app.get("/health", (c) => c.json({ ok: true }));
    app.get("/api/test", (c) => c.json({ ok: true }));

    const res1 = await app.request("/health");
    expect(res1.status).toBe(200);

    const res2 = await app.request("/health");
    expect(res2.status).toBe(200);

    const apiRes = await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(apiRes.status).toBe(200);

    const apiRes429 = await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(apiRes429.status).toBe(429);
  });

  it("custom keyFn overrides default IP extraction", async () => {
    const app = new Hono();
    app.use(
      "/*",
      slidingWindowRateLimit({
        windowMs: 60_000,
        maxRequests: 2,
        keyFn: () => "shared-key"
      })
    );
    app.get("/api/test", (c) => c.json({ ok: true }));

    await app.request("/api/test");
    await app.request("/api/test");

    const res = await app.request("/api/test");
    expect(res.status).toBe(429);
  });

  it("handles first value in comma-separated x-forwarded-for", async () => {
    const app = new Hono();
    app.use("/*", slidingWindowRateLimit({ windowMs: 60_000, maxRequests: 2 }));
    app.get("/api/test", (c) => c.json({ ok: true }));

    await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4, 5.6.7.8" }
    });
    await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4, 5.6.7.8" }
    });

    const res = await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4, 5.6.7.8" }
    });
    expect(res.status).toBe(429);

    const otherIpRes = await app.request("/api/test", {
      headers: { "x-forwarded-for": "9.10.11.12, 5.6.7.8" }
    });
    expect(otherIpRes.status).toBe(200);
  });

  it("uses default limits when no options provided", async () => {
    const app = new Hono();
    app.use("/*", slidingWindowRateLimit());
    app.get("/api/test", (c) => c.json({ ok: true }));

    const res = await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(res.headers.get("X-RateLimit-Limit")).toBe("100");
  });

  it("decrements remaining count in headers", async () => {
    const app = new Hono();
    app.use("/*", slidingWindowRateLimit({ windowMs: 60_000, maxRequests: 5 }));
    app.get("/api/test", (c) => c.json({ ok: true }));

    const res1 = await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(res1.headers.get("X-RateLimit-Remaining")).toBe("4");

    const res2 = await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(res2.headers.get("X-RateLimit-Remaining")).toBe("3");
  });

  it("bypasses rate limiting when enabled is false", async () => {
    const app = new Hono();
    app.use("/*", slidingWindowRateLimit({ windowMs: 60_000, maxRequests: 1, enabled: false }));
    app.get("/api/test", (c) => c.json({ ok: true }));

    for (let i = 0; i < 10; i++) {
      const res = await app.request("/api/test", {
        headers: { "x-forwarded-for": "1.2.3.4" }
      });
      expect(res.status).toBe(200);
    }
  });

  it("does not set rate limit headers when disabled", async () => {
    const app = new Hono();
    app.use("/*", slidingWindowRateLimit({ windowMs: 60_000, maxRequests: 5, enabled: false }));
    app.get("/api/test", (c) => c.json({ ok: true }));

    const res = await app.request("/api/test", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(res.headers.get("X-RateLimit-Limit")).toBeNull();
    expect(res.headers.get("X-RateLimit-Remaining")).toBeNull();
  });

  it("excludes exact paths and sub-paths but not unrelated prefix matches", async () => {
    const app = new Hono();
    app.use(
      "/*",
      slidingWindowRateLimit({
        windowMs: 60_000,
        maxRequests: 1,
        excludedPaths: ["/health"]
      })
    );
    app.get("/health", (c) => c.json({ ok: true }));
    app.get("/health-check", (c) => c.json({ ok: true }));
    app.get("/health/info", (c) => c.json({ ok: true }));

    const resExact = await app.request("/health", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(resExact.status).toBe(200);

    const resExact2 = await app.request("/health", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(resExact2.status).toBe(200);

    const resSubPath = await app.request("/health/info", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(resSubPath.status).toBe(200);

    const resFalse = await app.request("/health-check", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(resFalse.status).toBe(200);

    const resFalse2 = await app.request("/health-check", {
      headers: { "x-forwarded-for": "1.2.3.4" }
    });
    expect(resFalse2.status).toBe(429);
  });
});