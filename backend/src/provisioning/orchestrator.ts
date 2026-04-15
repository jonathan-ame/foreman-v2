import { randomUUID } from "node:crypto";
import type { Logger } from "pino";
import type { Env } from "../config/env.js";
import { insertAgent } from "../db/agents.js";
import { cacheResult } from "../db/idempotency.js";
import { appendLogEntryToFile, writeLogEntry } from "../db/provisioning-log.js";
import type { SupabaseClient } from "../db/supabase.js";
import { step0PaymentGate } from "./steps/step-0-payment-gate.js";
import { step1Idempotency } from "./steps/step-1-idempotency.js";
import { step2ValidateInputs } from "./steps/step-2-validate-inputs.js";
import { step3CreateWorkspace } from "./steps/step-3-create-workspace.js";
import { step4OpenClawAdd } from "./steps/step-4-openclaw-add.js";
import { step5PaperclipHire } from "./steps/step-5-paperclip-hire.js";
import { step6PaperclipApprove } from "./steps/step-6-paperclip-approve.js";
import { step7TokenSync } from "./steps/step-7-token-sync.js";
import { step8ConfigReload } from "./steps/step-8-config-reload.js";
import { step9Verify } from "./steps/step-9-verify.js";
import type { OpenClawClientLike, PaperclipClientLike, StepContext, StepResult, StripeClientLike } from "./steps/types.js";
import type { ProvisionFailure, ProvisionInput, ProvisioningOutcome, ProvisioningResult, ProvisionSuccess } from "./types.js";

export interface ProvisionDependencies {
  clients: {
    paperclip: PaperclipClientLike;
    openclaw: OpenClawClientLike;
    stripe: StripeClientLike;
  };
  db: SupabaseClient;
  logger: Logger;
  env: Env;
}

type StepFn = (ctx: StepContext) => Promise<StepResult>;

export async function provisionForemanAgent(
  input: ProvisionInput,
  deps: ProvisionDependencies
): Promise<ProvisioningResult> {
  const provisioningId = randomUUID();
  const startedAt = new Date();
  const stepLogger = deps.logger.child({ provisioningId });

  const ctx: StepContext = {
    input,
    clients: deps.clients,
    db: deps.db,
    logger: stepLogger,
    state: {
      provisioningId,
      startedAt
    }
  };

  const stepsRun: string[] = [];

  const r0 = await runStep("step_0_payment_gate", step0PaymentGate, ctx, stepsRun);
  if (!r0.ok) {
    return failureResult(r0, ctx, stepsRun, "step_0_payment_gate", "blocked");
  }

  const r1 = await runStep("step_1_idempotency", step1Idempotency, ctx, stepsRun);
  const cachedResult = r1.data?.cachedResult as ProvisioningResult | undefined;
  if (cachedResult) {
    return cachedResult;
  }

  const orderedSteps: Array<[string, StepFn]> = [
    ["step_2_validate_inputs", step2ValidateInputs],
    ["step_3_create_workspace", step3CreateWorkspace],
    ["step_4_openclaw_add", step4OpenClawAdd],
    ["step_5_paperclip_hire", step5PaperclipHire],
    ["step_6_paperclip_approve", step6PaperclipApprove],
    ["step_7_token_sync", step7TokenSync],
    ["step_8_config_reload", step8ConfigReload],
    ["step_9_verify", step9Verify]
  ];

  for (const [stepName, stepFn] of orderedSteps) {
    const result = await runStep(stepName, stepFn, ctx, stepsRun);
    if (!result.ok) {
      return failureResult(result, ctx, stepsRun, stepName, "failed");
    }
  }

  const successResult = await buildSuccessResult(ctx, stepsRun);
  const endedAt = new Date();

  const logEntry = {
    provisioning_id: provisioningId,
    workspace_slug: String(ctx.state.workspaceSlug ?? ""),
    customer_id: input.customerId,
    agent_name: input.agentName,
    role: input.role,
    model_tier: input.modelTier,
    billing_mode_at_time: String(
      (ctx.state.customer as { current_billing_mode?: string } | undefined)?.current_billing_mode ??
        "foreman_managed_tier"
    ),
    started_at: startedAt.toISOString(),
    ended_at: endedAt.toISOString(),
    duration_ms: endedAt.getTime() - startedAt.getTime(),
    outcome: successResult.outcome,
    failed_step: null,
    error_code: null,
    error_message: null,
    rollback_performed: false,
    steps_completed: stepsRun,
    raw_payload_excerpts: {
      paperclipAgentId: successResult.paperclipAgentId,
      openclawAgentId: successResult.openclawAgentId
    },
    idempotency_key: input.idempotencyKey,
    agent_id: successResult.agentId
  };

  await writeLogEntry(deps.db, logEntry);
  await appendLogEntryToFile(stepLogger, logEntry);
  await cacheResult(deps.db, input.idempotencyKey, input.customerId, successResult);

  return successResult;
}

async function runStep(
  stepName: string,
  stepFn: StepFn,
  ctx: StepContext,
  stepsRun: string[]
): Promise<StepResult> {
  try {
    const result = await stepFn(ctx);
    if (result.ok) {
      stepsRun.push(stepName);
      if (result.data) {
        Object.assign(ctx.state, result.data);
      }
    }
    return result;
  } catch (error) {
    ctx.logger.error({ err: error, stepName }, "step threw an exception");
    return {
      ok: false,
      errorCode: "STEP_EXCEPTION",
      errorMessage: error instanceof Error ? error.message : "Unknown step exception"
    };
  }
}

function failureResult(
  result: StepResult,
  ctx: StepContext,
  stepsRun: string[],
  failedStep: string,
  outcome: Extract<ProvisioningOutcome, "failed" | "blocked">
): ProvisionFailure {
  return {
    outcome,
    provisioningId: String(ctx.state.provisioningId),
    failedStep,
    errorCode: result.errorCode ?? "PROVISIONING_FAILED",
    errorMessage: result.errorMessage ?? "Provisioning step failed",
    customerMessage: "We could not complete your agent setup. Please try again.",
    rollbackPerformed: false,
    technicalDetails: {
      stepsCompleted: stepsRun
    }
  };
}

async function buildSuccessResult(ctx: StepContext, stepsRun: string[]): Promise<ProvisionSuccess> {
  const customer = ctx.state.customer as { customer_id: string; workspace_slug: string; current_billing_mode: string };
  const paperclipAgent = ctx.state.paperclipAgent as { id: string };
  const openclawAgentId = String(ctx.state.openclawAgentId);
  const tierSpec = ctx.state.tierSpec as { primary: string; fallbacks: string[] };

  const agentRecord = await insertAgent(ctx.db, {
    customer_id: customer.customer_id,
    workspace_slug: customer.workspace_slug,
    paperclip_agent_id: paperclipAgent.id,
    openclaw_agent_id: openclawAgentId,
    display_name: ctx.input.agentName,
    role: ctx.input.role,
    model_tier: ctx.input.modelTier,
    model_primary: tierSpec.primary,
    model_fallbacks: tierSpec.fallbacks,
    billing_mode_at_provision: customer.current_billing_mode
  });

  const outcome: ProvisionSuccess["outcome"] =
    stepsRun.includes("step_9_verify") ? "success" : "partial_with_warning";

  return {
    outcome,
    agentId: agentRecord.agent_id,
    paperclipAgentId: paperclipAgent.id,
    openclawAgentId,
    provisioningId: String(ctx.state.provisioningId),
    modelPrimary: tierSpec.primary,
    modelFallbacks: tierSpec.fallbacks,
    readyAt: new Date().toISOString()
  };
}
