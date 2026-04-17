import { describe, expect, it, vi } from "vitest";
import { createLogger } from "../../config/logger.js";
import { safePatchAgent } from "./safe-patch.js";

describe("safePatchAgent", () => {
  it("preserves existing adapter fields when patching headers", async () => {
    const getAgent = vi.fn().mockResolvedValue({
      id: "a1",
      name: "CEO",
      role: "ceo",
      adapterType: "openclaw_gateway",
      companyId: "c1",
      adapterConfig: {
        gatewayUrl: "ws://127.0.0.1:18789/",
        url: "ws://127.0.0.1:18789/",
        headers: {
          "x-openclaw-token": "old-token",
          existing: "value"
        }
      }
    });
    const patchAgent = vi.fn().mockResolvedValue({});

    await safePatchAgent(
      { getAgent, patchAgent } as any,
      "c1",
      "a1",
      {
        adapterConfig: {
          headers: {
            "x-openclaw-token": "new-token"
          }
        }
      },
      createLogger("safe-patch-test")
    );

    expect(patchAgent).toHaveBeenCalledWith(
      "a1",
      expect.objectContaining({
        adapterConfig: expect.objectContaining({
          gatewayUrl: "ws://127.0.0.1:18789/",
          url: "ws://127.0.0.1:18789/",
          headers: expect.objectContaining({
            "x-openclaw-token": "new-token",
            existing: "value"
          })
        })
      })
    );
  });
});

