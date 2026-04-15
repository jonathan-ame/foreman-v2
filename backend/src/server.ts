import { serve } from "@hono/node-server";
import { Hono } from "hono";
import process from "node:process";
import { createAppDeps } from "./app-deps.js";
import { env } from "./config/env.js";
import { createLogger } from "./config/logger.js";
import { startJobs } from "./jobs/runner.js";
import { registerAgentRoutes } from "./routes/agents.js";
import { registerStripeWebhookRoutes } from "./routes/stripe-webhook.js";

const logger = createLogger("server");

export const app = new Hono();
const deps = createAppDeps(logger.child({ name: "app-deps" }));

app.get("/health", (c) => {
  return c.json({
    status: "ok",
    uptime: process.uptime()
  });
});
registerAgentRoutes(app, deps);
registerStripeWebhookRoutes(app, deps);

const isTestRun = process.env.VITEST === "true";
const jobsOnly = process.argv.includes("--jobs-only");
const shouldRunProcess = env.NODE_ENV !== "test" && !isTestRun;

if (shouldRunProcess) {
  if (jobsOnly) {
    const jobsHandle = startJobs(deps);
    logger.info("jobs-only mode enabled; HTTP server not started");
    const shutdownJobsOnly = (signal: NodeJS.Signals) => {
      logger.info({ signal }, "jobs-only shutdown requested");
      jobsHandle.stop();
      logger.info("shutdown complete");
      process.exit(0);
    };
    process.on("SIGTERM", () => shutdownJobsOnly("SIGTERM"));
    process.on("SIGINT", () => shutdownJobsOnly("SIGINT"));
  } else {
    let jobsHandle: ReturnType<typeof startJobs> | null = null;
    const server = serve({ fetch: app.fetch, port: env.PORT }, () => {
      logger.info({ port: env.PORT }, `server started on port ${env.PORT}`);
      jobsHandle = startJobs(deps);
    });

    const shutdownServer = (signal: NodeJS.Signals) => {
      logger.info({ signal }, "shutdown requested");
      jobsHandle?.stop();
      server.close(() => {
        logger.info("shutdown complete");
        process.exit(0);
      });
    };

    process.on("SIGTERM", () => shutdownServer("SIGTERM"));
    process.on("SIGINT", () => shutdownServer("SIGINT"));
  }
}
