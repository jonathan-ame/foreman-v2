import type { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../app-deps.js";
import { resolveSessionCustomerId } from "../auth/session.js";

const SendOutreachSchema = z.object({
  to_email: z.string().email(),
  to_name: z.string().max(200).optional(),
  subject: z.string().min(1).max(500),
  body: z.string().min(1).max(100_000),
  is_html: z.boolean().default(true),
  cc_emails: z.array(z.string().email()).max(10).optional(),
  bcc_emails: z.array(z.string().email()).max(10).optional(),
});

const ListProspectsSchema = z.object({
  min_score: z.number().min(0).max(100).optional(),
  use_case: z.enum(["solopreneur", "small_team", "enterprise", "technical", "other"]).optional(),
  source: z.enum(["homepage", "blog", "contact", "other"]).optional(),
  limit: z.number().min(1).max(100).default(50),
  offset: z.number().min(0).default(0),
});

export function registerOutreachRoutes(app: Hono, deps: AppDeps) {
  app.post("/api/internal/outreach/send", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    if (!deps.clients.email.enabled) {
      return c.json({ error: "email_not_configured" }, 503);
    }

    let body: unknown;
    try {
      body = await c.req.json();
    } catch {
      return c.json({ error: "invalid_json" }, 400);
    }

    const parsed = SendOutreachSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    const data = parsed.data;

    try {
      const emailOpts: { to: string; subject: string; html: string; text?: string } = {
        to: data.to_email,
        subject: data.subject,
        html: data.is_html ? data.body : `<p>${data.body.replace(/\n/g, "<br>")}</p>`,
      };
      if (!data.is_html) {
        emailOpts.text = data.body;
      }
      await deps.clients.email.send(emailOpts);

      deps.logger.info(
        { to: data.to_email, subject: data.subject, customerId },
        "outreach: email sent"
      );

      return c.json({ ok: true }, 200);
    } catch (err) {
      deps.logger.error(
        { err, to: data.to_email, subject: data.subject },
        "outreach: failed to send email"
      );
      return c.json({ error: "email_send_failed" }, 500);
    }
  });

  app.get("/api/internal/outreach/prospects", async (c) => {
    const customerId = await resolveSessionCustomerId(c, deps);
    if (!customerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const rawQuery = c.req.query();
    const parsed = ListProspectsSchema.safeParse({
      min_score: rawQuery.min_score,
      use_case: rawQuery.use_case,
      source: rawQuery.source,
      limit: rawQuery.limit,
      offset: rawQuery.offset,
    });
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    const { min_score, use_case, source, limit, offset } = parsed.data;

    try {
      let q = deps.db
        .from("email_subscribers")
        .select("id, email, name, company, use_case, company_size, source, subscribed_at")
        .is("unsubscribed_at", null)
        .order("subscribed_at", { ascending: false })
        .range(offset, offset + limit - 1);

      if (use_case) {
        q = q.eq("use_case", use_case);
      }
      if (source) {
        q = q.eq("source", source);
      }

      const { data: prospects, error } = await q;

      if (error) {
        throw new Error(`Failed to fetch prospects: ${error.message}`);
      }

      return c.json({
        prospects: (prospects ?? []).map((p: Record<string, unknown>) => ({
          id: p.id,
          email: p.email,
          name: p.name,
          company: p.company,
          use_case: p.use_case,
          company_size: p.company_size,
          source: p.source,
          subscribed_at: p.subscribed_at,
        })),
      });
    } catch (err) {
      deps.logger.error({ err }, "outreach: failed to list prospects");
      return c.json({ error: "internal_error" }, 500);
    }
  });
}