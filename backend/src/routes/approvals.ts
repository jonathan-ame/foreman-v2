import type { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../app-deps.js";
import { resolveSessionCustomerId } from "../auth/session.js";
import { PaperclipNotFoundError } from "../clients/paperclip/errors.js";
import { getCustomerById } from "../db/customers.js";

const RequestChangesSchema = z.object({
  note: z.string().min(1).max(5_000)
});

function mapApprovalStatus(status: string): "pending" | "approved" | "changes_requested" {
  if (status === "approved") return "approved";
  if (status === "changes_requested" || status === "revision_requested") return "changes_requested";
  return "pending";
}

export function registerApprovalRoutes(app: Hono, deps: AppDeps) {
  app.get("/api/internal/approvals/pending", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const customer = await getCustomerById(deps.db, customerId);
    if (!customer?.paperclip_company_id) {
      return c.json({ approvals: [] });
    }

    try {
      const pending = await deps.clients.paperclip.listPendingApprovals(customer.paperclip_company_id);

      const approvals = await Promise.all(
        pending.map(async (approval) => {
          let agentName = "Agent";
          let agentRole = "agent";

          if (approval.requestedByAgentId) {
            try {
              const agent = await deps.clients.paperclip.getAgent(approval.requestedByAgentId);
              agentName = agent.name;
              agentRole = agent.role;
            } catch {
              // non-fatal: use defaults
            }
          }

          return {
            id: approval.id,
            agent_name: agentName,
            agent_role: agentRole,
            plan_title: approval.payload?.title ?? "Untitled Plan",
            summary: approval.payload?.summary ?? "",
            task_count: approval.payload?.taskCount ?? 0,
            estimated_cost_mo: approval.payload?.estimatedCostMo ?? null,
            requested_at: approval.createdAt ?? new Date().toISOString(),
            status: mapApprovalStatus(approval.status)
          };
        })
      );

      return c.json({ approvals });
    } catch (err) {
      deps.logger.error({ err, customerId }, "approvals: failed to fetch pending");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.post("/api/internal/approvals/:id/approve", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const approvalId = c.req.param("id");

    try {
      await deps.clients.paperclip.actOnApproval(approvalId, "approve");
      return c.json({ ok: true });
    } catch (err) {
      if (err instanceof PaperclipNotFoundError) {
        return c.json({ error: "not_found" }, 404);
      }
      deps.logger.error({ err, customerId, approvalId }, "approvals: failed to approve");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });

  app.post("/api/internal/approvals/:id/request-changes", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const approvalId = c.req.param("id");

    const body = await c.req.json();
    const parsed = RequestChangesSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    try {
      await deps.clients.paperclip.actOnApproval(approvalId, "request-revision", {
        comment: parsed.data.note
      });
      return c.json({ ok: true });
    } catch (err) {
      if (err instanceof PaperclipNotFoundError) {
        return c.json({ error: "not_found" }, 404);
      }
      deps.logger.error({ err, customerId, approvalId }, "approvals: failed to request changes");
      return c.json({ error: "internal_server_error" }, 500);
    }
  });
}
