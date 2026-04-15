import { readdir, rm, stat } from "node:fs/promises";
import type { Dirent, Stats } from "node:fs";
import path from "node:path";
import type { AppDeps } from "../app-deps.js";
import type { JobResult } from "./types.js";

const WORKSPACE_PREFIX = "workspace-";
const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;

interface FsOps {
  readdir: (dirPath: string, options: { withFileTypes: true }) => Promise<Dirent[]>;
  stat: (targetPath: string) => Promise<Stats>;
  rm: (targetPath: string, options: { recursive: true; force: true }) => Promise<void>;
}

const defaultFsOps: FsOps = {
  readdir,
  stat,
  rm
};

export async function runOrphanWorkspaceCleanupJob(
  deps: AppDeps,
  fsOps: FsOps = defaultFsOps
): Promise<JobResult> {
  const logger = deps.logger.child({ jobName: "orphan_workspace_cleanup" });
  const openclawDir = path.dirname(deps.env.OPENCLAW_CONFIG_PATH);
  const now = Date.now();
  const graceCutoff = now - SEVEN_DAYS_MS;

  const entries = await fsOps.readdir(openclawDir, { withFileTypes: true });
  const workspaceDirs = entries.filter((entry) => entry.isDirectory() && entry.name.startsWith(WORKSPACE_PREFIX));

  if (workspaceDirs.length === 0) {
    logger.info("no workspace directories found");
    return {
      jobName: "orphan_workspace_cleanup",
      status: "noop",
      message: "no workspace directories found"
    };
  }

  let deleted = 0;
  let skippedActive = 0;
  let skippedGrace = 0;
  const failures: Array<{ workspace: string; error: string }> = [];

  for (const directory of workspaceDirs) {
    const workspaceName = directory.name;
    const openclawAgentId = workspaceName.slice(WORKSPACE_PREFIX.length);
    const workspacePath = path.join(openclawDir, workspaceName);

    try {
      const { data, error } = await deps.db
        .from("agents")
        .select("openclaw_agent_id")
        .eq("openclaw_agent_id", openclawAgentId)
        .eq("current_status", "active")
        .limit(1);
      if (error) {
        throw new Error(error.message);
      }
      if ((data ?? []).length > 0) {
        skippedActive += 1;
        logger.debug({ workspacePath, openclawAgentId }, "workspace retained: active agent found");
        continue;
      }

      const stats = await fsOps.stat(workspacePath);
      if (stats.mtimeMs > graceCutoff) {
        skippedGrace += 1;
        logger.debug({ workspacePath, openclawAgentId }, "workspace retained: within grace period");
        continue;
      }

      await fsOps.rm(workspacePath, { recursive: true, force: true });
      deleted += 1;
      logger.info({ workspacePath, openclawAgentId }, "deleted orphan workspace directory");
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      failures.push({ workspace: workspacePath, error: message });
      logger.warn({ workspacePath, openclawAgentId, err: error }, "failed to evaluate/delete workspace");
    }
  }

  const status = failures.length > 0 ? "error" : deleted > 0 ? "ok" : "noop";
  return {
    jobName: "orphan_workspace_cleanup",
    status,
    message:
      failures.length > 0
        ? "workspace cleanup completed with errors"
        : deleted > 0
          ? "deleted orphan workspaces"
          : "no orphan workspaces eligible for cleanup",
    details: {
      scanned: workspaceDirs.length,
      deleted,
      skippedActive,
      skippedGrace,
      failures
    }
  };
}
