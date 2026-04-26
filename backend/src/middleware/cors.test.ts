import { Hono } from "hono";
import { describe, expect, it } from "vitest";
import { cors } from "./cors.js";

describe("cors middleware", () => {
  const defaultOptions = {
    allowedOrigins: ["https://app.foreman.company", "https://staging.foreman.company"]
  };

  function createApp(opts: Parameters<typeof cors>[0] = defaultOptions) {
    const app = new Hono();
    app.use("/api/*", cors(opts));
    app.get("/api/test", (c) => c.json({ ok: true }));
    app.post("/api/test", (c) => c.json({ ok: true }));
    return app;
  }

  describe("simple requests", () => {
    it("sets CORS headers for allowed origins", async () => {
      const app = createApp();
      const res = await app.request("/api/test", {
        headers: { Origin: "https://app.foreman.company" }
      });
      expect(res.status).toBe(200);
      expect(res.headers.get("Access-Control-Allow-Origin")).toBe("https://app.foreman.company");
    });

    it("sets Access-Control-Allow-Credentials when configured", async () => {
      const app = createApp();
      const res = await app.request("/api/test", {
        headers: { Origin: "https://app.foreman.company" }
      });
      expect(res.headers.get("Access-Control-Allow-Credentials")).toBe("true");
    });

    it("does not set CORS headers for disallowed origins", async () => {
      const app = createApp();
      const res = await app.request("/api/test", {
        headers: { Origin: "https://evil.example.com" }
      });
      expect(res.status).toBe(200);
      expect(res.headers.get("Access-Control-Allow-Origin")).toBeNull();
    });

    it("does not set CORS headers when no Origin header is present", async () => {
      const app = createApp();
      const res = await app.request("/api/test");
      expect(res.status).toBe(200);
      expect(res.headers.get("Access-Control-Allow-Origin")).toBeNull();
    });

    it("exposes configured headers via Access-Control-Expose-Headers", async () => {
      const app = createApp();
      const res = await app.request("/api/test", {
        headers: { Origin: "https://app.foreman.company" }
      });
      expect(res.headers.get("Access-Control-Expose-Headers")).toContain("X-RateLimit-Limit");
    });
  });

  describe("preflight requests", () => {
    it("allows preflight for allowed origins", async () => {
      const app = createApp();
      const res = await app.request("/api/test", {
        method: "OPTIONS",
        headers: {
          Origin: "https://app.foreman.company",
          "Access-Control-Request-Method": "POST"
        }
      });
      expect(res.status).toBe(204);
      expect(res.headers.get("Access-Control-Allow-Origin")).toBe("https://app.foreman.company");
      expect(res.headers.get("Access-Control-Allow-Methods")).toContain("POST");
      expect(res.headers.get("Access-Control-Allow-Headers")).toContain("Content-Type");
      expect(res.headers.get("Access-Control-Max-Age")).toBe("86400");
      expect(res.headers.get("Access-Control-Allow-Credentials")).toBe("true");
    });

    it("rejects preflight for disallowed origins with 403", async () => {
      const app = createApp();
      const res = await app.request("/api/test", {
        method: "OPTIONS",
        headers: {
          Origin: "https://evil.example.com",
          "Access-Control-Request-Method": "POST"
        }
      });
      expect(res.status).toBe(403);
      const body = await res.json();
      expect(body).toEqual({ error: "cors_forbidden", message: "Origin not allowed" });
    });

    it("rejects preflight without Origin header with 403", async () => {
      const app = createApp();
      const res = await app.request("/api/test", {
        method: "OPTIONS"
      });
      expect(res.status).toBe(403);
    });
  });

  describe("wildcard subdomain matching", () => {
    it("matches subdomains with *.domain pattern", async () => {
      const app = createApp({
        allowedOrigins: ["*.foreman.company"]
      });
      const res = await app.request("/api/test", {
        headers: { Origin: "https://app.foreman.company" }
      });
      expect(res.status).toBe(200);
      expect(res.headers.get("Access-Control-Allow-Origin")).toBe("https://app.foreman.company");
    });

    it("matches nested subdomains", async () => {
      const app = createApp({
        allowedOrigins: ["*.foreman.company"]
      });
      const res = await app.request("/api/test", {
        headers: { Origin: "https://staging.app.foreman.company" }
      });
      expect(res.status).toBe(200);
      expect(res.headers.get("Access-Control-Allow-Origin")).toBe("https://staging.app.foreman.company");
    });

    it("does not match bare domain with wildcard pattern", async () => {
      const app = createApp({
        allowedOrigins: ["*.foreman.company"]
      });
      const res = await app.request("/api/test", {
        headers: { Origin: "https://foreman.company" }
      });
      expect(res.headers.get("Access-Control-Allow-Origin")).toBeNull();
    });

    it("matches exact domain when listed alongside wildcard", async () => {
      const app = createApp({
        allowedOrigins: ["*.foreman.company", "https://foreman.company"]
      });
      const res = await app.request("/api/test", {
        headers: { Origin: "https://foreman.company" }
      });
      expect(res.headers.get("Access-Control-Allow-Origin")).toBe("https://foreman.company");
    });
  });

  describe("wildcard origin *", () => {
    it("allows all origins with wildcard *", async () => {
      const app = createApp({ allowedOrigins: ["*"] });
      const res = await app.request("/api/test", {
        headers: { Origin: "https://any-site.example.com" }
      });
      expect(res.status).toBe(200);
      expect(res.headers.get("Access-Control-Allow-Origin")).toBe("*");
    });

    it("does not set Allow-Credentials with wildcard *", async () => {
      const app = createApp({ allowedOrigins: ["*"] });
      const res = await app.request("/api/test", {
        headers: { Origin: "https://any-site.example.com" }
      });
      expect(res.headers.get("Access-Control-Allow-Credentials")).toBeNull();
    });

    it("preflight allows all origins with wildcard *", async () => {
      const app = createApp({ allowedOrigins: ["*"] });
      const res = await app.request("/api/test", {
        method: "OPTIONS",
        headers: {
          Origin: "https://any-site.example.com",
          "Access-Control-Request-Method": "GET"
        }
      });
      expect(res.status).toBe(204);
      expect(res.headers.get("Access-Control-Allow-Origin")).toBe("*");
      expect(res.headers.get("Access-Control-Allow-Credentials")).toBeNull();
    });
  });

  describe("custom options", () => {
    it("uses custom allowed methods", async () => {
      const app = createApp({
        ...defaultOptions,
        allowedMethods: ["GET", "POST"]
      });
      const res = await app.request("/api/test", {
        method: "OPTIONS",
        headers: {
          Origin: "https://app.foreman.company",
          "Access-Control-Request-Method": "GET"
        }
      });
      expect(res.headers.get("Access-Control-Allow-Methods")).toBe("GET, POST");
    });

    it("uses custom allowed headers", async () => {
      const app = createApp({
        ...defaultOptions,
        allowedHeaders: ["Authorization", "X-Custom-Header"]
      });
      const res = await app.request("/api/test", {
        method: "OPTIONS",
        headers: {
          Origin: "https://app.foreman.company",
          "Access-Control-Request-Method": "GET"
        }
      });
      expect(res.headers.get("Access-Control-Allow-Headers")).toBe("Authorization, X-Custom-Header");
    });

    it("uses custom max age", async () => {
      const app = createApp({
        ...defaultOptions,
        maxAge: 3600
      });
      const res = await app.request("/api/test", {
        method: "OPTIONS",
        headers: {
          Origin: "https://app.foreman.company",
          "Access-Control-Request-Method": "GET"
        }
      });
      expect(res.headers.get("Access-Control-Max-Age")).toBe("3600");
    });

    it("disables credentials when allowCredentials is false", async () => {
      const app = createApp({
        ...defaultOptions,
        allowCredentials: false
      });
      const res = await app.request("/api/test", {
        headers: { Origin: "https://app.foreman.company" }
      });
      expect(res.headers.get("Access-Control-Allow-Credentials")).toBeNull();
    });

    it("uses custom exposed headers", async () => {
      const app = createApp({
        ...defaultOptions,
        exposedHeaders: ["X-Custom-Response-Header"]
      });
      const res = await app.request("/api/test", {
        headers: { Origin: "https://app.foreman.company" }
      });
      expect(res.headers.get("Access-Control-Expose-Headers")).toBe("X-Custom-Response-Header");
    });
  });

  describe("empty allowedOrigins", () => {
    it("does not set CORS headers when no origins configured", async () => {
      const app = createApp({ allowedOrigins: [] });
      const res = await app.request("/api/test", {
        headers: { Origin: "https://app.foreman.company" }
      });
      expect(res.status).toBe(200);
      expect(res.headers.get("Access-Control-Allow-Origin")).toBeNull();
    });

    it("rejects preflight when no origins configured", async () => {
      const app = createApp({ allowedOrigins: [] });
      const res = await app.request("/api/test", {
        method: "OPTIONS",
        headers: {
          Origin: "https://app.foreman.company",
          "Access-Control-Request-Method": "GET"
        }
      });
      expect(res.status).toBe(403);
    });
  });

  describe("multiple origins", () => {
    it("reflects the matching origin (not all origins)", async () => {
      const app = createApp({
        allowedOrigins: ["https://app.foreman.company", "https://admin.foreman.company"]
      });

      const res1 = await app.request("/api/test", {
        headers: { Origin: "https://app.foreman.company" }
      });
      expect(res1.headers.get("Access-Control-Allow-Origin")).toBe("https://app.foreman.company");

      const res2 = await app.request("/api/test", {
        headers: { Origin: "https://admin.foreman.company" }
      });
      expect(res2.headers.get("Access-Control-Allow-Origin")).toBe("https://admin.foreman.company");
    });
  });
});