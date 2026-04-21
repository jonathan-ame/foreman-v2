import { describe, it, expect, beforeEach } from "vitest";

const originalEnv = process.env;

beforeEach(() => {
  process.env = { ...originalEnv };
});

describe("secrets module", () => {
  describe("redactSecret", () => {
    it("should show <empty> for undefined", async () => {
      const { redactSecret } = await import("./secrets.js");
      expect(redactSecret(undefined)).toBe("<empty>");
    });

    it("should show <empty> for empty string", async () => {
      const { redactSecret } = await import("./secrets.js");
      expect(redactSecret("")).toBe("<empty>");
    });

    it("should show length for short values", async () => {
      const { redactSecret } = await import("./secrets.js");
      expect(redactSecret("sk_test_1234")).toBe("<12 chars>");
    });

    it("should redact middle of long values", async () => {
      const { redactSecret } = await import("./secrets.js");
      expect(redactSecret("sk_live_abcdefghijklmnop")).toBe("sk_l***mnop");
    });
  });

  describe("resolveSecret", () => {
    it("should resolve a registered secret from env", async () => {
      process.env.STRIPE_SECRET_KEY = "sk_live_test1234567890";
      const { resolveSecret } = await import("./secrets.js");
      const result = resolveSecret("STRIPE_SECRET_KEY", "test");
      expect(result.resolved).toBe(true);
      expect(result.value).toBe("sk_live_test1234567890");
      expect(result.classification).toBe("restricted");
      expect(result.deferred).toBe(false);
    });

    it("should handle missing secret", async () => {
      delete process.env.RAILWAY_API_KEY;
      const { resolveSecret } = await import("./secrets.js");
      const result = resolveSecret("RAILWAY_API_KEY", "test");
      expect(result.resolved).toBe(false);
      expect(result.value).toBeUndefined();
    });

    it("should handle deferred secret", async () => {
      delete process.env.RESEND_API_KEY;
      const { resolveSecret } = await import("./secrets.js");
      const result = resolveSecret("RESEND_API_KEY", "test");
      expect(result.deferred).toBe(true);
    });

    it("should handle unregistered secret", async () => {
      process.env.UNKNOWN_VAR = "some_value";
      const { resolveSecret } = await import("./secrets.js");
      const result = resolveSecret("UNKNOWN_VAR", "test");
      expect(result.resolved).toBe(true);
      expect(result.classification).toBe("internal");
    });
  });

  describe("getSecretMetadata", () => {
    it("should return metadata for a registered secret", async () => {
      const { getSecretMetadata } = await import("./secrets.js");
      const meta = getSecretMetadata("STRIPE_SECRET_KEY");
      expect(meta).toBeDefined();
      expect(meta!.provider).toBe("stripe");
      expect(meta!.classification).toBe("restricted");
      expect(meta!.required).toBe(true);
    });

    it("should return undefined for unregistered secret", async () => {
      const { getSecretMetadata } = await import("./secrets.js");
      const meta = getSecretMetadata("NONEXISTENT_VAR");
      expect(meta).toBeUndefined();
    });
  });

  describe("validateRequiredSecrets", () => {
    it("should return missing required secrets", async () => {
      delete process.env.STRIPE_SECRET_KEY;
      const { validateRequiredSecrets } = await import("./secrets.js");
      const missing = validateRequiredSecrets();
      const stripeKey = missing.find((m: { key: string }) => m.key === "STRIPE_SECRET_KEY");
      expect(stripeKey).toBeDefined();
    });

    it("should not report deferred secrets as missing", async () => {
      delete process.env.RESEND_API_KEY;
      const { validateRequiredSecrets } = await import("./secrets.js");
      const missing = validateRequiredSecrets();
      const resendKey = missing.find((m: { key: string }) => m.key === "RESEND_API_KEY");
      expect(resendKey).toBeUndefined();
    });
  });

  describe("getDeferredSecrets", () => {
    it("should return deferred secrets with reasons", async () => {
      const { getDeferredSecrets } = await import("./secrets.js");
      const deferred = getDeferredSecrets();
      expect(deferred.length).toBeGreaterThan(0);
      const resend = deferred.find((s: { key: string }) => s.key === "RESEND_API_KEY");
      expect(resend).toBeDefined();
      expect(resend!.meta.deferReason).toContain("FORA-42");
    });
  });

  describe("listSecretsByProvider", () => {
    it("should group secrets by provider", async () => {
      const { listSecretsByProvider } = await import("./secrets.js");
      const grouped = listSecretsByProvider();
      expect(grouped.stripe).toBeDefined();
      expect(grouped.supabase).toBeDefined();
      expect(grouped.cloudflare).toBeDefined();
      expect(grouped.resend).toBeDefined();
    });
  });

  describe("getCredentialStatus", () => {
    it("should return status summary by provider", async () => {
      process.env.STRIPE_SECRET_KEY = "sk_live_test";
      process.env.STRIPE_WEBHOOK_SECRET = "whsec_test";
      const { getCredentialStatus } = await import("./secrets.js");
      const status = getCredentialStatus();
      expect(status.stripe).toBeDefined();
      expect(status.stripe!.total).toBeGreaterThan(0);
    });
  });

  describe("needsRotation", () => {
    it("should return false for secrets with no rotation policy", async () => {
      const { needsRotation } = await import("./secrets.js");
      expect(needsRotation("STRIPE_MODE")).toBe(false);
    });

    it("should return true if lastRotatedAt is not provided", async () => {
      const { needsRotation } = await import("./secrets.js");
      expect(needsRotation("STRIPE_SECRET_KEY")).toBe(true);
    });

    it("should return false if rotated recently", async () => {
      const { needsRotation } = await import("./secrets.js");
      const recentDate = new Date();
      expect(needsRotation("STRIPE_SECRET_KEY", recentDate)).toBe(false);
    });

    it("should return true if rotated too long ago", async () => {
      const { needsRotation } = await import("./secrets.js");
      const oldDate = new Date(Date.now() - 100 * 24 * 60 * 60 * 1000); // 100 days ago
      expect(needsRotation("STRIPE_SECRET_KEY", oldDate)).toBe(true);
    });
  });

  describe("access audit log", () => {
    it("should log secret access events", async () => {
      process.env.STRIPE_SECRET_KEY = "sk_live_test1234567890";
      const { resolveSecret, getAccessLog } = await import("./secrets.js");
      resolveSecret("STRIPE_SECRET_KEY", "test-audit");
      const log = getAccessLog();
      const entry = log.find((e: { key: string; source?: string }) => e.key === "STRIPE_SECRET_KEY" && e.source === "test-audit");
      expect(entry).toBeDefined();
      expect(entry!.timestamp).toBeTruthy();
    });
  });
});
