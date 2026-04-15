import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { AppDeps } from "../app-deps.js";
import { createLogger } from "../config/logger.js";
import { runOpenClawAbsorptionRepairJob } from "./openclaw-absorption-repair.js";

const tempRoots: string[] = [];

afterEach(async () => {
  for (const root of tempRoots) {
    await rm(root, { recursive: true, force: true });
  }
  tempRoots.length = 0;
});

const makeDeps = (
  openclawConfigPath: string,
  includePath: string,
  reloadImpl: () => Promise<void> = async () => undefined,
  restartImpl: () => Promise<void> = async () => undefined
) =>
  ({
    logger: createLogger("absorption-repair-test"),
    env: {
      OPENCLAW_CONFIG_PATH: openclawConfigPath,
      OPENCLAW_INCLUDE_PATH: includePath
    },
    clients: {
      openclaw: {
        reloadSecrets: vi.fn(reloadImpl),
        restartGateway: vi.fn(restartImpl)
      }
    }
  }) as unknown as AppDeps;

describe("runOpenClawAbsorptionRepairJob", () => {
  it("repairs root config, moves inlined keys to include, and reloads secrets", async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), "absorb-repair-"));
    tempRoots.push(root);
    const openclawConfigPath = path.join(root, "openclaw.json");
    const includePath = path.join(root, "foreman.json5");

    await writeFile(
      openclawConfigPath,
      JSON.stringify(
        {
          env: { vars: { OPENROUTER_API_KEY: "test" } },
          agents: { list: [{ id: "ceo" }] },
          gateway: { auth: { token: "tok" } }
        },
        null,
        2
      )
    );
    await writeFile(includePath, JSON.stringify({ models: { providers: { openrouter: {} } } }, null, 2));

    const deps = makeDeps(openclawConfigPath, includePath);
    const result = await runOpenClawAbsorptionRepairJob(deps);
    const repairedRoot = JSON.parse(await readFile(openclawConfigPath, "utf8")) as Record<string, unknown>;
    const repairedInclude = JSON.parse(await readFile(includePath, "utf8")) as Record<string, unknown>;

    expect(result.status).toBe("ok");
    expect(repairedRoot.$include).toBe("./foreman.json5");
    expect(repairedRoot.env).toBeUndefined();
    expect(repairedRoot.agents).toBeUndefined();
    expect((repairedInclude.env as { vars: Record<string, string> }).vars.OPENROUTER_API_KEY).toBe("test");
    expect((repairedInclude.agents as { list: Array<{ id: string }> }).list[0]?.id).toBe("ceo");
    expect((deps.clients.openclaw.reloadSecrets as ReturnType<typeof vi.fn>).mock.calls.length).toBe(1);
    expect((deps.clients.openclaw.restartGateway as ReturnType<typeof vi.fn>).mock.calls.length).toBe(0);
  });

  it("returns noop when config is already clean", async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), "absorb-clean-"));
    tempRoots.push(root);
    const openclawConfigPath = path.join(root, "openclaw.json");
    const includePath = path.join(root, "foreman.json5");

    await writeFile(
      openclawConfigPath,
      JSON.stringify(
        {
          $include: "./foreman.json5",
          gateway: { auth: { token: "tok" } }
        },
        null,
        2
      )
    );
    await writeFile(includePath, JSON.stringify({ agents: { list: [{ id: "ceo" }] } }, null, 2));

    const deps = makeDeps(openclawConfigPath, includePath);
    const result = await runOpenClawAbsorptionRepairJob(deps);
    expect(result.status).toBe("noop");
    expect((deps.clients.openclaw.reloadSecrets as ReturnType<typeof vi.fn>).mock.calls.length).toBe(0);
  });

  it("falls back to gateway restart when reload fails", async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), "absorb-fallback-"));
    tempRoots.push(root);
    const openclawConfigPath = path.join(root, "openclaw.json");
    const includePath = path.join(root, "foreman.json5");

    await writeFile(
      openclawConfigPath,
      JSON.stringify(
        {
          env: { vars: { OPENROUTER_API_KEY: "test" } },
          gateway: { auth: { token: "tok" } }
        },
        null,
        2
      )
    );
    await writeFile(includePath, JSON.stringify({ agents: { list: [] } }, null, 2));

    const deps = makeDeps(
      openclawConfigPath,
      includePath,
      async () => {
        throw new Error("reload failed");
      },
      async () => undefined
    );

    const result = await runOpenClawAbsorptionRepairJob(deps);
    expect(result.status).toBe("ok");
    expect((deps.clients.openclaw.reloadSecrets as ReturnType<typeof vi.fn>).mock.calls.length).toBe(1);
    expect((deps.clients.openclaw.restartGateway as ReturnType<typeof vi.fn>).mock.calls.length).toBe(1);
  });

  it("restores backups when reload and restart fail", async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), "absorb-fail-"));
    tempRoots.push(root);
    const openclawConfigPath = path.join(root, "openclaw.json");
    const includePath = path.join(root, "foreman.json5");

    const originalRoot = JSON.stringify(
      {
        env: { vars: { OPENROUTER_API_KEY: "test" } },
        gateway: { auth: { token: "tok" } }
      },
      null,
      2
    );
    const originalInclude = JSON.stringify({ agents: { list: [] } }, null, 2);
    await writeFile(openclawConfigPath, originalRoot);
    await writeFile(includePath, originalInclude);

    const deps = makeDeps(
      openclawConfigPath,
      includePath,
      async () => {
        throw new Error("reload failed");
      },
      async () => {
        throw new Error("restart failed");
      }
    );

    await expect(runOpenClawAbsorptionRepairJob(deps)).rejects.toThrow("restart failed");
    expect(await readFile(openclawConfigPath, "utf8")).toContain('"env"');
    expect(await readFile(includePath, "utf8")).toBe(originalInclude);
  });
});
