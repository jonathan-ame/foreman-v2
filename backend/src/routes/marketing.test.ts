import { Hono } from "hono";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AppDeps } from "../app-deps.js";

const { upsertSubscriberMock } = vi.hoisted(() => ({
  upsertSubscriberMock: vi.fn()
}));

vi.mock("../config/env.js", () => ({
  env: {
    NODE_ENV: "test",
    PORT: 8080,
    LOG_LEVEL: "warn",
    SUPABASE_URL: "http://localhost:54321",
    SUPABASE_SERVICE_KEY: "test-key",
    PAPERCLIP_API_BASE: "http://localhost:3100",
    OPENCLAW_BIN: "openclaw",
    OPENCLAW_GATEWAY_URL: "ws://127.0.0.1:18789/",
    OPENCLAW_CONFIG_PATH: "/tmp/openclaw.json",
    OPENCLAW_INCLUDE_PATH: "/tmp/foreman.json5",
    FOREMAN_LOG_DIR: "/tmp/foreman-logs",
    stripeMode: "test",
    STRIPE_SECRET_KEY_ACTIVE: "sk_test_placeholder",
    STRIPE_WEBHOOK_SECRET_ACTIVE: "whsec_test_placeholder",
    STRIPE_PRICE_TIER_1_ACTIVE: "price_test_t1",
    STRIPE_PRICE_TIER_2_ACTIVE: "price_test_t2",
    STRIPE_PRICE_TIER_3_ACTIVE: "price_test_t3",
    STRIPE_PRICE_BYOK_PLATFORM_ACTIVE: "price_test_byok",
  },
}));

vi.mock("../config/secrets.js", () => ({
  validateRequiredSecrets: () => [],
  getCredentialStatus: () => ({}),
  getDeferredSecrets: () => [],
}));

vi.mock("../config/logger.js", () => ({
  createLogger: () => ({
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
    debug: vi.fn(),
    child: vi.fn(() => ({
      info: vi.fn(),
      warn: vi.fn(),
      error: vi.fn(),
      debug: vi.fn(),
    })),
  }),
}));

vi.mock("../config/sentry.js", () => ({
  initSentry: vi.fn(),
  captureException: vi.fn(),
}));

vi.mock("../db/email-subscribers.js", () => ({
  upsertSubscriber: upsertSubscriberMock,
}));

import { registerMarketingRoutes } from "./marketing.js";

describe("marketing subscribe route", () => {
  let app: Hono;
  let deps: AppDeps;

  beforeEach(() => {
    vi.clearAllMocks();
    app = new Hono();
    deps = {
      db: {} as never,
      clients: {
        email: { send: vi.fn(async () => {}), enabled: false },
      } as never,
      logger: {
        info: vi.fn(),
        warn: vi.fn(),
        error: vi.fn(),
        debug: vi.fn(),
        child: vi.fn(() => ({
          info: vi.fn(),
          warn: vi.fn(),
          error: vi.fn(),
          debug: vi.fn(),
        })),
      } as never,
      env: { CEO_REVIEW_EMAIL: undefined } as never,
    } as unknown as AppDeps;
    registerMarketingRoutes(app, deps);
  });

  it("returns 400 for invalid JSON", async () => {
    const response = await app.request("/api/marketing/subscribe", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: "not json",
    });
    expect(response.status).toBe(400);
    const body = (await response.json()) as { error: string };
    expect(body.error).toBe("invalid_json");
  });

  it("returns 400 for missing email", async () => {
    const response = await app.request("/api/marketing/subscribe", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ source: "homepage" }),
    });
    expect(response.status).toBe(400);
    const body = (await response.json()) as { error: string };
    expect(body.error).toBe("invalid_input");
  });

  it("returns 400 for invalid email", async () => {
    const response = await app.request("/api/marketing/subscribe", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: "not-an-email", source: "homepage" }),
    });
    expect(response.status).toBe(400);
    const body = (await response.json()) as { error: string };
    expect(body.error).toBe("invalid_input");
  });

  it("returns 200 and created=true for new subscriber", async () => {
    upsertSubscriberMock.mockResolvedValue({
      created: true,
      subscriber: { id: "sub-1", email: "test@example.com" },
    });

    const response = await app.request("/api/marketing/subscribe", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: "test@example.com", source: "homepage" }),
    });
    expect(response.status).toBe(200);
    const body = (await response.json()) as { ok: boolean; created: boolean };
    expect(body.ok).toBe(true);
    expect(body.created).toBe(true);
  });

  it("returns 200 and created=false for existing subscriber", async () => {
    upsertSubscriberMock.mockResolvedValue({
      created: false,
      subscriber: { id: "sub-1", email: "test@example.com" },
    });

    const response = await app.request("/api/marketing/subscribe", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: "test@example.com", source: "blog" }),
    });
    expect(response.status).toBe(200);
    const body = (await response.json()) as { ok: boolean; created: boolean };
    expect(body.ok).toBe(true);
    expect(body.created).toBe(false);
  });

  it("passes optional fields to upsertSubscriber", async () => {
    upsertSubscriberMock.mockResolvedValue({
      created: true,
      subscriber: { id: "sub-2", email: "jane@example.com" },
    });

    await app.request("/api/marketing/subscribe", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email: "jane@example.com",
        name: "Jane",
        company: "Acme",
        useCase: "enterprise",
        message: "Hello",
        source: "contact",
        utmSource: "google",
        utmMedium: "cpc",
        utmCampaign: "launch",
      }),
    });

    expect(upsertSubscriberMock).toHaveBeenCalledWith(
      deps.db,
      expect.objectContaining({
        email: "jane@example.com",
        name: "Jane",
        company: "Acme",
        useCase: "enterprise",
        message: "Hello",
        source: "contact",
        utmSource: "google",
        utmMedium: "cpc",
        utmCampaign: "launch",
      })
    );
  });

  it("returns 500 when upsertSubscriber throws", async () => {
    upsertSubscriberMock.mockRejectedValue(new Error("db error"));

    const response = await app.request("/api/marketing/subscribe", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: "test@example.com", source: "homepage" }),
    });
    expect(response.status).toBe(500);
    const body = (await response.json()) as { error: string };
    expect(body.error).toBe("internal_error");
  });

  it("defaults source to 'other' when not provided", async () => {
    upsertSubscriberMock.mockResolvedValue({
      created: true,
      subscriber: { id: "sub-3", email: "test@example.com" },
    });

    await app.request("/api/marketing/subscribe", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: "test@example.com" }),
    });

    expect(upsertSubscriberMock).toHaveBeenCalledWith(
      deps.db,
      expect.objectContaining({ source: "other" })
    );
  });
});
