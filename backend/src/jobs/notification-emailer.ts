import type { AppDeps } from "../app-deps.js";
import type { JobResult } from "./types.js";

const JOB_NAME = "notification_emailer";
const EMAIL_BATCH_SIZE = 50;

const notificationSubjectMap: Record<string, string> = {
  agent_hired: "Your new Foreman agent is ready",
  agent_paused_health: "Agent paused — health check failed",
  agent_recovered_health: "Agent recovered and is active again",
  byok_fallback_started: "BYOK fallback activated on your workspace",
  byok_fallback_stopped: "BYOK fallback stopped — your key is healthy again"
};

const escapeHtml = (str: string): string =>
  str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

const buildEmailHtml = (title: string, body: string, workspaceSlug: string): string => `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8" /></head>
<body style="font-family:sans-serif;max-width:600px;margin:0 auto;padding:24px;color:#111;">
  <h2 style="margin-bottom:8px;">${escapeHtml(title)}</h2>
  <p style="line-height:1.6;white-space:pre-wrap;">${escapeHtml(body)}</p>
  <hr style="border:none;border-top:1px solid #eee;margin:24px 0;" />
  <p style="color:#888;font-size:12px;">Workspace: ${escapeHtml(workspaceSlug)}</p>
</body>
</html>
`;

export async function runNotificationEmailerJob(deps: AppDeps): Promise<JobResult> {
  if (!deps.clients.email.enabled) {
    return {
      jobName: JOB_NAME,
      status: "noop",
      message: "email client disabled — RESEND_API_KEY not set"
    };
  }

  const { data: pending, error } = await deps.db
    .from("notifications")
    .select("id, workspace_slug, type, title, body")
    .is("email_sent_at", null)
    .order("created_at", { ascending: true })
    .limit(EMAIL_BATCH_SIZE);

  if (error) {
    return {
      jobName: JOB_NAME,
      status: "error",
      message: `failed to query pending notifications: ${error.message}`
    };
  }

  if (!pending || pending.length === 0) {
    return { jobName: JOB_NAME, status: "noop", message: "no pending notifications" };
  }

  const customerEmails = await resolveCustomerEmails(
    deps,
    pending.map((n) => n.workspace_slug as string)
  );

  let sent = 0;
  let failed = 0;
  const errors: string[] = [];

  for (const notification of pending) {
    const slug = notification.workspace_slug as string;
    const to = customerEmails.get(slug);
    if (!to) {
      errors.push(`no email for workspace ${slug}`);
      failed++;
      continue;
    }

    const subject =
      notificationSubjectMap[notification.type as string] ?? (notification.title as string);

    try {
      await deps.clients.email.send({
        to,
        subject,
        html: buildEmailHtml(
          notification.title as string,
          notification.body as string,
          slug
        ),
        text: `${notification.title as string}\n\n${notification.body as string}`
      });

      await deps.db
        .from("notifications")
        .update({ email_sent_at: new Date().toISOString() })
        .eq("id", notification.id);

      sent++;
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      errors.push(`workspace ${slug} notification ${notification.id as string}: ${msg}`);
      failed++;
    }
  }

  return {
    jobName: JOB_NAME,
    status: failed === 0 ? "ok" : "error",
    message: `sent ${sent}, failed ${failed}`,
    ...(errors.length > 0 ? { details: { errors } } : {})
  };
}

async function resolveCustomerEmails(
  deps: AppDeps,
  slugs: string[]
): Promise<Map<string, string>> {
  const unique = [...new Set(slugs)];
  const { data, error } = await deps.db
    .from("customers")
    .select("workspace_slug, email")
    .in("workspace_slug", unique);

  if (error || !data) {
    return new Map();
  }

  return new Map(
    data.map((row) => [row.workspace_slug as string, row.email as string])
  );
}
