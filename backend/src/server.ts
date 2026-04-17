import { serve } from "@hono/node-server";
import { Hono } from "hono";
import { existsSync, statSync } from "node:fs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { createAppDeps } from "./app-deps.js";
import { env } from "./config/env.js";
import { createLogger } from "./config/logger.js";
import { startJobs } from "./jobs/runner.js";
import { registerAgentRoutes } from "./routes/agents.js";
import { registerAuthRoutes } from "./routes/auth.js";
import { registerEscalationRoutes } from "./routes/escalation.js";
import { registerHealthRoutes } from "./routes/health.js";
import { registerStripeWebhookRoutes } from "./routes/stripe-webhook.js";
import { registerUsageRoutes } from "./routes/usage.js";

const logger = createLogger("server");

export const app = new Hono();
const deps = createAppDeps(logger.child({ name: "app-deps" }));
const webDistDir = path.resolve(process.cwd(), "dist-web");
const webIndexPath = path.join(webDistDir, "index.html");
const mimeTypes: Record<string, string> = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".map": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".ico": "image/x-icon"
};

const serveWebFile = async (filePath: string) => {
  const body = await readFile(filePath);
  const extension = path.extname(filePath).toLowerCase();
  return {
    body,
    contentType: mimeTypes[extension] ?? "application/octet-stream"
  };
};

app.get("/health", (c) => {
  return c.json({
    status: "ok",
    uptime: process.uptime()
  });
});
registerAuthRoutes(app, deps);
registerHealthRoutes(app, deps);
registerAgentRoutes(app, deps);
registerEscalationRoutes(app, deps);
registerStripeWebhookRoutes(app, deps);
registerUsageRoutes(app, deps);
app.get("*", async (c) => {
  const requestPath = c.req.path;
  if (requestPath.startsWith("/api/") || requestPath === "/health") {
    return c.notFound();
  }

  const relativePath = requestPath === "/" ? "index.html" : requestPath.slice(1);
  const candidatePath = path.resolve(webDistDir, relativePath);
  const staysWithinDist = candidatePath.startsWith(webDistDir + path.sep) || candidatePath === webDistDir;

  if (staysWithinDist && existsSync(candidatePath) && statSync(candidatePath).isFile()) {
    const file = await serveWebFile(candidatePath);
    c.header("Content-Type", file.contentType);
    return c.body(file.body);
  }

  if (existsSync(webIndexPath)) {
    const file = await serveWebFile(webIndexPath);
    c.header("Content-Type", file.contentType);
    return c.body(file.body);
  }

  return c.notFound();
});

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
