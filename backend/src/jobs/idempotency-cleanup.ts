import type { AppDeps } from "../app-deps.js";
import type { JobResult } from "./types.js";

export async function runIdempotencyCleanupJob(deps: AppDeps): Promise<JobResult> {
  const logger = deps.logger.child({ jobName: "provisioning_idempotency_cleanup" });
  const nowIso = new Date().toISOString();
  const { error, count } = await deps.db
    .from("provisioning_idempotency")
    .delete({ count: "exact" })
    .lt("expires_at", nowIso);

  if (error) {
    logger.error({ err: error }, "idempotency cleanup failed");
    throw new Error(`idempotency cleanup failed: ${error.message}`);
  }

  logger.info({ deletedRows: count ?? 0 }, "idempotency cleanup completed");
  return {
    jobName: "provisioning_idempotency_cleanup",
    status: count && count > 0 ? "ok" : "noop",
    message: count && count > 0 ? "expired idempotency rows deleted" : "no expired idempotency rows found",
    details: { deletedRows: count ?? 0 }
  };
}
