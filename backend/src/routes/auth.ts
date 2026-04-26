import { randomBytes, randomUUID } from "node:crypto";
import type { Hono } from "hono";
import { deleteCookie, getCookie, setCookie } from "hono/cookie";
import { z } from "zod";
import { AuthClient, AuthConflictError, AuthError } from "../auth/neon-auth.js";
import { SESSION_COOKIE_NAME, SESSION_TTL_SECONDS, resolveSessionCustomerId } from "../auth/session.js";
import type { AppDeps } from "../app-deps.js";
import { getCustomerByEmail, getCustomerById, upsertCustomerFromAuth } from "../db/customers.js";
import { createSession, deleteSessionByToken } from "../db/sessions.js";

const DevLoginSchema = z.object({
  email: z.email()
});

const SignupSchema = z.object({
  email: z.email(),
  password: z.string().min(8),
  name: z.string().min(1).max(100).optional()
});

const LoginSchema = z.object({
  email: z.email(),
  password: z.string().min(1)
});

const ForgotPasswordSchema = z.object({
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
  onboarding_progress: Record<string, string> | null;
}) => ({
  customer_id: customer.customer_id,
  email: customer.email,
  display_name: customer.display_name,
  current_tier: customer.current_tier,
  current_billing_mode: customer.current_billing_mode,
  onboarding_progress: customer.onboarding_progress ?? {},
  onboarding_complete: (customer.onboarding_progress as Record<string, string> | null)?.complete !== undefined
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
  const authClient = new AuthClient(deps.env);

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
      secure: String(deps.env.NODE_ENV) === "production",
      sameSite: "Lax",
      path: "/",
      maxAge: SESSION_TTL_SECONDS
    });

    return c.json({ customer: serializeCustomer(customer) }, 200);
  });

  app.post("/api/internal/auth/signup", async (c) => {
    const body = await c.req.json();
    const parsed = SignupSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 422);
    }

    const { email, password, name } = parsed.data;

    try {
      const authResult = await authClient.signUp(email, password, name);
      const displayName = (name ?? email.split("@")[0]) as string;

      const customer = await upsertCustomerFromAuth(deps.db, {
        authUserId: authResult.user.id,
        email: authResult.user.email,
        displayName: displayName
      });

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
        secure: String(deps.env.NODE_ENV) === "production",
        sameSite: "Lax",
        path: "/",
        maxAge: SESSION_TTL_SECONDS
      });

      return c.json({ customer: serializeCustomer(customer) }, 200);
    } catch (err) {
      if (err instanceof AuthConflictError) {
        return c.json({ error: "email_in_use" }, 409);
      }
      if (err instanceof AuthError) {
        const code = err.statusCode >= 400 && err.statusCode < 500 ? err.statusCode : 500;
        return c.json({ error: err.message }, code as 400);
      }
      deps.logger.error({ err, email }, "signup failed");
      return c.json({ error: "signup_failed" }, 500);
    }
  });

  app.post("/api/internal/auth/login", async (c) => {
    const body = await c.req.json();
    const parsed = LoginSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 422);
    }

    const { email, password } = parsed.data;

    try {
      const authResult = await authClient.login(email, password);

      let customer = await getCustomerByEmail(deps.db, email.toLowerCase());
      if (!customer) {
        customer = await upsertCustomerFromAuth(deps.db, {
          authUserId: authResult.user.id,
          email: authResult.user.email,
          displayName: ((authResult.user as { name?: string }).name ?? email.split("@")[0]) as string
        });
      } else if (!customer.auth_user_id) {
        const { error } = await deps.db
          .from("customers")
          .update({ auth_user_id: authResult.user.id })
          .eq("customer_id", customer.customer_id);
        if (error) {
          deps.logger.error({ err: error, customerId: customer.customer_id }, "failed to link auth_user_id on login");
        }
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
        secure: String(deps.env.NODE_ENV) === "production",
        sameSite: "Lax",
        path: "/",
        maxAge: SESSION_TTL_SECONDS
      });

      return c.json({ customer: serializeCustomer(customer) }, 200);
    } catch (err) {
      if (err instanceof AuthError && err.statusCode === 401) {
        return c.json({ error: "invalid_credentials" }, 401);
      }
      if (err instanceof AuthError) {
        const code = err.statusCode >= 400 && err.statusCode < 500 ? err.statusCode : 500;
        return c.json({ error: err.message }, code as 400);
      }
      deps.logger.error({ err, email }, "login failed");
      return c.json({ error: "login_failed" }, 500);
    }
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

  app.post("/api/internal/auth/forgot-password", async (c) => {
    const body = await c.req.json();
    const parsed = ForgotPasswordSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    try {
      await authClient.forgotPassword(parsed.data.email.toLowerCase());
    } catch {
      // Always return success to avoid leaking account existence
    }

    return c.json({ ok: true }, 200);
  });

  const ResetPasswordSchema = z.object({
    token: z.string().min(1),
    password: z.string().min(8)
  });

  app.post("/api/internal/auth/reset-password", async (c) => {
    const body = await c.req.json();
    const parsed = ResetPasswordSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 422);
    }

    try {
      await authClient.resetPassword(parsed.data.token, parsed.data.password);
      return c.json({ ok: true }, 200);
    } catch (err) {
      if (err instanceof AuthError) {
        const code = err.statusCode >= 400 && err.statusCode < 500 ? err.statusCode : 500;
        return c.json({ error: err.message }, code as 400);
      }
      deps.logger.error({ err }, "password reset failed");
      return c.json({ error: "reset_failed" }, 500);
    }
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

  const OAuthProviders = ["google", "linkedin"] as const;
  type OAuthProvider = (typeof OAuthProviders)[number];

  app.get("/api/auth/:provider", async (c) => {
    const provider = c.req.param("provider") as string;
    if (!OAuthProviders.includes(provider as OAuthProvider)) {
      return c.json({ error: "unsupported_provider" }, 400);
    }

    const baseUrl = deps.env.FOREMAN_BASE_URL || "https://foreman.company";
    const callbackUrl = `${baseUrl}/api/auth/${provider}/callback`;
    const authUrl = `${deps.env.NEON_AUTH_URL}/sign-in/social?provider=${provider}&redirectTo=${encodeURIComponent(callbackUrl)}`;
    return c.redirect(authUrl);
  });

  app.get("/api/auth/:provider/callback", async (c) => {
    const token = c.req.query("token");
    if (!token) {
      return c.redirect("/app?auth=error");
    }

    try {
      const authUser = await authClient.verifyToken(token);
      if (!authUser) {
        return c.redirect("/app?auth=error");
      }

      const customer = await upsertCustomerFromAuth(deps.db, {
        authUserId: authUser.id,
        email: authUser.email,
        displayName: authUser.name ?? authUser.email.split("@")[0]
      });

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
        secure: String(deps.env.NODE_ENV) === "production",
        sameSite: "Lax",
        path: "/",
        maxAge: SESSION_TTL_SECONDS
      });

      return c.redirect("/app?auth=success");
    } catch (err) {
      deps.logger.error({ err }, "OAuth callback failed");
      return c.redirect("/app?auth=error");
    }
  });
}