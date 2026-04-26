import type { Hono } from "hono";
import type { AppDeps } from "../app-deps.js";
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

interface AgentRow {
  workspace_slug: string;
  surcharge_accrued_current_period_cents: number | null;
}

export function registerMonitoringRoutes(app: Hono, deps: AppDeps) {
  app.get("/api/internal/monitoring/dashboard", async (c) => {
    const [
      integrationResult,
      credentialResult,
      customersResult,
      agentsResult,
      funnelSummary,
      d7Retained,
      npsStats,
      pageViewStats,
      subscriberStats
    ] = await Promise.all([
      fetchIntegrationHealth(deps),
      fetchCredentialHealth(deps),
      deps.db.from("customers").select("current_tier, current_billing_mode, payment_status, created_at"),
      deps.db.from("agents").select("workspace_slug, surcharge_accrued_current_period_cents"),
      getFunnelSummary(deps.db),
      getD7RetainedCount(deps.db),
      getNpsStats(deps.db),
      getPageViewStats(deps.db).catch(() => ({ total_1d: 0, total_7d: 0, total_30d: 0, unique_ip_1d: 0, top_paths_1d: [], top_sources_1d: [] })),
      getSubscriberStats(deps.db).catch(() => ({ new_1d: 0, new_7d: 0, new_30d: 0, total_active: 0, by_source_7d: [] }))
    ]);

    if (customersResult.error) {
      deps.logger.error({ err: customersResult.error }, "monitoring dashboard: customers fetch failed");
      return c.json({ error: "database_error" }, 500);
    }
    if (agentsResult.error) {
      deps.logger.error({ err: agentsResult.error }, "monitoring dashboard: agents fetch failed");
      return c.json({ error: "database_error" }, 500);
    }

    const customers = (customersResult.data ?? []) as CustomerRow[];
    const agents = (agentsResult.data ?? []) as AgentRow[];
    const since30d = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

    const activeStatuses = new Set(["active", "trialing"]);
    const active = customers.filter((c) => activeStatuses.has(c.payment_status));
    let mrrCents = 0;
    for (const customer of active) {
      const tier = customer.current_billing_mode === "byok" ? "byok_platform" : (customer.current_tier ?? "");
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
    const churnRate30d = baselineCount > 0
      ? Math.round((canceledLast30d / baselineCount) * 10000) / 100
      : 0;

    const agentCounts = await getAgentStatusCounts(deps.db);

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
      system: {
        integration: integrationResult,
        credentials: credentialResult,
        uptime_seconds: process.uptime(),
        node_env: deps.env.NODE_ENV,
        timestamp: new Date().toISOString()
      },
      business: {
        mrr_cents: mrrCents,
        mrr_usd: (mrrCents / 100).toFixed(2),
        active_customers: activeCount,
        arpu_cents: arpuCents,
        arpu_usd: (arpuCents / 100).toFixed(2),
        churn_rate_30d_pct: churnRate30d,
        canceled_last_30d: canceledLast30d,
        surcharge_attach_rate_pct: surchargeAttachRate,
        workspaces_with_surcharge: workspacesWithSurcharge
      },
      agents: {
        active_count: agentCounts.active_count,
        paused_count: agentCounts.paused_count
      },
      funnel: {
        signups_30d: funnelSummary.signups_30d,
        first_agents_30d: funnelSummary.first_agents_30d,
        first_tasks_30d: funnelSummary.first_tasks_30d,
        total_signups: funnelSummary.total_signups,
        total_first_agents: funnelSummary.total_first_agents,
        total_first_tasks: funnelSummary.total_first_tasks,
        d7_retained: d7Retained
      },
      page_views: pageViewStats,
      subscribers: subscriberStats,
      nps: npsStats
    });
  });

  app.get("/api/internal/monitoring/readiness", async (c) => {
    const checks = await runReadinessChecks(deps);
    const isReady = checks.every((c) => c.ok);

    return c.json(
      {
        ready: isReady,
        checks,
        checked_at: new Date().toISOString()
      },
      isReady ? 200 : 503
    );
  });

  app.get("/api/internal/monitoring/liveness", async (c) => {
    return c.json({
      alive: true,
      uptime_seconds: process.uptime(),
      timestamp: new Date().toISOString()
    });
  });
}

interface ReadinessCheck {
  name: string;
  ok: boolean;
  detail?: string | undefined;
  latency_ms?: number;
}

async function runReadinessChecks(deps: AppDeps): Promise<ReadinessCheck[]> {
  const checks: ReadinessCheck[] = [];

  const supabaseStart = Date.now();
  try {
    const { error } = await deps.db
      .from("customers")
      .select("customer_id", { head: true, count: "exact" })
      .limit(1);
    checks.push({
      name: "supabase",
      ok: !error,
      detail: error?.message,
      latency_ms: Date.now() - supabaseStart
    });
  } catch (err) {
    checks.push({
      name: "supabase",
      ok: false,
      detail: err instanceof Error ? err.message : String(err),
      latency_ms: Date.now() - supabaseStart
    });
  }

  try {
    const result = await deps.clients.paperclip.ping();
    checks.push({
      name: "paperclip_api",
      ok: result.ok,
      detail: result.version
    });
  } catch (err) {
    checks.push({
      name: "paperclip_api",
      ok: false,
      detail: err instanceof Error ? err.message : String(err)
    });
  }

  const gatewayUrl = deps.env.OPENCLAW_GATEWAY_URL ?? "";
  const isLocalGateway = /(?:127\.0\.0\.1|localhost)/i.test(gatewayUrl);

  if (deps.env.NODE_ENV === "production" && isLocalGateway) {
    checks.push({
      name: "openclaw_gateway",
      ok: true,
      detail: "skipped: non-colocated production (gateway url is localhost)"
    });
  } else {
    try {
      const status = await deps.clients.openclaw.gatewayStatus();
      checks.push({
        name: "openclaw_gateway",
        ok: status.running === true,
        detail: status.listening ?? undefined
      });
    } catch (err) {
      checks.push({
        name: "openclaw_gateway",
        ok: false,
        detail: err instanceof Error ? err.message : String(err)
      });
    }
  }

  return checks;
}

interface IntegrationSummary {
  status: string;
  checks: Record<string, { ok: boolean; [key: string]: unknown }>;
}

async function fetchIntegrationHealth(deps: AppDeps): Promise<IntegrationSummary> {
  try {
    const resp = await fetch(`http://127.0.0.1:${deps.env.PORT}/api/internal/health/integration`);
    if (!resp.ok) {
      return { status: "down", checks: {} };
    }
    return (await resp.json()) as IntegrationSummary;
  } catch {
    return { status: "unknown", checks: {} };
  }
}

interface CredentialSummary {
  status: string;
  providers: Record<string, unknown>;
}

async function fetchCredentialHealth(deps: AppDeps): Promise<CredentialSummary> {
  try {
    const resp = await fetch(`http://127.0.0.1:${deps.env.PORT}/api/internal/health/credentials`);
    if (!resp.ok) {
      return { status: "unknown", providers: {} };
    }
    return (await resp.json()) as CredentialSummary;
  } catch {
    return { status: "unknown", providers: {} };
  }
}
