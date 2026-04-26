import { getFunnelSummary } from "../db/funnel-events.js";
import { getNpsStats } from "../db/nps.js";
import { getSubscriberStats } from "../db/email-subscribers.js";
import { getPageViewStats } from "../db/page-views.js";
import type { AppDeps } from "../app-deps.js";
import type { JobResult } from "./types.js";

const TIER_MRR_CENTS: Record<string, number> = {
  tier_1: 4_900,
  tier_2: 9_900,
  tier_3: 19_900,
  byok_platform: 4_900
};

interface CustomerRow {
  current_tier: string | null;
  current_billing_mode: string;
  payment_status: string;
  created_at: string;
}

function formatUsd(cents: number): string {
  return `$${(cents / 100).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

function buildReviewEmailHtml(params: {
  weekLabel: string;
  mrrCents: number;
  mrrChangePct: number | null;
  activeCustomers: number;
  arpuCents: number;
  churnRate30d: number;
  canceledLast30d: number;
  surchargeAttachRate: number;
  funnel: {
    signups_30d: number;
    first_agents_30d: number;
    first_tasks_30d: number;
  };
  nps: {
    nps_score: number | null;
    response_count: number;
    responses_30d: number;
  };
  pageViews: {
    total_1d: number;
    total_7d: number;
    unique_ip_1d: number;
    top_paths_1d: Array<{ path: string; count: number }>;
    top_sources_1d: Array<{ source: string; count: number }>;
  };
  subscribers: {
    new_1d: number;
    new_7d: number;
    new_30d: number;
    total_active: number;
    by_source_7d: Array<{ source: string; count: number }>;
  };
}): string {
  const {
    weekLabel,
    mrrCents,
    mrrChangePct,
    activeCustomers,
    arpuCents,
    churnRate30d,
    canceledLast30d,
    surchargeAttachRate,
    funnel,
    nps,
    pageViews,
    subscribers
  } = params;

  const mrrChangeLabel = mrrChangePct !== null
    ? ` <span style="color:${mrrChangePct >= 0 ? "#16a34a" : "#dc2626"}">(${mrrChangePct >= 0 ? "+" : ""}${mrrChangePct.toFixed(1)}% WoW)</span>`
    : "";

  const npsLabel = nps.nps_score !== null
    ? `${nps.nps_score} (${nps.response_count} responses, ${nps.responses_30d} last 30d)`
    : "No responses yet";

  const topPathsRows = pageViews.top_paths_1d
    .slice(0, 5)
    .map((p) => `<tr><td style="padding: 4px 0; color: #6b7280;">${p.path}</td><td style="padding: 4px 0; font-weight: bold; text-align: right;">${p.count}</td></tr>`)
    .join("\n");

  const topSourcesRows = pageViews.top_sources_1d
    .map((s) => `<tr><td style="padding: 4px 0; color: #6b7280;">${s.source}</td><td style="padding: 4px 0; font-weight: bold; text-align: right;">${s.count}</td></tr>`)
    .join("\n");

  const subscriberSourceRows = subscribers.by_source_7d
    .map((s) => `<tr><td style="padding: 4px 0; color: #6b7280;">${s.source}</td><td style="padding: 4px 0; font-weight: bold; text-align: right;">${s.count}</td></tr>`)
    .join("\n");

  return `
<div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; background: #fff;">
  <h1 style="font-size: 22px; color: #111; border-bottom: 2px solid #e5e7eb; padding-bottom: 12px;">
    Foreman Weekly CEO Review — ${weekLabel}
  </h1>

  <h2 style="font-size: 16px; color: #374151; margin-top: 24px;">Site Traffic</h2>
  <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
    <tr>
      <td style="padding: 8px 0; color: #6b7280;">Page views (7d)</td>
      <td style="padding: 8px 0; font-weight: bold; text-align: right;">${pageViews.total_7d.toLocaleString()}</td>
    </tr>
    <tr>
      <td style="padding: 8px 0; color: #6b7280;">Unique visitors (24h)</td>
      <td style="padding: 8px 0; font-weight: bold; text-align: right;">${pageViews.unique_ip_1d.toLocaleString()}</td>
    </tr>
    <tr>
      <td style="padding: 8px 0; color: #6b7280;">Page views (24h)</td>
      <td style="padding: 8px 0; font-weight: bold; text-align: right;">${pageViews.total_1d.toLocaleString()}</td>
    </tr>
  </table>
  ${topPathsRows ? `
  <p style="font-size: 12px; color: #6b7280; margin-top: 8px;">Top pages (24h):</p>
  <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
    ${topPathsRows}
  </table>` : ""}
  ${topSourcesRows ? `
  <p style="font-size: 12px; color: #6b7280; margin-top: 8px;">Top traffic sources (24h):</p>
  <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
    ${topSourcesRows}
  </table>` : ""}

  <h2 style="font-size: 16px; color: #374151; margin-top: 24px;">Form Submissions</h2>
  <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
    <tr>
      <td style="padding: 8px 0; color: #6b7280;">New subscribers (7d)</td>
      <td style="padding: 8px 0; font-weight: bold; text-align: right;">${subscribers.new_7d}</td>
    </tr>
    <tr>
      <td style="padding: 8px 0; color: #6b7280;">New subscribers (30d)</td>
      <td style="padding: 8px 0; font-weight: bold; text-align: right;">${subscribers.new_30d}</td>
    </tr>
    <tr>
      <td style="padding: 8px 0; color: #6b7280;">Total active subscribers</td>
      <td style="padding: 8px 0; font-weight: bold; text-align: right;">${subscribers.total_active}</td>
    </tr>
  </table>
  ${subscriberSourceRows ? `
  <p style="font-size: 12px; color: #6b7280; margin-top: 8px;">By source (7d):</p>
  <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
    ${subscriberSourceRows}
  </table>` : ""}

  <h2 style="font-size: 16px; color: #374151; margin-top: 24px;">Revenue</h2>
  <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
    <tr>
      <td style="padding: 8px 0; color: #6b7280;">MRR</td>
      <td style="padding: 8px 0; font-weight: bold; text-align: right;">${formatUsd(mrrCents)}${mrrChangeLabel}</td>
    </tr>
    <tr>
      <td style="padding: 8px 0; color: #6b7280;">ARPU</td>
      <td style="padding: 8px 0; font-weight: bold; text-align: right;">${formatUsd(arpuCents)}/mo</td>
    </tr>
    <tr>
      <td style="padding: 8px 0; color: #6b7280;">Surcharge attach rate</td>
      <td style="padding: 8px 0; font-weight: bold; text-align: right;">${surchargeAttachRate.toFixed(1)}%</td>
    </tr>
  </table>

  <h2 style="font-size: 16px; color: #374151; margin-top: 24px;">Customers</h2>
  <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
    <tr>
      <td style="padding: 8px 0; color: #6b7280;">Active customers</td>
      <td style="padding: 8px 0; font-weight: bold; text-align: right;">${activeCustomers}</td>
    </tr>
    <tr>
      <td style="padding: 8px 0; color: #6b7280;">Churn rate (30d)</td>
      <td style="padding: 8px 0; font-weight: bold; text-align: right;">${churnRate30d.toFixed(1)}%</td>
    </tr>
    <tr>
      <td style="padding: 8px 0; color: #6b7280;">Canceled last 30d</td>
      <td style="padding: 8px 0; font-weight: bold; text-align: right;">${canceledLast30d}</td>
    </tr>
  </table>

  <h2 style="font-size: 16px; color: #374151; margin-top: 24px;">Activation (last 30 days)</h2>
  <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
    <tr>
      <td style="padding: 8px 0; color: #6b7280;">Signups</td>
      <td style="padding: 8px 0; font-weight: bold; text-align: right;">${funnel.signups_30d}</td>
    </tr>
    <tr>
      <td style="padding: 8px 0; color: #6b7280;">First agent running</td>
      <td style="padding: 8px 0; font-weight: bold; text-align: right;">${funnel.first_agents_30d}</td>
    </tr>
    <tr>
      <td style="padding: 8px 0; color: #6b7280;">First task started</td>
      <td style="padding: 8px 0; font-weight: bold; text-align: right;">${funnel.first_tasks_30d}</td>
    </tr>
  </table>

  <h2 style="font-size: 16px; color: #374151; margin-top: 24px;">NPS</h2>
  <p style="font-size: 14px; color: #374151;">${npsLabel}</p>

  <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 24px 0;" />
  <p style="color: #9ca3af; font-size: 11px;">
    Generated by Foreman · ${new Date().toUTCString()}
  </p>
</div>`.trim();
}

export async function runWeeklyCeoReviewJob(deps: AppDeps): Promise<JobResult> {
  const logger = deps.logger.child({ jobName: "weekly_ceo_review" });

  if (!deps.clients.email.enabled) {
    logger.warn("email client not configured — skipping weekly CEO review");
    return {
      jobName: "weekly_ceo_review",
      status: "noop",
      message: "email client not configured"
    };
  }

  const toEmail = deps.env.CEO_REVIEW_EMAIL ?? deps.env.EMAIL_FROM;
  if (!toEmail) {
    logger.warn("CEO_REVIEW_EMAIL and EMAIL_FROM both unset — skipping");
    return {
      jobName: "weekly_ceo_review",
      status: "noop",
      message: "no recipient configured"
    };
  }

  try {
    const since30d = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

    const [customersResult, agentsResult, funnelSummary, npsStats, pageViewStats, subscriberStats] = await Promise.all([
      deps.db.from("customers").select("current_tier, current_billing_mode, payment_status, created_at"),
      deps.db.from("agents").select("workspace_slug, surcharge_accrued_current_period_cents"),
      getFunnelSummary(deps.db),
      getNpsStats(deps.db),
      getPageViewStats(deps.db).catch(() => ({ total_1d: 0, total_7d: 0, total_30d: 0, unique_ip_1d: 0, top_paths_1d: [], top_sources_1d: [] })),
      getSubscriberStats(deps.db).catch(() => ({ new_1d: 0, new_7d: 0, new_30d: 0, total_active: 0, by_source_7d: [] }))
    ]);

    if (customersResult.error) throw new Error(`customers fetch failed: ${customersResult.error.message}`);
    if (agentsResult.error) throw new Error(`agents fetch failed: ${agentsResult.error.message}`);

    const customers = (customersResult.data ?? []) as CustomerRow[];
    const agents = (agentsResult.data ?? []) as { workspace_slug: string; surcharge_accrued_current_period_cents: number | null }[];

    const activeStatuses = new Set(["active", "trialing"]);
    const active = customers.filter((c) => activeStatuses.has(c.payment_status));

    let mrrCents = 0;
    for (const c of active) {
      const tier = c.current_billing_mode === "byok" ? "byok_platform" : (c.current_tier ?? "");
      mrrCents += TIER_MRR_CENTS[tier] ?? 0;
    }

    const activeCount = active.length;
    const arpuCents = activeCount > 0 ? Math.round(mrrCents / activeCount) : 0;

    const canceledLast30d = customers.filter(
      (c) => c.payment_status === "canceled" && c.created_at >= since30d
    ).length;
    const baselineCount = customers.filter(
      (c) => activeStatuses.has(c.payment_status) || c.created_at < since30d
    ).length;
    const churnRate30d = baselineCount > 0 ? Math.round((canceledLast30d / baselineCount) * 10000) / 100 : 0;

    const surchargeMap = new Map<string, number>();
    for (const a of agents) {
      const cur = surchargeMap.get(a.workspace_slug) ?? 0;
      surchargeMap.set(a.workspace_slug, cur + (a.surcharge_accrued_current_period_cents ?? 0));
    }
    const withSurcharge = Array.from(surchargeMap.values()).filter((v) => v > 0).length;
    const totalWithAgents = surchargeMap.size;
    const surchargeAttachRate = totalWithAgents > 0 ? Math.round((withSurcharge / totalWithAgents) * 10000) / 100 : 0;

    const weekLabel = new Date().toLocaleDateString("en-US", {
      month: "short", day: "numeric", year: "numeric", timeZone: "UTC"
    });

    const html = buildReviewEmailHtml({
      weekLabel,
      mrrCents,
      mrrChangePct: null,
      activeCustomers: activeCount,
      arpuCents,
      churnRate30d,
      canceledLast30d,
      surchargeAttachRate,
      funnel: {
        signups_30d: funnelSummary.signups_30d,
        first_agents_30d: funnelSummary.first_agents_30d,
        first_tasks_30d: funnelSummary.first_tasks_30d
      },
      nps: npsStats,
      pageViews: pageViewStats,
      subscribers: subscriberStats
    });

    await deps.clients.email.send({
      to: toEmail,
      subject: `Foreman Weekly Review — ${weekLabel}`,
      html,
      text: `MRR: ${formatUsd(mrrCents)} | Active customers: ${activeCount} | Churn: ${churnRate30d.toFixed(1)}% | NPS: ${npsStats.nps_score ?? "n/a"} | PageViews: ${pageViewStats.total_7d} (7d) | New subscribers: ${subscriberStats.new_7d} (7d)`
    });

    logger.info({ to: toEmail, weekLabel }, "weekly CEO review sent");
    return {
      jobName: "weekly_ceo_review",
      status: "ok",
      message: `weekly review sent to ${toEmail} for week of ${weekLabel}`
    };
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    logger.error({ err: msg }, "weekly_ceo_review failed");
    return {
      jobName: "weekly_ceo_review",
      status: "error",
      message: `weekly review failed: ${msg}`
    };
  }
}
