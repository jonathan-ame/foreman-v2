import { appendFile, mkdir } from "node:fs/promises";
import path from "node:path";
import type { Logger } from "pino";
import { env } from "../config/env.js";
import type { ProvisioningOutcome } from "../provisioning/types.js";
import type { SupabaseClient } from "./supabase.js";

export interface ProvisioningLogEntry {
  provisioning_id: string;
  workspace_slug: string;
  customer_id: string;
  agent_name: string;
  role: string;
  model_tier: string;
  billing_mode_at_time: string;
  started_at: string;
  ended_at: string | null;
  duration_ms: number | null;
  outcome: ProvisioningOutcome;
  failed_step: string | null;
  error_code: string | null;
  error_message: string | null;
  rollback_performed: boolean;
  steps_completed: string[];
  raw_payload_excerpts: Record<string, unknown> | null;
  idempotency_key: string;
  agent_id: string | null;
}

export async function writeLogEntry(db: SupabaseClient, entry: ProvisioningLogEntry): Promise<void> {
  const { error } = await db.from("provisioning_log").insert(entry);
  if (error) {
    throw new Error(`Failed to write provisioning log entry: ${error.message}`);
  }
}

export async function appendLogEntryToFile(
  logger: Logger,
  entry: ProvisioningLogEntry
): Promise<void> {
  await mkdir(env.FOREMAN_LOG_DIR, { recursive: true });
  const logPath = path.join(env.FOREMAN_LOG_DIR, "provisioning.jsonl");
  await appendFile(logPath, `${JSON.stringify(entry)}\n`, "utf8");
  logger.debug({ logPath }, "appended provisioning log entry to file");
}
