import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AppDeps } from "../app-deps.js";
import type { ByokKey, ByokProvider } from "../db/byok-keys.js";
import { createLogger } from "../config/logger.js";
import { runByokKeyHealthCheckJob } from "./byok-key-health-check.js";

const {
  listAllValidByokKeysMock,
  updateByokKeyValidityMock,
  listByokKeysMock,
  getCustomerByIdMock,
  setCustomerByokFallbackMock,
  upsertByokFallbackEventMock,
  deleteByokFallbackEventMock,
  markByokFallbackEmailSentMock,
  insertNotificationMock,
  validateProviderKeyMock
} = vi.hoisted(() => ({
  listAllValidByokKeysMock: vi.fn(),
  updateByokKeyValidityMock: vi.fn(),
  listByokKeysMock: vi.fn(),
  getCustomerByIdMock: vi.fn(),
  setCustomerByokFallbackMock: vi.fn(),
  upsertByokFallbackEventMock: vi.fn(),
  deleteByokFallbackEventMock: vi.fn(),
  markByokFallbackEmailSentMock: vi.fn(),
  insertNotificationMock: vi.fn(),
  validateProviderKeyMock: vi.fn()
}));

vi.mock("../db/byok-keys.js", () => ({
  listAllValidByokKeys: listAllValidByokKeysMock,
  updateByokKeyValidity: updateByokKeyValidityMock,
  listByokKeys: listByokKeysMock,
  getByokKeyById: vi.fn(),
  getByokKeyByProvider: vi.fn(),
  upsertByokKey: vi.fn(),
  deleteByokKey: vi.fn(),
  countByokKeys: vi.fn(),
  byokKeyToPublic: vi.fn()
}));

vi.mock("../db/customers.js", () => ({
  listActiveByokCustomers: vi.fn(),
  getCustomerById: getCustomerByIdMock,
  setCustomerByokFallback: setCustomerByokFallbackMock,
  upsertByokFallbackEvent: upsertByokFallbackEventMock,
  deleteByokFallbackEvent: deleteByokFallbackEventMock,
  markByokFallbackEmailSent: markByokFallbackEmailSentMock
}));

vi.mock("../db/notifications.js", () => ({
  insertNotification: insertNotificationMock
}));

vi.mock("../clients/byok/providers.js", () => ({
  validateProviderKey: validateProviderKeyMock,
  SUPPORTED_PROVIDERS: ["openrouter", "together", "deepinfra", "dashscope", "openai"],
  prefixOf: (key: string) => key.length <= 8 ? "****" : key.slice(0, 4) + "****" + key.slice(-4)
}));

vi.mock("../crypto/key-encryption.js", () => ({
  KeyEncryption: class {
    encrypt = vi.fn((v: string) => `enc:${v}`)
    decrypt = vi.fn((v: string) => v.replace(/^enc:/, ""))
  }
}));

const makeFakeKey = (overrides: Partial<ByokKey> = {}): ByokKey => ({
  id: "key-1",
  customer_id: "cust-1",
  provider: "openrouter" as ByokProvider,
  key_encrypted: "fake-encrypted-key",
  key_prefix: "sk-o****test",
  label: null,
  is_valid: true,
  last_validated_at: null,
  created_at: new Date().toISOString(),
  updated_at: new Date().toISOString(),
  ...overrides
});

const makeDeps = (): AppDeps =>
  ({
    db: {} as never,
    logger: createLogger("byok-health-check-test"),
    clients: {} as never,
    env: { BYOK_ENCRYPTION_KEY: "dGVzdHRlc3R0ZXN0dGVzdHRlc3R0ZXN0MzI=" } as never
  }) as unknown as AppDeps;

const makeCustomer = (overrides: Record<string, unknown> = {}) => ({
  customer_id: "cust-1",
  workspace_slug: "ws-test",
  email: "test@example.com",
  display_name: "Test Customer",
  byok_key_encrypted: "sk-or-test-key",
  byok_fallback_enabled: true,
  byok_using_fallback: false,
  current_billing_mode: "byok",
  ...overrides
});

describe("byok_key_health_check job", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("returns noop when no active BYOK keys exist", async () => {
    listAllValidByokKeysMock.mockResolvedValue([]);
    const result = await runByokKeyHealthCheckJob(makeDeps());
    expect(result.status).toBe("noop");
  });

  it("validates keys and marks invalid ones", async () => {
    const key = makeFakeKey();
    listAllValidByokKeysMock.mockResolvedValue([key]);
    getCustomerByIdMock.mockResolvedValue(makeCustomer({ byok_fallback_enabled: false }));
    validateProviderKeyMock.mockResolvedValue({ valid: false, error: "Invalid API key" });
    updateByokKeyValidityMock.mockResolvedValue({ ...key, is_valid: false });
    listByokKeysMock.mockResolvedValue([{ ...key, is_valid: false }]);

    const result = await runByokKeyHealthCheckJob(makeDeps());
    expect(result.status).toBe("ok");
    expect(updateByokKeyValidityMock).toHaveBeenCalledWith(expect.anything(), "key-1", false);
    expect(insertNotificationMock).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ type: "byok_key_invalid" })
    );
  });

  it("validates keys and keeps valid ones", async () => {
    const key = makeFakeKey();
    listAllValidByokKeysMock.mockResolvedValue([key]);
    validateProviderKeyMock.mockResolvedValue({ valid: true });
    updateByokKeyValidityMock.mockResolvedValue(key);

    const result = await runByokKeyHealthCheckJob(makeDeps());
    expect(result.status).toBe("ok");
    expect(updateByokKeyValidityMock).toHaveBeenCalledWith(expect.anything(), "key-1", true);
  });

  it("activates fallback when all customer keys fail", async () => {
    const key = makeFakeKey({ customer_id: "cust-1" });
    listAllValidByokKeysMock.mockResolvedValue([key]);
    validateProviderKeyMock.mockResolvedValue({ valid: false, error: "Invalid API key" });
    updateByokKeyValidityMock.mockResolvedValue({ ...key, is_valid: false });
    getCustomerByIdMock.mockResolvedValue(makeCustomer({ byok_fallback_enabled: true, byok_using_fallback: false }));
    listByokKeysMock.mockResolvedValue([{ ...key, is_valid: false }]);
    setCustomerByokFallbackMock.mockResolvedValue(undefined);
    upsertByokFallbackEventMock.mockResolvedValue({
      workspace_slug: "ws-test",
      first_fallback_at: new Date().toISOString(),
      last_fallback_at: new Date().toISOString(),
      last_email_notified_at: null,
      fallback_count: 1
    });
    markByokFallbackEmailSentMock.mockResolvedValue(undefined);
    insertNotificationMock.mockResolvedValue(undefined);

    const result = await runByokKeyHealthCheckJob(makeDeps());
    expect(result.status).toBe("ok");
    expect(setCustomerByokFallbackMock).toHaveBeenCalledWith(expect.anything(), "ws-test", true);
    expect(insertNotificationMock).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ type: "byok_fallback_started", workspace_slug: "ws-test" })
    );
  });

  it("clears fallback when key recovers", async () => {
    const key = makeFakeKey({ customer_id: "cust-1" });
    listAllValidByokKeysMock.mockResolvedValue([key]);
    validateProviderKeyMock.mockResolvedValue({ valid: true });
    updateByokKeyValidityMock.mockResolvedValue(key);
    getCustomerByIdMock.mockResolvedValue(makeCustomer({ byok_using_fallback: true }));
    listByokKeysMock.mockResolvedValue([key]);
    setCustomerByokFallbackMock.mockResolvedValue(undefined);
    deleteByokFallbackEventMock.mockResolvedValue(undefined);
    insertNotificationMock.mockResolvedValue(undefined);

    const result = await runByokKeyHealthCheckJob(makeDeps());
    expect(result.status).toBe("ok");
    expect(setCustomerByokFallbackMock).toHaveBeenCalledWith(expect.anything(), "ws-test", false);
    expect(insertNotificationMock).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ type: "byok_fallback_stopped" })
    );
  });

  it("returns error status when db listing fails", async () => {
    listAllValidByokKeysMock.mockRejectedValue(new Error("db connection lost"));
    const result = await runByokKeyHealthCheckJob(makeDeps());
    expect(result.status).toBe("error");
    expect(result.message).toContain("db connection lost");
  });
});