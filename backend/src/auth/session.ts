import { deleteCookie, getCookie } from "hono/cookie";
import type { Context } from "hono";
import type { AppDeps } from "../app-deps.js";
import { getSessionByToken } from "../db/sessions.js";

export const SESSION_COOKIE_NAME = "foreman_session";
export const SESSION_TTL_SECONDS = 60 * 60 * 24 * 14;

export async function resolveSessionCustomerId(c: Context, deps: AppDeps): Promise<string | null> {
  const token = getCookie(c, SESSION_COOKIE_NAME);
  if (!token) {
    return null;
  }

  const session = await getSessionByToken(deps.db, token);
  if (!session) {
    deleteCookie(c, SESSION_COOKIE_NAME, {
      path: "/"
    });
    return null;
  }

  return session.customer_id;
}
