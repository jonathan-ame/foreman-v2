import type { Context } from "hono";
import type { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../app-deps.js";
import { resolveSessionCustomerId } from "../auth/session.js";
import { TavilyApiError } from "../clients/tavily/errors.js";

const toHttpStatusCode = (statusCode: number): 400 | 401 | 403 | 404 | 422 | 429 | 500 | 502 | 503 => {
  if (statusCode >= 400 && statusCode < 600) {
    return statusCode as 400 | 401 | 403 | 404 | 422 | 429 | 500 | 502 | 503;
  }
  return 500;
};

const errorResponse = (c: Context, err: unknown, logContext: Record<string, unknown>, errorCode: string) => {
  const tavilyErr = err instanceof TavilyApiError ? err : null;
  const status = toHttpStatusCode(tavilyErr?.statusCode ?? 500);
  const code = tavilyErr?.errorCode ?? errorCode;
  const message = err instanceof Error ? err.message : "Internal error";
  return c.json({ error: code, message }, status);
};

const SearchSchema = z.object({
  query: z.string().min(1).max(2000),
  max_results: z.number().int().min(1).max(20).optional(),
  search_depth: z.enum(["basic", "advanced"]).optional(),
  include_raw_content: z.boolean().optional(),
  include_domains: z.array(z.string()).optional(),
  exclude_domains: z.array(z.string()).optional(),
  topic: z.enum(["general", "news"]).optional(),
  days: z.number().int().min(0).optional()
});

const ExtractSchema = z.object({
  urls: z.array(z.string().url()).min(1).max(20),
  extract_depth: z.enum(["basic", "advanced"]).optional()
});

const ResearchSchema = z.object({
  query: z.string().min(1).max(2000),
  max_results: z.number().int().min(1).max(20).optional(),
  search_depth: z.enum(["basic", "advanced"]).optional(),
  include_domains: z.array(z.string()).optional(),
  exclude_domains: z.array(z.string()).optional()
});

export function registerTavilyRoutes(app: Hono, deps: AppDeps) {
  app.post("/api/internal/tavily/search", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    if (!deps.clients.tavily.isConfigured) {
      return c.json({ error: "tavily_not_configured" }, 503);
    }

    const body = await c.req.json();
    const parsed = SearchSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 422);
    }

    try {
      const searchOptions: Parameters<typeof deps.clients.tavily.search>[0] = {
        query: parsed.data.query
      };
      if (parsed.data.max_results) searchOptions.maxResults = parsed.data.max_results;
      if (parsed.data.search_depth) searchOptions.searchDepth = parsed.data.search_depth;
      if (parsed.data.include_raw_content !== undefined) searchOptions.includeRawContent = parsed.data.include_raw_content;
      if (parsed.data.include_domains) searchOptions.includeDomains = parsed.data.include_domains;
      if (parsed.data.exclude_domains) searchOptions.excludeDomains = parsed.data.exclude_domains;
      if (parsed.data.topic) searchOptions.topic = parsed.data.topic;
      if (parsed.data.days !== undefined) searchOptions.days = parsed.data.days;
      const result = await deps.clients.tavily.search(searchOptions);

      return c.json(result);
    } catch (err) {
      deps.logger.error({ err, customerId, query: parsed.data.query }, "tavily: search failed");
      return errorResponse(c, err, { customerId, query: parsed.data.query }, "TAVILY_SEARCH_ERROR");
    }
  });

  app.post("/api/internal/tavily/extract", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    if (!deps.clients.tavily.isConfigured) {
      return c.json({ error: "tavily_not_configured" }, 503);
    }

    const body = await c.req.json();
    const parsed = ExtractSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 422);
    }

    try {
      const extractOptions: { urls: string[]; extractDepth?: "basic" | "advanced" } = {
        urls: parsed.data.urls
      };
      if (parsed.data.extract_depth) extractOptions.extractDepth = parsed.data.extract_depth;
      const result = await deps.clients.tavily.extract(extractOptions);

      return c.json(result);
    } catch (err) {
      deps.logger.error({ err, customerId, urls: parsed.data.urls }, "tavily: extract failed");
      return errorResponse(c, err, { customerId, urls: parsed.data.urls }, "TAVILY_EXTRACT_ERROR");
    }
  });

  app.post("/api/internal/tavily/research", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    if (!deps.clients.tavily.isConfigured) {
      return c.json({ error: "tavily_not_configured" }, 503);
    }

    const body = await c.req.json();
    const parsed = ResearchSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 422);
    }

    try {
      const researchOptions: { query: string; maxResults?: number; searchDepth?: "basic" | "advanced"; includeDomains?: string[]; excludeDomains?: string[] } = {
        query: parsed.data.query
      };
      if (parsed.data.max_results) researchOptions.maxResults = parsed.data.max_results;
      if (parsed.data.search_depth) researchOptions.searchDepth = parsed.data.search_depth;
      if (parsed.data.include_domains) researchOptions.includeDomains = parsed.data.include_domains;
      if (parsed.data.exclude_domains) researchOptions.excludeDomains = parsed.data.exclude_domains;
      const result = await deps.clients.tavily.research(researchOptions);

      return c.json(result);
    } catch (err) {
      deps.logger.error({ err, customerId, query: parsed.data.query }, "tavily: research failed");
      return errorResponse(c, err, { customerId, query: parsed.data.query }, "TAVILY_RESEARCH_ERROR");
    }
  });
}