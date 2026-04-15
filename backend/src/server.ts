import { serve } from "@hono/node-server";
import { Hono } from "hono";
import process from "node:process";
import { env } from "./config/env.js";
import { createLogger } from "./config/logger.js";

const logger = createLogger("server");

export const app = new Hono();

app.get("/health", (c) => {
  return c.json({
    status: "ok",
    uptime: process.uptime()
  });
});

const isTestRun = process.env.VITEST === "true";

if (!isTestRun) {
  const server = serve({ fetch: app.fetch, port: env.PORT }, () => {
    logger.info({ port: env.PORT }, `server started on port ${env.PORT}`);
  });

  const shutdown = (signal: NodeJS.Signals) => {
    logger.info({ signal }, "shutdown requested");
    server.close(() => {
      logger.info("shutdown complete");
      process.exit(0);
    });
  };

  process.on("SIGTERM", () => shutdown("SIGTERM"));
  process.on("SIGINT", () => shutdown("SIGINT"));
}
