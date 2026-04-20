import { getWorkspacesAlreadySurveyed, insertNpsSurvey } from "../db/nps.js";
import type { AppDeps } from "../app-deps.js";
import type { JobResult } from "./types.js";

const POST_ONBOARDING_DELAY_DAYS = 7;
const QUARTERLY_MIN_GAP_DAYS = 90;

interface FunnelEventRow {
  workspace_slug: string;
  occurred_at: string;
}

interface CustomerRow {
  workspace_slug: string;
  email: string;
  display_name: string;
}

function buildNpsEmailHtml(
  displayName: string,
  surveyId: string,
  baseUrl: string
): string {
  return `
<div style="font-family: sans-serif; max-width: 560px; margin: 0 auto; padding: 24px;">
  <h2 style="font-size: 20px; color: #111;">How's Foreman working for you, ${displayName}?</h2>
  <p style="color: #444; line-height: 1.6;">
    On a scale from 0 to 10, how likely are you to recommend Foreman to a friend or colleague?
  </p>
  <div style="display: flex; gap: 8px; margin: 24px 0; flex-wrap: wrap;">
    ${Array.from({ length: 11 }, (_, i) => `
      <a href="${baseUrl}/api/internal/nps/quick-response?survey_id=${surveyId}&score=${i}"
         style="display: inline-block; width: 40px; height: 40px; line-height: 40px; text-align: center;
                background: #f3f4f6; border-radius: 6px; text-decoration: none; color: #111; font-weight: bold;">
        ${i}
      </a>`).join("")}
  </div>
  <p style="color: #888; font-size: 12px;">
    0 = Not at all likely &nbsp;·&nbsp; 10 = Extremely likely
  </p>
  <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 24px 0;" />
  <p style="color: #888; font-size: 12px;">
    You're receiving this because you recently started using Foreman.
    Questions? Reply to this email.
  </p>
</div>`.trim();
}

export async function runNpsSurveyDispatcherJob(deps: AppDeps): Promise<JobResult> {
  const logger = deps.logger.child({ jobName: "nps_survey_dispatcher" });
  const now = new Date();
  const nowIso = now.toISOString();
  const cutoffPostOnboarding = new Date(
    now.getTime() - POST_ONBOARDING_DELAY_DAYS * 24 * 60 * 60 * 1000
  ).toISOString();
  const cutoffQuarterly = new Date(
    now.getTime() - QUARTERLY_MIN_GAP_DAYS * 24 * 60 * 60 * 1000
  ).toISOString();

  let dispatched = 0;
  const errors: string[] = [];

  try {
    // Workspaces with first_agent_running older than POST_ONBOARDING_DELAY_DAYS
    const { data: eligibleAgentEvents, error: feError } = await deps.db
      .from("funnel_events")
      .select("workspace_slug, occurred_at")
      .eq("event_type", "first_agent_running")
      .lt("occurred_at", cutoffPostOnboarding);

    if (feError) {
      throw new Error(`failed to fetch funnel events: ${feError.message}`);
    }

    const eligibleWorkspaces = (eligibleAgentEvents ?? []) as FunnelEventRow[];
    if (eligibleWorkspaces.length === 0) {
      return { jobName: "nps_survey_dispatcher", status: "noop", message: "no eligible workspaces" };
    }

    const surveyed = await getWorkspacesAlreadySurveyed(deps.db);

    // Fetch customer emails for eligible workspaces
    const slugs = eligibleWorkspaces.map((r) => r.workspace_slug);
    const { data: customerRows, error: custError } = await deps.db
      .from("customers")
      .select("workspace_slug, email, display_name")
      .in("workspace_slug", slugs)
      .in("payment_status", ["active", "trialing"]);

    if (custError) {
      throw new Error(`failed to fetch customers: ${custError.message}`);
    }

    const customerMap = new Map<string, CustomerRow>();
    for (const row of (customerRows ?? []) as CustomerRow[]) {
      customerMap.set(row.workspace_slug, row);
    }

    const baseUrl = deps.env.NODE_ENV === "production"
      ? "https://api.foreman.company"
      : "http://localhost:8080";

    for (const { workspace_slug: slug } of eligibleWorkspaces) {
      const customer = customerMap.get(slug);
      if (!customer) continue;

      const history = surveyed.get(slug);
      let triggerType: "post_onboarding" | "quarterly" | null = null;

      if (!history?.triggerTypes.has("post_onboarding")) {
        triggerType = "post_onboarding";
      } else if (history.lastSurveyAt < cutoffQuarterly) {
        triggerType = "quarterly";
      }

      if (!triggerType) continue;

      // Insert survey record first to get the ID for the email link
      const survey = await insertNpsSurvey(deps.db, {
        workspace_slug: slug,
        trigger_type: triggerType,
        survey_sent_at: nowIso
      });

      const html = buildNpsEmailHtml(customer.display_name, survey.id, baseUrl);

      try {
        await deps.clients.email.send({
          to: customer.email,
          subject: "How's Foreman working for you?",
          html,
          text: `On a scale from 0–10, how likely are you to recommend Foreman? Reply with your score or visit: ${baseUrl}/nps?survey_id=${survey.id}`
        });

        // Mark email sent
        await deps.db
          .from("nps_responses")
          .update({ email_sent_at: nowIso })
          .eq("id", survey.id);

        dispatched++;
        logger.info({ workspaceSlug: slug, triggerType, surveyId: survey.id }, "nps survey sent");
      } catch (emailErr) {
        const msg = emailErr instanceof Error ? emailErr.message : String(emailErr);
        errors.push(`send_failed:${slug}:${msg}`);
        logger.warn({ workspaceSlug: slug, err: msg }, "failed to send nps survey email");
      }
    }
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    logger.error({ err: msg }, "nps_survey_dispatcher failed");
    return {
      jobName: "nps_survey_dispatcher",
      status: "error",
      message: `nps dispatch failed: ${msg}`
    };
  }

  const status = errors.length > 0 ? "error" : "ok";
  return {
    jobName: "nps_survey_dispatcher",
    status,
    message: `dispatched ${dispatched} surveys`,
    details: { dispatched, errors } as unknown as Record<string, unknown>
  };
}
