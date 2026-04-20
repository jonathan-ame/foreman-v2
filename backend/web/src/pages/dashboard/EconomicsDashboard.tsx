import { useEffect, useState } from "react";

interface FunnelMetrics {
  signups_30d: number;
  first_agents_30d: number;
  first_tasks_30d: number;
  total_signups: number;
  total_first_agents: number;
  total_first_tasks: number;
  d7_retained: number;
}

interface NpsMetrics {
  response_count: number;
  avg_score: number | null;
  promoters: number;
  passives: number;
  detractors: number;
  nps_score: number | null;
  responses_30d: number;
}

interface EconomicsData {
  mrr_cents: number;
  mrr_usd: string;
  active_customers: number;
  arpu_cents: number;
  arpu_usd: string;
  churn_rate_30d_pct: number;
  canceled_last_30d: number;
  surcharge_attach_rate_pct: number;
  workspaces_with_surcharge: number;
  funnel: FunnelMetrics;
  nps: NpsMetrics;
  computed_at: string;
}

function MetricCard({ label, value, sub }: { label: string; value: string; sub?: string }) {
  return (
    <div className="ec-metric-card">
      <span className="ec-metric-label">{label}</span>
      <span className="ec-metric-value">{value}</span>
      {sub && <span className="ec-metric-sub">{sub}</span>}
    </div>
  );
}

function FunnelBar({
  label,
  count,
  total
}: {
  label: string;
  count: number;
  total: number;
}) {
  const pct = total > 0 ? Math.round((count / total) * 100) : 0;
  return (
    <div className="ec-funnel-row">
      <span className="ec-funnel-label">{label}</span>
      <div className="ec-funnel-bar-wrap">
        <div className="ec-funnel-bar" style={{ width: `${pct}%` }} />
      </div>
      <span className="ec-funnel-count">
        {count} <span className="ec-funnel-pct">({pct}%)</span>
      </span>
    </div>
  );
}

export function EconomicsDashboard() {
  const [data, setData] = useState<EconomicsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const load = async () => {
      try {
        const res = await fetch("/api/internal/metrics/economics", { credentials: "include" });
        if (!res.ok) {
          setError("Failed to load metrics.");
          return;
        }
        const json = (await res.json()) as EconomicsData;
        setData(json);
      } catch {
        setError("Network error loading metrics.");
      } finally {
        setLoading(false);
      }
    };
    void load();
  }, []);

  if (loading) {
    return (
      <div className="ec-page">
        <p className="ec-loading">Loading metrics…</p>
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="ec-page">
        <p className="ec-error">{error ?? "No data."}</p>
      </div>
    );
  }

  const funnelBase = data.funnel.signups_30d || 1;
  const npsLabel = data.nps.nps_score !== null
    ? `${data.nps.nps_score}`
    : "—";
  const npsColor =
    data.nps.nps_score === null ? "#6b7280"
      : data.nps.nps_score >= 50 ? "#16a34a"
      : data.nps.nps_score >= 0 ? "#d97706"
      : "#dc2626";

  return (
    <div className="ec-page">
      <header className="ec-header">
        <h1 className="ec-title">Economics</h1>
        <span className="ec-updated">
          Updated {new Date(data.computed_at).toLocaleTimeString()}
        </span>
      </header>

      <section className="ec-section">
        <h2 className="ec-section-title">Revenue</h2>
        <div className="ec-metric-grid">
          <MetricCard label="MRR" value={`$${data.mrr_usd}`} />
          <MetricCard label="Active customers" value={String(data.active_customers)} />
          <MetricCard label="ARPU" value={`$${data.arpu_usd}/mo`} />
          <MetricCard
            label="Surcharge attach"
            value={`${data.surcharge_attach_rate_pct.toFixed(1)}%`}
            sub={`${data.workspaces_with_surcharge} workspaces`}
          />
        </div>
      </section>

      <section className="ec-section">
        <h2 className="ec-section-title">Retention</h2>
        <div className="ec-metric-grid">
          <MetricCard
            label="Churn rate (30d)"
            value={`${data.churn_rate_30d_pct.toFixed(1)}%`}
            sub={`${data.canceled_last_30d} canceled`}
          />
          <MetricCard label="D7 retained" value={String(data.funnel.d7_retained)} />
        </div>
      </section>

      <section className="ec-section">
        <h2 className="ec-section-title">Activation funnel (last 30 days)</h2>
        <div className="ec-funnel">
          <FunnelBar label="Signup" count={data.funnel.signups_30d} total={funnelBase} />
          <FunnelBar label="First agent running" count={data.funnel.first_agents_30d} total={funnelBase} />
          <FunnelBar label="First task started" count={data.funnel.first_tasks_30d} total={funnelBase} />
        </div>
        <div className="ec-funnel-totals">
          <span>All time: {data.funnel.total_signups} signups → {data.funnel.total_first_agents} agents → {data.funnel.total_first_tasks} first tasks</span>
        </div>
      </section>

      <section className="ec-section">
        <h2 className="ec-section-title">NPS</h2>
        <div className="ec-nps-row">
          <div className="ec-nps-score" style={{ color: npsColor }}>
            {npsLabel}
          </div>
          <div className="ec-nps-breakdown">
            <span className="ec-nps-promoters">Promoters: {data.nps.promoters}</span>
            <span className="ec-nps-passives">Passives: {data.nps.passives}</span>
            <span className="ec-nps-detractors">Detractors: {data.nps.detractors}</span>
            <span className="ec-nps-total">{data.nps.response_count} total responses</span>
          </div>
        </div>
      </section>
    </div>
  );
}
