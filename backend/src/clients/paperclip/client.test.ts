import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createLogger } from "../../config/logger.js";
import { PaperclipClient } from "./client.js";
import {
  PaperclipApiError,
  PaperclipAuthError,
  PaperclipNotFoundError,
  PaperclipTimeoutError
} from "./errors.js";
import type { PaperclipAgent } from "./types.js";

const logger = createLogger("paperclip-client-test");

describe("PaperclipClient", () => {
  const fetchMock = vi.fn<typeof fetch>();
  const baseConfig = {
    apiBase: "http://paperclip.local",
    apiKey: "token",
    runId: "run-123",
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

  it("hireAgent posts to native company hire endpoint", async () => {
    const client = new PaperclipClient(baseConfig);
    const agent: PaperclipAgent = {
      id: "a1",
      name: "CEO",
      role: "ceo",
      adapterType: "openclaw_gateway",
      adapterConfig: {
        gatewayUrl: "ws://localhost:18789",
        headers: { "x-openclaw-token": "abc" }
      },
      companyId: "c1"
    };

    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify({ agent }), { status: 200, headers: { "content-type": "application/json" } })
    );

    const response = await client.hireAgent("c1", {
      name: "CEO",
      role: "ceo",
      reportsTo: "board",
      capabilities: "execute",
      budgetMonthlyCents: 100000,
      adapterType: "openclaw_gateway",
      adapterConfig: {
        gatewayUrl: "ws://localhost:18789",
        headers: { "x-openclaw-token": "abc" }
      }
    });

    expect(response.agent.id).toBe("a1");
    expect(fetchMock).toHaveBeenCalledWith(
      "http://paperclip.local/api/companies/c1/agent-hires",
      expect.objectContaining({
        method: "POST",
        headers: expect.objectContaining({
          Authorization: "Bearer token",
          "X-Paperclip-Run-Id": "run-123"
        })
      })
    );
  });

  it("supports get, patch, delete, and approval operations", async () => {
    const client = new PaperclipClient(baseConfig);

    fetchMock
      .mockResolvedValueOnce(new Response(JSON.stringify({ id: "a1" }), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ id: "a1", name: "updated" }), { status: 200 }))
      .mockResolvedValueOnce(new Response(null, { status: 204 }))
      .mockResolvedValueOnce(new Response(JSON.stringify([{ id: "ap1", type: "hire_agent", status: "pending" }]), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ id: "ap1", type: "hire_agent", status: "pending" }), { status: 200 }))
      .mockResolvedValueOnce(new Response(null, { status: 204 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ version: "1.2.3" }), { status: 200 }));

    const agent = await client.getAgent("a1");
    expect(agent.id).toBe("a1");

    const updated = await client.patchAgent("a1", { name: "updated" } as Partial<PaperclipAgent>);
    expect(updated.name).toBe("updated");

    await expect(client.deleteAgent("a1")).resolves.toBeUndefined();

    const approvals = await client.listPendingApprovals("c1");
    expect(approvals).toHaveLength(1);

    const approval = await client.getApproval("ap1");
    expect(approval.id).toBe("ap1");

    await expect(client.actOnApproval("ap1", "approve")).resolves.toBeUndefined();

    const ping = await client.ping();
    expect(ping).toEqual({ ok: true, version: "1.2.3" });

    const [getAgentCall, patchAgentCall] = fetchMock.mock.calls;
    expect(getAgentCall?.[1]).toEqual(
      expect.objectContaining({
        headers: expect.not.objectContaining({
          "X-Paperclip-Run-Id": expect.anything()
        })
      })
    );
    expect(patchAgentCall?.[1]).toEqual(
      expect.objectContaining({
        headers: expect.objectContaining({
          "X-Paperclip-Run-Id": "run-123"
        })
      })
    );
  });

  it("maps 401 to PaperclipAuthError", async () => {
    const client = new PaperclipClient(baseConfig);
    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify({ message: "bad token" }), { status: 401 })
    );

    await expect(client.getAgent("a1")).rejects.toBeInstanceOf(PaperclipAuthError);
  });

  it("maps 404 to PaperclipNotFoundError", async () => {
    const client = new PaperclipClient(baseConfig);
    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify({ message: "missing" }), { status: 404 })
    );

    await expect(client.getAgent("a1")).rejects.toBeInstanceOf(PaperclipNotFoundError);
  });

  it("retries on 5xx and succeeds on later attempt", async () => {
    vi.useFakeTimers();
    const client = new PaperclipClient(baseConfig);
    fetchMock
      .mockResolvedValueOnce(new Response(JSON.stringify({ message: "server err" }), { status: 500 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ message: "still bad" }), { status: 500 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ id: "a1" }), { status: 200 }));

    const promise = client.getAgent("a1");
    await vi.advanceTimersByTimeAsync(3_000);
    const result = await promise;

    expect(result.id).toBe("a1");
    expect(fetchMock).toHaveBeenCalledTimes(3);
  });

  it("throws timeout error when request exceeds timeout", async () => {
    vi.useFakeTimers();
    const client = new PaperclipClient({
      ...baseConfig,
      timeoutMs: 10
    });
    fetchMock.mockImplementation((_input, init) => {
      const signal = init?.signal;
      return new Promise((_resolve, reject) => {
        signal?.addEventListener("abort", () => {
          reject(new DOMException("Aborted", "AbortError"));
        });
      });
    });

    const promise = expect(client.getAgent("a1")).rejects.toBeInstanceOf(PaperclipTimeoutError);
    await vi.advanceTimersByTimeAsync(15);
    await promise;
  });

  it("exhausts retries and throws PaperclipApiError", async () => {
    vi.useFakeTimers();
    const client = new PaperclipClient(baseConfig);
    fetchMock.mockImplementation(() =>
      Promise.resolve(new Response(JSON.stringify({ message: "fatal" }), { status: 500 }))
    );

    const promise = expect(client.getAgent("a1")).rejects.toBeInstanceOf(PaperclipApiError);
    await vi.advanceTimersByTimeAsync(7_100);
    await promise;
    expect(fetchMock).toHaveBeenCalledTimes(4);
  });
});
