import type { Logger } from "pino";
import type { PaperclipClient } from "./client.js";
import type { PaperclipAgent } from "./types.js";

type JsonRecord = Record<string, unknown>;

const isObject = (value: unknown): value is JsonRecord =>
  typeof value === "object" && value !== null && !Array.isArray(value);

const deepMerge = (base: unknown, patch: unknown): unknown => {
  if (!isObject(base) || !isObject(patch)) {
    return patch;
  }
  const merged: JsonRecord = { ...base };
  for (const [key, value] of Object.entries(patch)) {
    merged[key] = key in merged ? deepMerge(merged[key], value) : value;
  }
  return merged;
};

/**
 * Safely PATCH a Paperclip agent's config by reading the full current
 * config first, merging the changes, and sending the merged payload.
 *
 * Paperclip bug #964: PATCH replaces adapterConfig entirely instead
 * of merging. This wrapper prevents accidental field wipes.
 */
export async function safePatchAgent(
  client: Pick<PaperclipClient, "getAgent" | "patchAgent">,
  companyId: string,
  agentId: string,
  patch: JsonRecord,
  logger: Logger
): Promise<void> {
  const current = await client.getAgent(agentId);
  const merged = deepMerge(current as unknown as JsonRecord, patch) as JsonRecord;

  const currentAdapter = (current.adapterConfig ?? {}) as JsonRecord;
  const mergedAdapter = (merged.adapterConfig ?? {}) as JsonRecord;
  const currentHeaders = (currentAdapter.headers ?? {}) as JsonRecord;
  const mergedHeaders = (mergedAdapter.headers ?? {}) as JsonRecord;

  if (!mergedAdapter.gatewayUrl && currentAdapter.gatewayUrl) {
    throw new Error("safePatchAgent: merge would wipe gatewayUrl - aborting");
  }
  if (!mergedHeaders["x-openclaw-token"] && currentHeaders["x-openclaw-token"]) {
    throw new Error("safePatchAgent: merge would wipe x-openclaw-token - aborting");
  }

  // Send only patch-intended top-level fields, but with fully merged nested payloads.
  const payload: Partial<PaperclipAgent> & JsonRecord = { ...patch };
  if ("adapterConfig" in patch) {
    payload.adapterConfig = mergedAdapter as PaperclipAgent["adapterConfig"];
  }
  if ("runtimeConfig" in patch) {
    payload.runtimeConfig = merged.runtimeConfig as JsonRecord;
  }
  if ("metadata" in patch) {
    payload.metadata = merged.metadata as JsonRecord;
  }

  await client.patchAgent(agentId, payload);
  logger.info({ companyId, agentId }, "safePatchAgent: PATCH succeeded with merge protection");
}

