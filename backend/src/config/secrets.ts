/**
 * Secure Credential Storage Module for Phase 1 Infrastructure
 *
 * Centralizes credential access with:
 * - Audit logging for all secret reads
 * - Access classification (public, internal, restricted)
 * - Credential metadata (rotation policy, source, last-rotated)
 * - Runtime validation and redaction helpers
 *
 * Design decisions:
 * - Phase 1 uses environment variables as the backing store
 * - Railway provides secure env var injection in production
 * - Supabase Vault is available for DB-stored secrets (future Phase 2)
 * - All secret access is logged for audit trails
 * - No secrets are ever logged or included in error messages
 */

import process from "node:process";

// ─── Types ───────────────────────────────────────────────────────────────────

export type SecretClassification = "public" | "internal" | "restricted";

export interface SecretMetadata {
  /** Human-readable name */
  name: string;
  /** Which provider/service this credential belongs to */
  provider: "railway" | "stripe" | "supabase" | "cloudflare" | "resend" | "sentry" | "openrouter" | "dashscope" | "together" | "deepinfra" | "openclaw" | "paperclip" | "other";
  /** Sensitivity classification */
  classification: SecretClassification;
  /** Whether this credential is required for the app to start */
  required: boolean;
  /** Suggested rotation interval in days (0 = no rotation policy) */
  rotationDays: number;
  /** Whether this credential is deferred (not yet available) */
  deferred: boolean;
  /** Defer reason (e.g., blocked by FORA-42) */
  deferReason?: string;
  /** Description of what this credential is used for */
  description: string;
}

export interface SecretAccessEvent {
  key: string;
  timestamp: string;
  source?: string;
}

export interface SecretResolveResult {
  value: string | undefined;
  resolved: boolean;
  classification: SecretClassification;
  deferred: boolean;
}

// ─── Secret Registry ─────────────────────────────────────────────────────────

const SECRET_REGISTRY: Map<string, SecretMetadata> = new Map();

function registerSecret(envVar: string, meta: SecretMetadata): void {
  SECRET_REGISTRY.set(envVar, meta);
}

// ─── Railway ─────────────────────────────────────────────────────────────────

registerSecret("RAILWAY_API_KEY", {
  name: "Railway API Key",
  provider: "railway",
  classification: "restricted",
  required: false,
  rotationDays: 90,
  deferred: false,
  description: "Railway deployment API token for programmatic deploys and env management",
});

// ─── Stripe ──────────────────────────────────────────────────────────────────

registerSecret("STRIPE_SECRET_KEY", {
  name: "Stripe Secret Key (Live)",
  provider: "stripe",
  classification: "restricted",
  required: false,
  rotationDays: 90,
  deferred: false,
  description: "Stripe live-mode secret key for payment processing",
});

registerSecret("STRIPE_SECRET_KEY_TEST", {
  name: "Stripe Secret Key (Test)",
  provider: "stripe",
  classification: "restricted",
  required: false,
  rotationDays: 90,
  deferred: false,
  description: "Stripe test-mode secret key for development",
});

registerSecret("STRIPE_WEBHOOK_SECRET", {
  name: "Stripe Webhook Secret (Live)",
  provider: "stripe",
  classification: "restricted",
  required: false,
  rotationDays: 180,
  deferred: false,
  description: "Stripe live webhook signing secret for verifying webhook signatures",
});

registerSecret("STRIPE_WEBHOOK_SECRET_TEST", {
  name: "Stripe Webhook Secret (Test)",
  provider: "stripe",
  classification: "restricted",
  required: false,
  rotationDays: 180,
  deferred: false,
  description: "Stripe test webhook signing secret",
});

registerSecret("STRIPE_MODE", {
  name: "Stripe Mode",
  provider: "stripe",
  classification: "public",
  required: false,
  rotationDays: 0,
  deferred: false,
  description: "Stripe mode selector: 'live' or 'test'",
});

// Stripe price IDs are semi-public (used in client-side checkout)
const STRIPE_PRICE_VARS = [
  "STRIPE_PRICE_TIER_1", "STRIPE_PRICE_TIER_2", "STRIPE_PRICE_TIER_3",
  "STRIPE_PRICE_BYOK_PLATFORM",
  "STRIPE_PRICE_TIER_1_TEST", "STRIPE_PRICE_TIER_2_TEST", "STRIPE_PRICE_TIER_3_TEST",
  "STRIPE_PRICE_BYOK_PLATFORM_TEST",
  "STRIPE_PRICE_AGENT_ANALYTICS", "STRIPE_PRICE_AGENT_CHIEFOFSTAFF",
  "STRIPE_PRICE_AGENT_COMPLIANCE", "STRIPE_PRICE_AGENT_CONTENT",
  "STRIPE_PRICE_AGENT_CUST_SUCCESS", "STRIPE_PRICE_AGENT_DEVOPS",
  "STRIPE_PRICE_AGENT_ENGINEERING", "STRIPE_PRICE_AGENT_FINANCE",
  "STRIPE_PRICE_AGENT_FOLLOWUP", "STRIPE_PRICE_AGENT_INBOX",
  "STRIPE_PRICE_AGENT_LEAD_GEN", "STRIPE_PRICE_AGENT_LEGAL",
  "STRIPE_PRICE_AGENT_OUTREACH", "STRIPE_PRICE_AGENT_PA",
  "STRIPE_PRICE_AGENT_PRIVACY", "STRIPE_PRICE_AGENT_PRODUCT_LEAD",
  "STRIPE_PRICE_AGENT_PROVIDER_ACQ", "STRIPE_PRICE_AGENT_PROVIDER_OPS",
  "STRIPE_PRICE_AGENT_QA", "STRIPE_PRICE_AGENT_RESEARCH",
  "STRIPE_PRICE_AGENT_SCHEDULER", "STRIPE_PRICE_AGENT_SECURITY",
  "STRIPE_PRICE_AGENT_SEO", "STRIPE_PRICE_AGENT_TERMS",
  "STRIPE_PRICE_AGENT_USER_GROWTH",
  "STRIPE_PRICE_BUSINESS_ANNUAL", "STRIPE_PRICE_COMPLETE",
  "STRIPE_PRICE_GROWTH", "STRIPE_PRICE_INTEL", "STRIPE_PRICE_LEGAL",
  "STRIPE_PRICE_OPS", "STRIPE_PRICE_PARTNER", "STRIPE_PRICE_PRO_ANNUAL",
  "STRIPE_PRICE_PRODUCT", "STRIPE_PRICE_STARTER_ANNUAL",
  "STRIPE_PRICE_SUPPORT_BUILDER", "STRIPE_PRICE_SUPPORT_DFY",
  "STRIPE_PRICE_SUPPORT_PRO", "STRIPE_PRICE_SUPPORT_STARTER",
];

for (const varName of STRIPE_PRICE_VARS) {
  registerSecret(varName, {
    name: `Stripe Price ID (${varName})`,
    provider: "stripe",
    classification: "internal",
    required: false,
    rotationDays: 0,
    deferred: false,
    description: "Stripe price/plan ID — semi-public, used in checkout sessions",
  });
}

// Stripe links are public URLs
const STRIPE_LINK_VARS = [
  "STRIPE_LINK_STARTER_ANNUAL", "STRIPE_LINK_GROWTH", "STRIPE_LINK_PRO_ANNUAL",
  "STRIPE_LINK_BUSINESS_ANNUAL", "STRIPE_LINK_COMPLETE", "STRIPE_LINK_INTEL",
  "STRIPE_LINK_LEGAL", "STRIPE_LINK_OPS", "STRIPE_LINK_PARTNER",
  "STRIPE_LINK_PRODUCT", "STRIPE_LINK_SUPPORT_STARTER", "STRIPE_LINK_SUPPORT_BUILDER",
  "STRIPE_LINK_SUPPORT_DFY", "STRIPE_LINK_SUPPORT_PRO",
];

for (const varName of STRIPE_LINK_VARS) {
  registerSecret(varName, {
    name: `Stripe Payment Link (${varName})`,
    provider: "stripe",
    classification: "public",
    required: false,
    rotationDays: 0,
    deferred: false,
    description: "Stripe payment link URL — public-facing checkout link",
  });
}

// ─── Supabase ────────────────────────────────────────────────────────────────

registerSecret("SUPABASE_URL", {
  name: "Supabase Project URL",
  provider: "supabase",
  classification: "internal",
  required: true,
  rotationDays: 0,
  deferred: false,
  description: "Supabase project URL for API and DB connections",
});

registerSecret("SUPABASE_SERVICE_KEY", {
  name: "Supabase Service Role Key",
  provider: "supabase",
  classification: "restricted",
  required: true,
  rotationDays: 90,
  deferred: false,
  description: "Supabase service role key — bypasses RLS, used for server-side operations only",
});

registerSecret("SUPABASE_ANON_KEY", {
  name: "Supabase Anon Key",
  provider: "supabase",
  classification: "internal",
  required: false,
  rotationDays: 180,
  deferred: false,
  description: "Supabase anon/public key — used client-side, respects RLS policies",
});

registerSecret("SUPABASE_PROJECT_URL", {
  name: "Supabase Dashboard URL",
  provider: "supabase",
  classification: "internal",
  required: false,
  rotationDays: 0,
  deferred: false,
  description: "Supabase project dashboard URL (alias for SUPABASE_URL)",
});

registerSecret("SUPABASE_SERVICE_ROLE", {
  name: "Supabase Service Role Key (alias)",
  provider: "supabase",
  classification: "restricted",
  required: false,
  rotationDays: 90,
  deferred: false,
  description: "Supabase service role key alias",
});

registerSecret("NEON_DATABASE_URL", {
  name: "Neon Database Connection URL",
  provider: "supabase",
  classification: "restricted",
  required: false,
  rotationDays: 90,
  deferred: false,
  description: "Neon PostgreSQL connection string — used for migration runner and direct SQL access",
});

// ─── Composio ──────────────────────────────────────────────────────────────

registerSecret("COMPOSIO_API_KEY", {
  name: "Composio API Key",
  provider: "other",
  classification: "restricted",
  required: false,
  rotationDays: 90,
  deferred: false,
  description: "Composio API key for external toolkit integration (GitHub, Slack, Gmail, etc.)",
});

registerSecret("COMPOSIO_WEBHOOK_SECRET", {
  name: "Composio Webhook Secret",
  provider: "other",
  classification: "restricted",
  required: false,
  rotationDays: 180,
  deferred: false,
  description: "Webhook signing secret for verifying Composio trigger event payloads",
});

registerSecret("COMPOSIO_API_BASE", {
  name: "Composio API Base URL",
  provider: "other",
  classification: "internal",
  required: false,
  rotationDays: 0,
  deferred: false,
  description: "Composio API base URL (defaults to https://backend.composio.dev)",
});

registerSecret("COMPOSIO_CONNECTED_ACCOUNT_ID_OUTLOOK", {
  name: "Composio Outlook Connected Account ID",
  provider: "other",
  classification: "internal",
  required: false,
  rotationDays: 0,
  deferred: false,
  description: "Connected account ID for Outlook email integration via Composio",
});

registerSecret("COMPOSIO_USER_ID", {
  name: "Composio User ID",
  provider: "other",
  classification: "internal",
  required: false,
  rotationDays: 0,
  deferred: false,
  description: "Default Composio user identifier for session creation",
});

// ─── Cloudflare ──────────────────────────────────────────────────────────────

registerSecret("CLOUDFLARE_API_TOKEN", {
  name: "Cloudflare API Token",
  provider: "cloudflare",
  classification: "restricted",
  required: false,
  rotationDays: 90,
  deferred: false,
  description: "Cloudflare API token for DNS and zone management",
});

registerSecret("CLOUDFLARE_ACCOUNT_ID", {
  name: "Cloudflare Account ID",
  provider: "cloudflare",
  classification: "internal",
  required: false,
  rotationDays: 0,
  deferred: false,
  description: "Cloudflare account identifier",
});

registerSecret("CLOUDFLARE_ZONE_ID", {
  name: "Cloudflare Zone ID",
  provider: "cloudflare",
  classification: "internal",
  required: false,
  rotationDays: 0,
  deferred: false,
  description: "Cloudflare DNS zone identifier for foreman.company",
});

registerSecret("CLOUDFLARE_LOAD_BALANCER_ID", {
  name: "Cloudflare Load Balancer ID",
  provider: "cloudflare",
  classification: "internal",
  required: false,
  rotationDays: 0,
  deferred: false,
  description: "Cloudflare load balancer identifier",
});

registerSecret("CLOUDFLARE_LOAD_BALANCER_POOL_ID", {
  name: "Cloudflare Load Balancer Pool ID",
  provider: "cloudflare",
  classification: "internal",
  required: false,
  rotationDays: 0,
  deferred: false,
  description: "Cloudflare load balancer pool identifier",
});

// ─── Resend (deferred — blocked by FORA-42) ─────────────────────────────────

registerSecret("RESEND_API_KEY", {
  name: "Resend API Key",
  provider: "resend",
  classification: "restricted",
  required: false,
  rotationDays: 90,
  deferred: true,
  deferReason: "Blocked by FORA-42 — CEO must obtain key from resend.com",
  description: "Resend API key for transactional email delivery",
});

registerSecret("EMAIL_FROM", {
  name: "Email From Address",
  provider: "resend",
  classification: "public",
  required: false,
  rotationDays: 0,
  deferred: true,
  deferReason: "Depends on RESEND_API_KEY",
  description: "Sender email address for transactional emails",
});

registerSecret("CEO_REVIEW_EMAIL", {
  name: "CEO Review Email",
  provider: "resend",
  classification: "public",
  required: false,
  rotationDays: 0,
  deferred: true,
  deferReason: "Depends on RESEND_API_KEY",
  description: "Email address for CEO review notifications",
});

// ─── Sentry (deferred — blocked by FORA-42) ─────────────────────────────────

registerSecret("SENTRY_DSN", {
  name: "Sentry DSN",
  provider: "sentry",
  classification: "internal",
  required: false,
  rotationDays: 0,
  deferred: true,
  deferReason: "Blocked by FORA-42 — CEO must create Sentry project at sentry.io",
  description: "Sentry Data Source Name for error monitoring",
});

// ─── AI/Model Providers ─────────────────────────────────────────────────────

registerSecret("OPENROUTER_API_KEY", {
  name: "OpenRouter API Key",
  provider: "openrouter",
  classification: "restricted",
  required: false,
  rotationDays: 90,
  deferred: false,
  description: "OpenRouter API key for LLM provider routing",
});

registerSecret("DASHSCOPE_SG_KEY", {
  name: "DashScope Singapore Key",
  provider: "dashscope",
  classification: "restricted",
  required: false,
  rotationDays: 90,
  deferred: false,
  description: "DashScope API key for Singapore embedding endpoint",
});

registerSecret("DASHSCOPE_US_KEY", {
  name: "DashScope US Virginia Key",
  provider: "dashscope",
  classification: "restricted",
  required: false,
  rotationDays: 90,
  deferred: false,
  description: "DashScope API key for US Virginia chat workers",
});

registerSecret("TOGETHER_API_KEY", {
  name: "Together AI Key",
  provider: "together",
  classification: "restricted",
  required: false,
  rotationDays: 90,
  deferred: false,
  description: "Together AI API key for CEO planner (DeepSeek V3.1 pass-through)",
});

registerSecret("DEEPINFRA_API_KEY", {
  name: "DeepInfra API Key",
  provider: "deepinfra",
  classification: "restricted",
  required: false,
  rotationDays: 90,
  deferred: false,
  description: "DeepInfra API key for OpenClaw template validation",
});

// ─── OpenClaw / Paperclip ───────────────────────────────────────────────────

registerSecret("OPENCLAW_GATEWAY_URL", {
  name: "OpenClaw Gateway URL",
  provider: "openclaw",
  classification: "internal",
  required: false,
  rotationDays: 0,
  deferred: false,
  description: "OpenClaw gateway WebSocket URL for agent runtime",
});

registerSecret("OPENCLAW_GATEWAY_TOKEN", {
  name: "OpenClaw Gateway Token",
  provider: "openclaw",
  classification: "restricted",
  required: false,
  rotationDays: 90,
  deferred: false,
  description: "OpenClaw gateway authentication token (if token-protected)",
});

registerSecret("PAPERCLIP_API_BASE", {
  name: "Paperclip API Base URL",
  provider: "paperclip",
  classification: "internal",
  required: false,
  rotationDays: 0,
  deferred: false,
  description: "Paperclip control plane API base URL",
});

registerSecret("PAPERCLIP_API_KEY", {
  name: "Paperclip API Key",
  provider: "paperclip",
  classification: "restricted",
  required: false,
  rotationDays: 90,
  deferred: false,
  description: "Paperclip API key for agent authentication",
});

// ─── Audit Log ───────────────────────────────────────────────────────────────

const accessLog: SecretAccessEvent[] = [];
const MAX_ACCESS_LOG_SIZE = 1000;

function logAccess(key: string, source?: string): void {
  const event: SecretAccessEvent = { key, timestamp: new Date().toISOString() };
  if (source !== undefined) {
    event.source = source;
  }
  accessLog.push(event);
  if (accessLog.length > MAX_ACCESS_LOG_SIZE) {
    accessLog.shift();
  }
}

// ─── Public API ──────────────────────────────────────────────────────────────

/**
 * Resolve a secret by environment variable name.
 * Logs access for audit purposes and returns metadata alongside the value.
 */
export function resolveSecret(envVar: string, source?: string): SecretResolveResult {
  const meta = SECRET_REGISTRY.get(envVar);

  if (!meta) {
    // Unknown secret — still resolve but flag as unregistered
    const value = process.env[envVar];
    logAccess(envVar, source);
    return {
      value,
      resolved: value !== undefined && value !== "",
      classification: "internal" as SecretClassification,
      deferred: false,
    };
  }

  const value = process.env[envVar];
  logAccess(envVar, source);

  return {
    value,
    resolved: value !== undefined && value !== "",
    classification: meta.classification,
    deferred: meta.deferred,
  };
}

/**
 * Get metadata for a registered secret. Does NOT access the secret value.
 */
export function getSecretMetadata(envVar: string): SecretMetadata | undefined {
  return SECRET_REGISTRY.get(envVar);
}

/**
 * List all registered secrets with their metadata (no values).
 */
export function listSecrets(): Array<{ key: string; meta: SecretMetadata }> {
  return Array.from(SECRET_REGISTRY.entries()).map(([key, meta]) => ({ key, meta }));
}

/**
 * List secrets grouped by provider (no values).
 */
export function listSecretsByProvider(): Record<string, Array<{ key: string; meta: SecretMetadata }>> {
  const result: Record<string, Array<{ key: string; meta: SecretMetadata }>> = {};
  for (const [key, meta] of SECRET_REGISTRY.entries()) {
    const group = result[meta.provider] ?? [];
    group.push({ key, meta });
    result[meta.provider] = group;
  }
  return result;
}

/**
 * Get the access audit log (most recent entries).
 */
export function getAccessLog(limit = 100): SecretAccessEvent[] {
  return accessLog.slice(-limit);
}

/**
 * Redact a secret value for safe logging.
 * Shows first 4 chars and last 4 chars, with *** in between.
 * For values shorter than 12 chars, shows only the length.
 */
export function redactSecret(value: string | undefined): string {
  if (!value) return "<empty>";
  if (value.length <= 12) return `<${value.length} chars>`;
  return `${value.slice(0, 4)}***${value.slice(-4)}`;
}

/**
 * Validate that all required, non-deferred secrets are present.
 * Returns an array of missing secret keys.
 */
export function validateRequiredSecrets(): Array<{ key: string; meta: SecretMetadata }> {
  const missing: Array<{ key: string; meta: SecretMetadata }> = [];
  for (const [key, meta] of SECRET_REGISTRY.entries()) {
    if (meta.required && !meta.deferred) {
      const value = process.env[key];
      if (!value || value.trim() === "") {
        missing.push({ key, meta });
      }
    }
  }
  return missing;
}

/**
 * Validate that all secrets for a specific provider are present.
 * Returns an array of missing secret keys.
 */
export function validateProviderSecrets(provider: SecretMetadata["provider"]): Array<{ key: string; meta: SecretMetadata }> {
  const missing: Array<{ key: string; meta: SecretMetadata }> = [];
  for (const [key, meta] of SECRET_REGISTRY.entries()) {
    if (meta.provider === provider && !meta.deferred) {
      const value = process.env[key];
      if (!value || value.trim() === "") {
        missing.push({ key, meta });
      }
    }
  }
  return missing;
}

/**
 * Get a summary of credential status by provider.
 * Useful for health checks and dashboards.
 */
export function getCredentialStatus(): Record<string, {
  total: number;
  resolved: number;
  deferred: number;
  missing: number;
  restricted: number;
}> {
  const status: Record<string, {
    total: number;
    resolved: number;
    deferred: number;
    missing: number;
    restricted: number;
  }> = {};

  for (const [key, meta] of SECRET_REGISTRY.entries()) {
    if (!status[meta.provider]) {
      status[meta.provider] = { total: 0, resolved: 0, deferred: 0, missing: 0, restricted: 0 };
    }
    const s = status[meta.provider]!;
    s.total++;
    if (meta.deferred) {
      s.deferred++;
    } else {
      const value = process.env[key];
      if (value && value.trim() !== "") {
        s.resolved++;
      } else {
        s.missing++;
      }
    }
    if (meta.classification === "restricted") {
      s.restricted++;
    }
  }

  return status;
}

/**
 * Check if a specific secret needs rotation based on its policy.
 * Returns true if the secret has a rotation policy and has been
 * in the environment for longer than the rotation period.
 *
 * Note: Phase 1 tracks rotation policy in metadata but does not
 * auto-rotate. This is for alerting/documentation purposes.
 */
export function needsRotation(envVar: string, lastRotatedAt?: Date): boolean {
  const meta = SECRET_REGISTRY.get(envVar);
  if (!meta || meta.rotationDays === 0) return false;

  if (!lastRotatedAt) {
    // If we don't know when it was last rotated, assume it needs rotation
    return true;
  }

  const daysSinceRotation = (Date.now() - lastRotatedAt.getTime()) / (1000 * 60 * 60 * 24);
  return daysSinceRotation > meta.rotationDays;
}

/**
 * Get secrets that are deferred (blocked by other issues).
 */
export function getDeferredSecrets(): Array<{ key: string; meta: SecretMetadata }> {
  return Array.from(SECRET_REGISTRY.entries())
    .filter(([, meta]) => meta.deferred)
    .map(([key, meta]) => ({ key, meta }));
}
