import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AppDeps } from "../app-deps.js";
import { createLogger } from "../config/logger.js";
import { runByokKeyHealthCheckJob } from "./byok-key-health-check.js";

const {
  listActiveByokCustomersMock,
  setCustomerByokFallbackMock,
  upsertByokFallbackEventMock,
  deleteByokFallbackEventMock,
  markByokFallbackEmailSentMock,
  insertNotificationMock
} = vi.hoisted(() => ({
  listActiveByokCustomersMock: vi.fn(),
  setCustomerByokFallbackMock: vi.fn(),
  upsertByokFallbackEventMock: vi.fn(),
  deleteByokFallbackEventMock: vi.fn(),
  markByokFallbackEmailSentMock: vi.fn(),
  insertNotificationMock: vi.fn()
}));

vi.mock("../db/customers.js", () => ({
  listActiveByokCustomers: listActiveByokCustomersMock,
  setCustomerByokFallback: setCustomerByokFallbackMock,
  upsertByokFallbackEvent: upsertByokFallbackEventMock,
  deleteByokFallbackEvent: deleteByokFallbackEventMock,
  markByokFallbackEmailSent: markByokFallbackEmailSentMock
}));

vi.mock("../db/notifications.js", () => ({
  insertNotification: insertNotificationMock
}));

const makeDeps = (): AppDeps =>
  ({
    db: {} as never,
    logger: createLogger("byok-health-check-test"),
    clients: {} as never,
    env: {} as never
  }) as unknown as AppDeps;

const makeCustomer = (overrides: Record<string, unknown> = {}) => ({
  workspace_slug: "ws-test",
  byok_key_encrypted: "sk-or-test-key",
  byok_fallback_enabled: true,
  byok_using_fallback: false,
  customer_id: "cust-1",
  email: "test@example.com",
  display_name: "Test Customer",
  ...overrides
});

describe("byok_key_health_check job", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    global.fetch = vi.fn();
  });

  it("returns noop when no active BYOK customers", async () => {
    listActiveByokCustomersMock.mockResolvedValue([]);
    const result = await runByokKeyHealthCheckJob(makeDeps());
    expect(result.status).toBe("noop");
  });

  it("activates fallback when key fails and fallback is enabled", async () => {
    listActiveByokCustomersMock.mockResolvedValue([makeCustomer()]);
    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue(new Response(null, { status: 401 }));
    upsertByokFallbackEventMock.mockResolvedValue({
      workspace_slug: "ws-test",
      first_fallback_at: new Date().toISOString(),
      last_fallback_at: new Date().toISOString(),
      last_email_notified_at: null,
      fallback_count: 1
    });
    markByokFallbackEmailSentMock.mockResolvedValue(undefined);
    setCustomerByokFallbackMock.mockResolvedValue(undefined);
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
    listActiveByokCustomersMock.mockResolvedValue([makeCustomer({ byok_using_fallback: true })]);
    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue(
      new Response(JSON.stringify({ data: [] }), { status: 200 })
    );
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

  it("does not activate fallback when key is valid", async () => {
    listActiveByokCustomersMock.mockResolvedValue([makeCustomer()]);
    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue(
      new Response(JSON.stringify({ data: [] }), { status: 200 })
    );

    const result = await runByokKeyHealthCheckJob(makeDeps());
    expect(result.status).toBe("ok");
    expect(setCustomerByokFallbackMock).not.toHaveBeenCalled();
  });

  it("returns error status when db listing fails", async () => {
    listActiveByokCustomersMock.mockRejectedValue(new Error("db connection lost"));
    const result = await runByokKeyHealthCheckJob(makeDeps());
    expect(result.status).toBe("error");
    expect(result.message).toContain("db connection lost");
  });
});
