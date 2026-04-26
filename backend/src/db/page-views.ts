import type { SupabaseClient } from "./supabase.js";

export interface PageViewRow {
  path: string;
  referrer: string | null;
  utm_source: string | null;
  utm_medium: string | null;
  utm_campaign: string | null;
  created_at: string;
}

export async function insertPageView(
  db: SupabaseClient,
  input: {
    path: string;
    referrer?: string;
    utmSource?: string;
    utmMedium?: string;
    utmCampaign?: string;
    userAgent?: string;
    ipHash?: string;
  }
): Promise<void> {
  const { error } = await db.from("page_views").insert({
    path: input.path,
    referrer: input.referrer ?? null,
    utm_source: input.utmSource ?? null,
    utm_medium: input.utmMedium ?? null,
    utm_campaign: input.utmCampaign ?? null,
    user_agent: input.userAgent ?? null,
    ip_hash: input.ipHash ?? null,
  });

  if (error) {
    throw new Error(`Failed to insert page view: ${error.message}`);
  }
}

export interface PageViewStats {
  total_1d: number;
  total_7d: number;
  total_30d: number;
  unique_ip_1d: number;
  top_paths_1d: Array<{ path: string; count: number }>;
  top_sources_1d: Array<{ source: string; count: number }>;
}

export async function getPageViewStats(db: SupabaseClient): Promise<PageViewStats> {
  const now = new Date();
  const since1d = new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString();
  const since7d = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();
  const since30d = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString();

  const { data, error } = await db
    .from("page_views")
    .select("path, utm_source, ip_hash, created_at")
    .gte("created_at", since30d);

  if (error) {
    throw new Error(`Failed to fetch page views: ${error.message}`);
  }

  const rows = (data ?? []) as {
    path: string;
    utm_source: string | null;
    ip_hash: string | null;
    created_at: string;
  }[];

  let total1d = 0;
  let total7d = 0;
  let total30d = 0;
  const uniqueIps1d = new Set<string>();
  const pathCounts1d = new Map<string, number>();
  const sourceCounts1d = new Map<string, number>();

  for (const row of rows) {
    total30d++;
    if (row.created_at >= since7d) total7d++;
    if (row.created_at >= since1d) {
      total1d++;
      if (row.ip_hash) uniqueIps1d.add(row.ip_hash);
      pathCounts1d.set(row.path, (pathCounts1d.get(row.path) ?? 0) + 1);
      const src = row.utm_source ?? "direct";
      sourceCounts1d.set(src, (sourceCounts1d.get(src) ?? 0) + 1);
    }
  }

  const topPaths1d = Array.from(pathCounts1d.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .map(([path, count]) => ({ path, count }));

  const topSources1d = Array.from(sourceCounts1d.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([source, count]) => ({ source, count }));

  return {
    total_1d: total1d,
    total_7d: total7d,
    total_30d: total30d,
    unique_ip_1d: uniqueIps1d.size,
    top_paths_1d: topPaths1d,
    top_sources_1d: topSources1d,
  };
}
