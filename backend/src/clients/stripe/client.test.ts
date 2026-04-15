import { describe, expect, it, vi } from "vitest";
import { createLogger } from "../../config/logger.js";
import { StripeClient } from "./client.js";
import { StripeApiError } from "./errors.js";

describe("StripeClient stub", () => {
  const logger = createLogger("stripe-client-test");

  it("returns canned subscription status", async () => {
    const warnSpy = vi.spyOn(logger, "warn");
    const client = new StripeClient({ logger });
    await expect(client.getSubscriptionStatus("cus_1")).resolves.toBe("active");
    expect(warnSpy).toHaveBeenCalledWith(
      expect.objectContaining({ stub: true }),
      "stripe client running in STUB mode"
    );
  });

  it("returns canned failed payment state", async () => {
    const client = new StripeClient({ logger });
    await expect(client.hasFailedPaymentSince("cus_1", new Date())).resolves.toBe(false);
  });

  it("returns canned prepaid balance", async () => {
    const client = new StripeClient({ logger });
    await expect(client.getPrepaidBalanceCents("cus_1")).resolves.toBe(1_000_000);
  });

  it("throws NotImplemented for write operations", async () => {
    const client = new StripeClient({ logger });

    await expect(client.createSubscription()).rejects.toBeInstanceOf(StripeApiError);
    await expect(client.cancelSubscription()).rejects.toBeInstanceOf(StripeApiError);
    await expect(client.createPaymentIntent()).rejects.toBeInstanceOf(StripeApiError);
  });
});
