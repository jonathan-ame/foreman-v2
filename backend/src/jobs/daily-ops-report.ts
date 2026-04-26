import type { AppDeps } from "../app-deps.js";
import type { JobResult } from "./types.js";
import { getAgentStatusCounts } from "../db/agents.js";
import { getFunnelSummary, getD7RetainedCount } from "../db/funnel-events.js";
import { getNpsStats } from "../db/nps.js";
import { getSubscriberStats } from "../db/email-subscribers.js";
import { getPageViewStats } from "../db/page-views.js";

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

function buildDailyReportHtml(params: {
  dateLabel: string;
  mrrCents: number;
  activeCustomerCount: number;
  arpuCents: number;
  churnRate30d: number;
  activeAgents: number;
  pausedAgents: number;
  funnel: {
    signups_30d: number;
    first_agents_30d: number;
    first_tasks_30d: number;
    d7_retained: number;
  };
  nps: {
    nps_score: number | null;
    response_count: number;
  };
  integrationStatus: string;
  pageViews: {
    total_1d: number;
    total_7d: number;
    unique_ip_1d: number;
    top_paths_1d: Array<{ path: string; count: number }>;
  };
  subscribers: {
    new_1d: number;
    new_7d: number;
    total_active: number;
    by_source_7d: Array<{ source: string; count: number }>;
  };
}): string {
  const {
    dateLabel,
    mrrCents,
    activeCustomerCount,
    arpuCents,
    churnRate30d,
    activeAgents,
    pausedAgents,
    funnel,
    nps,
    integrationStatus,
    pageViews,
    subscribers
  } = params;

  void activeCustomerCount;

  const npsLabel = nps.nps_score !== null
    ? `${nps.nps_score} (${nps.response_count} responses)`
    : "No responses yet";

  const statusColor = integrationStatus === "ok" ? "#16a34a" : integrationStatus === "degraded" ? "#d97706" : "#dc2626";

  const topPathsRows = pageViews.top_paths_1d
    .slice(0, 5)
    .map((p) => `<tr><td style="padding: 4px 0; color: #6b7280;">${p.path}</td><td style="padding: 4px 0; font-weight: bold; text-align: right;">${p.count}</td></tr>`)
    .join("\n");

  const sourceRows = subscribers.by_source_7d
    .map((s) => `<tr><td style="padding: 4px 0; color: #6b7280;">${s.source}</td><td style="padding: 4px 0; font-weight: bold; text-align: right;">${s.count}</td></tr>`)
    .join("\n");

  return `
<div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; background: #fff;">
  <h1 style="font-size: 20px; color: #111; border-bottom: 2px solid #e5e7eb; padding-bottom: 12px;">
    Foreman Daily Ops Report — ${dateLabel}
  </h1>

  <h2 style="font-size: 14px; color: #374151; margin-top: 20px;">System Status</h2>
  <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
    <tr>
      <td style="padding: 6px 0; color: #6b7280;">Integration health</td>
      <td style="padding: 6px 0; font-weight: bold; text-align: right; color: ${statusColor};">${integrationStatus.toUpperCase()}</td>
    </tr>
    <tr>
      <td style="padding: 6px 0; color: #6b7280;">Active agents</td>
      <td style="padding: 6px 0; font-weight: bold; text-align: right;">${activeAgents}</td>
    </tr>
    <tr>
      <td style="padding: 6px 0; color: #6b7280;">Paused agents</td>
      <td style="padding: 6px 0; font-weight: bold; text-align: right; color: ${pausedAgents > 0 ? "#d97706" : "#16a34a"};">${pausedAgents}</td>
    </tr>
  </table>

  <h2 style="font-size: 14px; color: #374151; margin-top: 20px;">Site Traffic</h2>
  <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
    <tr>
      <td style="padding: 6px 0; color: #6b7280;">Page views (24h)</td>
      <td style="padding: 6px 0; font-weight: bold; text-align: right;">${pageViews.total_1d.toLocaleString()}</td>
    </tr>
    <tr>
      <td style="padding: 6px 0; color: #6b7280;">Unique visitors (24h)</td>
      <td style="padding: 6px 0; font-weight: bold; text-align: right;">${pageViews.unique_ip_1d.toLocaleString()}</td>
    </tr>
    <tr>
      <td style="padding: 6px 0; color: #6b7280;">Page views (7d)</td>
      <td style="padding: 6px 0; font-weight: bold; text-align: right;">${pageViews.total_7d.toLocaleString()}</td>
    </tr>
  </table>
  ${topPathsRows ? `
  <p style="font-size: 12px; color: #6b7280; margin-top: 8px;">Top pages (24h):</p>
  <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
    ${topPathsRows}
  </table>` : ""}

  <h2 style="font-size: 14px; color: #374151; margin-top: 20px;">Form Submissions</h2>
  <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
    <tr>
      <td style="padding: 6px 0; color: #6b7280;">New subscribers (24h)</td>
      <td style="padding: 6px 0; font-weight: bold; text-align: right;">${subscribers.new_1d}</td>
    </tr>
    <tr>
      <td style="padding: 6px 0; color: #6b7280;">New subscribers (7d)</td>
      <td style="padding: 6px 0; font-weight: bold; text-align: right;">${subscribers.new_7d}</td>
    </tr>
    <tr>
      <td style="padding: 6px 0; color: #6b7280;">Total active subscribers</td>
      <td style="padding: 6px 0; font-weight: bold; text-align: right;">${subscribers.total_active}</td>
    </tr>
  </table>
  ${sourceRows ? `
  <p style="font-size: 12px; color: #6b7280; margin-top: 8px;">By source (7d):</p>
  <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
    ${sourceRows}
  </table>` : ""}

  <h2 style="font-size: 14px; color: #374151; margin-top: 20px;">Revenue</h2>
  <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
    <tr>
      <td style="padding: 6px 0; color: #6b7280;">MRR</td>
      <td style="padding: 6px 0; font-weight: bold; text-align: right;">${formatUsd(mrrCents)}</td>
    </tr>
    <tr>
      <td style="padding: 6px 0; color: #6b7280;">ARPU</td>
      <td style="padding: 6px 0; font-weight: bold; text-align: right;">${formatUsd(arpuCents)}/mo</td>
    </tr>
    <tr>
      <td style="padding: 6px 0; color: #6b7280;">Churn (30d)</td>
      <td style="padding: 6px 0; font-weight: bold; text-align: right;">${churnRate30d.toFixed(1)}%</td>
    </tr>
  </table>

  <h2 style="font-size: 14px; color: #374151; margin-top: 20px;">Activation (30d)</h2>
  <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
    <tr>
      <td style="padding: 6px 0; color: #6b7280;">Signups</td>
      <td style="padding: 6px 0; font-weight: bold; text-align: right;">${funnel.signups_30d}</td>
    </tr>
    <tr>
      <td style="padding: 6px 0; color: #6b7280;">First agent</td>
      <td style="padding: 6px 0; font-weight: bold; text-align: right;">${funnel.first_agents_30d}</td>
    </tr>
    <tr>
      <td style="padding: 6px 0; color: #6b7280;">First task</td>
      <td style="padding: 6px 0; font-weight: bold; text-align: right;">${funnel.first_tasks_30d}</td>
    </tr>
    <tr>
      <td style="padding: 6px 0; color: #6b7280;">D7 retained</td>
      <td style="padding: 6px 0; font-weight: bold; text-align: right;">${funnel.d7_retained}</td>
    </tr>
  </table>

  <h2 style="font-size: 14px; color: #374151; margin-top: 20px;">NPS</h2>
  <p style="font-size: 13px; color: #374151;">${npsLabel}</p>

  <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 20px 0;" />
  <p style="color: #9ca3af; font-size: 11px;">
    Generated by Foreman · ${new Date().toUTCString()}
  </p>
</div>`.trim();
}

export async function runDailyOpsReportJob(deps: AppDeps): Promise<JobResult> {
  const logger = deps.logger.child({ jobName: "daily_ops_report" });

  if (!deps.clients.email.enabled) {
    logger.warn("email client not configured — skipping daily ops report");
    return {
      jobName: "daily_ops_report",
      status: "noop",
      message: "email client not configured"
    };
  }

  const toEmail = deps.env.CEO_REVIEW_EMAIL ?? deps.env.EMAIL_FROM;
  if (!toEmail) {
    logger.warn("CEO_REVIEW_EMAIL and EMAIL_FROM both unset — skipping daily ops report");
    return {
      jobName: "daily_ops_report",
      status: "noop",
      message: "no recipient configured"
    };
  }

  try {
    const [customersResult, funnelSummary, d7Retained, npsStats, agentCounts, pageViewStats, subscriberStats] = await Promise.all([
      deps.db.from("customers").select("current_tier, current_billing_mode, payment_status, created_at"),
      getFunnelSummary(deps.db),
      getD7RetainedCount(deps.db),
      getNpsStats(deps.db),
      getAgentStatusCounts(deps.db),
      getPageViewStats(deps.db).catch(() => ({ total_1d: 0, total_7d: 0, total_30d: 0, unique_ip_1d: 0, top_paths_1d: [], top_sources_1d: [] })),
      getSubscriberStats(deps.db).catch(() => ({ new_1d: 0, new_7d: 0, new_30d: 0, total_active: 0, by_source_7d: [] }))
    ]);

    if (customersResult.error) {
      throw new Error(`customers fetch failed: ${customersResult.error.message}`);
    }

    const customers = (customersResult.data ?? []) as CustomerRow[];
    const activeStatuses = new Set(["active", "trialing"]);
    const active = customers.filter((c) => activeStatuses.has(c.payment_status));

    let mrrCents = 0;
    for (const c of active) {
      const tier = c.current_billing_mode === "byok" ? "byok_platform" : (c.current_tier ?? "");
      mrrCents += TIER_MRR_CENTS[tier] ?? 0;
    }

    const activeCount = active.length;
    const arpuCents = activeCount > 0 ? Math.round(mrrCents / activeCount) : 0;

    const since30d = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
    const canceledLast30d = customers.filter(
      (c) => c.payment_status === "canceled" && c.created_at >= since30d
    ).length;
    const baselineCount = customers.filter(
      (c) => activeStatuses.has(c.payment_status) || c.created_at < since30d
    ).length;
    const churnRate30d = baselineCount > 0 ? Math.round((canceledLast30d / baselineCount) * 10000) / 100 : 0;

    let integrationStatus = "ok";
    try {
      const paperclipResult = await deps.clients.paperclip.ping();
      const gatewayStatus = await deps.clients.openclaw.gatewayStatus();
      if (!paperclipResult.ok || !gatewayStatus.running) {
        integrationStatus = "degraded";
      }
    } catch {
      integrationStatus = "down";
    }

    const dateLabel = new Date().toLocaleDateString("en-US", {
      month: "short", day: "numeric", year: "numeric", timeZone: "UTC"
    });

    const html = buildDailyReportHtml({
      dateLabel,
      mrrCents,
      activeCustomerCount: activeCount,
      arpuCents,
      churnRate30d,
      activeAgents: agentCounts.active_count,
      pausedAgents: agentCounts.paused_count,
      funnel: {
        signups_30d: funnelSummary.signups_30d,
        first_agents_30d: funnelSummary.first_agents_30d,
        first_tasks_30d: funnelSummary.first_tasks_30d,
        d7_retained: d7Retained
      },
      nps: npsStats,
      integrationStatus,
      pageViews: pageViewStats,
      subscribers: subscriberStats
    });

    await deps.clients.email.send({
      to: toEmail,
      subject: `Foreman Daily Ops — ${dateLabel}`,
      html,
      text: `MRR: ${formatUsd(mrrCents)} | Active: ${activeCount} | Agents: ${agentCounts.active_count} active / ${agentCounts.paused_count} paused | System: ${integrationStatus} | NPS: ${npsStats.nps_score ?? "n/a"} | PageViews: ${pageViewStats.total_1d} (24h) | Subscribers: ${subscriberStats.new_1d} new (24h)`
    });

    logger.info({ to: toEmail, dateLabel }, "daily ops report sent");
    return {
      jobName: "daily_ops_report",
      status: "ok",
      message: `daily ops report sent to ${toEmail} for ${dateLabel}`
    };
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    logger.error({ err: msg }, "daily_ops_report failed");
    return {
      jobName: "daily_ops_report",
      status: "error",
      message: `daily ops report failed: ${msg}`
    };
  }
}
