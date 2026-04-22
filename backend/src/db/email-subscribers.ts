import type { SupabaseClient } from "./supabase.js";

export type UseCase = "solopreneur" | "small_team" | "enterprise" | "technical" | "other";
export type SubscriberSource = "homepage" | "blog" | "contact" | "other";

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
