import { Hono } from "hono";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AppDeps } from "../app-deps.js";
import { createLogger } from "../config/logger.js";
import { registerByokRoutes } from "./byok.js";

const {
  resolveSessionCustomerIdMock,
  getCustomerByIdMock,
  listByokKeysMock,
  countByokKeysMock,
  getByokKeyByProviderMock,
  getByokKeyByIdMock,
  upsertByokKeyMock,
  deleteByokKeyMock,
  updateByokKeyValidityMock,
  byokKeyToPublicMock,
  validateProviderKeyMock,
  insertNotificationMock
} = vi.hoisted(() => ({
  resolveSessionCustomerIdMock: vi.fn(),
  getCustomerByIdMock: vi.fn(),
  listByokKeysMock: vi.fn(),
  countByokKeysMock: vi.fn(),
  getByokKeyByProviderMock: vi.fn(),
  getByokKeyByIdMock: vi.fn(),
  upsertByokKeyMock: vi.fn(),
  deleteByokKeyMock: vi.fn(),
  updateByokKeyValidityMock: vi.fn(),
  byokKeyToPublicMock: vi.fn(),
  validateProviderKeyMock: vi.fn(),
  insertNotificationMock: vi.fn()
}));

vi.mock("../auth/session.js", () => ({
  resolveSessionCustomerId: resolveSessionCustomerIdMock
}));

vi.mock("../db/customers.js", () => ({
  getCustomerById: getCustomerByIdMock
}));

vi.mock("../db/byok-keys.js", () => ({
  listByokKeys: listByokKeysMock,
  countByokKeys: countByokKeysMock,
  getByokKeyByProvider: getByokKeyByProviderMock,
  getByokKeyById: getByokKeyByIdMock,
  upsertByokKey: upsertByokKeyMock,
  deleteByokKey: deleteByokKeyMock,
  updateByokKeyValidity: updateByokKeyValidityMock,
  byokKeyToPublic: byokKeyToPublicMock
}));

vi.mock("../clients/byok/providers.js", () => ({
  validateProviderKey: validateProviderKeyMock,
  SUPPORTED_PROVIDERS: ["openrouter", "together", "deepinfra", "dashscope", "openai"],
  prefixOf: (key: string) => (key.length <= 8 ? "****" : key.slice(0, 4) + "****" + key.slice(-4))
}));

vi.mock("../db/notifications.js", () => ({
  insertNotification: insertNotificationMock
}));

vi.mock("../crypto/key-encryption.js", () => ({
  KeyEncryption: class {
    constructor() {}
    encrypt = vi.fn((v: string) => `enc:${v}`)
    decrypt = vi.fn((v: string) => v.replace(/^enc:/, ""))
  }
}));

const makeDeps = (): AppDeps =>
  ({
    db: {
      from: vi.fn().mockReturnValue({
        update: vi.fn().mockReturnValue({
          eq: vi.fn().mockResolvedValue({ error: null })
        })
      })
    },
    logger: createLogger("byok-route-test"),
    clients: {} as never,
    env: { BYOK_ENCRYPTION_KEY: "dGVzdHRlc3R0ZXN0dGVzdHRlc3R0ZXN0MzI=" } as never
  }) as unknown as AppDeps;

const makeKey = (overrides: Record<string, unknown> = {}) => ({
  id: "key-1",
  customer_id: "cust-1",
  provider: "openrouter",
  key_encrypted: "enc:sk-or-test-key",
  key_prefix: "sk-o****test",
  label: null,
  is_valid: true,
  last_validated_at: null,
  created_at: new Date().toISOString(),
  updated_at: new Date().toISOString(),
  ...overrides
});

const makePublic = (key: Record<string, unknown>) => ({
  id: key.id,
  provider: key.provider,
  key_prefix: key.key_prefix,
  label: key.label,
  is_valid: key.is_valid,
  last_validated_at: key.last_validated_at,
  created_at: key.created_at,
  updated_at: key.updated_at
});

describe("BYOK route handlers", () => {
  let app: Hono;
  let deps: AppDeps;

  beforeEach(() => {
    vi.clearAllMocks();
    app = new Hono();
    deps = makeDeps();
    registerByokRoutes(app, deps);
  });

  describe("GET /api/internal/byok/keys", () => {
    it("returns 401 when not authenticated", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue(null);
      const res = await app.request("/api/internal/byok/keys");
      expect(res.status).toBe(401);
    });

    it("returns keys for authenticated customer", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");
      const key = makeKey();
      listByokKeysMock.mockResolvedValue([key]);
      byokKeyToPublicMock.mockImplementation((k: Record<string, unknown>) => makePublic(k));

      const res = await app.request("/api/internal/byok/keys");
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.keys).toHaveLength(1);
    });

    it("returns 500 on db error", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");
      listByokKeysMock.mockRejectedValue(new Error("db error"));

      const res = await app.request("/api/internal/byok/keys");
      expect(res.status).toBe(500);
    });
  });

  describe("POST /api/internal/byok/keys", () => {
    it("returns 401 when not authenticated", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue(null);
      const res = await app.request("/api/internal/byok/keys", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ provider: "openrouter", api_key: "sk-or-test" })
      });
      expect(res.status).toBe(401);
    });

    it("returns 503 when BYOK_ENCRYPTION_KEY not configured", async () => {
      const depsNoKey = { ...deps, env: { ...deps.env, BYOK_ENCRYPTION_KEY: undefined } } as unknown as AppDeps;
      const localApp = new Hono();
      registerByokRoutes(localApp, depsNoKey);
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");

      const res = await localApp.request("/api/internal/byok/keys", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ provider: "openrouter", api_key: "sk-or-test" })
      });
      expect(res.status).toBe(503);
    });

    it("returns 422 for invalid input", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");
      const res = await app.request("/api/internal/byok/keys", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ provider: "invalid_provider", api_key: "sk-test" })
      });
      expect(res.status).toBe(422);
    });

    it("returns 404 when customer not found", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");
      getCustomerByIdMock.mockResolvedValue(null);
      validateProviderKeyMock.mockResolvedValue({ valid: true });

      const res = await app.request("/api/internal/byok/keys", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ provider: "openrouter", api_key: "sk-or-test" })
      });
      expect(res.status).toBe(404);
    });

    it("returns 400 when key limit reached for new provider", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");
      getCustomerByIdMock.mockResolvedValue({ customer_id: "cust-1", workspace_slug: "ws-test", current_billing_mode: "foreman_managed_tier" });
      getByokKeyByProviderMock.mockResolvedValue(null);
      countByokKeysMock.mockResolvedValue(10);
      validateProviderKeyMock.mockResolvedValue({ valid: true });

      const res = await app.request("/api/internal/byok/keys", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ provider: "openrouter", api_key: "sk-or-test" })
      });
      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error).toBe("key_limit_reached");
    });

    it("returns 400 when provider key validation fails", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");
      getCustomerByIdMock.mockResolvedValue({ customer_id: "cust-1", workspace_slug: "ws-test", current_billing_mode: "foreman_managed_tier" });
      countByokKeysMock.mockResolvedValue(0);
      getByokKeyByProviderMock.mockResolvedValue(null);
      validateProviderKeyMock.mockResolvedValue({ valid: false, error: "Invalid API key" });

      const res = await app.request("/api/internal/byok/keys", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ provider: "openrouter", api_key: "sk-or-bad" })
      });
      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error).toBe("key_validation_failed");
    });

    it("creates new key successfully (201)", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");
      const customer = { customer_id: "cust-1", workspace_slug: "ws-test", current_billing_mode: "foreman_managed_tier" };
      getCustomerByIdMock.mockResolvedValue(customer);
      countByokKeysMock.mockResolvedValue(0);
      getByokKeyByProviderMock.mockResolvedValue(null);
      validateProviderKeyMock.mockResolvedValue({ valid: true });
      const newKey = makeKey();
      upsertByokKeyMock.mockResolvedValue(newKey);
      byokKeyToPublicMock.mockImplementation((k: Record<string, unknown>) => makePublic(k));

      const res = await app.request("/api/internal/byok/keys", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ provider: "openrouter", api_key: "sk-or-test-key-123" })
      });
      expect(res.status).toBe(201);
      expect(upsertByokKeyMock).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ provider: "openrouter", keyPrefix: "sk-o****-123" })
      );
    });

    it("updates existing key for same provider (200)", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");
      const customer = { customer_id: "cust-1", workspace_slug: "ws-test", current_billing_mode: "byok" };
      getCustomerByIdMock.mockResolvedValue(customer);
      const existingKey = makeKey();
      getByokKeyByProviderMock.mockResolvedValue(existingKey);
      validateProviderKeyMock.mockResolvedValue({ valid: true });
      const updatedKey = makeKey({ key_prefix: "sk-o****new1" });
      upsertByokKeyMock.mockResolvedValue(updatedKey);
      byokKeyToPublicMock.mockImplementation((k: Record<string, unknown>) => makePublic(k));

      const res = await app.request("/api/internal/byok/keys", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ provider: "openrouter", api_key: "sk-or-new-key-1" })
      });
      expect(res.status).toBe(200);
    });
  });

  describe("DELETE /api/internal/byok/keys/:keyId", () => {
    it("returns 401 when not authenticated", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue(null);
      const res = await app.request("/api/internal/byok/keys/key-1", { method: "DELETE" });
      expect(res.status).toBe(401);
    });

    it("returns 404 when key not found", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");
      getByokKeyByIdMock.mockResolvedValue(null);
      const res = await app.request("/api/internal/byok/keys/key-1", { method: "DELETE" });
      expect(res.status).toBe(404);
    });

    it("returns 403 when key belongs to another customer", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");
      getByokKeyByIdMock.mockResolvedValue(makeKey({ customer_id: "cust-2" }));
      const res = await app.request("/api/internal/byok/keys/key-1", { method: "DELETE" });
      expect(res.status).toBe(403);
    });

    it("deletes key and reverts billing when no keys remain", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");
      getByokKeyByIdMock.mockResolvedValue(makeKey({ customer_id: "cust-1" }));
      deleteByokKeyMock.mockResolvedValue(undefined);
      listByokKeysMock.mockResolvedValue([]);

      const res = await app.request("/api/internal/byok/keys/key-1", { method: "DELETE" });
      expect(res.status).toBe(200);
    });

    it("deletes key and keeps billing when other keys exist", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");
      getByokKeyByIdMock.mockResolvedValue(makeKey({ customer_id: "cust-1" }));
      deleteByokKeyMock.mockResolvedValue(undefined);
      listByokKeysMock.mockResolvedValue([makeKey({ id: "key-2" })]);

      const res = await app.request("/api/internal/byok/keys/key-1", { method: "DELETE" });
      expect(res.status).toBe(200);
    });
  });

  describe("POST /api/internal/byok/keys/:keyId/validate", () => {
    it("returns 401 when not authenticated", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue(null);
      const res = await app.request("/api/internal/byok/keys/key-1/validate", { method: "POST" });
      expect(res.status).toBe(401);
    });

    it("returns 503 when BYOK_ENCRYPTION_KEY not configured", async () => {
      const depsNoKey = { ...deps, env: { ...deps.env, BYOK_ENCRYPTION_KEY: undefined } } as unknown as AppDeps;
      const localApp = new Hono();
      registerByokRoutes(localApp, depsNoKey);
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");

      const res = await localApp.request("/api/internal/byok/keys/key-1/validate", { method: "POST" });
      expect(res.status).toBe(503);
    });

    it("returns 404 when key not found", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");
      getByokKeyByIdMock.mockResolvedValue(null);
      const res = await app.request("/api/internal/byok/keys/key-1/validate", { method: "POST" });
      expect(res.status).toBe(404);
    });

    it("returns 403 when key belongs to another customer", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");
      getByokKeyByIdMock.mockResolvedValue(makeKey({ customer_id: "cust-2" }));
      const res = await app.request("/api/internal/byok/keys/key-1/validate", { method: "POST" });
      expect(res.status).toBe(403);
    });

    it("returns valid true when key decrypts and validates", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");
      const key = makeKey({ customer_id: "cust-1" });
      getByokKeyByIdMock.mockResolvedValue(key);
      validateProviderKeyMock.mockResolvedValue({ valid: true });
      updateByokKeyValidityMock.mockResolvedValue({ ...key, is_valid: true, last_validated_at: new Date().toISOString() });

      const res = await app.request("/api/internal/byok/keys/key-1/validate", { method: "POST" });
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.valid).toBe(true);
      expect(updateByokKeyValidityMock).toHaveBeenCalledWith(expect.anything(), "key-1", true);
    });

    it("returns valid false and sends notification when key fails", async () => {
      resolveSessionCustomerIdMock.mockResolvedValue("cust-1");
      const key = makeKey({ customer_id: "cust-1" });
      getByokKeyByIdMock.mockResolvedValue(key);
      validateProviderKeyMock.mockResolvedValue({ valid: false, error: "Invalid API key" });
      updateByokKeyValidityMock.mockResolvedValue({ ...key, is_valid: false });
      getCustomerByIdMock.mockResolvedValue({ customer_id: "cust-1", workspace_slug: "ws-test" });

      const res = await app.request("/api/internal/byok/keys/key-1/validate", { method: "POST" });
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.valid).toBe(false);
      expect(body.error).toBe("Invalid API key");
      expect(insertNotificationMock).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ type: "byok_key_invalid" })
      );
    });
  });
});