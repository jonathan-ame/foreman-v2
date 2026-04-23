import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createLogger } from "../../config/logger.js";
import { ComposioClient } from "./client.js";
import {
  ComposioApiError,
  ComposioAuthError,
  ComposioNotFoundError
} from "./errors.js";

const logger = createLogger("composio-client-test");

describe("ComposioClient", () => {
  const fetchMock = vi.fn<typeof fetch>();
  const baseConfig = {
    apiBase: "https://backend.composio.dev",
    apiKey: "cpk_test_key",
    logger
  };

  beforeEach(() => {
    vi.stubGlobal("fetch", fetchMock);
    fetchMock.mockReset();
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it("reports isConfigured when apiKey is set", () => {
    const client = new ComposioClient(baseConfig);
    expect(client.isConfigured).toBe(true);
  });

  it("reports not isConfigured when apiKey is empty", () => {
    const client = new ComposioClient({ ...baseConfig, apiKey: "" });
    expect(client.isConfigured).toBe(false);
  });

  it("createSession posts to /v3/sessions", async () => {
    const client = new ComposioClient(baseConfig);
    const sessionResponse = {
      id: "sess_abc",
      userId: "foreman_cust123",
      mcp: { url: "https://mcp.composio.dev/sess_abc", headers: { Authorization: "Bearer tok" } },
      toolkits: [],
      createdAt: "2026-04-22T00:00:00Z"
    };

    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify(sessionResponse), { status: 200, headers: { "content-type": "application/json" } })
    );

    const result = await client.createSession("foreman_cust123");
    expect(result.id).toBe("sess_abc");
    expect(result.mcp.url).toBe("https://mcp.composio.dev/sess_abc");
    expect(fetchMock).toHaveBeenCalledWith(
      "https://backend.composio.dev/api/v3/sessions",
      expect.objectContaining({
        method: "POST",
        headers: expect.objectContaining({
          "x-api-key": "cpk_test_key"
        })
      })
    );
  });

  it("createSession passes toolkits when provided", async () => {
    const client = new ComposioClient(baseConfig);
    const sessionResponse = {
      id: "sess_def",
      userId: "foreman_cust456",
      mcp: { url: "https://mcp.composio.dev/sess_def", headers: {} },
      toolkits: ["github", "slack"],
      createdAt: "2026-04-22T00:00:00Z"
    };

    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify(sessionResponse), { status: 200 })
    );

    await client.createSession("foreman_cust456", { toolkits: ["github", "slack"] });

    const callBody = JSON.parse((fetchMock.mock.calls[0]?.[1] as RequestInit)?.body as string);
    expect(callBody.toolkits).toEqual(["github", "slack"]);
  });

  it("authorizeToolkit posts to /v3/connections/authorize", async () => {
    const client = new ComposioClient(baseConfig);
    const authResponse = {
      connectUrl: "https://connect.composio.dev/link/ln_abc",
      connectedAccountId: "ca_123"
    };

    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify(authResponse), { status: 200 })
    );

    const result = await client.authorizeToolkit("foreman_cust123", "github", "https://app.foreman.company/integrations/callback");
    expect(result.connectUrl).toBe("https://connect.composio.dev/link/ln_abc");

    const callBody = JSON.parse((fetchMock.mock.calls[0]?.[1] as RequestInit)?.body as string);
    expect(callBody.user_id).toBe("foreman_cust123");
    expect(callBody.toolkit).toBe("github");
    expect(callBody.redirect_url).toBe("https://app.foreman.company/integrations/callback");
  });

  it("listToolkits returns toolkit array", async () => {
    const client = new ComposioClient(baseConfig);
    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify({ toolkits: [{ slug: "github", name: "GitHub" }] }), { status: 200 })
    );

    const toolkits = await client.listToolkits();
    expect(toolkits).toHaveLength(1);
    expect(toolkits[0]?.slug).toBe("github");
  });

  it("listConnectedAccounts returns connections array", async () => {
    const client = new ComposioClient(baseConfig);
    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify({ connections: [{ id: "ca_1", toolkitSlug: "github" }] }), { status: 200 })
    );

    const connections = await client.listConnectedAccounts("foreman_cust123");
    expect(connections).toHaveLength(1);
  });

  it("maps 401 to ComposioAuthError", async () => {
    const client = new ComposioClient(baseConfig);
    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify({ message: "bad token" }), { status: 401 })
    );

    await expect(client.listToolkits()).rejects.toBeInstanceOf(ComposioAuthError);
  });

  it("maps 404 to ComposioNotFoundError", async () => {
    const client = new ComposioClient(baseConfig);
    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify({ message: "not found" }), { status: 404 })
    );

    await expect(client.getSession("missing")).rejects.toBeInstanceOf(ComposioNotFoundError);
  });

  it("retries on 5xx and succeeds on later attempt", async () => {
    vi.useFakeTimers();
    const client = new ComposioClient(baseConfig);
    fetchMock
      .mockResolvedValueOnce(new Response(JSON.stringify({ message: "server err" }), { status: 500 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ toolkits: [] }), { status: 200 }));

    const promise = client.listToolkits();
    await vi.advanceTimersByTimeAsync(2_000);
    const result = await promise;

    expect(result).toEqual([]);
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it("ping returns ok: false on failure", async () => {
    const client = new ComposioClient(baseConfig);
    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify({ message: "error" }), { status: 500 })
    );

    const result = await client.ping();
    expect(result).toEqual({ ok: false });
  });

  it("deleteConnectedAccount sends DELETE request", async () => {
    const client = new ComposioClient(baseConfig);
    fetchMock.mockResolvedValueOnce(new Response(null, { status: 204 }));

    await client.deleteConnectedAccount("ca_123");
    expect(fetchMock).toHaveBeenCalledWith(
      "https://backend.composio.dev/api/v3/connections/ca_123",
      expect.objectContaining({ method: "DELETE" })
    );
  });

  it("createTrigger posts to /v3/triggers", async () => {
    const client = new ComposioClient(baseConfig);
    const triggerResponse = {
      id: "trg_abc",
      triggerType: "GITHUB_COMMIT_EVENT",
      toolkitSlug: "github",
      status: "active",
      config: { owner: "composio", repo: "sdk" },
      createdAt: "2026-04-22T00:00:00Z",
      updatedAt: "2026-04-22T00:00:00Z"
    };

    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify(triggerResponse), { status: 200 })
    );

    const result = await client.createTrigger("foreman_cust123", {
      triggerType: "GITHUB_COMMIT_EVENT",
      toolkitSlug: "github",
      config: { owner: "composio", repo: "sdk" }
    });

    expect(result.id).toBe("trg_abc");
    expect(fetchMock).toHaveBeenCalledWith(
      "https://backend.composio.dev/api/v3/triggers",
      expect.objectContaining({ method: "POST" })
    );
  });

  describe("verifyWebhookSignature", () => {
    it("rejects when secret is empty", () => {
      const client = new ComposioClient(baseConfig);
      expect(client.verifyWebhookSignature("payload", "sig", "")).toBe(false);
    });

    it("rejects mismatched signatures", () => {
      const client = new ComposioClient(baseConfig);
      expect(client.verifyWebhookSignature("payload", "badsig", "secret")).toBe(false);
    });

    it("accepts valid HMAC signatures", () => {
      const client = new ComposioClient(baseConfig);
      const crypto = require("node:crypto");
      const validSig = crypto.createHmac("sha256", "secret").update("payload").digest("hex");
      expect(client.verifyWebhookSignature("payload", validSig, "secret")).toBe(true);
    });
  });
});
