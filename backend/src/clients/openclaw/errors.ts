export class OpenClawCliError extends Error {
  command: string;
  exitCode: number | null;
  stderr: string;
  stdout: string;

  constructor(params: {
    command: string;
    exitCode: number | null;
    stderr: string;
    stdout: string;
    message: string;
  }) {
    super(params.message);
    this.name = "OpenClawCliError";
    this.command = params.command;
    this.exitCode = params.exitCode;
    this.stderr = params.stderr;
    this.stdout = params.stdout;
  }
}

export class OpenClawAgentExistsError extends OpenClawCliError {
  constructor(params: { command: string; exitCode: number | null; stderr: string; stdout: string }) {
    super({
      ...params,
      message: "OpenClaw agent already exists"
    });
    this.name = "OpenClawAgentExistsError";
  }
}

export class OpenClawAgentNotFoundError extends OpenClawCliError {
  constructor(params: { command: string; exitCode: number | null; stderr: string; stdout: string }) {
    super({
      ...params,
      message: "OpenClaw agent not found"
    });
    this.name = "OpenClawAgentNotFoundError";
  }
}

export class OpenClawGatewayDownError extends OpenClawCliError {
  constructor(params: { command: string; exitCode: number | null; stderr: string; stdout: string }) {
    super({
      ...params,
      message: "OpenClaw gateway is unavailable"
    });
    this.name = "OpenClawGatewayDownError";
  }
}
