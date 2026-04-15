import { describe, expect, it, vi } from "vitest";
import type { AppDeps } from "../app-deps.js";
import { createLogger } from "../config/logger.js";
import { runIdempotencyCleanupJob } from "./idempotency-cleanup.js";

describe("runIdempotencyCleanupJob", () => {
  const makeDeps = (ltImpl: () => Promise<{ error: { message: string } | null; count: number | null }>) => {
    const lt = vi.fn(ltImpl);
    const del = vi.fn(() => ({ lt }));
    const from = vi.fn(() => ({ delete: del }));
    return {
      deps: {
        logger: createLogger("idempotency-cleanup-test"),
        db: { from } as unknown as AppDeps["db"]
      } as AppDeps,
      from,
      del,
      lt
    };
  };

  it("returns ok when rows are deleted", async () => {
    const { deps, from, del, lt } = makeDeps(async () => ({ error: null, count: 4 }));
    const result = await runIdempotencyCleanupJob(deps);

    expect(from).toHaveBeenCalledWith("provisioning_idempotency");
    expect(del).toHaveBeenCalledWith({ count: "exact" });
    expect(lt).toHaveBeenCalledTimes(1);
    expect(result.status).toBe("ok");
    expect(result.details?.deletedRows).toBe(4);
  });

  it("returns noop when no rows are deleted", async () => {
    const { deps } = makeDeps(async () => ({ error: null, count: 0 }));
    const result = await runIdempotencyCleanupJob(deps);
    expect(result.status).toBe("noop");
  });

  it("throws when delete query fails", async () => {
    const { deps } = makeDeps(async () => ({ error: { message: "db down" }, count: null }));
    await expect(runIdempotencyCleanupJob(deps)).rejects.toThrow("idempotency cleanup failed: db down");
  });
});
