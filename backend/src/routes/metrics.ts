import type { Hono } from "hono";
import type { AppDeps } from "../app-deps.js";
import { getFunnelSummary, getD7RetainedCount } from "../db/funnel-events.js";
import { getNpsStats } from "../db/nps.js";

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

interface AgentRow {
  workspace_slug: string;
  surcharge_accrued_current_period_cents: number | null;
}

export function registerMetricsRoutes(app: Hono, deps: AppDeps) {
  app.get("/api/internal/metrics/economics", async (c) => {
    const [
      customersResult,
      agentsResult,
      funnelSummary,
      d7Retained,
      npsStats
    ] = await Promise.all([
      deps.db.from("customers").select(
        "current_tier, current_billing_mode, payment_status, created_at"
      ),
      deps.db.from("agents").select("workspace_slug, surcharge_accrued_current_period_cents"),
      getFunnelSummary(deps.db),
      getD7RetainedCount(deps.db),
      getNpsStats(deps.db)
    ]);

    if (customersResult.error) {
      deps.logger.error({ err: customersResult.error }, "metrics: failed to fetch customers");
      return c.json({ error: "database_error" }, 500);
    }
    if (agentsResult.error) {
      deps.logger.error({ err: agentsResult.error }, "metrics: failed to fetch agents");
      return c.json({ error: "database_error" }, 500);
    }

    const customers = (customersResult.data ?? []) as CustomerRow[];
    const agents = (agentsResult.data ?? []) as AgentRow[];
    const since30d = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

    const activeStatuses = new Set(["active", "trialing"]);
    const active = customers.filter((c) => activeStatuses.has(c.payment_status));
    const canceledLast30d = customers.filter(
      (c) => c.payment_status === "canceled" && c.created_at >= since30d
    );
    const activeOrCanceledBefore30d = customers.filter(
      (c) => activeStatuses.has(c.payment_status) || c.created_at < since30d
    );

    // MRR
    let mrrCents = 0;
    for (const customer of active) {
      const tier = customer.current_billing_mode === "byok" ? "byok_platform" : (customer.current_tier ?? "");
      mrrCents += TIER_MRR_CENTS[tier] ?? 0;
    }

    const activeCount = active.length;
    const arpuCents = activeCount > 0 ? Math.round(mrrCents / activeCount) : 0;

    // Churn rate (30d)
    const baselineCount = activeOrCanceledBefore30d.length;
    const churnRate30d = baselineCount > 0
      ? Math.round((canceledLast30d.length / baselineCount) * 10000) / 100
      : 0;

    // Surcharge attach rate: workspaces where any agent accrued surcharge this period
    const workspaceSurchargeMap = new Map<string, number>();
    for (const agent of agents) {
      const current = workspaceSurchargeMap.get(agent.workspace_slug) ?? 0;
      workspaceSurchargeMap.set(
        agent.workspace_slug,
        current + (agent.surcharge_accrued_current_period_cents ?? 0)
      );
    }
    const workspacesWithSurcharge = Array.from(workspaceSurchargeMap.values()).filter((v) => v > 0).length;
    const totalWorkspacesWithAgents = workspaceSurchargeMap.size;
    const surchargeAttachRate = totalWorkspacesWithAgents > 0
      ? Math.round((workspacesWithSurcharge / totalWorkspacesWithAgents) * 10000) / 100
      : 0;

    return c.json({
      mrr_cents: mrrCents,
      mrr_usd: (mrrCents / 100).toFixed(2),
      active_customers: activeCount,
      arpu_cents: arpuCents,
      arpu_usd: (arpuCents / 100).toFixed(2),
      churn_rate_30d_pct: churnRate30d,
      canceled_last_30d: canceledLast30d.length,
      surcharge_attach_rate_pct: surchargeAttachRate,
      workspaces_with_surcharge: workspacesWithSurcharge,
      funnel: {
        signups_30d: funnelSummary.signups_30d,
        first_agents_30d: funnelSummary.first_agents_30d,
        first_tasks_30d: funnelSummary.first_tasks_30d,
        total_signups: funnelSummary.total_signups,
        total_first_agents: funnelSummary.total_first_agents,
        total_first_tasks: funnelSummary.total_first_tasks,
        d7_retained: d7Retained
      },
      nps: npsStats,
      computed_at: new Date().toISOString()
    });
  });
}
