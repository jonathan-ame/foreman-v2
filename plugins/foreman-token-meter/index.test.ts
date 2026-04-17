import { describe, expect, it } from "vitest";
import { calculateCostUsd, resolveModelCostRates } from "./pricing.js";

describe("foreman-token-meter pricing", () => {
  it("resolves model cost rates from provider config", () => {
    const rates = resolveModelCostRates(
      {
        models: {
          providers: {
            openrouter: {
              models: [
                {
                  id: "deepseek/deepseek-chat-v3.1",
                  cost: { input: 0.15, output: 0.75, cacheRead: 0, cacheWrite: 0 }
                }
              ]
            }
          }
        }
      },
      "openrouter",
      "openrouter/deepseek/deepseek-chat-v3.1"
    );

    expect(rates).toEqual({
      input: 0.15,
      output: 0.75,
      cacheRead: 0,
      cacheWrite: 0
    });
  });

  it("computes usd cost from token usage", () => {
    const costUsd = calculateCostUsd(
      {
        input: 100_000,
        output: 10_000,
        cacheRead: 0,
        cacheWrite: 0
      },
      {
        input: 0.15,
        output: 0.75,
        cacheRead: 0,
        cacheWrite: 0
      }
    );

    expect(costUsd).toBeCloseTo(0.0225, 8);
  });
});
