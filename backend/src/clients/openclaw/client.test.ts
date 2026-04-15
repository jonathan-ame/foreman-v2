import { EventEmitter } from "node:events";
import { PassThrough } from "node:stream";
import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { createLogger } from "../../config/logger.js";
import { OpenClawClient } from "./client.js";
import {
  OpenClawAgentExistsError,
  OpenClawAgentNotFoundError,
  OpenClawGatewayDownError
} from "./errors.js";

const { spawnMock, readFileMock } = vi.hoisted(() => ({
  spawnMock: vi.fn(),
  readFileMock: vi.fn()
}));

vi.mock("node:child_process", () => ({
  spawn: spawnMock
}));

vi.mock("node:fs/promises", () => ({
  readFile: readFileMock
}));

interface SpawnScenario {
  code?: number;
  stdout?: string;
  stderr?: string;
  error?: Error;
  neverClose?: boolean;
}

const logger = createLogger("openclaw-client-test");

const createChild = (scenario: SpawnScenario) => {
  const proc = new EventEmitter() as EventEmitter & {
    stdout: PassThrough;
    stderr: PassThrough;
    kill: ReturnType<typeof vi.fn>;
  };
  proc.stdout = new PassThrough();
  proc.stderr = new PassThrough();
  proc.kill = vi.fn();

  setImmediate(() => {
    if (scenario.error) {
      proc.emit("error", scenario.error);
      return;
    }
    if (scenario.stdout) {
      proc.stdout.write(scenario.stdout);
    }
    if (scenario.stderr) {
      proc.stderr.write(scenario.stderr);
    }
    proc.stdout.end();
    proc.stderr.end();
    if (!scenario.neverClose) {
      proc.emit("close", scenario.code ?? 0);
    }
  });

  return proc;
};

describe("OpenClawClient", () => {
  beforeEach(() => {
    spawnMock.mockReset();
    readFileMock.mockReset();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("constructs addAgent command with non-interactive and json flags", async () => {
    spawnMock.mockImplementation(() =>
      createChild({
        code: 0,
        stdout: JSON.stringify({
          id: "agent-1",
          workspace: "/tmp/ws",
          defaultAgent: false
        })
      })
    );
    const client = new OpenClawClient({
      binPath: "openclaw",
      configPath: "/tmp/openclaw.json",
      includePath: "/tmp/foreman.json5",
      logger
    });

    const created = await client.addAgent({
      id: "agent-1",
      workspace: "/tmp/ws",
      identity: { name: "CEO", emoji: ":robot:" }
    });

    expect(created.id).toBe("agent-1");
    expect(spawnMock).toHaveBeenCalledWith(
      "openclaw",
      expect.arrayContaining([
        "agents",
        "add",
        "agent-1",
        "--workspace",
        "/tmp/ws",
        "--non-interactive",
        "--json"
      ]),
      expect.any(Object)
    );
  });

  it("parses listAgents JSON output", async () => {
    spawnMock.mockImplementation(() =>
      createChild({
        code: 0,
        stdout: JSON.stringify([{ id: "a1", workspace: "/tmp/ws", defaultAgent: false }])
      })
    );
    const client = new OpenClawClient({
      binPath: "openclaw",
      configPath: "/tmp/openclaw.json",
      includePath: "/tmp/foreman.json5",
      logger
    });

    const agents = await client.listAgents();
    expect(agents).toHaveLength(1);
    expect(agents[0]?.id).toBe("a1");
  });

  it("maps addAgent already exists error", async () => {
    spawnMock.mockImplementation(() =>
      createChild({ code: 1, stderr: "Agent already exists" })
    );
    const client = new OpenClawClient({
      binPath: "openclaw",
      configPath: "/tmp/openclaw.json",
      includePath: "/tmp/foreman.json5",
      logger
    });

    await expect(client.addAgent({ id: "a1", workspace: "/tmp/ws" })).rejects.toBeInstanceOf(
      OpenClawAgentExistsError
    );
  });

  it("treats delete not found as idempotent success", async () => {
    spawnMock.mockImplementation(() =>
      createChild({ code: 1, stderr: "agent not found" })
    );
    const client = new OpenClawClient({
      binPath: "openclaw",
      configPath: "/tmp/openclaw.json",
      includePath: "/tmp/foreman.json5",
      logger
    });

    await expect(client.deleteAgent("missing")).resolves.toBeUndefined();
  });

  it("uses --force for delete", async () => {
    spawnMock.mockImplementation(() =>
      createChild({ code: 0, stdout: "{}" })
    );
    const client = new OpenClawClient({
      binPath: "openclaw",
      configPath: "/tmp/openclaw.json",
      includePath: "/tmp/foreman.json5",
      logger
    });

    await client.deleteAgent("agent-123");

    expect(spawnMock).toHaveBeenCalledWith(
      "openclaw",
      expect.arrayContaining([
        "agents",
        "delete",
        "agent-123",
        "--force"
      ]),
      expect.any(Object)
    );
  });

  it("does not treat plugin-not-found warnings as agent-not-found", async () => {
    spawnMock.mockImplementation(() =>
      createChild({
        code: 1,
        stderr:
          "Config warnings:\n- plugins.entries.qwen_embedding: plugin not found: qwen_embedding\nNon-interactive session. Re-run with --force."
      })
    );
    const client = new OpenClawClient({
      binPath: "openclaw",
      configPath: "/tmp/openclaw.json",
      includePath: "/tmp/foreman.json5",
      logger
    });

    await expect(client.deleteAgent("agent-123")).rejects.toThrow("OpenClaw command failed");
  });

  it("maps non-idempotent not found to typed error for other operations", async () => {
    spawnMock.mockImplementation(() =>
      createChild({ code: 1, stderr: "agent not found" })
    );
    const client = new OpenClawClient({
      binPath: "openclaw",
      configPath: "/tmp/openclaw.json",
      includePath: "/tmp/foreman.json5",
      logger
    });

    await expect(client.listAgents()).rejects.toBeInstanceOf(OpenClawAgentNotFoundError);
  });

  it("times out long running commands", async () => {
    vi.useFakeTimers();
    spawnMock.mockImplementation(() =>
      createChild({ neverClose: true })
    );
    const client = new OpenClawClient({
      binPath: "openclaw",
      configPath: "/tmp/openclaw.json",
      includePath: "/tmp/foreman.json5",
      logger
    });

    const promise = expect(client.gatewayStatus()).rejects.toBeInstanceOf(OpenClawGatewayDownError);
    await vi.advanceTimersByTimeAsync(60_100);
    await promise;
  });

  it("reads gateway token from config file", async () => {
    readFileMock.mockResolvedValue(
      JSON.stringify({
        gateway: {
          auth: {
            token: "gateway-token"
          }
        }
      })
    );
    const client = new OpenClawClient({
      binPath: "openclaw",
      configPath: "/tmp/openclaw.json",
      includePath: "/tmp/foreman.json5",
      logger
    });

    await expect(client.readGatewayToken()).resolves.toBe("gateway-token");
    expect(readFileMock).toHaveBeenCalledWith("/tmp/openclaw.json", "utf8");
  });

  it("reloads secrets without unsupported non-interactive flag", async () => {
    spawnMock.mockImplementation(() =>
      createChild({ code: 0, stdout: "ok" })
    );
    const client = new OpenClawClient({
      binPath: "openclaw",
      configPath: "/tmp/openclaw.json",
      includePath: "/tmp/foreman.json5",
      logger
    });

    await client.reloadSecrets();

    expect(spawnMock).toHaveBeenCalledWith(
      "openclaw",
      ["secrets", "reload"],
      expect.any(Object)
    );
  });

  it("restarts gateway without unsupported non-interactive flag", async () => {
    spawnMock.mockImplementation(() =>
      createChild({ code: 0, stdout: "ok" })
    );
    const client = new OpenClawClient({
      binPath: "openclaw",
      configPath: "/tmp/openclaw.json",
      includePath: "/tmp/foreman.json5",
      logger
    });

    await client.restartGateway();

    expect(spawnMock).toHaveBeenCalledWith(
      "openclaw",
      ["gateway", "restart"],
      expect.any(Object)
    );
  });
});
