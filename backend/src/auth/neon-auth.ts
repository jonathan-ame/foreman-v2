import type { Env } from "../config/env.js";

export interface AuthUser {
  id: string;
  email: string;
  name: string;
}

export interface AuthResult {
  user: AuthUser;
  token: string;
}

export class AuthClient {
  private baseUrl: string;

  constructor(env: Env) {
    if (!env.NEON_AUTH_URL) {
      throw new Error("NEON_AUTH_URL environment variable is required");
    }
    this.baseUrl = env.NEON_AUTH_URL;
  }

  async signUp(email: string, password: string, name?: string): Promise<AuthResult> {
    const response = await fetch(`${this.baseUrl}/sign-up/email`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password, name: name ?? email.split("@")[0] })
    });
    if (!response.ok) {
      const body = (await response.json().catch(() => ({}))) as { message?: string };
      if (response.status === 409 || response.status === 422) {
        throw new AuthConflictError(body.message ?? "Account already exists");
      }
      throw new AuthError(`Sign-up failed: ${body.message ?? response.statusText}`, response.status);
    }
    return response.json() as Promise<AuthResult>;
  }

  async login(email: string, password: string): Promise<AuthResult> {
    const response = await fetch(`${this.baseUrl}/sign-in/email`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password })
    });
    if (!response.ok) {
      const body = (await response.json().catch(() => ({}))) as { message?: string };
      if (response.status === 401) {
        throw new AuthError("Invalid email or password", 401);
      }
      throw new AuthError(`Login failed: ${body.message ?? response.statusText}`, response.status);
    }
    return response.json() as Promise<AuthResult>;
  }

  async forgotPassword(email: string): Promise<void> {
    const response = await fetch(`${this.baseUrl}/forget-password`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, redirectTo: "/reset-password" })
    });
    if (!response.ok) {
      const body = (await response.json().catch(() => ({}))) as { message?: string };
      throw new AuthError(`Password reset failed: ${body.message ?? response.statusText}`, response.status);
    }
  }

  async resetPassword(token: string, newPassword: string): Promise<void> {
    const response = await fetch(`${this.baseUrl}/reset-password`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ token, newPassword })
    });
    if (!response.ok) {
      const body = (await response.json().catch(() => ({}))) as { message?: string };
      throw new AuthError(`Password reset failed: ${body.message ?? response.statusText}`, response.status);
    }
  }

  async verifyToken(token: string): Promise<AuthUser | null> {
    const response = await fetch(`${this.baseUrl}/session`, {
      method: "GET",
      headers: { Authorization: `Bearer ${token}` }
    });
    if (!response.ok) {
      return null;
    }
    const data = (await response.json()) as { user: AuthUser };
    return data.user;
  }
}

export class AuthError extends Error {
  statusCode: number;

  constructor(message: string, statusCode: number) {
    super(message);
    this.name = "AuthError";
    this.statusCode = statusCode;
  }
}

export class AuthConflictError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AuthConflictError";
  }
}
