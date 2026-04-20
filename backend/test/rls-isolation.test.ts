/**
 * Two-tenant RLS isolation test.
 *
 * Proves that a Supabase authenticated session for workspace A cannot read
 * rows that belong to workspace B.
 *
 * Prerequisites (run once before this suite):
 *   - Migration 018_rls.sql applied to your Supabase project
 *   - SUPABASE_URL and SUPABASE_ANON_KEY env vars set
 *   - Two test customer rows exist (created with the service key)
 *
 * How it works:
 *   Supabase RLS reads `current_setting('app.workspace_slug', true)` from the
 *   session config. We simulate two separate authenticated sessions by setting
 *   that config variable via `set_config` before each query. In production the
 *   app sets this in the JWT claims or via the `auth.uid()` mapping; here we
 *   set it directly via a raw SQL call to validate the policy logic.
 *
 * This test is skipped when SUPABASE_ANON_KEY is not provided (CI / local dev
 * without a live Supabase project).
 */

import { createClient } from "@supabase/supabase-js";
import { describe, it, expect, beforeAll, afterAll } from "vitest";

const supabaseUrl = process.env.SUPABASE_URL ?? "";
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY ?? "";
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY ?? "";

const SKIP = !supabaseUrl || !supabaseServiceKey || !supabaseAnonKey;
const maybeDescribe = SKIP ? describe.skip : describe;

maybeDescribe("RLS two-tenant isolation", () => {
  const slugA = `test-rls-tenant-a-${Date.now()}`;
  const slugB = `test-rls-tenant-b-${Date.now()}`;
  const emailA = `rls-a-${Date.now()}@example.com`;
  const emailB = `rls-b-${Date.now()}@example.com`;

  const serviceClient = createClient(supabaseUrl, supabaseServiceKey, {
    auth: { persistSession: false }
  });

  // Session client uses anon key but we set app.workspace_slug via set_config
  const sessionClientA = createClient(supabaseUrl, supabaseAnonKey, {
    auth: { persistSession: false }
  });
  const sessionClientB = createClient(supabaseUrl, supabaseAnonKey, {
    auth: { persistSession: false }
  });

  beforeAll(async () => {
    // Insert two customers via service key (bypasses RLS)
    const { error: errA } = await serviceClient.from("customers").insert({
      workspace_slug: slugA,
      email: emailA,
      display_name: "RLS Test Tenant A"
    });
    if (errA) throw new Error(`Setup failed (A): ${errA.message}`);

    const { error: errB } = await serviceClient.from("customers").insert({
      workspace_slug: slugB,
      email: emailB,
      display_name: "RLS Test Tenant B"
    });
    if (errB) throw new Error(`Setup failed (B): ${errB.message}`);

    // Insert a notification for each tenant
    await serviceClient.from("notifications").insert({
      workspace_slug: slugA,
      type: "agent_hired",
      title: "Test notif A",
      body: "body A"
    });
    await serviceClient.from("notifications").insert({
      workspace_slug: slugB,
      type: "agent_hired",
      title: "Test notif B",
      body: "body B"
    });
  });

  afterAll(async () => {
    // Clean up via service key
    await serviceClient.from("notifications").delete().eq("workspace_slug", slugA);
    await serviceClient.from("notifications").delete().eq("workspace_slug", slugB);
    await serviceClient.from("customers").delete().eq("workspace_slug", slugA);
    await serviceClient.from("customers").delete().eq("workspace_slug", slugB);
  });

  const setWorkspaceSlug = async (
    client: ReturnType<typeof createClient>,
    slug: string
  ): Promise<void> => {
    // set_config('app.workspace_slug', slug, true) — true = local (per-transaction)
    await client.rpc("set_config" as never, {
      setting: "app.workspace_slug",
      value: slug,
      is_local: true
    } as never);
  };

  it("tenant A can read its own customers row", async () => {
    await setWorkspaceSlug(sessionClientA, slugA);
    const { data, error } = await sessionClientA
      .from("customers")
      .select("workspace_slug")
      .eq("workspace_slug", slugA);
    expect(error).toBeNull();
    expect(data).toHaveLength(1);
    expect(data![0].workspace_slug).toBe(slugA);
  });

  it("tenant A cannot read tenant B customers row", async () => {
    await setWorkspaceSlug(sessionClientA, slugA);
    const { data, error } = await sessionClientA
      .from("customers")
      .select("workspace_slug")
      .eq("workspace_slug", slugB);
    expect(error).toBeNull();
    // RLS filters to empty — zero rows returned, no error
    expect(data).toHaveLength(0);
  });

  it("tenant B cannot read tenant A notifications", async () => {
    await setWorkspaceSlug(sessionClientB, slugB);
    const { data, error } = await sessionClientB
      .from("notifications")
      .select("workspace_slug")
      .eq("workspace_slug", slugA);
    expect(error).toBeNull();
    expect(data).toHaveLength(0);
  });

  it("tenant B can read its own notifications", async () => {
    await setWorkspaceSlug(sessionClientB, slugB);
    const { data, error } = await sessionClientB
      .from("notifications")
      .select("workspace_slug, title")
      .eq("workspace_slug", slugB);
    expect(error).toBeNull();
    expect(data?.length).toBeGreaterThanOrEqual(1);
    for (const row of data ?? []) {
      expect(row.workspace_slug).toBe(slugB);
    }
  });

  it("service key can read both tenants (bypasses RLS)", async () => {
    const { data: dataA } = await serviceClient
      .from("customers")
      .select("workspace_slug")
      .eq("workspace_slug", slugA);
    const { data: dataB } = await serviceClient
      .from("customers")
      .select("workspace_slug")
      .eq("workspace_slug", slugB);
    expect(dataA).toHaveLength(1);
    expect(dataB).toHaveLength(1);
  });
});
