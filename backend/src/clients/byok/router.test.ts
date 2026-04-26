import { describe, expect, it, vi, beforeEach } from "vitest";
import { ByokRouter } from "./router.js";
import type { ByokKey } from "../../db/byok-keys.js";
import { createLogger } from "../../config/logger.js";

const { getByokKeyByProviderMock } = vi.hoisted(() => ({
  getByokKeyByProviderMock: vi.fn()
}));

vi.mock("../../db/byok-keys.js", () => ({
  getByokKeyByProvider: getByokKeyByProviderMock
}));

vi.mock("../../crypto/key-encryption.js", () => ({
  KeyEncryption: class {
    encrypt = vi.fn((v: string) => `enc:${v}`)
    decrypt = vi.fn((v: string) => v.replace(/^enc:/, ""))
  }
}));

const ENCRYPTION_KEY = "dGVzdHRlc3R0ZXN0dGVzdHRlc3R0ZXN0MzI=";

const makeByokKey = (overrides: Partial<ByokKey> = {}): ByokKey => ({
  id: "key-1",
  customer_id: "cust-1",
  provider: "openrouter",
  key_encrypted: "sk-or-test-key",
  key_prefix: "sk-o****test",
  label: null,
  is_valid: true,
  last_validated_at: null,
  created_at: new Date().toISOString(),
  updated_at: new Date().toISOString(),
  ...overrides
});

describe("ByokRouter", () => {
  let router: ByokRouter;
  const logger = createLogger("byok-router-test");

  beforeEach(() => {
    vi.clearAllMocks();
    router = new ByokRouter({
      encryptionKey: ENCRYPTION_KEY,
      db: {} as never,
      logger,
      openrouterKey: "or-managed-key"
    });
  });

  describe("resolveApiKey", () => {
    it("returns BYOK key when valid key exists", async () => {
      const key = makeByokKey({ is_valid: true });
      getByokKeyByProviderMock.mockResolvedValue(key);

      const result = await router.resolveApiKey("cust-1", "openrouter");
      expect(result).not.toBeNull();
      expect(result!.isByok).toBe(true);
      expect(result!.apiKey).toBe("sk-or-test-key");
    });

    it("falls back to managed key when BYOK key is invalid", async () => {
      const key = makeByokKey({ is_valid: false });
      getByokKeyByProviderMock.mockResolvedValue(key);

      const result = await router.resolveApiKey("cust-1", "openrouter");
      expect(result).not.toBeNull();
      expect(result!.isByok).toBe(false);
      expect(result!.apiKey).toBe("or-managed-key");
    });

    it("falls back to managed key when no BYOK key exists", async () => {
      getByokKeyByProviderMock.mockResolvedValue(null);

      const result = await router.resolveApiKey("cust-1", "openrouter");
      expect(result).not.toBeNull();
      expect(result!.isByok).toBe(false);
      expect(result!.apiKey).toBe("or-managed-key");
    });

    it("returns null when no BYOK key and no managed key", async () => {
      const noManagedRouter = new ByokRouter({
        encryptionKey: ENCRYPTION_KEY,
        db: {} as never,
        logger: logger as never
      });
      getByokKeyByProviderMock.mockResolvedValue(null);

      const result = await noManagedRouter.resolveApiKey("cust-1", "openrouter");
      expect(result).toBeNull();
    });

    it("falls back to managed key on BYOK decryption error", async () => {
      getByokKeyByProviderMock.mockRejectedValue(new Error("decryption error"));

      const result = await router.resolveApiKey("cust-1", "openrouter");
      expect(result).not.toBeNull();
      expect(result!.isByok).toBe(false);
      expect(result!.apiKey).toBe("or-managed-key");
    });
  });

  describe("decryptKey", () => {
    it("decrypts an encrypted key", () => {
      const key = makeByokKey({ key_encrypted: "enc:my-secret-key" });
      const decrypted = router.decryptKey(key);
      expect(decrypted).toBe("my-secret-key");
    });
  });

  describe("passthroughLlmRequest", () => {
    beforeEach(() => {
      vi.restoreAllMocks();
    });

    it("returns error when no API key available", async () => {
      const noKeyRouter = new ByokRouter({
        encryptionKey: ENCRYPTION_KEY,
        db: {} as never,
        logger: logger as never
      });
      getByokKeyByProviderMock.mockResolvedValue(null);

      const result = await noKeyRouter.passthroughLlmRequest("cust-1", {
        provider: "openrouter",
        model: "openai/gpt-4",
        messages: [{ role: "user", content: "hello" }]
      });

      expect(result.success).toBe(false);
      expect(result.error).toContain("No API key available");
    });

    it("makes successful LLM request with BYOK key", async () => {
      const key = makeByokKey({ is_valid: true, key_encrypted: "enc:sk-or-real-key" });
      getByokKeyByProviderMock.mockResolvedValue(key);

      vi.spyOn(global, "fetch").mockResolvedValueOnce(
        new Response(JSON.stringify({ choices: [] }), { status: 200, headers: { "Content-Type": "application/json" } })
      );

      const result = await router.passthroughLlmRequest("cust-1", {
        provider: "openrouter",
        model: "openai/gpt-4",
        messages: [{ role: "user", content: "hello" }],
        maxTokens: 100,
        temperature: 0.7
      });

      expect(result.success).toBe(true);
      expect(result.usedByok).toBe(true);
    });

    it("makes successful LLM request with managed key fallback", async () => {
      getByokKeyByProviderMock.mockResolvedValue(null);

      vi.spyOn(global, "fetch").mockResolvedValueOnce(
        new Response(JSON.stringify({ choices: [] }), { status: 200, headers: { "Content-Type": "application/json" } })
      );

      const result = await router.passthroughLlmRequest("cust-1", {
        provider: "openrouter",
        model: "openai/gpt-4",
        messages: [{ role: "user", content: "hello" }]
      });

      expect(result.success).toBe(true);
      expect(result.usedByok).toBe(false);
    });

    it("returns error on provider failure", async () => {
      const key = makeByokKey({ is_valid: true, key_encrypted: "enc:sk-or-real-key" });
      getByokKeyByProviderMock.mockResolvedValue(key);

      vi.spyOn(global, "fetch").mockResolvedValueOnce(
        new Response("Rate limited", { status: 429 })
      );

      const result = await router.passthroughLlmRequest("cust-1", {
        provider: "openrouter",
        model: "openai/gpt-4",
        messages: [{ role: "user", content: "hello" }]
      });

      expect(result.success).toBe(false);
      expect(result.error).toContain("429");
    });

    it("returns error on network failure", async () => {
      const key = makeByokKey({ is_valid: true, key_encrypted: "enc:sk-or-real-key" });
      getByokKeyByProviderMock.mockResolvedValue(key);

      vi.spyOn(global, "fetch").mockRejectedValueOnce(new Error("Connection refused"));

      const result = await router.passthroughLlmRequest("cust-1", {
        provider: "openrouter",
        model: "openai/gpt-4",
        messages: [{ role: "user", content: "hello" }]
      });

      expect(result.success).toBe(false);
      expect(result.error).toBe("Connection refused");
    });
  });
});