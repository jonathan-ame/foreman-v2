import { describe, expect, it, vi, beforeEach } from "vitest";
import { validateProviderKey, prefixOf, SUPPORTED_PROVIDERS } from "./providers.js";

describe("BYOK providers", () => {
  describe("prefixOf", () => {
    it("returns **** for keys 8 chars or less", () => {
      expect(prefixOf("sk-1234")).toBe("****");
    });

    it("returns first4****last4 for longer keys", () => {
      expect(prefixOf("sk-or-longapikey12345678")).toBe("sk-o****5678");
    });
  });

  describe("SUPPORTED_PROVIDERS", () => {
    it("includes all expected providers", () => {
      expect(SUPPORTED_PROVIDERS).toContain("openrouter");
      expect(SUPPORTED_PROVIDERS).toContain("together");
      expect(SUPPORTED_PROVIDERS).toContain("deepinfra");
      expect(SUPPORTED_PROVIDERS).toContain("dashscope");
      expect(SUPPORTED_PROVIDERS).toContain("openai");
      expect(SUPPORTED_PROVIDERS).toHaveLength(5);
    });
  });

  describe("validateProviderKey", () => {
    it("returns invalid for unknown provider", async () => {
      const result = await validateProviderKey("unknown_provider" as never, "any-key");
      expect(result.valid).toBe(false);
      expect(result.error).toContain("Unknown provider");
    });

    describe("openrouter", () => {
      beforeEach(() => {
        vi.restoreAllMocks();
      });

      it("returns valid on 200 response", async () => {
        vi.spyOn(global, "fetch").mockResolvedValueOnce(new Response(null, { status: 200 }));
        const result = await validateProviderKey("openrouter", "sk-or-test");
        expect(result.valid).toBe(true);
      });

      it("returns invalid on 401", async () => {
        vi.spyOn(global, "fetch").mockResolvedValueOnce(new Response(null, { status: 401 }));
        const result = await validateProviderKey("openrouter", "sk-or-bad");
        expect(result.valid).toBe(false);
        expect(result.error).toBe("Invalid API key");
      });

      it("returns invalid on 403", async () => {
        vi.spyOn(global, "fetch").mockResolvedValueOnce(new Response(null, { status: 403 }));
        const result = await validateProviderKey("openrouter", "sk-or-bad");
        expect(result.valid).toBe(false);
        expect(result.error).toBe("Invalid API key");
      });

      it("returns error on unexpected status", async () => {
        vi.spyOn(global, "fetch").mockResolvedValueOnce(new Response(null, { status: 500 }));
        const result = await validateProviderKey("openrouter", "sk-or-test");
        expect(result.valid).toBe(false);
        expect(result.error).toContain("500");
      });

      it("returns error on network failure", async () => {
        vi.spyOn(global, "fetch").mockRejectedValueOnce(new Error("Network timeout"));
        const result = await validateProviderKey("openrouter", "sk-or-test");
        expect(result.valid).toBe(false);
        expect(result.error).toBe("Network timeout");
      });
    });

    describe("together", () => {
      beforeEach(() => {
        vi.restoreAllMocks();
      });

      it("returns valid on 200", async () => {
        vi.spyOn(global, "fetch").mockResolvedValueOnce(new Response(null, { status: 200 }));
        const result = await validateProviderKey("together", "sk-together-test");
        expect(result.valid).toBe(true);
      });

      it("returns invalid on 401", async () => {
        vi.spyOn(global, "fetch").mockResolvedValueOnce(new Response(null, { status: 401 }));
        const result = await validateProviderKey("together", "bad-key");
        expect(result.valid).toBe(false);
      });
    });

    describe("deepinfra", () => {
      beforeEach(() => {
        vi.restoreAllMocks();
      });

      it("returns valid on 200", async () => {
        vi.spyOn(global, "fetch").mockResolvedValueOnce(new Response(null, { status: 200 }));
        const result = await validateProviderKey("deepinfra", "di-test-key");
        expect(result.valid).toBe(true);
      });
    });

    describe("openai", () => {
      beforeEach(() => {
        vi.restoreAllMocks();
      });

      it("returns valid on 200", async () => {
        vi.spyOn(global, "fetch").mockResolvedValueOnce(new Response(null, { status: 200 }));
        const result = await validateProviderKey("openai", "sk-oai-test-key");
        expect(result.valid).toBe(true);
      });
    });

    describe("dashscope", () => {
      beforeEach(() => {
        vi.restoreAllMocks();
      });

      it("returns valid on 200", async () => {
        vi.spyOn(global, "fetch").mockResolvedValueOnce(new Response(null, { status: 200 }));
        const result = await validateProviderKey("dashscope", "ds-test-key");
        expect(result.valid).toBe(true);
      });

      it("returns valid on 400 (bad request but key authenticated)", async () => {
        vi.spyOn(global, "fetch").mockResolvedValueOnce(new Response(null, { status: 400 }));
        const result = await validateProviderKey("dashscope", "ds-test-key");
        expect(result.valid).toBe(true);
      });

      it("returns invalid on 401", async () => {
        vi.spyOn(global, "fetch").mockResolvedValueOnce(new Response(null, { status: 401 }));
        const result = await validateProviderKey("dashscope", "bad-key");
        expect(result.valid).toBe(false);
      });
    });
  });
});