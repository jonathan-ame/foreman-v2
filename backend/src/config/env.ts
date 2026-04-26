import { config as loadDotenv } from "dotenv";
import os from "node:os";
import path from "node:path";
import process from "node:process";
import { z } from "zod";
import { validateRequiredSecrets, getCredentialStatus, getDeferredSecrets } from "./secrets.js";

loadDotenv();

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  PORT: z.coerce.number().default(8080),
  LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info"),
  SUPABASE_URL: z.string().min(1),
  SUPABASE_SERVICE_KEY: z.string().min(1),
  PAPERCLIP_API_BASE: z.string().min(1).default("http://localhost:3100"),
  PAPERCLIP_API_KEY: z.string().min(1).optional(),
  PAPERCLIP_RUN_ID: z.string().min(1).optional(),
  OPENCLAW_BIN: z.string().min(1).default("openclaw"),
  OPENCLAW_GATEWAY_URL: z.string().min(1).default("ws://127.0.0.1:18789/"),
  OPENCLAW_CONFIG_PATH: z.string().min(1).default("~/.openclaw/openclaw.json"),
  OPENCLAW_INCLUDE_PATH: z.string().min(1).default("~/.openclaw/foreman.json5"),
  OPENROUTER_API_KEY: z.string().min(1).optional(),
  DASHSCOPE_SG_KEY: z.string().min(1).optional(),
  STRIPE_MODE: z.enum(["live", "test"]).optional(),
  STRIPE_SECRET_KEY: z.string().min(1).optional(),
  STRIPE_WEBHOOK_SECRET: z.string().min(1).optional(),
  STRIPE_PRICE_TIER_1: z.string().min(1).optional(),
  STRIPE_PRICE_TIER_2: z.string().min(1).optional(),
  STRIPE_PRICE_TIER_3: z.string().min(1).optional(),
  STRIPE_PRICE_BYOK_PLATFORM: z.string().min(1).optional(),
  STRIPE_SECRET_KEY_TEST: z.string().min(1).optional(),
  STRIPE_WEBHOOK_SECRET_TEST: z.string().min(1).optional(),
  STRIPE_PRICE_TIER_1_TEST: z.string().min(1).optional(),
  STRIPE_PRICE_TIER_2_TEST: z.string().min(1).optional(),
  STRIPE_PRICE_TIER_3_TEST: z.string().min(1).optional(),
  STRIPE_PRICE_BYOK_PLATFORM_TEST: z.string().min(1).optional(),
  FOREMAN_LOG_DIR: z.string().min(1).default("~/.foreman/logs"),
  RESEND_API_KEY: z.string().min(1).optional(),
  EMAIL_FROM: z.string().min(1).optional(),
  CEO_REVIEW_EMAIL: z.string().min(1).optional(),
  SENTRY_DSN: z.string().url().optional(),
  COMPOSIO_API_KEY: z.string().min(1).optional(),
  COMPOSIO_API_BASE: z.string().min(1).default("https://backend.composio.dev"),
  COMPOSIO_WEBHOOK_SECRET: z.string().min(1).optional(),
  COMPOSIO_CONNECTED_ACCOUNT_ID_OUTLOOK: z.string().min(1).optional(),
  COMPOSIO_USER_ID: z.string().min(1).default("paperclip_company_b8d234ec-515c-4331-9a5a-bb2f0c239ef5"),
  FOREMAN_BASE_URL: z.string().min(1).default("https://foreman.company"),
  NEON_DATABASE_URL: z.string().min(1).optional(),
  NEON_AUTH_URL: z.string().min(1).default("https://ep-calm-voice-amfgpq8c.neonauth.c-5.us-east-1.aws.neon.tech/neondb/auth"),
  NEON_AUTH_JWKS_URL: z.string().min(1).default("https://ep-calm-voice-amfgpq8c.neonauth.c-5.us-east-1.aws.neon.tech/neondb/auth/.well-known/jwks.json"),
  BYOK_ENCRYPTION_KEY: z.string().min(1).optional(),
  TAVILY_API_KEY: z.string().min(1).optional(),
  RATE_LIMIT_ENABLED: z
    .enum(["true", "false"])
    .default("true")
    .transform((v) => v === "true"),
  RATE_LIMIT_STANDARD_MAX: z.coerce.number().default(100),
  RATE_LIMIT_STRICT_MAX: z.coerce.number().default(20),
  RATE_LIMIT_AUTH_MAX: z.coerce.number().default(10),
  RATE_LIMIT_WINDOW_MS: z.coerce.number().default(60_000),
  RATE_LIMIT_AUTH_WINDOW_MS: z.coerce.number().default(15 * 60_000),
  CORS_ALLOWED_ORIGINS: z.string().default(""),
  CORS_MAX_AGE: z.coerce.number().default(86400)
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  process.stderr.write("Environment validation failed:\n");
  for (const issue of parsed.error.issues) {
    process.stderr.write(`- ${issue.path.join(".") || "<root>"}: ${issue.message}\n`);
  }
  process.exit(1);
}

const data = parsed.data;
const isVitest = process.env.VITEST === "true";

// Validate required secrets from the secrets registry (supplements Zod schema)
const missingSecrets = validateRequiredSecrets();
if (!isVitest && missingSecrets.length > 0) {
  process.stderr.write("Required secrets missing from environment:\n");
  for (const { key, meta } of missingSecrets) {
    process.stderr.write(`- ${key}: ${meta.description}\n`);
  }
  process.exit(1);
}

// Log credential status summary at startup (non-sensitive)
if (!isVitest) {
  const status = getCredentialStatus();
  const deferred = getDeferredSecrets();
  const summary: string[] = [];
  for (const [provider, s] of Object.entries(status)) {
    if (s.total > 0) {
      summary.push(`${provider}: ${s.resolved}/${s.total} resolved` + (s.deferred > 0 ? `, ${s.deferred} deferred` : ""));
    }
  }
  process.stderr.write(`Credential status: ${summary.join(", ")}\n`);
  if (deferred.length > 0) {
    process.stderr.write(`Deferred secrets: ${deferred.map(s => s.key).join(", ")}\n`);
  }
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

// data and isVitest already declared above
const defaultStripeMode: "live" | "test" = data.NODE_ENV === "production" ? "live" : "test";
const stripeMode: "live" | "test" = data.STRIPE_MODE ?? defaultStripeMode;

const selectByMode = (liveValue: string | undefined, testValue: string | undefined): string | undefined =>
  stripeMode === "live" ? liveValue : testValue;

const activeStripeSecretKey = selectByMode(data.STRIPE_SECRET_KEY, data.STRIPE_SECRET_KEY_TEST);
const activeStripeWebhookSecret = selectByMode(data.STRIPE_WEBHOOK_SECRET, data.STRIPE_WEBHOOK_SECRET_TEST);
const activeStripeTier1Price = selectByMode(data.STRIPE_PRICE_TIER_1, data.STRIPE_PRICE_TIER_1_TEST);
const activeStripeTier2Price = selectByMode(data.STRIPE_PRICE_TIER_2, data.STRIPE_PRICE_TIER_2_TEST);
const activeStripeTier3Price = selectByMode(data.STRIPE_PRICE_TIER_3, data.STRIPE_PRICE_TIER_3_TEST);
const activeStripeByokPrice = selectByMode(
  data.STRIPE_PRICE_BYOK_PLATFORM,
  data.STRIPE_PRICE_BYOK_PLATFORM_TEST
);

const modePrefix = stripeMode === "live" ? "" : "_TEST";
const validationErrors: string[] = [];
if (!activeStripeSecretKey) {
  validationErrors.push(`STRIPE_SECRET_KEY${modePrefix} is required for STRIPE_MODE=${stripeMode}`);
}
if (!activeStripeWebhookSecret) {
  validationErrors.push(`STRIPE_WEBHOOK_SECRET${modePrefix} is required for STRIPE_MODE=${stripeMode}`);
}
if (!activeStripeTier1Price) {
  validationErrors.push(`STRIPE_PRICE_TIER_1${modePrefix} is required for STRIPE_MODE=${stripeMode}`);
}
if (!activeStripeTier2Price) {
  validationErrors.push(`STRIPE_PRICE_TIER_2${modePrefix} is required for STRIPE_MODE=${stripeMode}`);
}
if (!activeStripeTier3Price) {
  validationErrors.push(`STRIPE_PRICE_TIER_3${modePrefix} is required for STRIPE_MODE=${stripeMode}`);
}
if (!activeStripeByokPrice) {
  validationErrors.push(`STRIPE_PRICE_BYOK_PLATFORM${modePrefix} is required for STRIPE_MODE=${stripeMode}`);
}

if (!isVitest && validationErrors.length > 0) {
  process.stderr.write("Stripe configuration warnings (non-fatal):\n");
  for (const error of validationErrors) {
    process.stderr.write(`- ${error}\n`);
  }
}

const fallbackByMode = (liveFallback: string, testFallback: string): string =>
  stripeMode === "live" ? liveFallback : testFallback;

export const env = {
  ...data,
  stripeMode,
  STRIPE_SECRET_KEY_ACTIVE:
    activeStripeSecretKey ?? fallbackByMode("sk_live_test_placeholder", "sk_test_test_placeholder"),
  STRIPE_WEBHOOK_SECRET_ACTIVE:
    activeStripeWebhookSecret ?? fallbackByMode("whsec_live_test_placeholder", "whsec_test_test_placeholder"),
  STRIPE_PRICE_TIER_1_ACTIVE:
    activeStripeTier1Price ?? fallbackByMode("price_live_tier_1_test", "price_test_tier_1_test"),
  STRIPE_PRICE_TIER_2_ACTIVE:
    activeStripeTier2Price ?? fallbackByMode("price_live_tier_2_test", "price_test_tier_2_test"),
  STRIPE_PRICE_TIER_3_ACTIVE:
    activeStripeTier3Price ?? fallbackByMode("price_live_tier_3_test", "price_test_tier_3_test"),
  STRIPE_PRICE_BYOK_PLATFORM_ACTIVE:
    activeStripeByokPrice ?? fallbackByMode("price_live_byok_test", "price_test_byok_test"),
  OPENCLAW_CONFIG_PATH: expandHome(data.OPENCLAW_CONFIG_PATH),
  OPENCLAW_INCLUDE_PATH: expandHome(data.OPENCLAW_INCLUDE_PATH),
  FOREMAN_LOG_DIR: expandHome(data.FOREMAN_LOG_DIR),
  rateLimit: {
    enabled: data.RATE_LIMIT_ENABLED,
    standard: { windowMs: data.RATE_LIMIT_WINDOW_MS, maxRequests: data.RATE_LIMIT_STANDARD_MAX },
    strict: { windowMs: data.RATE_LIMIT_WINDOW_MS, maxRequests: data.RATE_LIMIT_STRICT_MAX },
    auth: { windowMs: data.RATE_LIMIT_AUTH_WINDOW_MS, maxRequests: data.RATE_LIMIT_AUTH_MAX },
    lenient: { windowMs: data.RATE_LIMIT_WINDOW_MS, maxRequests: 300 },
    excludedPaths: ["/health", "/api/internal/health", "/api/stripe/webhook"]
  },
  cors: {
    allowedOrigins: data.CORS_ALLOWED_ORIGINS
      ? data.CORS_ALLOWED_ORIGINS.split(",").map((s) => s.trim()).filter(Boolean)
      : [],
    maxAge: data.CORS_MAX_AGE
  }
};

export type Env = typeof env;
