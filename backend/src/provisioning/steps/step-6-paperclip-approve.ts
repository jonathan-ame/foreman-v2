import type { Customer } from "../../db/customers.js";
import type { PendingApproval } from "../../clients/paperclip/types.js";
import type { StepContext, StepResult } from "./types.js";
import process from "node:process";

export async function step6PaperclipApprove(ctx: StepContext): Promise<StepResult> {
  if (process.env.FOREMAN_FORCE_STEP6_FAILURE === "1") {
    return {
      ok: false,
      errorCode: "STEP6_FORCED_FAILURE",
      errorMessage: "step 6 forced failure for rollback smoke test"
    };
  }

  const customer = ctx.state.customer as Customer | undefined;
  if (!customer?.paperclip_company_id) {
    return {
      ok: false,
      errorCode: "PAPERCLIP_COMPANY_ID_MISSING",
      errorMessage: "paperclip company id is required for approvals"
    };
  }

  const existingApproval = ctx.state.pendingApproval as PendingApproval | null | undefined;
  let approval = existingApproval;

  if (!approval) {
    const pending = await ctx.clients.paperclip.listPendingApprovals(customer.paperclip_company_id);
    approval = pending.find((item) => item.type === "hire_agent" && item.status === "pending") ?? null;
  }

  if (!approval) {
    return {
      ok: false,
      errorCode: "PAPERCLIP_APPROVAL_NOT_FOUND",
      errorMessage: "No pending hire_agent approval found"
    };
  }

  await ctx.clients.paperclip.actOnApproval(approval.id, "approve");

  return {
    ok: true,
    data: {
      approvedId: approval.id
    }
  };
}

export async function rollbackStep6PaperclipApprove(ctx: StepContext): Promise<void> {
  ctx.logger.info("rolling back step_6_paperclip_approve: approval action is not undoable");
}
