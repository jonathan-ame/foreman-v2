import { getAgentStatusCounts, listAgentsForHealthCheck, updateAgentHealth, type Agent } from "../db/agents.js";
import { insertNotification } from "../db/notifications.js";
import type { AppDeps } from "../app-deps.js";
import type { JobResult } from "./types.js";

const FAILURE_THRESHOLD = 3;

interface ParsedHealthResult {
  failure_streak: number;
}

interface GatewayHealthResult {
  ok: boolean;
  detail: string;
}

const parsePreviousHealth = (raw: string | null | undefined): ParsedHealthResult => {
  if (!raw) {
    return { failure_streak: 0 };
  }
  try {
    const parsed = JSON.parse(raw) as { failure_streak?: unknown };
    return {
      failure_streak: typeof parsed.failure_streak === "number" ? parsed.failure_streak : 0
    };
  } catch {
    return { failure_streak: 0 };
  }
};

const determineGatewayHealth = async (deps: AppDeps, agent: Agent): Promise<GatewayHealthResult> => {
  try {
    const paperclipAgent = await deps.clients.paperclip.getAgent(agent.paperclip_agent_id);
    if (paperclipAgent.adapterType !== "openclaw_gateway") {
      return { ok: false, detail: `unexpected_adapter_type:${paperclipAgent.adapterType}` };
    }
    if (paperclipAgent.status && paperclipAgent.status.toLowerCase() === "error") {
      return { ok: false, detail: "paperclip_status:error" };
    }
    return { ok: true, detail: `paperclip_status:${paperclipAgent.status ?? "ok"}` };
  } catch (error) {
    return {
      ok: false,
      detail: `paperclip_error:${error instanceof Error ? error.message : String(error)}`
    };
  }
};

export async function runAgentHealthCheckJob(deps: AppDeps): Promise<JobResult> {
  const logger = deps.logger.child({ jobName: "agent_health_check" });
  const agents = await listAgentsForHealthCheck(deps.db);
  if (agents.length === 0) {
    return {
      jobName: "agent_health_check",
      status: "noop",
      message: "no agents in active or paused state"
    };
  }

  let pausedTransitions = 0;
  let recoveredTransitions = 0;
  let healthyChecks = 0;
  let failedChecks = 0;

  for (const agent of agents) {
    const checkedAt = new Date().toISOString();
    const previous = parsePreviousHealth(agent.last_health_check_result);
    const health = await determineGatewayHealth(deps, agent);
    const nextFailureStreak = health.ok ? 0 : previous.failure_streak + 1;

    let nextStatus: "active" | "paused" = agent.current_status === "paused" ? "paused" : "active";
    if (agent.current_status === "active" && !health.ok && nextFailureStreak >= FAILURE_THRESHOLD) {
      nextStatus = "paused";
      pausedTransitions += 1;
      await insertNotification(deps.db, {
        workspace_slug: agent.workspace_slug,
        type: "agent_paused_health",
        title: "Agent paused after health check failures",
        body: `${agent.display_name} was paused after ${nextFailureStreak} consecutive gateway health check failures.`,
        reference_id: agent.agent_id,
        reference_type: "agent"
      });
      logger.warn(
        { agentId: agent.agent_id, openclawAgentId: agent.openclaw_agent_id, failureStreak: nextFailureStreak },
        "agent paused due to consecutive health-check failures"
      );
    } else if (agent.current_status === "paused" && health.ok) {
      nextStatus = "active";
      recoveredTransitions += 1;
      await insertNotification(deps.db, {
        workspace_slug: agent.workspace_slug,
        type: "agent_recovered_health",
        title: "Agent recovered and resumed",
        body: `${agent.display_name} passed health checks and was resumed automatically.`,
        reference_id: agent.agent_id,
        reference_type: "agent"
      });
    }

    if (health.ok) {
      healthyChecks += 1;
    } else {
      failedChecks += 1;
    }

    await updateAgentHealth(deps.db, agent.agent_id, {
      current_status: nextStatus,
      last_health_check_at: checkedAt,
      last_health_check_result: JSON.stringify({
        ok: health.ok,
        detail: health.detail,
        failure_streak: nextFailureStreak,
        checked_at: checkedAt
      })
    });
  }

  const counts = await getAgentStatusCounts(deps.db);
  return {
    jobName: "agent_health_check",
    status: "ok",
    message: "agent health check run completed",
    details: {
      checked: agents.length,
      healthyChecks,
      failedChecks,
      pausedTransitions,
      recoveredTransitions,
      active_count: counts.active_count,
      paused_count: counts.paused_count
    }
  };
}
