import type { AppDeps } from "../app-deps.js";
import type { JobResult } from "./types.js";
import { getAgentStatusCounts } from "../db/agents.js";
import { insertNotification } from "../db/notifications.js";
import { getSubscriberStats } from "../db/email-subscribers.js";
import { getPageViewStats } from "../db/page-views.js";

interface AlertRule {
  name: string;
  check: (deps: AppDeps) => Promise<AlertEvaluation>;
}

interface AlertEvaluation {
  firing: boolean;
  severity: "critical" | "warning" | "info";
  message: string;
  details?: Record<string, unknown>;
}

const ALERT_COOLDOWN_MS = 15 * 60 * 1000;
const alertLastFiredAt = new Map<string, number>();

const checkSupabaseConnectivity = async (deps: AppDeps): Promise<AlertEvaluation> => {
  try {
    const start = Date.now();
    const { error } = await deps.db
      .from("customers")
      .select("customer_id", { head: true, count: "exact" })
      .limit(1);
    if (error) {
      return {
        firing: true,
        severity: "critical",
        message: `Supabase query failed: ${error.message}`,
        details: { latency_ms: Date.now() - start }
      };
    }
    const latency = Date.now() - start;
    if (latency > 2000) {
      return {
        firing: true,
        severity: "warning",
        message: `Supabase latency high: ${latency}ms`,
        details: { latency_ms: latency }
      };
    }
    return { firing: false, severity: "info", message: "Supabase OK" };
  } catch (err) {
    return {
      firing: true,
      severity: "critical",
      message: `Supabase unreachable: ${err instanceof Error ? err.message : String(err)}`
    };
  }
};

const checkPaperclipApi = async (deps: AppDeps): Promise<AlertEvaluation> => {
  try {
    const result = await deps.clients.paperclip.ping();
    if (!result.ok) {
      return {
        firing: true,
        severity: "critical",
        message: "Paperclip API ping failed"
      };
    }
    return { firing: false, severity: "info", message: "Paperclip API OK" };
  } catch (err) {
    return {
      firing: true,
      severity: "critical",
      message: `Paperclip API unreachable: ${err instanceof Error ? err.message : String(err)}`
    };
  }
};

const checkOpenClawGateway = async (deps: AppDeps): Promise<AlertEvaluation> => {
  try {
    const status = await deps.clients.openclaw.gatewayStatus();
    if (!status.running) {
      return {
        firing: true,
        severity: "critical",
        message: "OpenClaw gateway not running"
      };
    }
    return { firing: false, severity: "info", message: "OpenClaw gateway OK" };
  } catch (err) {
    return {
      firing: true,
      severity: "critical",
      message: `OpenClaw gateway unreachable: ${err instanceof Error ? err.message : String(err)}`
    };
  }
};

const checkPausedAgents = async (deps: AppDeps): Promise<AlertEvaluation> => {
  try {
    const counts = await getAgentStatusCounts(deps.db);
    if (counts.paused_count > 0 && counts.paused_count >= counts.active_count * 0.5) {
      return {
        firing: true,
        severity: "warning",
        message: `High agent pause ratio: ${counts.paused_count} paused vs ${counts.active_count} active`,
        details: { paused_count: counts.paused_count, active_count: counts.active_count }
      };
    }
    if (counts.paused_count > 3) {
      return {
        firing: true,
        severity: "warning",
        message: `${counts.paused_count} agents paused`,
        details: { paused_count: counts.paused_count, active_count: counts.active_count }
      };
    }
    return {
      firing: false,
      severity: "info",
      message: `Agent health OK: ${counts.active_count} active, ${counts.paused_count} paused`
    };
  } catch (err) {
    return {
      firing: true,
      severity: "warning",
      message: `Cannot check agent counts: ${err instanceof Error ? err.message : String(err)}`
    };
  }
};

const checkFormSubmissionDrop = async (deps: AppDeps): Promise<AlertEvaluation> => {
  try {
    const stats = await getSubscriberStats(deps.db);
    if (stats.new_7d === 0 && stats.total_active > 0) {
      return {
        firing: true,
        severity: "warning",
        message: "Zero new form submissions in the last 7 days",
        details: { total_active: stats.total_active, new_7d: stats.new_7d }
      };
    }
    return { firing: false, severity: "info", message: "Form submissions OK" };
  } catch (err) {
    return {
      firing: false,
      severity: "info",
      message: `Cannot check form submissions: ${err instanceof Error ? err.message : String(err)}`
    };
  }
};

const checkSiteTrafficDrop = async (deps: AppDeps): Promise<AlertEvaluation> => {
  try {
    const stats = await getPageViewStats(deps.db);
    if (stats.total_7d === 0) {
      return {
        firing: true,
        severity: "warning",
        message: "Zero page views in the last 7 days — site traffic tracking may be broken",
        details: { total_7d: stats.total_7d, total_1d: stats.total_1d }
      };
    }
    if (stats.total_1d === 0 && stats.total_7d > 10) {
      return {
        firing: true,
        severity: "warning",
        message: "Zero page views in last 24h despite traffic in prior days — possible tracking failure",
        details: { total_1d: stats.total_1d, total_7d: stats.total_7d }
      };
    }
    return { firing: false, severity: "info", message: "Site traffic OK" };
  } catch (err) {
    return {
      firing: false,
      severity: "info",
      message: `Cannot check site traffic: ${err instanceof Error ? err.message : String(err)}`
    };
  }
};

const ALERT_RULES: AlertRule[] = [
  { name: "supabase_connectivity", check: checkSupabaseConnectivity },
  { name: "paperclip_api", check: checkPaperclipApi },
  { name: "openclaw_gateway", check: checkOpenClawGateway },
  { name: "paused_agents", check: checkPausedAgents },
  { name: "form_submission_drop", check: checkFormSubmissionDrop },
  { name: "site_traffic_drop", check: checkSiteTrafficDrop }
];

export async function runMonitoringAlertsJob(deps: AppDeps): Promise<JobResult> {
  const logger = deps.logger.child({ jobName: "monitoring_alerts" });
  const firingAlerts: Array<{ name: string; severity: string; message: string }> = [];
  const resolvedAlerts: string[] = [];

  for (const rule of ALERT_RULES) {
    try {
      const evaluation = await rule.check(deps);

      if (evaluation.firing) {
        const lastFired = alertLastFiredAt.get(rule.name) ?? 0;
        const now = Date.now();

        if (now - lastFired > ALERT_COOLDOWN_MS) {
          logger.warn(
            { alertName: rule.name, severity: evaluation.severity, message: evaluation.message },
            "alert firing"
          );

          if (evaluation.severity === "critical") {
            try {
              await insertNotification(deps.db, {
                workspace_slug: "system",
                type: "agent_paused_health",
                title: `[ALERT] ${rule.name}: ${evaluation.severity}`,
                body: evaluation.message,
                reference_type: "monitoring_alert"
              });
            } catch (notifErr) {
              logger.error({ err: notifErr }, "failed to write alert notification");
            }
          }

          alertLastFiredAt.set(rule.name, now);
        }

        firingAlerts.push({
          name: rule.name,
          severity: evaluation.severity,
          message: evaluation.message
        });
      } else {
        const wasFiring = alertLastFiredAt.has(rule.name);
        if (wasFiring) {
          alertLastFiredAt.delete(rule.name);
          resolvedAlerts.push(rule.name);
          logger.info({ alertName: rule.name }, "alert resolved");
        }
      }
    } catch (err) {
      logger.error({ alertName: rule.name, err }, "alert check threw unexpectedly");
      firingAlerts.push({
        name: rule.name,
        severity: "warning",
        message: `Alert check failed: ${err instanceof Error ? err.message : String(err)}`
      });
    }
  }

  return {
    jobName: "monitoring_alerts",
    status: firingAlerts.some((a) => a.severity === "critical")
      ? "error"
      : firingAlerts.length > 0
        ? "ok"
        : "ok",
    message: firingAlerts.length > 0
      ? `${firingAlerts.length} alert(s) firing, ${resolvedAlerts.length} resolved`
      : "all clear",
    details: {
      firing: firingAlerts,
      resolved: resolvedAlerts
    }
  };
}
