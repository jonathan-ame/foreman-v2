import { randomBytes, randomUUID } from "node:crypto";
import type { Hono } from "hono";
import { deleteCookie, getCookie, setCookie } from "hono/cookie";
import { z } from "zod";
import { SESSION_COOKIE_NAME, SESSION_TTL_SECONDS, resolveSessionCustomerId } from "../auth/session.js";
import type { AppDeps } from "../app-deps.js";
import { getCustomerByEmail, getCustomerById } from "../db/customers.js";
import { createSession, deleteSessionByToken } from "../db/sessions.js";

const DevLoginSchema = z.object({
  email: z.email()
});

const OpenRouterKeySchema = z.object({
  api_key: z.string().min(1)
});

const serializeCustomer = (customer: {
  customer_id: string;
  email: string;
  display_name: string;
  current_tier: string | null;
  current_billing_mode: string;
}) => ({
  customer_id: customer.customer_id,
  email: customer.email,
  display_name: customer.display_name,
  current_tier: customer.current_tier,
  current_billing_mode: customer.current_billing_mode
});

async function validateOpenRouterKey(apiKey: string): Promise<{ valid: boolean; reason?: string }> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 8_000);
  try {
    const response = await fetch("https://openrouter.ai/api/v1/auth/key", {
      method: "GET",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        Accept: "application/json"
      },
      signal: controller.signal
    });

    if (response.ok) {
      return { valid: true };
    }

    let reason = "OpenRouter rejected the key";
    try {
      const body = (await response.json()) as { error?: { message?: string } };
      if (body.error?.message) {
        reason = body.error.message;
      }
    } catch {
      // Ignore parse failures and keep generic reason.
    }

    return { valid: false, reason };
  } catch (error) {
    if (error instanceof Error && error.name === "AbortError") {
      return { valid: false, reason: "OpenRouter validation timed out" };
    }
    return { valid: false, reason: "OpenRouter validation failed due to a network error" };
  } finally {
    clearTimeout(timeout);
  }
}

export function registerAuthRoutes(app: Hono, deps: AppDeps) {
  app.post("/api/internal/auth/dev-login", async (c) => {
    if (deps.env.NODE_ENV === "production") {
      return c.json({ error: "not_found" }, 404);
    }

    const body = await c.req.json();
    const parsed = DevLoginSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    const customer = await getCustomerByEmail(deps.db, parsed.data.email.toLowerCase());
    if (!customer) {
      return c.json({ error: "customer_not_found" }, 404);
    }

    const sessionToken = randomBytes(32).toString("hex");
    const expiresAt = new Date(Date.now() + SESSION_TTL_SECONDS * 1_000).toISOString();
    await createSession(deps.db, {
      sessionId: randomUUID(),
      customerId: customer.customer_id,
      token: sessionToken,
      expiresAt
    });

    setCookie(c, SESSION_COOKIE_NAME, sessionToken, {
      httpOnly: true,
      secure: false,
      sameSite: "Lax",
      path: "/",
      maxAge: SESSION_TTL_SECONDS
    });

    return c.json({ customer: serializeCustomer(customer) }, 200);
  });

  app.get("/api/internal/auth/me", async (c) => {
    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    if (!sessionCustomerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const customer = await getCustomerById(deps.db, sessionCustomerId);
    if (!customer) {
      return c.json({ error: "customer_not_found" }, 404);
    }

    return c.json({ customer: serializeCustomer(customer) }, 200);
  });

  app.post("/api/internal/auth/logout", async (c) => {
    const token = getCookie(c, SESSION_COOKIE_NAME);
    if (token) {
      await deleteSessionByToken(deps.db, token);
      deleteCookie(c, SESSION_COOKIE_NAME, {
        path: "/"
      });
    }
    return c.json({ ok: true }, 200);
  });

  app.post("/api/internal/openrouter/validate-key", async (c) => {
    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    if (!sessionCustomerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const body = await c.req.json();
    const parsed = OpenRouterKeySchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    const result = await validateOpenRouterKey(parsed.data.api_key);
    return c.json(result, 200);
  });
}
