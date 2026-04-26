import { Hono } from "hono";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AppDeps } from "../app-deps.js";
import { createLogger } from "../config/logger.js";
import { registerComposioRoutes } from "./composio.js";
import { createHmac } from "node:crypto";

const { insertComposioSessionMock } = vi.hoisted(() => ({
  insertComposioSessionMock: vi.fn()
}));

vi.mock("../db/composio.js", () => ({
  insertComposioSession: insertComposioSessionMock,
  insertComposioConnection: vi.fn(),
  insertComposioTrigger: vi.fn(),
  listComposioConnections: vi.fn().mockResolvedValue([]),
  listComposioTriggers: vi.fn().mockResolvedValue([]),
  deleteComposioConnection: vi.fn(),
  deleteComposioTrigger: vi.fn()
}));

const { getComposioTriggerByComposioIdMock } = vi.hoisted(() => ({
  getComposioTriggerByComposioIdMock: vi.fn()
}));

vi.mock("../db/composio-triggers.js", () => ({
  getComposioTriggerByComposioId: getComposioTriggerByComposioIdMock
}));

const {
  insertWebhookEventMock,
  updateWebhookEventStatusMock,
  insertWebhookDeliveryMock,
  updateWebhookDeliveryStatusMock
} = vi.hoisted(() => ({
  insertWebhookEventMock: vi.fn(),
  updateWebhookEventStatusMock: vi.fn(),
  insertWebhookDeliveryMock: vi.fn(),
  updateWebhookDeliveryStatusMock: vi.fn()
}));

vi.mock("../db/webhook-events.js", () => ({
  insertWebhookEvent: insertWebhookEventMock,
  updateWebhookEventStatus: updateWebhookEventStatusMock,
  insertWebhookDelivery: insertWebhookDeliveryMock,
  updateWebhookDeliveryStatus: updateWebhookDeliveryStatusMock,
  getPendingWebhookEvents: vi.fn().mockResolvedValue([])
}));

const { getCustomerByIdMock, insertNotificationMock } = vi.hoisted(() => ({
  getCustomerByIdMock: vi.fn(),
  insertNotificationMock: vi.fn()
}));

vi.mock("../db/customers.js", () => ({
  getCustomerById: getCustomerByIdMock
}));

vi.mock("../db/notifications.js", () => ({
  insertNotification: insertNotificationMock
}));

vi.mock("../auth/session.js", () => ({
  resolveSessionCustomerId: vi.fn().mockResolvedValue("cust_test123")
}));

function makeSignature(payload: string, secret: string): string {
  return createHmac("sha256", secret).update(payload).digest("hex");
}

describe("Composio webhook route", () => {
  const logger = createLogger("composio-webhook-test");
  const webhookSecret = "whsec_test_secret";

  const dispatchMock = vi.fn();
  const verifyMock = vi.fn();

  const fromMock = vi.fn();
  const selectMock = vi.fn();
  const eqMock = vi.fn();
  const maybeSingleMock = vi.fn();

  function setupDbMock() {
    maybeSingleMock.mockResolvedValue({ data: null });
    eqMock.mockReturnValue({ maybeSingle: maybeSingleMock });
    selectMock.mockReturnValue({ eq: eqMock });
    fromMock.mockReturnValue({ select: selectMock });
  }

  const deps = {
    clients: {
      composio: {
        isConfigured: true,
        verifyWebhookSignature: verifyMock,
        createSession: vi.fn(),
        listToolkits: vi.fn(),
        authorizeToolkit: vi.fn(),
        listConnectedAccounts: vi.fn(),
        deleteConnectedAccount: vi.fn(),
        createTrigger: vi.fn(),
        deleteTrigger: vi.fn(),
        ping: vi.fn()
      },
      paperclip: {},
      openclaw: {},
      stripe: {},
      email: {},
      tavily: {}
    },
    webhookDispatcher: { dispatch: dispatchMock } as unknown as AppDeps["webhookDispatcher"],
    db: { from: fromMock } as unknown as AppDeps["db"],
    logger,
    env: {
      NODE_ENV: "test",
      COMPOSIO_WEBHOOK_SECRET: webhookSecret,
      COMPOSIO_API_KEY: "cpk_test",
      COMPOSIO_API_BASE: "https://backend.composio.dev",
      COMPOSIO_USER_ID: "test_user"
    }
  } as unknown as AppDeps;

  const app = new Hono();
  registerComposioRoutes(app, deps);

  beforeEach(() => {
    vi.clearAllMocks();
    setupDbMock();
    verifyMock.mockReturnValue(true);
  });

  describe("POST /api/internal/composio/webhook", () => {
    it("rejects requests with invalid signature when secret is configured", async () => {
      verifyMock.mockReturnValue(false);

      const response = await app.request("/api/internal/composio/webhook", {
        method: "POST",
        headers: { "x-composio-signature": "invalid_signature" },
        body: JSON.stringify({ trigger_id: "trg_1" })
      });

      expect(response.status).toBe(401);
      const body = await response.json();
      expect(body.error).toBe("invalid_signature");
    });

    it("accepts requests without signature when secret is not configured", async () => {
      const depsNoSecret = {
        ...deps,
        env: { ...deps.env, COMPOSIO_WEBHOOK_SECRET: undefined }
      } as unknown as AppDeps;

      const appNoSecret = new Hono();
      registerComposioRoutes(appNoSecret, depsNoSecret);

      dispatchMock.mockResolvedValue({ eventId: "evt_1", delivered: 1, failed: 0 });

      const payload = JSON.stringify({ trigger_id: "trg_1", trigger_type: "github_on_issue_opened" });
      const response = await appNoSecret.request("/api/internal/composio/webhook", {
        method: "POST",
        body: payload
      });

      expect(response.status).toBe(200);
    });

    it("accepts valid webhook and dispatches event", async () => {
      dispatchMock.mockResolvedValue({ eventId: "evt_abc", delivered: 2, failed: 0 });

      const payload = JSON.stringify({
        trigger_id: "trg_123",
        trigger_type: "github_on_issue_opened",
        toolkit: "github",
        payload: { title: "Bug report", body: "Something broke" },
        timestamp: "2026-04-25T12:00:00Z"
      });

      const validSig = makeSignature(payload, webhookSecret);
      verifyMock.mockReturnValue(true);

      const response = await app.request("/api/internal/composio/webhook", {
        method: "POST",
        headers: { "x-composio-signature": validSig },
        body: payload
      });

      expect(response.status).toBe(200);
      const body = await response.json();
      expect(body.ok).toBe(true);
      expect(body.event_id).toBe("evt_abc");
      expect(body.delivered).toBe(2);
      expect(body.failed).toBe(0);

      expect(dispatchMock).toHaveBeenCalledWith(
        expect.objectContaining({
          trigger_id: "trg_123",
          trigger_type: "github_on_issue_opened"
        })
      );
    });

    it("returns 400 for malformed JSON", async () => {
      verifyMock.mockReturnValue(true);

      const response = await app.request("/api/internal/composio/webhook", {
        method: "POST",
        headers: { "x-composio-signature": "any" },
        body: "not valid json {{{"
      });

      expect(response.status).toBe(400);
    });

    it("returns 400 when dispatcher throws", async () => {
      verifyMock.mockReturnValue(true);
      dispatchMock.mockRejectedValue(new Error("db connection failed"));

      const response = await app.request("/api/internal/composio/webhook", {
        method: "POST",
        headers: { "x-composio-signature": "any" },
        body: JSON.stringify({ trigger_id: "trg_1" })
      });

      expect(response.status).toBe(400);
    });
  });
});