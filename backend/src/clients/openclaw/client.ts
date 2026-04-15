import { readFile } from "node:fs/promises";
import { spawn } from "node:child_process";
import type { Logger } from "pino";
import {
  OpenClawAgentExistsError,
  OpenClawAgentNotFoundError,
  OpenClawCliError,
  OpenClawGatewayDownError
} from "./errors.js";
import type { OpenClawAgentRecord, OpenClawAgentSpec } from "./types.js";

const COMMAND_TIMEOUT_MS = 60_000;

interface CommandResult {
  stdout: string;
  stderr: string;
}

export interface OpenClawClientConfig {
  binPath: string;
  configPath: string;
  includePath: string;
  logger: Logger;
}

export class OpenClawClient {
  private readonly binPath: string;
  private readonly configPath: string;
  private readonly includePath: string;
  private readonly logger: Logger;

  constructor(config: OpenClawClientConfig) {
    this.binPath = config.binPath;
    this.configPath = config.configPath;
    this.includePath = config.includePath;
    this.logger = config.logger;
  }

  async addAgent(spec: OpenClawAgentSpec): Promise<OpenClawAgentRecord> {
    const args = ["agents", "add", spec.id, "--workspace", spec.workspace, "--non-interactive", "--json"];
    if (spec.identity?.name) {
      args.push("--name", spec.identity.name);
    }
    if (spec.identity?.emoji) {
      args.push("--emoji", spec.identity.emoji);
    }
    if (spec.identity?.avatar) {
      args.push("--avatar", spec.identity.avatar);
    }

    try {
      const output = await this.runCommand(args, true);
      const parsed = this.parseJson<Record<string, unknown>>(output.stdout, args);
      const record = (parsed.agent ?? parsed) as OpenClawAgentRecord;
      return record;
    } catch (error) {
      if (error instanceof OpenClawCliError && /already exists/i.test(error.stderr)) {
        throw new OpenClawAgentExistsError({
          command: error.command,
          exitCode: error.exitCode,
          stderr: error.stderr,
          stdout: error.stdout
        });
      }
      throw error;
    }
  }

  async deleteAgent(agentId: string): Promise<void> {
    const args = ["agents", "delete", agentId, "--non-interactive", "--json"];
    try {
      await this.runCommand(args, true);
    } catch (error) {
      if (error instanceof OpenClawCliError && /not found/i.test(error.stderr)) {
        this.logger.info({ agentId }, "openclaw delete idempotent: agent not found");
        return;
      }
      throw error;
    }
  }

  async listAgents(): Promise<OpenClawAgentRecord[]> {
    const output = await this.runCommand(["agents", "list", "--non-interactive", "--json"], true);
    const parsed = this.parseJson<unknown>(output.stdout, ["agents", "list", "--non-interactive", "--json"]);
    if (Array.isArray(parsed)) {
      return parsed as OpenClawAgentRecord[];
    }
    if (parsed && typeof parsed === "object" && "agents" in parsed) {
      return (parsed as { agents: OpenClawAgentRecord[] }).agents;
    }
    return [];
  }

  async getAgent(agentId: string): Promise<OpenClawAgentRecord | null> {
    const agents = await this.listAgents();
    return agents.find((agent) => agent.id === agentId) ?? null;
  }

  async reloadSecrets(): Promise<void> {
    await this.runCommand(["secrets", "reload", "--non-interactive"], false);
  }

  async restartGateway(): Promise<void> {
    await this.runCommand(["gateway", "restart", "--non-interactive"], false);
  }

  async readGatewayToken(): Promise<string> {
    const raw = await readFile(this.configPath, "utf8");
    const parsed = JSON.parse(raw) as {
      gateway?: {
        auth?: {
          token?: string;
        };
      };
    };
    const token = parsed.gateway?.auth?.token;
    if (!token) {
      throw new OpenClawCliError({
        command: `read ${this.configPath}`,
        exitCode: null,
        stderr: "gateway.auth.token missing",
        stdout: raw,
        message: "OpenClaw gateway token not found in config"
      });
    }
    return token;
  }

  async gatewayStatus(): Promise<{ running: boolean; pid?: number; listening?: string }> {
    const output = await this.runCommand(["gateway", "status", "--non-interactive", "--json"], true);
    return this.parseJson<{ running: boolean; pid?: number; listening?: string }>(output.stdout, [
      "gateway",
      "status",
      "--non-interactive",
      "--json"
    ]);
  }

  private async runCommand(args: string[], expectJson: boolean): Promise<CommandResult> {
    const startedAt = Date.now();
    const command = `${this.binPath} ${args.join(" ")}`;

    return await new Promise<CommandResult>((resolve, reject) => {
      const child = spawn(this.binPath, args, {
        env: process.env,
        stdio: ["ignore", "pipe", "pipe"]
      });

      let stdout = "";
      let stderr = "";
      let timedOut = false;

      child.stdout?.on("data", (chunk: Buffer | string) => {
        stdout += chunk.toString();
      });

      child.stderr?.on("data", (chunk: Buffer | string) => {
        stderr += chunk.toString();
      });

      const timeout = setTimeout(() => {
        timedOut = true;
        child.kill("SIGKILL");
        reject(
          new OpenClawGatewayDownError({
            command,
            exitCode: null,
            stderr: `Command timed out after ${COMMAND_TIMEOUT_MS}ms`,
            stdout
          })
        );
      }, COMMAND_TIMEOUT_MS);

      child.on("error", (error) => {
        clearTimeout(timeout);
        reject(
          new OpenClawCliError({
            command,
            exitCode: null,
            stderr: error.message,
            stdout,
            message: "Failed to execute OpenClaw command"
          })
        );
      });

      child.on("close", (code) => {
        clearTimeout(timeout);
        if (timedOut) {
          return;
        }

        const durationMs = Date.now() - startedAt;
        this.logger.debug(
          { command, durationMs, exitCode: code, includePath: this.includePath },
          "openclaw command complete"
        );

        if (code !== 0) {
          const mapped = this.mapCliError({ command, exitCode: code, stdout, stderr });
          reject(mapped);
          return;
        }

        if (expectJson && !stdout.trim()) {
          resolve({ stdout: "{}", stderr });
          return;
        }

        resolve({ stdout, stderr });
      });
    });
  }

  private parseJson<T>(value: string, args: string[]): T {
    try {
      return JSON.parse(value) as T;
    } catch {
      throw new OpenClawCliError({
        command: `${this.binPath} ${args.join(" ")}`,
        exitCode: 0,
        stderr: "Failed to parse JSON output",
        stdout: value,
        message: "OpenClaw returned invalid JSON"
      });
    }
  }

  private mapCliError(params: {
    command: string;
    exitCode: number | null;
    stdout: string;
    stderr: string;
  }): OpenClawCliError {
    const stderrLower = params.stderr.toLowerCase();

    if (stderrLower.includes("already exists")) {
      return new OpenClawAgentExistsError(params);
    }
    if (stderrLower.includes("not found")) {
      return new OpenClawAgentNotFoundError(params);
    }
    if (
      stderrLower.includes("gateway") ||
      stderrLower.includes("connection refused") ||
      stderrLower.includes("econnrefused")
    ) {
      return new OpenClawGatewayDownError(params);
    }
    return new OpenClawCliError({
      ...params,
      message: "OpenClaw command failed"
    });
  }
}
