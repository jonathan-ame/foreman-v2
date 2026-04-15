import { config as loadDotenv } from "dotenv";
import os from "node:os";
import path from "node:path";
import process from "node:process";
import { z } from "zod";

loadDotenv();

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  PORT: z.coerce.number().default(8080),
  LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info"),
  SUPABASE_URL: z.string().min(1),
  SUPABASE_SERVICE_KEY: z.string().min(1),
  PAPERCLIP_API_BASE: z.string().min(1).default("http://localhost:3125"),
  PAPERCLIP_API_KEY: z.string().min(1),
  OPENCLAW_BIN: z.string().min(1).default("openclaw"),
  OPENCLAW_GATEWAY_URL: z.string().min(1).default("ws://127.0.0.1:18789/"),
  OPENCLAW_CONFIG_PATH: z.string().min(1).default("~/.openclaw/openclaw.json"),
  OPENCLAW_INCLUDE_PATH: z.string().min(1).default("~/.openclaw/foreman.json5"),
  OPENROUTER_API_KEY: z.string().min(1),
  DASHSCOPE_SG_KEY: z.string().min(1),
  STRIPE_SECRET_KEY: z.string().optional(),
  STRIPE_WEBHOOK_SECRET: z.string().optional(),
  FOREMAN_LOG_DIR: z.string().min(1).default("~/.foreman/logs")
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  process.stderr.write("Environment validation failed:\n");
  for (const issue of parsed.error.issues) {
    process.stderr.write(`- ${issue.path.join(".") || "<root>"}: ${issue.message}\n`);
  }
  process.exit(1);
}

const expandHome = (value: string): string => {
  if (value === "~") {
    return os.homedir();
  }

  if (value.startsWith("~/")) {
    return path.join(os.homedir(), value.slice(2));
  }

  return value;
};

const data = parsed.data;

export const env = {
  ...data,
  OPENCLAW_CONFIG_PATH: expandHome(data.OPENCLAW_CONFIG_PATH),
  OPENCLAW_INCLUDE_PATH: expandHome(data.OPENCLAW_INCLUDE_PATH),
  FOREMAN_LOG_DIR: expandHome(data.FOREMAN_LOG_DIR)
};
