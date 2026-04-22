import type { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../app-deps.js";
import { upsertSubscriber, type SubscriberSource } from "../db/email-subscribers.js";

const SubscribeSchema = z.object({
  email: z.string().email(),
  name: z.string().max(200).optional(),
  company: z.string().max(200).optional(),
  useCase: z.enum(["solopreneur", "small_team", "enterprise", "technical", "other"]).optional(),
  companySize: z.string().max(50).optional(),
  message: z.string().max(2000).optional(),
  source: z.enum(["homepage", "blog", "contact", "other"]).default("other"),
  utmSource: z.string().max(200).optional(),
  utmMedium: z.string().max(200).optional(),
  utmCampaign: z.string().max(200).optional(),
});

export function registerMarketingRoutes(app: Hono, deps: AppDeps) {
  app.post("/api/marketing/subscribe", async (c) => {
    let body: unknown;
    try {
      body = await c.req.json();
    } catch {
      return c.json({ error: "invalid_json" }, 400);
    }

    const parsed = SubscribeSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    const data = parsed.data;

    const input: Parameters<typeof upsertSubscriber>[1] = {
      email: data.email,
      source: data.source as SubscriberSource,
    };
    if (data.name) input.name = data.name;
    if (data.company) input.company = data.company;
    if (data.useCase) input.useCase = data.useCase;
    if (data.companySize) input.companySize = data.companySize;
    if (data.message) input.message = data.message;
    if (data.utmSource) input.utmSource = data.utmSource;
    if (data.utmMedium) input.utmMedium = data.utmMedium;
    if (data.utmCampaign) input.utmCampaign = data.utmCampaign;

    try {
      const result = await upsertSubscriber(deps.db, input);

      if (result.created && deps.clients.email.enabled && deps.env.CEO_REVIEW_EMAIL) {
        deps.clients.email.send({
          to: deps.env.CEO_REVIEW_EMAIL,
          subject: `New subscriber: ${data.email}`,
          html: `<p><strong>${data.name ?? "Anonymous"}</strong> (${data.email}) subscribed via ${data.source}.</p>${
            data.company ? `<p>Company: ${data.company}</p>` : ""
          }${
            data.useCase ? `<p>Use case: ${data.useCase}</p>` : ""
          }${
            data.message ? `<p>Message: ${data.message}</p>` : ""
          }`,
          text: `${data.name ?? "Anonymous"} (${data.email}) subscribed via ${data.source}.${
            data.company ? ` Company: ${data.company}.` : ""
          }${
            data.useCase ? ` Use case: ${data.useCase}.` : ""
          }${
            data.message ? ` Message: ${data.message}.` : ""
          }`,
        }).catch((err: unknown) => {
          deps.logger.warn({ err }, "marketing: failed to send subscriber notification email");
        });
      }

      deps.logger.info(
        { email: data.email, source: data.source, created: result.created },
        "marketing: subscriber recorded"
      );

      return c.json({ ok: true, created: result.created }, 200);
    } catch (err) {
      deps.logger.error({ err, email: data.email }, "marketing: failed to record subscriber");
      return c.json({ error: "internal_error" }, 500);
    }
  });
}
