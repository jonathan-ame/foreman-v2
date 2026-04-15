import { randomUUID } from "node:crypto";
import process from "node:process";
import { Command } from "commander";
import { createAppDeps } from "../app-deps.js";
import { JOB_NAMES, runJobByName } from "../jobs/runner.js";
import { provisionForemanAgent } from "../provisioning/orchestrator.js";

const program = new Command();
program.name("foreman");

program
  .command("ping")
  .description("Ping the backend CLI")
  .action(() => {
    process.stdout.write(
      `${JSON.stringify({ status: "ok", env: process.env.NODE_ENV ?? "development" })}\n`
    );
  });

const agent = program.command("agent");
agent
  .command("provision")
  .requiredOption("--customer-id <id>")
  .requiredOption("--agent-name <name>")
  .requiredOption("--role <role>")
  .requiredOption("--model-tier <tier>")
  .option("--idempotency-key <uuid>")
  .option("--workspace-path <path>")
  .action(async (options) => {
    const idempotencyKey = options.idempotencyKey ?? randomUUID();
    if (!options.idempotencyKey) {
      process.stderr.write(`Generated idempotency key: ${idempotencyKey}\n`);
    }

    const deps = createAppDeps();
    const result = await provisionForemanAgent(
      {
        customerId: options.customerId,
        agentName: options.agentName,
        role: options.role,
        modelTier: options.modelTier,
        idempotencyKey,
        ...(options.workspacePath ? { workspacePath: options.workspacePath } : {})
      },
      deps
    );

    process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
    if (result.outcome === "failed" || result.outcome === "blocked") {
      process.exitCode = 1;
    }
  });

const jobs = program.command("jobs");
jobs
  .command("run")
  .argument("<name>", `job name (${JOB_NAMES.join(", ")})`)
  .action(async (name: string) => {
    const deps = createAppDeps();
    const result = await runJobByName(name, deps);
    process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
    if (result.status === "error") {
      process.exitCode = 1;
    }
  });

program.parseAsync(process.argv).catch((error: unknown) => {
  process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`);
  process.exit(1);
});
