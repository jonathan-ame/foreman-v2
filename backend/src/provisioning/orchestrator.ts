import { randomUUID } from "node:crypto";
import type { Logger } from "pino";
import type { Env } from "../config/env.js";
import { insertAgent } from "../db/agents.js";
import { recordFunnelEvent } from "../db/funnel-events.js";
import { cacheResult } from "../db/idempotency.js";
import { appendLogEntryToFile, writeLogEntry } from "../db/provisioning-log.js";
import type { SupabaseClient } from "../db/supabase.js";
import { step0PaymentGate } from "./steps/step-0-payment-gate.js";
import { rollbackStep0PaymentGate } from "./steps/step-0-payment-gate.js";
import { step1Idempotency } from "./steps/step-1-idempotency.js";
import { rollbackStep1Idempotency } from "./steps/step-1-idempotency.js";
import { step2ValidateInputs } from "./steps/step-2-validate-inputs.js";
import { rollbackStep2ValidateInputs } from "./steps/step-2-validate-inputs.js";
import { step3CreateWorkspace } from "./steps/step-3-create-workspace.js";
import { rollbackStep3CreateWorkspace } from "./steps/step-3-create-workspace.js";
import { step4OpenClawAdd } from "./steps/step-4-openclaw-add.js";
import { rollbackStep4OpenClawAdd } from "./steps/step-4-openclaw-add.js";
import { step5PaperclipHire } from "./steps/step-5-paperclip-hire.js";
import { rollbackStep5PaperclipHire } from "./steps/step-5-paperclip-hire.js";
import { step6PaperclipApprove } from "./steps/step-6-paperclip-approve.js";
import { rollbackStep6PaperclipApprove } from "./steps/step-6-paperclip-approve.js";
import { step7TokenSync } from "./steps/step-7-token-sync.js";
import { rollbackStep7TokenSync } from "./steps/step-7-token-sync.js";
import { step8ConfigReload } from "./steps/step-8-config-reload.js";
import { rollbackStep8ConfigReload } from "./steps/step-8-config-reload.js";
import { step9Verify } from "./steps/step-9-verify.js";
import { rollbackStep9Verify } from "./steps/step-9-verify.js";
import type { ComposioClientLike, OpenClawClientLike, PaperclipClientLike, StepContext, StepResult, StripeClientLike } from "./steps/types.js";
import type { ProvisionFailure, ProvisionInput, ProvisioningOutcome, ProvisioningResult, ProvisionSuccess } from "./types.js";

export interface ProvisionDependencies {
  clients: {
    paperclip: PaperclipClientLike;
    openclaw: OpenClawClientLike;
    stripe: StripeClientLike;
    composio: ComposioClientLike;
  };
  db: SupabaseClient;
  logger: Logger;
  env: Env;
}

type StepFn = (ctx: StepContext) => Promise<StepResult>;
type RollbackFn = (ctx: StepContext) => Promise<void>;

interface ProvisioningStep {
  name: string;
  run: StepFn;
  rollback: RollbackFn;
}

const STEPS: ProvisioningStep[] = [
  { name: "step_0_payment_gate", run: step0PaymentGate, rollback: rollbackStep0PaymentGate },
  { name: "step_1_idempotency", run: step1Idempotency, rollback: rollbackStep1Idempotency },
  { name: "step_2_validate_inputs", run: step2ValidateInputs, rollback: rollbackStep2ValidateInputs },
  { name: "step_3_create_workspace", run: step3CreateWorkspace, rollback: rollbackStep3CreateWorkspace },
  { name: "step_4_openclaw_add", run: step4OpenClawAdd, rollback: rollbackStep4OpenClawAdd },
  { name: "step_5_paperclip_hire", run: step5PaperclipHire, rollback: rollbackStep5PaperclipHire },
  { name: "step_6_paperclip_approve", run: step6PaperclipApprove, rollback: rollbackStep6PaperclipApprove },
  { name: "step_7_token_sync", run: step7TokenSync, rollback: rollbackStep7TokenSync },
  { name: "step_8_config_reload", run: step8ConfigReload, rollback: rollbackStep8ConfigReload },
  { name: "step_9_verify", run: step9Verify, rollback: rollbackStep9Verify }
];

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
  const rollbackActions: string[] = [];

  const step0 = STEPS[0]!;
  const r0 = await runStep(step0, ctx, stepsRun);
  if (!r0.ok) {
    return await failProvisioning({
      failedStep: step0.name,
      failedOutcome: "blocked",
      failedResult: r0,
      ctx,
      stepsRun,
      rollbackActions,
      deps
    });
  }

  const step1 = STEPS[1]!;
  const r1 = await runStep(step1, ctx, stepsRun);
  const cachedResult = r1.data?.cachedResult as ProvisioningResult | undefined;
  if (cachedResult) {
    return cachedResult;
  }

  for (let i = 2; i < STEPS.length; i += 1) {
    const step = STEPS[i]!;
    const result = await runStep(step, ctx, stepsRun);
    if (!result.ok) {
      await rollbackTo(i, ctx, stepsRun, rollbackActions);
      return await failProvisioning({
        failedStep: step.name,
        failedOutcome: "failed",
        failedResult: result,
        ctx,
        stepsRun,
        rollbackActions,
        deps
      });
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

  // Fire activation funnel events (best-effort, non-blocking).
  const workspaceSlug = logEntry.workspace_slug;
  if (workspaceSlug && successResult.outcome !== "partial_with_warning") {
    const isFirstAgentForWorkspace = stepsRun.includes("step_9_verify");
    if (isFirstAgentForWorkspace) {
      void (async () => {
        try {
          await recordFunnelEvent(deps.db, workspaceSlug, "first_agent_running");
          if (input.role === "ceo") {
            await recordFunnelEvent(deps.db, workspaceSlug, "signup");
          }
        } catch (err) {
          deps.logger.warn({ err, workspaceSlug }, "failed to record funnel event after provisioning");
        }
      })();
    }
  }

  return successResult;
}

async function runStep(step: ProvisioningStep, ctx: StepContext, stepsRun: string[]): Promise<StepResult> {
  try {
    const result = await step.run(ctx);
    if (result.ok) {
      stepsRun.push(step.name);
      if (result.data) {
        Object.assign(ctx.state, result.data);
      }
    }
    return result;
  } catch (error) {
    ctx.logger.error({ err: error, stepName: step.name }, "step threw an exception");
    return {
      ok: false,
      errorCode: "STEP_EXCEPTION",
      errorMessage: error instanceof Error ? error.message : "Unknown step exception"
    };
  }
}

async function rollbackTo(
  stepIndex: number,
  ctx: StepContext,
  completed: string[],
  rollbackActions: string[]
): Promise<void> {
  for (let i = stepIndex - 1; i >= 0; i -= 1) {
    const step = STEPS[i];
    if (!step) {
      continue;
    }
    if (!completed.includes(step.name)) {
      continue;
    }
    try {
      await step.rollback(ctx);
      rollbackActions.push(`${step.name}:ok`);
      ctx.logger.info({ step: step.name }, "rollback completed");
    } catch (error) {
      rollbackActions.push(`${step.name}:failed`);
      ctx.logger.warn({ step: step.name, err: error }, "rollback failed — continuing");
    }
  }
}

function failureResult(
  result: StepResult,
  ctx: StepContext,
  stepsRun: string[],
  failedStep: string,
  outcome: Extract<ProvisioningOutcome, "failed" | "blocked">,
  rollbackActions: string[]
): ProvisionFailure {
  return {
    outcome,
    provisioningId: String(ctx.state.provisioningId),
    failedStep,
    errorCode: result.errorCode ?? "PROVISIONING_FAILED",
    errorMessage: result.errorMessage ?? "Provisioning step failed",
    customerMessage: "We could not complete your agent setup. Please try again.",
    rollbackPerformed: rollbackActions.length > 0,
    technicalDetails: {
      stepsCompleted: stepsRun,
      rollbackActions
    }
  };
}

async function failProvisioning(params: {
  failedStep: string;
  failedOutcome: Extract<ProvisioningOutcome, "failed" | "blocked">;
  failedResult: StepResult;
  ctx: StepContext;
  stepsRun: string[];
  rollbackActions: string[];
  deps: ProvisionDependencies;
}): Promise<ProvisionFailure> {
  const { failedStep, failedOutcome, failedResult, ctx, stepsRun, rollbackActions, deps } = params;
  const failure = failureResult(
    failedResult,
    ctx,
    stepsRun,
    failedStep,
    failedOutcome,
    rollbackActions
  );

  const endedAt = new Date();
  const startedAt = new Date(String(ctx.state.startedAt));
  const customer = ctx.state.customer as { workspace_slug?: string; current_billing_mode?: string } | undefined;

  const logEntry = {
    provisioning_id: failure.provisioningId,
    workspace_slug: customer?.workspace_slug ?? "",
    customer_id: ctx.input.customerId,
    agent_name: ctx.input.agentName,
    role: ctx.input.role,
    model_tier: ctx.input.modelTier,
    billing_mode_at_time: customer?.current_billing_mode ?? "foreman_managed_tier",
    started_at: startedAt.toISOString(),
    ended_at: endedAt.toISOString(),
    duration_ms: endedAt.getTime() - startedAt.getTime(),
    outcome: failure.outcome,
    failed_step: failure.failedStep,
    error_code: failure.errorCode,
    error_message: failure.errorMessage,
    rollback_performed: failure.rollbackPerformed,
    steps_completed: stepsRun,
    raw_payload_excerpts: failure.technicalDetails,
    idempotency_key: ctx.input.idempotencyKey,
    agent_id: null
  };

  await writeLogEntry(deps.db, logEntry);
  await appendLogEntryToFile(deps.logger, logEntry);
  return failure;
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
