import type { SupabaseClient } from "./supabase.js";

export type NpsTriggerType = "post_onboarding" | "quarterly";

export interface NpsResponse {
  id: string;
  workspace_slug: string;
  trigger_type: NpsTriggerType;
  score: number | null;
  comment: string | null;
  survey_sent_at: string;
  responded_at: string | null;
  email_sent_at: string | null;
}

export interface NpsSurveyInsert {
  workspace_slug: string;
  trigger_type: NpsTriggerType;
  survey_sent_at: string;
  email_sent_at?: string | null;
}

export async function insertNpsSurvey(
  db: SupabaseClient,
  survey: NpsSurveyInsert
): Promise<NpsResponse> {
  const { data, error } = await db
    .from("nps_responses")
    .insert({
      workspace_slug: survey.workspace_slug,
      trigger_type: survey.trigger_type,
      survey_sent_at: survey.survey_sent_at,
      email_sent_at: survey.email_sent_at ?? null
    })
    .select("*")
    .single();

  if (error) {
    throw new Error(`Failed to insert NPS survey for workspace ${survey.workspace_slug}: ${error.message}`);
  }

  return data as NpsResponse;
}

export async function recordNpsResponse(
  db: SupabaseClient,
  surveyId: string,
  score: number,
  comment: string | null,
  respondedAt: string
): Promise<void> {
  const { error } = await db
    .from("nps_responses")
    .update({ score, comment, responded_at: respondedAt })
    .eq("id", surveyId);

  if (error) {
    throw new Error(`Failed to record NPS response for survey ${surveyId}: ${error.message}`);
  }
}

export interface PendingNpsSurveyCheck {
  workspace_slug: string;
  last_any_survey_at: string | null;
  last_post_onboarding_at: string | null;
}

export async function getWorkspacesAlreadySurveyed(
  db: SupabaseClient
): Promise<Map<string, { lastSurveyAt: string; triggerTypes: Set<string> }>> {
  const { data, error } = await db
    .from("nps_responses")
    .select("workspace_slug, trigger_type, survey_sent_at");

  if (error) {
    throw new Error(`Failed to fetch NPS survey history: ${error.message}`);
  }

  const result = new Map<string, { lastSurveyAt: string; triggerTypes: Set<string> }>();
  for (const row of (data ?? []) as { workspace_slug: string; trigger_type: string; survey_sent_at: string }[]) {
    const existing = result.get(row.workspace_slug);
    if (!existing) {
      result.set(row.workspace_slug, {
        lastSurveyAt: row.survey_sent_at,
        triggerTypes: new Set([row.trigger_type])
      });
    } else {
      if (row.survey_sent_at > existing.lastSurveyAt) {
        existing.lastSurveyAt = row.survey_sent_at;
      }
      existing.triggerTypes.add(row.trigger_type);
    }
  }

  return result;
}

export interface NpsStats {
  response_count: number;
  avg_score: number | null;
  promoters: number;
  passives: number;
  detractors: number;
  nps_score: number | null;
  responses_30d: number;
  responses_90d: number;
  response_rate_30d: number | null;
  response_rate_90d: number | null;
}

export async function getEnhancedNpsStats(db: SupabaseClient): Promise<NpsStats> {
  const since30d = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

  const { data, error } = await db
    .from("nps_responses")
    .select("score, responded_at")
    .not("responded_at", "is", null);

  if (error) {
    throw new Error(`Failed to fetch NPS stats: ${error.message}`);
  }

  const rows = (data ?? []) as { score: number | null; responded_at: string | null }[];
  const scored = rows.filter((r) => r.score !== null);

  if (scored.length === 0) {
    return {
      response_count: 0,
      avg_score: null,
      promoters: 0,
      passives: 0,
      detractors: 0,
      nps_score: null,
      responses_30d: 0
    };
  }

  let sum = 0;
  let promoters = 0;
  let passives = 0;
  let detractors = 0;
  let recent = 0;

  for (const row of scored) {
    const s = row.score as number;
    sum += s;
    if (s >= 9) promoters++;
    else if (s >= 7) passives++;
    else detractors++;
    if (row.responded_at && row.responded_at >= since30d) recent++;
  }

  const total = scored.length;
  const npsScore = Math.round(((promoters - detractors) / total) * 100);

  return {
    response_count: total,
    avg_score: Math.round((sum / total) * 10) / 10,
    promoters,
    passives,
    detractors,
    nps_score: npsScore,
    responses_30d: recent
  };
}
