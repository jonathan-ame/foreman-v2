import type { Hono } from "hono";
import { getAgentStatusCounts } from "../db/agents.js";
import type { AppDeps } from "../app-deps.js";

interface IntegrationCheckResult {
  ok: boolean;
  [key: string]: unknown;
}

const checkSupabase = async (deps: AppDeps): Promise<IntegrationCheckResult> => {
  const startedAt = Date.now();
  try {
    const { error } = await deps.db.from("customers").select("customer_id", { head: true, count: "exact" }).limit(1);
    if (error) {
      return { ok: false, error: error.message };
    }
    return { ok: true, latency_ms: Date.now() - startedAt };
  } catch (error) {
    return { ok: false, error: error instanceof Error ? error.message : String(error) };
  }
};

const checkPaperclip = async (deps: AppDeps): Promise<IntegrationCheckResult> => {
  try {
    const response = await deps.clients.paperclip.ping();
    return {
      ok: response.ok,
      ...(response.version ? { version: response.version } : {})
    };
  } catch (error) {
    return { ok: false, error: error instanceof Error ? error.message : String(error) };
  }
};

const checkOpenClawGateway = async (deps: AppDeps): Promise<IntegrationCheckResult> => {
  try {
    const status = await deps.clients.openclaw.gatewayStatus();
    return {
      ok: status.running === true,
      ...(status.pid !== undefined ? { pid: status.pid } : {}),
      ...(status.listening ? { listening: status.listening } : {})
    };
  } catch (error) {
    return { ok: false, error: error instanceof Error ? error.message : String(error) };
  }
};

const checkOpenRouter = async (deps: AppDeps): Promise<IntegrationCheckResult> => {
  try {
    const response = await fetch("https://openrouter.ai/api/v1/models", {
      method: "GET",
      headers: {
        Authorization: `Bearer ${deps.env.OPENROUTER_API_KEY}`
      }
    });
    if (!response.ok) {
      return { ok: false, status_code: response.status };
    }
    const payload = (await response.json().catch(() => ({}))) as { data?: unknown[] };
    return {
      ok: true,
      models_available: Array.isArray(payload.data) ? payload.data.length : 0
    };
  } catch (error) {
    return { ok: false, error: error instanceof Error ? error.message : String(error) };
  }
};

const checkAgentCounts = async (deps: AppDeps): Promise<IntegrationCheckResult> => {
  try {
    const counts = await getAgentStatusCounts(deps.db);
    return {
      ok: true,
      active_count: counts.active_count,
      paused_count: counts.paused_count
    };
  } catch (error) {
    return { ok: false, error: error instanceof Error ? error.message : String(error) };
  }
};

export function registerHealthRoutes(app: Hono, deps: AppDeps) {
  app.get("/api/internal/health/integration", async (c) => {
    const backendSelf: IntegrationCheckResult = { ok: true };
    const [supabase, paperclipApi, openclawGateway, openrouter, activeAgents] = await Promise.all([
      checkSupabase(deps),
      checkPaperclip(deps),
      checkOpenClawGateway(deps),
      checkOpenRouter(deps),
      checkAgentCounts(deps)
    ]);

    const status =
      !backendSelf.ok || !supabase.ok || !paperclipApi.ok || !openclawGateway.ok
        ? "down"
        : !openrouter.ok || !activeAgents.ok
          ? "degraded"
          : "ok";

    return c.json({
      status,
      checks: {
        backend_self: backendSelf,
        supabase,
        paperclip_api: paperclipApi,
        openclaw_gateway: openclawGateway,
        openrouter,
        active_agents: activeAgents
      },
      checked_at: new Date().toISOString()
    });
  });
}
