import crypto from "node:crypto";
import type { Hono } from "hono";
import { z } from "zod";
import type { AppDeps } from "../app-deps.js";
import { upsertSubscriber, type SubscriberSource } from "../db/email-subscribers.js";
import { insertPageView } from "../db/page-views.js";

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

const FeedbackSchema = z.object({
  category: z.enum(["bug", "suggestion", "praise", "other"]),
  message: z.string().min(1).max(5000),
  email: z.string().email().optional(),
  page: z.string().max(500).optional(),
});

const PreferencesSchema = z.object({
  email: z.string().email(),
  token: z.string().optional(),
});

const UpdatePreferencesSchema = z.object({
  email: z.string().email(),
  token: z.string(),
  preferences: z.object({
    launch_updates: z.boolean().optional(),
    product_news: z.boolean().optional(),
    tips_resources: z.boolean().optional(),
    community: z.boolean().optional(),
  }).optional(),
});

const UnsubscribeSchema = z.object({
  email: z.string().email(),
  token: z.string().optional(),
});

const ResubscribeSchema = z.object({
  email: z.string().email(),
  token: z.string(),
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

      return c.json({ ok: true, created: result.created, unsubscribe_token: result.subscriber.unsubscribe_token }, 200);
    } catch (err) {
      deps.logger.error({ err, email: data.email }, "marketing: failed to record subscriber");
      return c.json({ error: "internal_error" }, 500);
    }
  });

  app.post("/api/marketing/pageview", async (c) => {
    let body: unknown;
    try {
      body = await c.req.json();
    } catch {
      return c.json({ error: "invalid_json" }, 400);
    }

    const PageViewSchema = z.object({
      path: z.string().max(500),
      referrer: z.string().max(2000).optional(),
      utmSource: z.string().max(200).optional(),
      utmMedium: z.string().max(200).optional(),
      utmCampaign: z.string().max(200).optional(),
    });

    const parsed = PageViewSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ ok: true }, 200);
    }

    const data = parsed.data;
    const ip = c.req.header("x-forwarded-for") ?? c.req.header("x-real-ip") ?? "unknown";
    const ipHash = crypto.createHash("sha256").update(ip).digest("hex").slice(0, 16);

    try {
      const pageViewInput: Parameters<typeof insertPageView>[1] = {
        path: data.path,
        ipHash,
      };
      if (data.referrer) pageViewInput.referrer = data.referrer;
      if (data.utmSource) pageViewInput.utmSource = data.utmSource;
      if (data.utmMedium) pageViewInput.utmMedium = data.utmMedium;
      if (data.utmCampaign) pageViewInput.utmCampaign = data.utmCampaign;
      const ua = c.req.header("user-agent");
      if (ua) pageViewInput.userAgent = ua.slice(0, 500);

      await insertPageView(deps.db, pageViewInput);
    } catch (err) {
      deps.logger.warn({ err, path: data.path }, "marketing: failed to record page view");
    }

    return c.json({ ok: true }, 200);
  });

  app.post("/api/marketing/feedback", async (c) => {
    let body: unknown;
    try {
      body = await c.req.json();
    } catch {
      return c.json({ error: "invalid_json" }, 400);
    }

    const parsed = FeedbackSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    const data = parsed.data;

    try {
      if (deps.clients.email.enabled && deps.env.CEO_REVIEW_EMAIL) {
        deps.clients.email.send({
          to: deps.env.CEO_REVIEW_EMAIL,
          subject: `Site feedback: ${data.category}`,
          html: `<p><strong>Category:</strong> ${data.category}</p>
<p><strong>Page:</strong> ${data.page ?? "unknown"}</p>
<p><strong>Email:</strong> ${data.email ?? "anonymous"}</p>
<p><strong>Message:</strong></p>
<p>${data.message}</p>`,
          text: `Category: ${data.category}\nPage: ${data.page ?? "unknown"}\nEmail: ${data.email ?? "anonymous"}\nMessage: ${data.message}`,
        }).catch((err: unknown) => {
          deps.logger.warn({ err }, "marketing: failed to send feedback notification email");
        });
      }

      deps.logger.info(
        { category: data.category, page: data.page, email: data.email },
        "marketing: feedback received"
      );

      return c.json({ ok: true }, 200);
    } catch (err) {
      deps.logger.error({ err }, "marketing: failed to process feedback");
      return c.json({ error: "internal_error" }, 500);
    }
  });

  app.get("/api/marketing/preferences", async (c) => {
    const email = c.req.query("email");
    const token = c.req.query("token");

    if (!email) {
      return c.json({ error: "email_required" }, 400);
    }

    try {
      const { data: subscriber, error } = await deps.db
        .from("email_subscribers")
        .select("id, email, name, source, preferences, unsubscribed_at, unsubscribe_token")
        .eq("email", email)
        .maybeSingle();

      if (error) {
        deps.logger.error({ err: error, email }, "marketing: failed to query preferences");
        return c.json({ error: "internal_error" }, 500);
      }

      if (!subscriber) {
        return c.json({ error: "not_found" }, 404);
      }

      if (token && subscriber.unsubscribe_token && token !== subscriber.unsubscribe_token) {
        return c.json({ error: "invalid_token" }, 403);
      }

      if (subscriber.unsubscribed_at) {
        return c.json({
          email: subscriber.email,
          unsubscribed_at: subscriber.unsubscribed_at,
          preferences: subscriber.preferences ?? { launch_updates: true, product_news: true, tips_resources: true, community: true },
        });
      }

      return c.json({
        email: subscriber.email,
        name: subscriber.name,
        source: subscriber.source,
        preferences: subscriber.preferences ?? { launch_updates: true, product_news: true, tips_resources: true, community: true },
        unsubscribed_at: null,
      });
    } catch (err) {
      deps.logger.error({ err, email }, "marketing: preferences query failed");
      return c.json({ error: "internal_error" }, 500);
    }
  });

  app.patch("/api/marketing/preferences", async (c) => {
    let body: unknown;
    try {
      body = await c.req.json();
    } catch {
      return c.json({ error: "invalid_json" }, 400);
    }

    const parsed = UpdatePreferencesSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    const { email, token, preferences: newPrefs } = parsed.data;

    try {
      const { data: subscriber, error: findError } = await deps.db
        .from("email_subscribers")
        .select("id, unsubscribe_token, preferences, unsubscribed_at")
        .eq("email", email)
        .maybeSingle();

      if (findError || !subscriber) {
        return c.json({ error: "not_found" }, 404);
      }

      if (token !== subscriber.unsubscribe_token) {
        return c.json({ error: "invalid_token" }, 403);
      }

      if (subscriber.unsubscribed_at) {
        return c.json({ error: "unsubscribed", message: "Resubscribe first to update preferences" }, 400);
      }

      const merged = {
        ...(typeof subscriber.preferences === "object" && subscriber.preferences !== null ? subscriber.preferences as Record<string, boolean> : { launch_updates: true, product_news: true, tips_resources: true, community: true }),
        ...newPrefs,
      };

      const { error: updateError } = await deps.db
        .from("email_subscribers")
        .update({ preferences: merged })
        .eq("id", (subscriber as { id: string }).id);

      if (updateError) {
        deps.logger.error({ err: updateError, email }, "marketing: failed to update preferences");
        return c.json({ error: "internal_error" }, 500);
      }

      deps.logger.info({ email }, "marketing: preferences updated");
      return c.json({ ok: true, preferences: merged }, 200);
    } catch (err) {
      deps.logger.error({ err, email }, "marketing: preferences update failed");
      return c.json({ error: "internal_error" }, 500);
    }
  });

  app.post("/api/marketing/unsubscribe", async (c) => {
    let body: unknown;
    try {
      body = await c.req.json();
    } catch {
      return c.json({ error: "invalid_json" }, 400);
    }

    const parsed = UnsubscribeSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    const { email, token } = parsed.data;

    try {
      const query = deps.db
        .from("email_subscribers")
        .select("id, email, unsubscribe_token, unsubscribed_at")
        .eq("email", email)
        .maybeSingle();

      const { data: subscriber, error: findError } = await query;

      if (findError || !subscriber) {
        return c.json({ error: "not_found" }, 404);
      }

      if (token && (subscriber as { unsubscribe_token: string | null }).unsubscribe_token && token !== (subscriber as { unsubscribe_token: string | null }).unsubscribe_token) {
        return c.json({ error: "invalid_token" }, 403);
      }

      if ((subscriber as { unsubscribed_at: string | null }).unsubscribed_at) {
        return c.json({ ok: true, message: "already_unsubscribed" }, 200);
      }

      const { error: updateError } = await deps.db
        .from("email_subscribers")
        .update({
          unsubscribed_at: new Date().toISOString(),
          preferences: { launch_updates: false, product_news: false, tips_resources: false, community: false },
        })
        .eq("id", (subscriber as { id: string }).id);

      if (updateError) {
        deps.logger.error({ err: updateError, email }, "marketing: failed to unsubscribe");
        return c.json({ error: "internal_error" }, 500);
      }

      deps.logger.info({ email }, "marketing: subscriber unsubscribed");
      return c.json({ ok: true }, 200);
    } catch (err) {
      deps.logger.error({ err, email }, "marketing: unsubscribe failed");
      return c.json({ error: "internal_error" }, 500);
    }
  });

  app.post("/api/marketing/resubscribe", async (c) => {
    let body: unknown;
    try {
      body = await c.req.json();
    } catch {
      return c.json({ error: "invalid_json" }, 400);
    }

    const parsed = ResubscribeSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 400);
    }

    const { email, token } = parsed.data;

    try {
      const { data: subscriber, error: findError } = await deps.db
        .from("email_subscribers")
        .select("id, unsubscribe_token")
        .eq("email", email)
        .maybeSingle();

      if (findError || !subscriber) {
        return c.json({ error: "not_found" }, 404);
      }

      if (token !== (subscriber as { unsubscribe_token: string }).unsubscribe_token) {
        return c.json({ error: "invalid_token" }, 403);
      }

      const { error: updateError } = await deps.db
        .from("email_subscribers")
        .update({
          unsubscribed_at: null,
          preferences: { launch_updates: true, product_news: true, tips_resources: true, community: true },
        })
        .eq("id", (subscriber as { id: string }).id);

      if (updateError) {
        deps.logger.error({ err: updateError, email }, "marketing: failed to resubscribe");
        return c.json({ error: "internal_error" }, 500);
      }

      deps.logger.info({ email }, "marketing: subscriber resubscribed");
      return c.json({ ok: true }, 200);
    } catch (err) {
      deps.logger.error({ err, email }, "marketing: resubscribe failed");
      return c.json({ error: "internal_error" }, 500);
    }
  });
}
