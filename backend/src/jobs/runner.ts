import cron, { type ScheduledTask } from "node-cron";
import type { AppDeps } from "../app-deps.js";
import { runAgentHealthCheckJob } from "./agent-health-check.js";
import { runByokKeyHealthCheckJob } from "./byok-key-health-check.js";
import { runIdempotencyCleanupJob } from "./idempotency-cleanup.js";
import { runOpenClawAbsorptionRepairJob } from "./openclaw-absorption-repair.js";
import { runOrphanWorkspaceCleanupJob } from "./orphan-workspace-cleanup.js";
import { runPaperclipUsageReconcileJob } from "./paperclip-usage-reconcile.js";
import type { JobDefinition, JobResult } from "./types.js";

const JOBS: JobDefinition[] = [
  {
    name: "openclaw_config_absorption_repair",
    schedule: "0 3 * * *",
    run: runOpenClawAbsorptionRepairJob
  },
  {
    name: "provisioning_idempotency_cleanup",
    schedule: "0 * * * *",
    run: runIdempotencyCleanupJob
  },
  {
    name: "orphan_workspace_cleanup",
    schedule: "30 3 * * *",
    run: runOrphanWorkspaceCleanupJob
  },
  {
    name: "agent_health_check",
    schedule: "*/5 * * * *",
    run: runAgentHealthCheckJob
  },
  {
    name: "byok_key_health_check",
    schedule: "0 * * * *",
    run: runByokKeyHealthCheckJob
  },
  {
    name: "paperclip_usage_reconcile",
    schedule: "0 */4 * * *",
    run: runPaperclipUsageReconcileJob
  }
];

export const JOB_NAMES = JOBS.map((job) => job.name);

export function getJobDefinition(name: string): JobDefinition | undefined {
  return JOBS.find((job) => job.name === name);
}

export async function runJobByName(name: string, deps: AppDeps): Promise<JobResult> {
  const definition = getJobDefinition(name);
  if (!definition) {
    throw new Error(`Unknown job '${name}'. Known jobs: ${JOB_NAMES.join(", ")}`);
  }
  return definition.run(deps);
}

export function startJobs(deps: AppDeps): { stop: () => void } {
  const logger = deps.logger.child({ subsystem: "jobs" });
  const scheduledTasks: ScheduledTask[] = [];

  for (const job of JOBS) {
    const task = cron.schedule(
      job.schedule,
      async () => {
        try {
          const result = await job.run(deps);
          logger.info({ jobName: job.name, result }, "scheduled job completed");
        } catch (error) {
          logger.error({ jobName: job.name, err: error }, "scheduled job failed");
        }
      },
      {
        timezone: "UTC"
      }
    );
    scheduledTasks.push(task);
    logger.info({ jobName: job.name, schedule: job.schedule, timezone: "UTC" }, "scheduled job registered");
  }

  return {
    stop: () => {
      for (const task of scheduledTasks) {
        task.stop();
      }
      logger.info("all scheduled jobs stopped");
    }
  };
}
