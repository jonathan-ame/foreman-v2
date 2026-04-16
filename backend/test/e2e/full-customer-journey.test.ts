import { randomUUID } from "node:crypto";
import { execFile, spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { cp, mkdir, rm } from "node:fs/promises";
import { promisify } from "node:util";
import path from "node:path";
import process from "node:process";
import { config as loadDotenv } from "dotenv";
import { chromium, type Browser } from "playwright";
import Stripe from "stripe";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const execFileAsync = promisify(execFile);
const logger = {
  debug: (meta: Record<string, unknown>, message: string) => {
    console.debug(`[e2e] ${message}`, meta);
  }
};

interface RuntimeConfig {
  baseUrl: string;
  port: number;
  paperclipBase: string;
  paperclipApiBase: string;
  paperclipApiKey: string;
  paperclipCompanyId: string;
  stripeSecretKeyTest: string;
  supabaseUrl: string;
  supabaseServiceKey: string;
  openrouterApiKey: string;
  dashscopeApiKey: string;
}

interface CreatedIssue {
  id: string;
}

const ROOT_ENV_PATH = path.resolve(process.cwd(), "..", ".env");

const normalizeBaseUrl = (value: string): string => value.replace(/\/+$/, "");

const required = (value: string | undefined, name: string): string => {
  if (!value || value.trim() === "") {
    throw new Error(`Missing required env var ${name} for e2e test`);
  }
  return value.trim();
};

const waitForServerReady = async (baseUrl: string, timeoutMs = 90_000): Promise<void> => {
  const started = Date.now();
  while (Date.now() - started < timeoutMs) {
    try {
      const response = await fetch(`${baseUrl}/health`);
      if (response.ok) {
        return;
      }
    } catch {
      // server still booting
    }
    await new Promise((resolve) => setTimeout(resolve, 1_000));
  }
  throw new Error(`Timed out waiting for backend at ${baseUrl}`);
};

const paperclipRequest = async <T>(
  cfg: RuntimeConfig,
  method: string,
  apiPath: string,
  body?: unknown
): Promise<T> => {
  const response = await fetch(`${cfg.paperclipApiBase}${apiPath}`, {
    method,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${cfg.paperclipApiKey}`
    },
    ...(body !== undefined ? { body: JSON.stringify(body) } : {})
  });

  const text = await response.text();
  if (!response.ok) {
    throw new Error(`Paperclip ${method} ${apiPath} failed (${response.status}): ${text.slice(0, 400)}`);
  }
  if (!text) {
    return undefined as T;
  }
  return JSON.parse(text) as T;
};

describe("full customer journey e2e", () => {
  let runtime: RuntimeConfig | null = null;
  let supabase: SupabaseClient | null = null;
  let stripe: Stripe | null = null;
  let backendProcess: ChildProcessWithoutNullStreams | null = null;

  let createdCustomerId: string | null = null;
  let createdStripeCustomerId: string | null = null;
  let createdStripeProductId: string | null = null;
  let createdStripePriceId: string | null = null;
  let createdStripeSubscriptionId: string | null = null;
  let createdPaperclipAgentId: string | null = null;
  let createdOpenClawAgentId: string | null = null;
  let createdIssueId: string | null = null;
  let createdWorkspaceSlug: string | null = null;

  beforeAll(async () => {
    loadDotenv({ path: ROOT_ENV_PATH, override: true });

    runtime = {
      port: 18080,
      baseUrl: "http://127.0.0.1:18080",
      paperclipBase: normalizeBaseUrl(required(process.env.PAPERCLIP_API_URL, "PAPERCLIP_API_URL")),
      paperclipApiBase: `${normalizeBaseUrl(required(process.env.PAPERCLIP_API_URL, "PAPERCLIP_API_URL"))}/api`,
      paperclipApiKey: required(process.env.PAPERCLIP_API_KEY, "PAPERCLIP_API_KEY"),
      paperclipCompanyId: required(process.env.PAPERCLIP_COMPANY_ID, "PAPERCLIP_COMPANY_ID"),
      stripeSecretKeyTest: required(process.env.STRIPE_SECRET_KEY_TEST, "STRIPE_SECRET_KEY_TEST"),
      supabaseUrl: required(process.env.SUPABASE_PROJECT_URL, "SUPABASE_PROJECT_URL"),
      supabaseServiceKey: required(process.env.SUPABASE_SERVICE_ROLE, "SUPABASE_SERVICE_ROLE"),
      openrouterApiKey: required(process.env.OPENROUTER_API_KEY, "OPENROUTER_API_KEY"),
      dashscopeApiKey: required(process.env.DASHSCOPE_SG_KEY, "DASHSCOPE_SG_KEY")
    };

    supabase = createClient(runtime.supabaseUrl, runtime.supabaseServiceKey, {
      auth: { persistSession: false, autoRefreshToken: false }
    });
    stripe = new Stripe(runtime.stripeSecretKeyTest);

    const pluginSource = path.resolve(process.cwd(), "..", "plugins", "foreman-hire-agent");
    const pluginTarget = path.resolve(process.env.HOME ?? "", ".openclaw", "plugins", "foreman-hire-agent");
    await mkdir(path.dirname(pluginTarget), { recursive: true });
    await rm(pluginTarget, { recursive: true, force: true });
    await cp(pluginSource, pluginTarget, { recursive: true });

    // Ensure SPA assets are current before the backend serves them.
    await execFileAsync("pnpm", ["--dir", "web", "build"], { cwd: process.cwd() });

    const serverEnv = {
      ...process.env,
      VITEST: "",
      NODE_ENV: "development",
      PORT: String(runtime.port),
      SUPABASE_URL: runtime.supabaseUrl,
      SUPABASE_SERVICE_KEY: runtime.supabaseServiceKey,
      PAPERCLIP_API_BASE: runtime.paperclipBase,
      PAPERCLIP_API_KEY: runtime.paperclipApiKey,
      OPENROUTER_API_KEY: runtime.openrouterApiKey,
      DASHSCOPE_SG_KEY: runtime.dashscopeApiKey,
      STRIPE_MODE: "test",
      STRIPE_SECRET_KEY_TEST: runtime.stripeSecretKeyTest,
      STRIPE_WEBHOOK_SECRET_TEST: process.env.STRIPE_WEBHOOK_SECRET_TEST ?? "whsec_e2e_placeholder",
      STRIPE_PRICE_TIER_1_TEST: process.env.STRIPE_PRICE_TIER_1_TEST ?? "price_e2e_tier_1",
      STRIPE_PRICE_TIER_2_TEST: process.env.STRIPE_PRICE_TIER_2_TEST ?? "price_e2e_tier_2",
      STRIPE_PRICE_TIER_3_TEST: process.env.STRIPE_PRICE_TIER_3_TEST ?? "price_e2e_tier_3",
      STRIPE_PRICE_BYOK_PLATFORM_TEST: process.env.STRIPE_PRICE_BYOK_PLATFORM_TEST ?? "price_e2e_byok"
    };

    backendProcess = spawn("pnpm", ["dev"], {
      cwd: process.cwd(),
      env: serverEnv,
      stdio: "pipe"
    });
    backendProcess.stdout.on("data", () => {
      // Keep stream drained to avoid backpressure.
    });
    backendProcess.stderr.on("data", () => {
      // Keep stream drained to avoid backpressure.
    });

    await waitForServerReady(runtime.baseUrl);
  }, 180_000);

  afterAll(async () => {
    if (runtime && createdIssueId) {
      await paperclipRequest<void>(runtime, "DELETE", `/issues/${createdIssueId}`).catch(() => undefined);
    }

    if (runtime && createdPaperclipAgentId) {
      await paperclipRequest<void>(runtime, "DELETE", `/agents/${createdPaperclipAgentId}`).catch(() => undefined);
    }

    if (createdOpenClawAgentId) {
      await execFileAsync("openclaw", ["agents", "delete", createdOpenClawAgentId, "--force"]).catch(() => undefined);
    }

    if (createdStripeSubscriptionId) {
      await stripe?.subscriptions.cancel(createdStripeSubscriptionId).catch(() => undefined);
    }

    if (createdStripePriceId) {
      await stripe?.prices.update(createdStripePriceId, { active: false }).catch(() => undefined);
    }

    if (createdStripeProductId) {
      await stripe?.products.update(createdStripeProductId, { active: false }).catch(() => undefined);
    }

    if (createdStripeCustomerId) {
      await stripe?.customers.del(createdStripeCustomerId).catch(() => undefined);
    }

    if (createdCustomerId) {
      await supabase?.from("agents").delete().eq("customer_id", createdCustomerId);
      await supabase?.from("customer_sessions").delete().eq("customer_id", createdCustomerId);
      if (createdWorkspaceSlug) {
        await supabase?.from("notifications").delete().eq("workspace_slug", createdWorkspaceSlug);
      }
      await supabase?.from("customers").delete().eq("customer_id", createdCustomerId);
    if (!runtime || !supabase || !stripe) {
      throw new Error("E2E runtime not initialized");
    }

    }

    if (backendProcess && !backendProcess.killed) {
      backendProcess.kill("SIGTERM");
      await new Promise((resolve) => {
        backendProcess?.once("exit", resolve);
      });
    }
  }, 180_000);

  it("runs signup to working CEO journey", async () => {
    const runId = randomUUID().slice(0, 8);
    const email = `foreman-e2e-${runId}@example.com`;
    const workspaceSlug = `e2e-${runId}`;
    const displayName = `E2E Customer ${runId}`;
    const ceoDisplayName = `CEO E2E ${runId}`;
    createdWorkspaceSlug = workspaceSlug;

    const stripeCustomer = await stripe.customers.create({
      email,
      name: displayName
    });
    createdStripeCustomerId = stripeCustomer.id;

    const stripeProduct = await stripe.products.create({
      name: `Foreman E2E Tier 1 ${runId}`,
      description: "Temporary product for full-customer-journey e2e smoke."
    });
    createdStripeProductId = stripeProduct.id;

    const stripePrice = await stripe.prices.create({
      product: stripeProduct.id,
      currency: "usd",
      unit_amount: 1000,
      recurring: {
        interval: "month"
      }
    });
    createdStripePriceId = stripePrice.id;

    const stripeSubscription = await stripe.subscriptions.create({
      customer: stripeCustomer.id,
      items: [{ price: stripePrice.id }],
      trial_period_days: 14
    });
    createdStripeSubscriptionId = stripeSubscription.id;

    const customerId = randomUUID();
    createdCustomerId = customerId;
      const { error: insertError } = await supabase.from("customers").insert({
      customer_id: customerId,
      workspace_slug: workspaceSlug,
      email,
      display_name: displayName,
      stripe_customer_id: stripeCustomer.id,
      current_billing_mode: "foreman_managed_tier",
      current_tier: "tier_1",
      payment_status: "active",
      paperclip_company_id: runtime.paperclipCompanyId,
      tokens_consumed_current_period_cents: 0,
      tier_allowance_cents: 1_000_000
    });
    if (insertError) {
      throw new Error(`Failed to seed customer row: ${insertError.message}`);
    }

    let browser: Browser | null = null;
    try {
      browser = await chromium.launch({ headless: true });
      const context = await browser.newContext();
      const page = await context.newPage();

      await page.goto(runtime.baseUrl, { waitUntil: "domcontentloaded" });
      await page.getByLabel("Customer email").fill(email);
      await page.getByRole("button", { name: "Sign in (dev)" }).click();

      await page.getByText(`Logged in as ${email}.`).waitFor({ state: "visible", timeout: 30_000 });
      await page.getByLabel("Display name").fill(ceoDisplayName);
      await page.getByRole("button", { name: "Create CEO" }).click();

      await page.waitForURL(/\/dashboard$/, { timeout: 180_000 });

      const { data: createdAgent, error: agentsError } = await supabase
        .from("agents")
        .select("*")
        .eq("customer_id", customerId)
        .eq("role", "ceo")
        .eq("display_name", ceoDisplayName)
        .maybeSingle();
      if (agentsError) {
        throw new Error(`Failed to query provisioned agent row: ${agentsError.message}`);
      }
      if (!createdAgent) {
        throw new Error("Provisioning did not create a CEO agent row");
      }
      createdPaperclipAgentId = String(createdAgent.paperclip_agent_id);
      createdOpenClawAgentId = String(createdAgent.openclaw_agent_id);

      const issue = await paperclipRequest<CreatedIssue>(
        runtime,
        "POST",
        `/companies/${runtime.paperclipCompanyId}/issues`,
        {
          title: `E2E smoke task ${runId}`,
          description: "Reply with the sum of 19 + 23 and one sentence explaining your result.",
          status: "todo",
          priority: "low",
          assigneeAgentId: createdPaperclipAgentId
        }
      );
      createdIssueId = issue.id;
      expect(createdIssueId).toBeTruthy();

      const run = await paperclipRequest<{ id: string }>(
        runtime,
        "POST",
        `/agents/${createdPaperclipAgentId}/heartbeat/invoke`,
        {
          taskId: createdIssueId,
          wakeReason: "on_demand"
        }
      );
      expect(run.id).toBeTruthy();

      const startedAt = Date.now();
      const maxPollMs = 180_000;
      const maxBackoffMs = 15_000;
      let finalRun: { status?: string; error?: string } | null = null;
      let attempt = 1;
      let backoffMs = 2_000;
      while (Date.now() - startedAt < maxPollMs) {
        const current = await paperclipRequest<{ status?: string; error?: string }>(
          runtime,
          "GET",
          `/heartbeat-runs/${run.id}`
        );
        logger.debug(
          {
            attempt,
            elapsedMs: Date.now() - startedAt,
            status: current.status ?? "pending"
          },
          "polling for run completion"
        );
        if (current.status === "succeeded" || current.status === "failed" || current.status === "cancelled") {
          finalRun = current;
          break;
        }
        await new Promise((resolve) => setTimeout(resolve, backoffMs));
        backoffMs = Math.min(backoffMs * 2, maxBackoffMs);
        attempt += 1;
      }

      expect(finalRun).not.toBeNull();
      if (!finalRun) {
        throw new Error(`Heartbeat run ${run.id} did not reach terminal state within ${maxPollMs}ms`);
      }
      if (finalRun.status !== "succeeded") {
        throw new Error(`Heartbeat run ${run.id} ended with unexpected status=${finalRun.status ?? "unknown"}`);
      }

      const commentsResponse = await paperclipRequest<unknown>(
        runtime,
        "GET",
        `/issues/${createdIssueId}/comments?limit=20&offset=0`
      );
      const comments = Array.isArray(commentsResponse)
        ? commentsResponse
        : Array.isArray((commentsResponse as { items?: unknown[] }).items)
          ? (commentsResponse as { items: unknown[] }).items
          : [];
      if (comments.length === 0) {
        const detail = await paperclipRequest<{ error?: string; stdoutExcerpt?: string; stderrExcerpt?: string }>(
          runtime,
          "GET",
          `/heartbeat-runs/${run.id}`
        );
        throw new Error(
          `Heartbeat run ${run.id} produced no comments. status=${finalRun?.status ?? "unknown"} error=${detail.error ?? "unknown"} stdout=${(detail.stdoutExcerpt ?? "").slice(0, 300)}`
        );
      }
      expect(comments.length).toBeGreaterThan(0);

      const hasMeaningfulBody = comments.some((entry) => {
        if (!entry || typeof entry !== "object") {
          return false;
        }
        const body = (entry as { body?: unknown }).body;
        return typeof body === "string" && body.trim().length > 20;
      });
      expect(hasMeaningfulBody).toBe(true);

      const includesExpectedAnswer = comments.some((entry) => {
        if (!entry || typeof entry !== "object") {
          return false;
        }
        const body = (entry as { body?: unknown }).body;
        return typeof body === "string" && body.includes("42");
      });
      expect(includesExpectedAnswer).toBe(true);
    } finally {
      if (browser) {
        await browser.close();
      }
    }
  }, 600_000);
});
