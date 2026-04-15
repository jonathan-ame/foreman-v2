import { mkdtemp, mkdir, readdir, rm, stat, utimes } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { AppDeps } from "../app-deps.js";
import { createLogger } from "../config/logger.js";
import { runOrphanWorkspaceCleanupJob } from "./orphan-workspace-cleanup.js";

const tempRoots: string[] = [];

afterEach(async () => {
  for (const root of tempRoots) {
    await rm(root, { recursive: true, force: true });
  }
  tempRoots.length = 0;
});

const makeDb = (activeIds: Set<string>) => {
  let currentAgentId = "";
  const limit = vi.fn(async () => ({
    data: activeIds.has(currentAgentId) ? [{ openclaw_agent_id: currentAgentId }] : [],
    error: null
  }));
  const eqStatus = vi.fn(() => ({ limit }));
  const eqAgent = vi.fn((column: string, value: string) => {
    if (column === "openclaw_agent_id") {
      currentAgentId = value;
    }
    return { eq: eqStatus };
  });
  const select = vi.fn(() => ({ eq: eqAgent }));
  const from = vi.fn(() => ({ select }));
  return { from };
};

const makeDeps = (openclawDir: string, activeIds: string[] = []) =>
  ({
    logger: createLogger("orphan-workspace-cleanup-test"),
    env: {
      OPENCLAW_CONFIG_PATH: path.join(openclawDir, "openclaw.json")
    },
    db: makeDb(new Set(activeIds)) as unknown as AppDeps["db"]
  }) as AppDeps;

describe("runOrphanWorkspaceCleanupJob", () => {
  it("deletes orphaned workspaces older than seven days", async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), "orphan-cleanup-"));
    tempRoots.push(root);

    const oldWorkspace = path.join(root, "workspace-orphan-old");
    const activeWorkspace = path.join(root, "workspace-active-agent");
    const recentWorkspace = path.join(root, "workspace-orphan-recent");
    await mkdir(oldWorkspace);
    await mkdir(activeWorkspace);
    await mkdir(recentWorkspace);

    const now = Date.now();
    const tenDaysAgo = new Date(now - 10 * 24 * 60 * 60 * 1000);
    const oneDayAgo = new Date(now - 24 * 60 * 60 * 1000);
    await utimes(oldWorkspace, tenDaysAgo, tenDaysAgo);
    await utimes(activeWorkspace, tenDaysAgo, tenDaysAgo);
    await utimes(recentWorkspace, oneDayAgo, oneDayAgo);

    const result = await runOrphanWorkspaceCleanupJob(makeDeps(root, ["active-agent"]));

    expect(result.status).toBe("ok");
    await expect(stat(oldWorkspace)).rejects.toThrow();
    await expect(stat(activeWorkspace)).resolves.toBeDefined();
    await expect(stat(recentWorkspace)).resolves.toBeDefined();
    expect(result.details?.deleted).toBe(1);
    expect(result.details?.skippedActive).toBe(1);
    expect(result.details?.skippedGrace).toBe(1);
  });

  it("returns noop when no workspace directories are present", async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), "orphan-cleanup-empty-"));
    tempRoots.push(root);

    const result = await runOrphanWorkspaceCleanupJob(makeDeps(root));
    expect(result.status).toBe("noop");
    expect(result.message).toBe("no workspace directories found");
  });

  it("continues when one workspace delete fails", async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), "orphan-cleanup-fail-"));
    tempRoots.push(root);

    const badWorkspace = path.join(root, "workspace-orphan-fail");
    const goodWorkspace = path.join(root, "workspace-orphan-ok");
    await mkdir(badWorkspace);
    await mkdir(goodWorkspace);

    const tenDaysAgo = new Date(Date.now() - 10 * 24 * 60 * 60 * 1000);
    await utimes(badWorkspace, tenDaysAgo, tenDaysAgo);
    await utimes(goodWorkspace, tenDaysAgo, tenDaysAgo);

    const fsOps = {
      readdir: vi.fn(async (dirPath: string, options: { withFileTypes: true }) => readdir(dirPath, options)),
      stat: vi.fn(async (targetPath: string) => stat(targetPath)),
      rm: vi.fn(async (targetPath: string, options: { recursive: true; force: true }) => {
        if (String(targetPath).includes("workspace-orphan-fail")) {
          throw new Error("simulated rm failure");
        }
        return rm(targetPath, options);
      })
    };

    const result = await runOrphanWorkspaceCleanupJob(makeDeps(root), fsOps);
    expect(result.status).toBe("error");
    expect(result.details?.deleted).toBe(1);
    expect(Array.isArray(result.details?.failures)).toBe(true);
    expect((result.details?.failures as Array<{ error: string }>)[0]?.error).toContain("simulated rm failure");
    await expect(stat(goodWorkspace)).rejects.toThrow();
    await expect(stat(badWorkspace)).resolves.toBeDefined();
  });
});
