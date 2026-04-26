import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createLogger } from "../../config/logger.js";
import { TavilyClient } from "./client.js";
import { TavilyApiError, TavilyTimeoutError } from "./errors.js";

const logger = createLogger("tavily-client-test");

describe("TavilyClient", () => {
  const fetchMock = vi.fn<typeof fetch>();
  const baseConfig = { apiKey: "tvly-test-key", logger };

  beforeEach(() => {
    vi.stubGlobal("fetch", fetchMock);
    fetchMock.mockReset();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("isConfigured returns true when apiKey is provided", () => {
    const client = new TavilyClient(baseConfig);
    expect(client.isConfigured).toBe(true);
  });

  it("isConfigured returns false when apiKey is empty", () => {
    const client = new TavilyClient({ apiKey: "", logger });
    expect(client.isConfigured).toBe(false);
  });

  it("search sends POST to Tavily search endpoint", async () => {
    const client = new TavilyClient(baseConfig);
    const mockResponse = {
      query: "test query",
      results: [{ title: "Test", url: "https://example.com", content: "content", score: 0.9 }],
      responseTime: 500
    };

    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify(mockResponse), { status: 200, headers: { "content-type": "application/json" } })
    );

    const result = await client.search({ query: "test query" });
    expect(result.query).toBe("test query");
    expect(result.results).toHaveLength(1);
    expect(fetchMock).toHaveBeenCalledWith(
      "https://api.tavily.com/search",
      expect.objectContaining({ method: "POST" })
    );
  });

  it("extract sends POST to Tavily extract endpoint", async () => {
    const client = new TavilyClient(baseConfig);
    const mockResponse = {
      results: [{ url: "https://example.com", rawContent: "extracted" }],
      responseTime: 300
    };

    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify(mockResponse), { status: 200, headers: { "content-type": "application/json" } })
    );

    const result = await client.extract({ urls: ["https://example.com"] });
    expect(result.results).toHaveLength(1);
    expect(fetchMock).toHaveBeenCalledWith(
      "https://api.tavily.com/extract",
      expect.objectContaining({ method: "POST" })
    );
  });

  it("research returns answer and results", async () => {
    const client = new TavilyClient(baseConfig);
    const mockResponse = {
      query: "test research",
      answer: "This is the answer",
      results: [{ title: "Test", url: "https://example.com", content: "content", score: 0.9 }],
      responseTime: 800
    };

    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify(mockResponse), { status: 200, headers: { "content-type": "application/json" } })
    );

    const result = await client.research({ query: "test research" });
    expect(result.answer).toBe("This is the answer");
    expect(result.results).toHaveLength(1);
  });

  it("throws TavilyApiError when not configured", async () => {
    const client = new TavilyClient({ apiKey: "", logger });
    await expect(client.search({ query: "test" })).rejects.toThrow(TavilyApiError);
  });

  it("retries on 5xx errors", async () => {
    const client = new TavilyClient(baseConfig);

    fetchMock.mockResolvedValueOnce(new Response("Internal Server Error", { status: 500 }));
    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify({ query: "test", results: [], responseTime: 100 }), { status: 200 })
    );

    const result = await client.search({ query: "test" });
    expect(result.results).toHaveLength(0);
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it("throws TavilyApiError on 4xx errors", async () => {
    const client = new TavilyClient(baseConfig);

    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify({ detail: "Unauthorized" }), { status: 401 })
    );

    await expect(client.search({ query: "test" })).rejects.toThrow(TavilyApiError);
  });

  it("ping returns ok: true on success", async () => {
    const client = new TavilyClient(baseConfig);

    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify({ query: "ping", results: [], responseTime: 100 }), { status: 200 })
    );

    const result = await client.ping();
    expect(result.ok).toBe(true);
  });

  it("ping returns ok: false on failure", async () => {
    const client = new TavilyClient({ ...baseConfig, timeoutMs: 500 });

    for (let i = 0; i < 4; i++) {
      fetchMock.mockResolvedValueOnce(new Response("error", { status: 500 }));
    }

    const result = await client.ping();
    expect(result.ok).toBe(false);
  }, 15_000);

  it("sends Authorization header with Bearer token", async () => {
    const client = new TavilyClient(baseConfig);

    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify({ query: "test", results: [], responseTime: 100 }), { status: 200 })
    );

    await client.search({ query: "test" });

    expect(fetchMock).toHaveBeenCalledWith(
      "https://api.tavily.com/search",
      expect.objectContaining({
        headers: expect.objectContaining({ Authorization: "Bearer tvly-test-key" })
      })
    );
  });
});