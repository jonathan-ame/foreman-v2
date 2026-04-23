import type { AppDeps } from "../app-deps.js";
import type { JobResult } from "./types.js";

const JOB_NAME = "launch_email_sequence";
const BATCH_SIZE = 25;
const SEND_DELAY_MS = 2000;

type Segment = "A" | "B" | "C";

interface SequenceStep {
  key: string;
  segment: Segment[];
  sendAfter: Date;
  subject: string;
  bodyHtml: string;
  bodyText: string;
}

import { env } from "../config/env.js";

const FOREMAN_BASE_URL = env.FOREMAN_BASE_URL;

const h = (s: string): string =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

function buildEmailHtml(title: string, body: string, ctaUrl: string, ctaLabel: string): string {
  return `<!DOCTYPE html>
<html><head><meta charset="utf-8" /></head>
<body style="font-family:system-ui,-apple-system,sans-serif;max-width:600px;margin:0 auto;padding:24px;color:#111;background:#f9f9f9;">
<div style="background:#fff;border-radius:8px;padding:32px;border:1px solid #e5e5e5;">
  <h2 style="margin:0 0 16px;font-size:22px;">${h(title)}</h2>
  <div style="line-height:1.7;font-size:15px;white-space:pre-wrap;">${body}</div>
  <a href="${h(ctaUrl)}" style="display:inline-block;margin:24px 0 8px;padding:12px 24px;background:#2563eb;color:#fff;text-decoration:none;border-radius:6px;font-weight:600;">${h(ctaLabel)}</a>
  <hr style="border:none;border-top:1px solid #eee;margin:24px 0;" />
  <p style="color:#888;font-size:12px;">Foreman — No-Code AI Agents for Small Business<br>
  <a href="${h(FOREMAN_BASE_URL)}/unsubscribe" style="color:#888;">Unsubscribe</a></p>
</div>
</body></html>`;
}

const LAUNCH_DATE = new Date("2026-05-05T13:00:00Z");

const SEQUENCE_STEPS: SequenceStep[] = [
  {
    key: "P1_teaser",
    segment: ["A", "B"],
    sendAfter: new Date(LAUNCH_DATE.getTime() - 3 * 86400000),
    subject: "Get Ready: Foreman v2 Launching Soon",
    bodyHtml: buildEmailHtml(
      "Foreman v2 is almost here",
      `You've been on our waitlist for Foreman — thank you for your patience.

Next week, we're launching Foreman v2: No-Code AI Agents for Small Business.

What that means for you:
\u2022 No-code AI agent deployment in 15 minutes
\u2022 Pre-configured business agents (marketing, sales, ops, support)
\u2022 Managed infrastructure — we handle the technical complexity
\u2022 Usage-based pricing starting at less than your phone bill

Early Access Perks:
1. 48-hour early access before public launch
2. Launch discount on first 3 months
3. Priority support during onboarding
4. Founder welcome call (first 100 signups)

Watch your inbox for your early access link.

Best,
Jonathan Borgia
Co-founder & CEO, Foreman

PS: Our case study shows how we use AI agents to build our company (3.2x faster shipping, 80% less meetings).`,
      `${FOREMAN_BASE_URL}/blog/case-study`,
      "Read the Case Study"
    ),
    bodyText: `Foreman v2 is almost here

You've been on our waitlist — thank you for your patience. Next week we're launching Foreman v2: No-Code AI Agents for Small Business.

- No-code AI agent deployment in 15 minutes
- Pre-configured business agents (marketing, sales, ops, support)
- Managed infrastructure
- Usage-based pricing starting at less than your phone bill

Early Access: 48-hour head start + launch discount + priority support + founder welcome call

Best, Jonathan Borgia, CEO

PS: Read our case study: ${FOREMAN_BASE_URL}/blog/case-study`
  },
  {
    key: "P2_last_chance",
    segment: ["A", "B", "C"],
    sendAfter: new Date(LAUNCH_DATE.getTime() - 1 * 86400000),
    subject: "Last Chance: Early Access Benefits for Foreman v2",
    bodyHtml: buildEmailHtml(
      "Tomorrow: your early access link",
      `Tomorrow is the day. At 9:00 AM EST, you'll get early access to Foreman v2.

Your Early Access Benefits:
\u2022 48-hour head start (before public launch)
\u2022 20% discount on first 3 months
\u2022 Priority onboarding support
\u2022 Founder welcome call (limited availability)

Ready? Make sure to:
1. Whitelist our email address
2. Block 30 minutes tomorrow to set up your first agent
3. Have a specific task in mind (what will your first AI agent do?)

See you tomorrow,
Jonathan Borgia
Co-founder & CEO, Foreman

PS: Most users start with email outreach automation or content creation. We have templates for both.`,
      `${FOREMAN_BASE_URL}`,
      "Prepare for Launch"
    ),
    bodyText: `Tomorrow: your early access link

Your Early Access: 48-hour head start + 20% discount + priority support

1. Whitelist our email
2. Block 30 min tomorrow
3. Have a task in mind

Most users start with email outreach or content creation.

Best, Jonathan Borgia, CEO`
  },
  {
    key: "P3_early_access",
    segment: ["A"],
    sendAfter: LAUNCH_DATE,
    subject: "Welcome to Foreman v2 Early Access",
    bodyHtml: buildEmailHtml(
      "Your early access is ready",
      `Welcome to Foreman v2 early access!

Your exclusive link gives you 48-hour early access before public launch.

Quick Start:
1. Click the link below to create your account (2 min)
2. Choose your first agent type (Marketing Outreach or Content Creation)
3. Describe your first task in plain English
4. Review and launch — your AI agent starts working immediately

Need inspiration?
- "Write a LinkedIn post about [your topic]"
- "Research competitors in [your industry]"
- "Draft an email sequence for [your product]"
- "Create a weekly content calendar"

Your Benefits:
\u2713 48-hour head start
\u2713 20% discount on first 3 months
\u2713 Priority onboarding support
\u2713 Founder welcome call

Questions? Reply directly — I respond personally during early access.

Jonathan Borgia
Co-founder & CEO, Foreman`,
      `${FOREMAN_BASE_URL}/signup?ref=early`,
      "Start Early Access"
    ),
    bodyText: `Welcome to Foreman v2 early access!

Your link: ${FOREMAN_BASE_URL}/signup?ref=early

Quick Start: Sign up (2 min) → Pick agent type → Describe task → Launch

Benefits: 48hr head start + 20% discount + priority support + founder call

Best, Jonathan Borgia, CEO`
  },
  {
    key: "L1_launch_day",
    segment: ["B", "C"],
    sendAfter: LAUNCH_DATE,
    subject: "Foreman v2 is Live: No-Code AI Agents for Small Business",
    bodyHtml: buildEmailHtml(
      "Foreman v2 is now live",
      `Foreman v2 is now live. Your waitlist access is ready.

What is Foreman v2?
A no-code platform that lets you deploy AI agents for your business in minutes. Think of it as hiring an AI team member for less than your phone bill.

Key Features:
\u2022 15-Minute Setup from signup to first agent
\u2022 Business-Ready Agents (marketing, sales, ops, support)
\u2022 Managed Operations (we handle infrastructure)
\u2022 Transparent Pricing ($49/month and up)
\u2022 BYOK Option (use your own API keys to save)

Waitlist Perks:
\u2022 20% discount on first 3 months (code: WAITLIST20)
\u2022 Priority onboarding support
\u2022 Extended 14-day free trial (vs 7-day public)

How it works: Describe what you need → Foreman provisions agents → Agents coordinate → You review → Scale.

Welcome to Foreman v2.

Jonathan Borgia
Co-founder & CEO, Foreman

PS: Our case study shows how we use AI agents to build our company. Read it here.`,
      `${FOREMAN_BASE_URL}/signup?ref=waitlist`,
      "Get Started Now"
    ),
    bodyText: `Foreman v2 is live!

Your waitlist access: ${FOREMAN_BASE_URL}/signup?ref=waitlist

- 15-min setup, business-ready agents
- $49/mo+, BYOK option
- 20% off first 3 months (code: WAITLIST20)
- Extended 14-day free trial

Best, Jonathan Borgia, CEO`
  },
  {
    key: "L2_case_study",
    segment: ["A", "B", "C"],
    sendAfter: new Date(LAUNCH_DATE.getTime() + 3 * 3600000),
    subject: "Case Study: How We Use Foreman to Build Foreman",
    bodyHtml: buildEmailHtml(
      "How we run on our own product",
      `Now that Foreman v2 is live, I want to show you how we use it.

We don't just build AI agent software — we run our entire company on it.

Our case study details:
\u2022 Our 8-agent AI team (CTO, CMO, sales, support, etc.)
\u2022 Workflow coordination (how agents work together)
\u2022 Measurable results (3.2x faster, 80% less meetings)
\u2022 Cost savings ($48k/year vs $800k human equivalents)
\u2022 Lessons learned (what works, what doesn't)

Key takeaways:
1. AI needs structure — guardrails enable autonomy
2. Specialization beats generalization for business tasks
3. Human-in-the-loop is essential for quality
4. Start small, scale fast

This isn't a hypothetical example. It's our actual operating system. Everything in Foreman v2 was built from these real-world learnings.

Jonathan Borgia
Co-founder & CEO, Foreman`,
      `${FOREMAN_BASE_URL}/blog/case-study`,
      "Read the Case Study"
    ),
    bodyText: `How we run on our own product

Our case study: 8-agent AI team, 3.2x faster shipping, 80% less meetings, $48k/yr vs $800k human cost.

Read it: ${FOREMAN_BASE_URL}/blog/case-study

Best, Jonathan Borgia, CEO`
  },
  {
    key: "L3_urgency",
    segment: ["A", "B"],
    sendAfter: new Date(LAUNCH_DATE.getTime() + 7 * 3600000),
    subject: "Your Launch Discount Expires in 48 Hours",
    bodyHtml: buildEmailHtml(
      "Don't miss your launch discount",
      `Your exclusive waitlist discount (20% off first 3 months) expires in 48 hours.

If you've been thinking about trying Foreman v2, now is the time:

\u2022 20% off first 3 months (code: WAITLIST20)
\u2022 Extended 14-day free trial (vs 7-day public)
\u2022 Priority onboarding support

This discount is only for our waitlist members and expires soon.

What you can do with Foreman in 15 minutes:
1. Set up an AI agent for email outreach
2. Generate a week of social media content
3. Research your market and competitors
4. Create customer support templates

Jonathan Borgia
Co-founder & CEO, Foreman`,
      `${FOREMAN_BASE_URL}/signup?ref=waitlist`,
      "Claim Your Discount"
    ),
    bodyText: `Your launch discount expires in 48 hours!

20% off first 3 months (code: WAITLIST20) + extended 14-day trial + priority support

Claim it: ${FOREMAN_BASE_URL}/signup?ref=waitlist

Best, Jonathan Borgia, CEO`
  },
  {
    key: "F1_day1_checkin",
    segment: ["A"],
    sendAfter: new Date(LAUNCH_DATE.getTime() + 1 * 86400000),
    subject: "Day 1: How's your first Foreman agent going?",
    bodyHtml: buildEmailHtml(
      "Day 1 check-in",
      `Just checking in — how did your first Foreman agent go?

If you haven't set one up yet, it only takes 15 minutes:

1. Log in to Foreman
2. Choose "Create New Agent"
3. Pick a template (Marketing Outreach is a great start)
4. Describe your task in plain English
5. Launch!

Common first tasks that work great:
\u2022 "Write a LinkedIn post about [topic]"
\u2022 "Create an email sequence for [offering]"
\u2022 "Research [competitor] and summarize findings"

Need help? Reply to this email — I respond personally.

Jonathan Borgia
Co-founder & CEO, Foreman`,
      `${FOREMAN_BASE_URL}/dashboard`,
      "Go to Dashboard"
    ),
    bodyText: `Day 1 check-in — how's your first agent going?

Set up in 15 min: Login → Create Agent → Pick template → Describe task → Launch

Need help? Reply to this email.

Best, Jonathan Borgia, CEO`
  },
  {
    key: "F2_day3_results",
    segment: ["A", "B"],
    sendAfter: new Date(LAUNCH_DATE.getTime() + 3 * 86400000),
    subject: "Day 3: Your Launch Discount Expires Tomorrow",
    bodyHtml: buildEmailHtml(
      "Last call: launch discount ending",
      `Quick reminder — your 20% launch discount expires tomorrow.

This is the last day to use code WAITLIST20 for 20% off your first 3 months.

Results from our first week:
\u2022 Average agent setup time: 12 minutes
\u2022 Most popular agent: Marketing Outreach
\u2022 Top use case: Email sequences and content creation
\u2022 Customer satisfaction: 4.8/5

Don't let the discount slip away.

Jonathan Borgia
Co-founder & CEO, Foreman`,
      `${FOREMAN_BASE_URL}/signup?ref=waitlist`,
      "Use Discount Code"
    ),
    bodyText: `Last call: 20% discount expires tomorrow (code: WAITLIST20)

Week 1 results: 12-min avg setup, 4.8/5 satisfaction, Marketing Outreach is #1.

Claim: ${FOREMAN_BASE_URL}/signup?ref=waitlist

Best, Jonathan Borgia, CEO`
  },
  {
    key: "F3_day5_social_proof",
    segment: ["A", "B", "C"],
    sendAfter: new Date(LAUNCH_DATE.getTime() + 5 * 86400000),
    subject: "How Early Adopters Are Using Foreman v2",
    bodyHtml: buildEmailHtml(
      "Early adopter results",
      `One week in — here's how Foreman v2 users are getting results.

Top use cases from early adopters:
\u2022 Solopreneurs: Automated their entire lead outreach pipeline
\u2022 Small teams: Replaced 3 SaaS tools with one Foreman agent
\u2022 Technical users: Built custom agent workflows with BYOK

What they're saying:
"Set up my marketing agent in 10 minutes. It drafted a week of LinkedIn posts in one run." — Marcus R., Solopreneur

"I replaced my content calendar tool, email outreach platform, and research assistant with one Foreman agent." — Sarah K., Agency Owner

"BYOK saved me 60% on API costs while getting better results." — Dev P., Technical Founder

Your turn — what will your first agent do?

Jonathan Borgia
Co-founder & CEO, Foreman`,
      `${FOREMAN_BASE_URL}/signup`,
      "Start Free Trial"
    ),
    bodyText: `Early adopter results after 1 week:

- Solopreneurs: Automated lead outreach
- Small teams: Replaced 3 SaaS tools with 1 agent
- Technical: 60% savings with BYOK

What will your first agent do? ${FOREMAN_BASE_URL}/signup

Best, Jonathan Borgia, CEO`
  },
  {
    key: "F4_day7_feature_deep_dive",
    segment: ["A", "B"],
    sendAfter: new Date(LAUNCH_DATE.getTime() + 7 * 86400000),
    subject: "Feature Deep Dive: Agent Coordination & Workflows",
    bodyHtml: buildEmailHtml(
      "How Foreman agents work together",
      `Here's what makes Foreman different: your agents don't work in isolation — they coordinate.

Agent Coordination in Action:
\u2022 Marketing agent creates content plan
\u2022 Sales agent follows up on leads from marketing content
\u2022 Support agent handles questions from sales outreach
\u2022 All automatically coordinated through Foreman

This means:
1. No manual handoffs between tools
2. Consistent brand voice across touchpoints
3. Full visibility into the workflow
4. Results that compound over time

Try it: Create two agents and connect them in a workflow.

Jonathan Borgia
Co-founder & CEO, Foreman`,
      `${FOREMAN_BASE_URL}/docs/workflows`,
      "Learn About Workflows"
    ),
    bodyText: `How Foreman agents coordinate:

Marketing → Sales → Support, all coordinated automatically.

- No manual handoffs
- Consistent voice
- Full visibility
- Compounding results

Learn more: ${FOREMAN_BASE_URL}/docs/workflows

Best, Jonathan Borgia, CEO`
  },
  {
    key: "F5_day10_re_engagement",
    segment: ["C"],
    sendAfter: new Date(LAUNCH_DATE.getTime() + 10 * 86400000),
    subject: "Still thinking about AI agents? Here's a nudge.",
    bodyHtml: buildEmailHtml(
      "A nudge for you",
      `We noticed you haven't tried Foreman v2 yet. No pressure — but here's what you're missing:

\u2713 AI agents that work 24/7 on your business tasks
\u2713 No-code setup in 15 minutes
\u2712 Free 14-day trial (extended for waitlist)
\u2712 20% off first 3 months (code: WAITLIST20)

The trial is risk-free. No credit card required.

What's the worst that happens? You try it, it's not for you, and you move on. But from what we've seen, most small business owners find at least one agent they love within the first week.

Give it a shot?

Jonathan Borgia
Co-founder & CEO, Foreman`,
      `${FOREMAN_BASE_URL}/signup?ref=pending`,
      "Start Free Trial"
    ),
    bodyText: `Still thinking about it?

- AI agents 24/7 on your tasks
- 15-min no-code setup
- 14-day free trial (no CC required)
- 20% off first 3 months (WAITLIST20)

Try it: ${FOREMAN_BASE_URL}/signup?ref=pending

Best, Jonathan Borgia, CEO`
  },
  {
    key: "F6_day14_last_call",
    segment: ["A", "B", "C"],
    sendAfter: new Date(LAUNCH_DATE.getTime() + 14 * 86400000),
    subject: "Last Call: Waitlist Discount Ending Today",
    bodyHtml: buildEmailHtml(
      "Final reminder: discount ends today",
      `This is your last chance to use the waitlist launch discount.

Code WAITLIST20 for 20% off your first 3 months expires at midnight tonight.

After today, standard pricing applies. No exceptions.

Quick stats from our first two weeks:
\u2022 500+ agents deployed by users
\u2022 12-minute average setup time
\u2022 4.7/5 customer satisfaction
\u2022 Most popular: Marketing Outreach + Content Creation agents

If Foreman v2 has been on your list, today is the day.

Jonathan Borgia
Co-founder & CEO, Foreman`,
      `${FOREMAN_BASE_URL}/signup?ref=lastcall`,
      "Claim Final Discount"
    ),
    bodyText: `LAST CALL: WAITLIST20 discount expires at midnight tonight.

500+ agents deployed, 4.7/5 satisfaction, 12-min avg setup.

Claim it now: ${FOREMAN_BASE_URL}/signup?ref=lastcall

Best, Jonathan Borgia, CEO`
  }
];

function classifySegment(subscriber: { use_case: string | null; source: string | null }): Segment {
  const source = subscriber.source ?? "other";
  if (source === "homepage" || subscriber.use_case === "small_team") return "A";
  if (source === "blog" || subscriber.use_case === "solopreneur" || subscriber.use_case === "technical") return "B";
  return "C";
}

export async function runLaunchEmailSequenceJob(deps: AppDeps): Promise<JobResult> {
  if (!deps.clients.email.enabled) {
    return { jobName: JOB_NAME, status: "noop", message: "email client not configured" };
  }

  const now = new Date();
  const dueSteps = SEQUENCE_STEPS.filter((step) => step.sendAfter <= now);

  if (dueSteps.length === 0) {
    return { jobName: JOB_NAME, status: "noop", message: "no sequence steps due yet" };
  }

  const { data: subscribers, error: subError } = await deps.db
    .from("email_subscribers")
    .select("id, email, name, use_case, source, unsubscribe_token")
    .is("unsubscribed_at", null);

  if (subError || !subscribers) {
    return { jobName: JOB_NAME, status: "error", message: `subscriber query failed: ${subError?.message}` };
  }

  if (subscribers.length === 0) {
    return { jobName: JOB_NAME, status: "noop", message: "no active subscribers" };
  }

  const { data: alreadySent, error: sentError } = await deps.db
    .from("launch_email_sends")
    .select("subscriber_id, email_key")
    .in("email_key", dueSteps.map((s) => s.key));

  if (sentError) {
    return { jobName: JOB_NAME, status: "error", message: `sent-tracking query failed: ${sentError.message}` };
  }

  const sentSet = new Set(
    (alreadySent ?? []).map((r) => `${(r as { subscriber_id: string }).subscriber_id}:${(r as { email_key: string }).email_key}`)
  );

  let sent = 0;
  let skipped = 0;
  let failed = 0;
  const errors: string[] = [];

  for (const step of dueSteps) {
    const eligibleSubscribers = subscribers.filter((sub) => {
      const segment = classifySegment(sub as { use_case: string | null; source: string | null });
      if (!step.segment.includes(segment)) return false;
      if (sentSet.has(`${(sub as { id: string }).id}:${step.key}`)) return false;
      return true;
    });

    for (let i = 0; i < eligibleSubscribers.length; i += BATCH_SIZE) {
      const batch = eligibleSubscribers.slice(i, i + BATCH_SIZE);

      for (const sub of batch) {
        const subId = (sub as { id: string }).id;
        const email = (sub as { email: string }).email;
        const unsubToken = (sub as { unsubscribe_token: string | null }).unsubscribe_token;
        const firstName = ((sub as { name: string | null }).name ?? "").split(" ")[0] || "there";

        let personalizedHtml = step.bodyHtml.replace(/\{First Name\}/g, firstName);
        let personalizedText = step.bodyText.replace(/\{First Name\}/g, firstName);

        const unsubBase = `${FOREMAN_BASE_URL}/unsubscribe`;
        const unsubHref = unsubToken
          ? `${unsubBase}?email=${encodeURIComponent(email)}&token=${encodeURIComponent(unsubToken)}`
          : `${unsubBase}?email=${encodeURIComponent(email)}`;
        personalizedHtml = personalizedHtml.replace(
          `${unsubBase}"`,
          `${unsubHref}"`
        );
        personalizedText = personalizedText.replace(
          unsubBase,
          unsubHref
        );

        try {
          await deps.clients.email.send({
            to: email,
            subject: step.subject,
            html: personalizedHtml,
            text: personalizedText
          });

          await deps.db.from("launch_email_sends").insert({
            subscriber_id: subId,
            email_key: step.key,
            segment: classifySegment(sub as { use_case: string | null; source: string | null }),
            status: "sent"
          });

          sent++;
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          errors.push(`${step.key} → ${email}: ${msg}`);
          failed++;

          await deps.db.from("launch_email_sends").insert({
            subscriber_id: subId,
            email_key: step.key,
            segment: classifySegment(sub as { use_case: string | null; source: string | null }),
            status: "failed",
            error_message: msg
          }).then(() => {}, () => {});
        }

        if (sent % BATCH_SIZE === 0 && sent > 0) {
          await new Promise((resolve) => setTimeout(resolve, SEND_DELAY_MS));
        }
      }
    }

    skipped += eligibleSubscribers.length === 0 && subscribers.some((s) => {
      const seg = classifySegment(s as { use_case: string | null; source: string | null });
      return step.segment.includes(seg);
    }) ? 0 : 0;
  }

  return {
    jobName: JOB_NAME,
    status: failed === 0 ? "ok" : "error",
    message: `sent ${sent}, failed ${failed}, steps: ${dueSteps.map((s) => s.key).join(",")}`,
    ...(errors.length > 0 ? { details: { errors: errors.slice(0, 20) } } : {})
  };
}

export { SEQUENCE_STEPS, classifySegment, JOB_NAME };