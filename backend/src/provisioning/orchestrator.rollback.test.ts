import { beforeEach, describe, expect, it, vi } from "vitest";
import { createLogger } from "../config/logger.js";
import { provisionForemanAgent } from "./orchestrator.js";

const failAtStep = vi.hoisted(() => ({ value: "none" as string }));

const stepRuns = vi.hoisted(() => ({
  s0: vi.fn(async () =>
    failAtStep.value === "step_0_payment_gate"
      ? { ok: false, errorCode: "step_0_payment_gate_FAILED", errorMessage: "step_0_payment_gate failed" }
      : { ok: true }
  ),
  s1: vi.fn(async () =>
    failAtStep.value === "step_1_idempotency"
      ? { ok: false, errorCode: "step_1_idempotency_FAILED", errorMessage: "step_1_idempotency failed" }
      : { ok: true }
  ),
  s2: vi.fn(async () =>
    failAtStep.value === "step_2_validate_inputs"
      ? { ok: false, errorCode: "step_2_validate_inputs_FAILED", errorMessage: "step_2_validate_inputs failed" }
      : { ok: true }
  ),
  s3: vi.fn(async () =>
    failAtStep.value === "step_3_create_workspace"
      ? { ok: false, errorCode: "step_3_create_workspace_FAILED", errorMessage: "step_3_create_workspace failed" }
      : { ok: true }
  ),
  s4: vi.fn(async () =>
    failAtStep.value === "step_4_openclaw_add"
      ? { ok: false, errorCode: "step_4_openclaw_add_FAILED", errorMessage: "step_4_openclaw_add failed" }
      : { ok: true }
  ),
  s5: vi.fn(async () =>
    failAtStep.value === "step_5_paperclip_hire"
      ? { ok: false, errorCode: "step_5_paperclip_hire_FAILED", errorMessage: "step_5_paperclip_hire failed" }
      : { ok: true }
  ),
  s6: vi.fn(async () =>
    failAtStep.value === "step_6_paperclip_approve"
      ? { ok: false, errorCode: "step_6_paperclip_approve_FAILED", errorMessage: "step_6_paperclip_approve failed" }
      : { ok: true }
  ),
  s7: vi.fn(async () =>
    failAtStep.value === "step_7_token_sync"
      ? { ok: false, errorCode: "step_7_token_sync_FAILED", errorMessage: "step_7_token_sync failed" }
      : { ok: true }
  ),
  s8: vi.fn(async () =>
    failAtStep.value === "step_8_config_reload"
      ? { ok: false, errorCode: "step_8_config_reload_FAILED", errorMessage: "step_8_config_reload failed" }
      : { ok: true }
  ),
  s9: vi.fn(async () =>
    failAtStep.value === "step_9_verify"
      ? { ok: false, errorCode: "step_9_verify_FAILED", errorMessage: "step_9_verify failed" }
      : { ok: true }
  )
}));

const stepRollbacks = vi.hoisted(() => ({
  s0: vi.fn(async () => undefined),
  s1: vi.fn(async () => undefined),
  s2: vi.fn(async () => undefined),
  s3: vi.fn(async () => undefined),
  s4: vi.fn(async () => undefined),
  s5: vi.fn(async () => undefined),
  s6: vi.fn(async () => undefined),
  s7: vi.fn(async () => undefined),
  s8: vi.fn(async () => undefined),
  s9: vi.fn(async () => undefined)
}));

const writeLogEntryMock = vi.hoisted(() => vi.fn().mockResolvedValue(undefined));
const appendLogEntryToFileMock = vi.hoisted(() => vi.fn().mockResolvedValue(undefined));

vi.mock("./steps/step-0-payment-gate.js", () => ({
  step0PaymentGate: stepRuns.s0,
  rollbackStep0PaymentGate: stepRollbacks.s0
}));
vi.mock("./steps/step-1-idempotency.js", () => ({
  step1Idempotency: stepRuns.s1,
  rollbackStep1Idempotency: stepRollbacks.s1
}));
vi.mock("./steps/step-2-validate-inputs.js", () => ({
  step2ValidateInputs: stepRuns.s2,
  rollbackStep2ValidateInputs: stepRollbacks.s2
}));
vi.mock("./steps/step-3-create-workspace.js", () => ({
  step3CreateWorkspace: stepRuns.s3,
  rollbackStep3CreateWorkspace: stepRollbacks.s3
}));
vi.mock("./steps/step-4-openclaw-add.js", () => ({
  step4OpenClawAdd: stepRuns.s4,
  rollbackStep4OpenClawAdd: stepRollbacks.s4
}));
vi.mock("./steps/step-5-paperclip-hire.js", () => ({
  step5PaperclipHire: stepRuns.s5,
  rollbackStep5PaperclipHire: stepRollbacks.s5
}));
vi.mock("./steps/step-6-paperclip-approve.js", () => ({
  step6PaperclipApprove: stepRuns.s6,
  rollbackStep6PaperclipApprove: stepRollbacks.s6
}));
vi.mock("./steps/step-7-token-sync.js", () => ({
  step7TokenSync: stepRuns.s7,
  rollbackStep7TokenSync: stepRollbacks.s7
}));
vi.mock("./steps/step-8-config-reload.js", () => ({
  step8ConfigReload: stepRuns.s8,
  rollbackStep8ConfigReload: stepRollbacks.s8
}));
vi.mock("./steps/step-9-verify.js", () => ({
  step9Verify: stepRuns.s9,
  rollbackStep9Verify: stepRollbacks.s9
}));
vi.mock("../db/provisioning-log.js", () => ({
  writeLogEntry: writeLogEntryMock,
  appendLogEntryToFile: appendLogEntryToFileMock
}));

describe("provisionForemanAgent rollback", () => {
  beforeEach(() => {
    failAtStep.value = "none";
    for (const fn of Object.values(stepRuns)) {
      fn.mockClear();
    }
    for (const fn of Object.values(stepRollbacks)) {
      fn.mockClear();
    }
    writeLogEntryMock.mockClear();
    appendLogEntryToFileMock.mockClear();
  });

  const deps = {
    clients: {} as never,
    db: {} as never,
    logger: createLogger("rollback-test"),
    env: {} as never
  };

  const input = {
    customerId: "c1",
    agentName: "CEO",
    role: "ceo" as const,
    modelTier: "open" as const,
    idempotencyKey: "idem-1"
  };

  it.each([
    ["step_3_create_workspace", ["s2", "s1", "s0"]],
    ["step_4_openclaw_add", ["s3", "s2", "s1", "s0"]],
    ["step_5_paperclip_hire", ["s4", "s3", "s2", "s1", "s0"]],
    ["step_6_paperclip_approve", ["s5", "s4", "s3", "s2", "s1", "s0"]],
    ["step_7_token_sync", ["s6", "s5", "s4", "s3", "s2", "s1", "s0"]],
    ["step_8_config_reload", ["s7", "s6", "s5", "s4", "s3", "s2", "s1", "s0"]],
    ["step_9_verify", ["s8", "s7", "s6", "s5", "s4", "s3", "s2", "s1", "s0"]]
  ])("rolls back previous steps when %s fails", async (failedStep, expectedRollbackKeys) => {
    failAtStep.value = failedStep;
    const result = await provisionForemanAgent(input, deps);

    expect(result.outcome).toBe("failed");
    if (result.outcome !== "failed" && result.outcome !== "blocked") {
      throw new Error("Expected failure result");
    }

    expect(result.rollbackPerformed).toBe(true);
    expect(result.technicalDetails.rollbackActions).toBeTruthy();
    expect(writeLogEntryMock).toHaveBeenCalledTimes(1);
    expect(writeLogEntryMock.mock.calls[0]?.[1]?.outcome).toBe("failed");
    expect(writeLogEntryMock.mock.calls[0]?.[1]?.failed_step).toBe(failedStep);

    for (const key of expectedRollbackKeys) {
      expect(stepRollbacks[key as keyof typeof stepRollbacks]).toHaveBeenCalledTimes(1);
    }
  });
});
