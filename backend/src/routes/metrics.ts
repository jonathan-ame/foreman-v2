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
  updated_at: string;
}

interface AgentRow {
  workspace_slug: string;
  surcharge_accrued_current_period_cents: number | null;
}

export function registerMetricsRoutes(app: Hono, deps: AppDeps) {
  app.get("/api/internal/metrics/economics", async (c) => {
    // Use Promise.allSettled for error resilience
    const [
      customersResult,
      agentsResult,
      funnelSummary,
      d7Retained,
      npsStats
    ] = await Promise.allSettled([
      deps.db.from("customers").select(
        "current_tier, current_billing_mode, payment_status, created_at, updated_at"
      ),
      deps.db.from("agents").select("workspace_slug, surcharge_accrued_current_period_cents"),
      getFunnelSummary(deps.db).catch(() => null),
      getD7RetainedCount(deps.db).catch(() => null),
      getNpsStats(deps.db).catch(() => null)
    ]);

    // Handle customer query errors
    if (customersResult.status === 'rejected' || (customersResult.status === 'fulfilled' && customersResult.value.error)) {
      deps.logger.error({ err: customersResult.status === 'rejected' ? customersResult.reason : customersResult.value.error }, 
                       "metrics: failed to fetch customers");
      return c.json({ error: "database_error" }, 500);
    }
    
    // Handle agent query errors (non-critical, continue with empty)
    let agents: AgentRow[] = [];
    if (agentsResult.status === 'fulfilled' && !agentsResult.value.error) {
      agents = (agentsResult.value.data ?? []) as AgentRow[];
    }

    const customers = (customersResult.status === 'fulfilled' ? customersResult.value.data : []) as CustomerRow[];
    const since30d = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

    // Active customers (excluding trialing for MRR calculation)
    const activeStatuses = new Set(["active"]);
    const trialingStatuses = new Set(["trialing"]);
    
    const active = customers.filter((c) => activeStatuses.has(c.payment_status));
    const trialing = customers.filter((c) => trialingStatuses.has(c.payment_status));
    const canceledLast30d = customers.filter(
      (c) => c.payment_status === "canceled" && c.updated_at >= since30d
    );

    // MRR (exclude trialing customers as they don't contribute to revenue)
    let mrrCents = 0;
    for (const customer of active) {
      const tier = customer.current_billing_mode === "byok" ? "byok_platform" : (customer.current_tier ?? "");
      mrrCents += TIER_MRR_CENTS[tier] ?? 0;
    }

    // Total active + trialing for customer count metrics
    const totalActiveCustomers = active.length + trialing.length;
    const arpuCents = totalActiveCustomers > 0 ? Math.round(mrrCents / totalActiveCustomers) : 0;

    // Calculate 30-day churn rate properly
    // Baseline: Customers who were active 30+ days ago
    const baselineDate = new Date(Date.now() - 60 * 24 * 60 * 60 * 1000).toISOString(); // 60 days ago
    const baselineActive = customers.filter(
      (c) => (activeStatuses.has(c.payment_status) || trialingStatuses.has(c.payment_status)) 
             && c.created_at < baselineDate
    );
    
    const churnedInLast30d = customers.filter(
      (c) => c.payment_status === "canceled" 
             && c.updated_at >= since30d
             && c.created_at < baselineDate
    );
    
    const churnRate30d = baselineActive.length > 0
      ? Math.round((churnedInLast30d.length / baselineActive.length) * 10000) / 100
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

    // Handle optional metrics with null safety
    const funnelData = funnelSummary.status === 'fulfilled' ? funnelSummary.value : null;
    const d7Data = d7Retained.status === 'fulfilled' ? d7Retained.value : null;
    const npsData = npsStats.status === 'fulfilled' ? npsStats.value : null;

    return c.json({
      mrr_cents: mrrCents,
      mrr_usd: (mrrCents / 100).toFixed(2),
      active_customers: totalActiveCustomers,
      active_paying_customers: active.length,
      trialing_customers: trialing.length,
      arpu_cents: arpuCents,
      arpu_usd: (arpuCents / 100).toFixed(2),
      churn_rate_30d_pct: churnRate30d,
      canceled_last_30d: churnedInLast30d.length,
      surcharge_attach_rate_pct: surchargeAttachRate,
      workspaces_with_surcharge: workspacesWithSurcharge,
      funnel: funnelData ? {
        signups_30d: funnelData.signups_30d,
        first_agents_30d: funnelData.first_agents_30d,
        first_tasks_30d: funnelData.first_tasks_30d,
        total_signups: funnelData.total_signups,
        total_first_agents: funnelData.total_first_agents,
        total_first_tasks: funnelData.total_first_tasks,
        d7_retained: d7Data
      } : null,
      nps: npsData,
      computed_at: new Date().toISOString(),
      metric_errors: {
        funnel: funnelSummary.status === 'rejected',
        d7_retention: d7Retained.status === 'rejected',
        nps: npsStats.status === 'rejected'
      }
    });
  });
}
