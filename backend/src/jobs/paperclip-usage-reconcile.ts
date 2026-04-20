import { getAgentUsageTotalsSince } from "../db/agent-usage-events.js";
import { recordFunnelEvent } from "../db/funnel-events.js";
import type { AppDeps } from "../app-deps.js";
import type { JobResult } from "./types.js";

const RECONCILE_WINDOW_HOURS = 4;
const DRIFT_THRESHOLD_PCT = 0.01;
const LAST_RESULT_KEY = "paperclip_usage_reconcile_last";

interface ReconcileStats {
  window_start: string;
  agents_checked: number;
  agents_drifted: number;
  max_drift_pct: number;
  patched: string[];
  errors: string[];
}

interface AgentRecord {
  agent_id: string;
  paperclip_agent_id: string;
  surcharge_accrued_current_period_cents: number | null;
}

export let lastReconcileResult: ReconcileStats | null = null;

export async function runPaperclipUsageReconcileJob(deps: AppDeps): Promise<JobResult> {
  const logger = deps.logger.child({ jobName: "paperclip_usage_reconcile" });
  const windowStart = new Date(Date.now() - RECONCILE_WINDOW_HOURS * 60 * 60 * 1000).toISOString();

  const stats: ReconcileStats = {
    window_start: windowStart,
    agents_checked: 0,
    agents_drifted: 0,
    max_drift_pct: 0,
    patched: [],
    errors: []
  };

  try {
    // Aggregate usage events recorded in the window
    const eventTotals = await getAgentUsageTotalsSince(deps.db, windowStart);
    if (eventTotals.length === 0) {
      lastReconcileResult = stats;
      return {
        jobName: "paperclip_usage_reconcile",
        status: "noop",
        message: "no usage events in reconciliation window"
      };
    }

    // Fetch corresponding agent counter rows
    const paperclipAgentIds = eventTotals.map((e) => e.paperclip_agent_id);
    const { data: agentRows, error } = await deps.db
      .from("agents")
      .select("agent_id, paperclip_agent_id, surcharge_accrued_current_period_cents, workspace_slug")
      .in("paperclip_agent_id", paperclipAgentIds);

    if (error) {
      throw new Error(`failed to fetch agent rows: ${error.message}`);
    }

    interface AgentRecordFull extends AgentRecord {
      workspace_slug: string;
    }

    const agentMap = new Map<string, AgentRecordFull>();
    for (const row of (agentRows ?? []) as AgentRecordFull[]) {
      agentMap.set(row.paperclip_agent_id, row);
    }

    stats.agents_checked = paperclipAgentIds.length;

    for (const totals of eventTotals) {
      const agent = agentMap.get(totals.paperclip_agent_id);
      if (!agent) {
        stats.errors.push(`agent_not_found:${totals.paperclip_agent_id}`);
        continue;
      }

      const dbCents = agent.surcharge_accrued_current_period_cents ?? 0;
      const eventCents = totals.total_cost_cents;

      // Fire first_task_in_progress funnel event once per workspace when usage appears.
      if (eventCents > 0 && agent.workspace_slug) {
        void recordFunnelEvent(deps.db, agent.workspace_slug, "first_task_in_progress").catch(
          (err: unknown) => {
            logger.warn(
              { err, workspaceSlug: agent.workspace_slug },
              "failed to record first_task_in_progress funnel event"
            );
          }
        );
      }

      if (eventCents === 0 && dbCents === 0) {
        continue;
      }

      const driftPct =
        dbCents === 0 ? 1 : Math.abs(eventCents - dbCents) / Math.max(dbCents, eventCents);

      if (driftPct > stats.max_drift_pct) {
        stats.max_drift_pct = driftPct;
      }

      if (driftPct > DRIFT_THRESHOLD_PCT) {
        stats.agents_drifted++;
        logger.warn(
          {
            paperclipAgentId: totals.paperclip_agent_id,
            dbCents,
            eventCents,
            driftPct: (driftPct * 100).toFixed(2) + "%"
          },
          "usage counter drift detected — patching from event log"
        );

        // Patch the DB counter to match the event log (source of truth for the window)
        const patch = {
          total_tokens_input: totals.total_input_tokens,
          total_tokens_output: totals.total_output_tokens,
          surcharge_accrued_current_period_cents: eventCents
        };
        const { error: patchErr } = await deps.db
          .from("agents")
          .update(patch)
          .eq("agent_id", agent.agent_id);

        if (patchErr) {
          stats.errors.push(`patch_failed:${totals.paperclip_agent_id}:${patchErr.message}`);
        } else {
          stats.patched.push(totals.paperclip_agent_id);
        }
      }
    }
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    logger.error({ err: msg }, "paperclip_usage_reconcile failed");
    lastReconcileResult = stats;
    return {
      jobName: "paperclip_usage_reconcile",
      status: "error",
      message: `reconciliation failed: ${msg}`,
      details: stats as unknown as Record<string, unknown>
    };
  }

  lastReconcileResult = stats;

  const status = stats.errors.length > 0 ? "error" : "ok";
  const msg =
    `checked ${stats.agents_checked} agents in ${RECONCILE_WINDOW_HOURS}h window; ` +
    `${stats.agents_drifted} drifted (max ${(stats.max_drift_pct * 100).toFixed(2)}%); ` +
    `${stats.patched.length} patched`;

  logger.info(stats, "paperclip_usage_reconcile complete");
  return {
    jobName: "paperclip_usage_reconcile",
    status,
    message: msg,
    details: stats as unknown as Record<string, unknown>
  };
}
