import crypto from "node:crypto";
import type { SupabaseClient } from "./supabase.js";

export type UseCase = "solopreneur" | "small_team" | "enterprise" | "technical" | "other";
export type SubscriberSource = "homepage" | "blog" | "contact" | "other";

export interface SubscriberStats {
  new_1d: number;
  new_7d: number;
  new_30d: number;
  total_active: number;
  by_source_7d: Array<{ source: string; count: number }>;
}

export async function getSubscriberStats(db: SupabaseClient): Promise<SubscriberStats> {
  const now = new Date();
  const since1d = new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString();
  const since7d = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();
  const since30d = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString();

  const { data, error } = await db
    .from("email_subscribers")
    .select("source, subscribed_at, unsubscribed_at")
    .gte("subscribed_at", since30d);

  if (error) {
    throw new Error(`Failed to fetch subscriber stats: ${error.message}`);
  }

  const rows = (data ?? []) as {
    source: string;
    subscribed_at: string;
    unsubscribed_at: string | null;
  }[];

  let new1d = 0;
  let new7d = 0;
  let new30d = 0;
  let totalActive = 0;
  const sourceCounts7d = new Map<string, number>();

  const { count: activeCount } = await db
    .from("email_subscribers")
    .select("*", { head: true, count: "exact" })
    .is("unsubscribed_at", null);

  totalActive = activeCount ?? 0;

  for (const row of rows) {
    if (!row.unsubscribed_at) {
      new30d++;
      if (row.subscribed_at >= since7d) {
        new7d++;
        const src = row.source ?? "other";
        sourceCounts7d.set(src, (sourceCounts7d.get(src) ?? 0) + 1);
      }
      if (row.subscribed_at >= since1d) {
        new1d++;
      }
    }
  }

  const bySource7d = Array.from(sourceCounts7d.entries())
    .sort((a, b) => b[1] - a[1])
    .map(([source, count]) => ({ source, count }));

  return {
    new_1d: new1d,
    new_7d: new7d,
    new_30d: new30d,
    total_active: totalActive,
    by_source_7d: bySource7d,
  };
}

export interface EmailSubscriber {
  id: string;
  email: string;
  name: string | null;
  company: string | null;
  use_case: UseCase | null;
  company_size: string | null;
  message: string | null;
  source: SubscriberSource;
  utm_source: string | null;
  utm_medium: string | null;
  utm_campaign: string | null;
  subscribed_at: string;
  unsubscribed_at: string | null;
  preferences: Record<string, boolean> | null;
  unsubscribe_token: string | null;
}

export interface SubscribeInput {
  email: string;
  name?: string;
  company?: string;
  useCase?: UseCase;
  companySize?: string;
  message?: string;
  source: SubscriberSource;
  utmSource?: string;
  utmMedium?: string;
  utmCampaign?: string;
}

export async function upsertSubscriber(
  db: SupabaseClient,
  input: SubscribeInput
): Promise<{ created: boolean; subscriber: EmailSubscriber }> {
  const row = {
    email: input.email,
    name: input.name ?? null,
    company: input.company ?? null,
    use_case: input.useCase ?? null,
    company_size: input.companySize ?? null,
    message: input.message ?? null,
    source: input.source,
    utm_source: input.utmSource ?? null,
    utm_medium: input.utmMedium ?? null,
    utm_campaign: input.utmCampaign ?? null,
    unsubscribe_token: crypto.randomUUID(),
  };

  const { data: existing } = await db
    .from("email_subscribers")
    .select("id, unsubscribed_at")
    .eq("email", input.email)
    .maybeSingle();

  if (existing) {
    const updates: Record<string, unknown> = { ...row };
    if ((existing as { unsubscribed_at: string | null }).unsubscribed_at) {
      updates.unsubscribed_at = null;
    }
    const { data, error } = await db
      .from("email_subscribers")
      .update(updates)
      .eq("id", (existing as { id: string }).id)
      .select("*")
      .single();

    if (error) {
      throw new Error(`Failed to update subscriber ${input.email}: ${error.message}`);
    }
    return { created: false, subscriber: data as EmailSubscriber };
  }

  const { data, error } = await db
    .from("email_subscribers")
    .insert(row)
    .select("*")
    .single();

  if (error) {
    throw new Error(`Failed to insert subscriber ${input.email}: ${error.message}`);
  }
  return { created: true, subscriber: data as EmailSubscriber };
}
