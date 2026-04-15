import { createClient } from "@supabase/supabase-js";
import type { Env } from "../config/env.js";

export function createSupabaseClient(env: Env) {
  return createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_KEY, {
    auth: { persistSession: false }
  });
}

export type SupabaseClient = ReturnType<typeof createSupabaseClient>;
