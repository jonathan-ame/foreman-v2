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

  async signUp(email: string, password: string, name?: string): Promise