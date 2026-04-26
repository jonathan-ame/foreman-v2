import type { Hono } from "hono";
import { z } from "zod";
import { resolveSessionCustomerId } from "../auth/session.js";
import type { AppDeps } from "../app-deps.js";
import { getCustomerById } from "../db/customers.js";

const VALID_STEPS = ["profile", "plan", "model", "agent", "complete"] as const;
type OnboardingStep = (typeof VALID_STEPS)[number];

const MarkStepSchema = z.object({
  step: z.enum(VALID_STEPS)
});

export function registerOnboardingRoutes(app: Hono, deps: AppDeps) {
  app.get("/api/internal/onboarding", async (c) => {
    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    if (!sessionCustomerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const customer = await getCustomerById(deps.db, sessionCustomerId);
    if (!customer) {
      return c.json({ error: "customer_not_found" }, 404);
    }

    const progress = (customer.onboarding_progress as Record<string, string>) ?? {};
    const nextStep = determineNextStep(progress);

    return c.json({
      completed_steps: Object.keys(progress),
      progress,
      next_step: nextStep,
      onboarding_complete: progress.complete !== undefined
    }, 200);
  });

  app.post("/api/internal/onboarding/complete-step", async (c) => {
    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    if (!sessionCustomerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const body = await c.req.json();
    const parsed = MarkStepSchema.safeParse(body);
    if (!parsed.success) {
      return c.json({ error: "invalid_input", details: parsed.error.flatten() }, 422);
    }

    const { step } = parsed.data;
    const customer = await getCustomerById(deps.db, sessionCustomerId);
    if (!customer) {
      return c.json({ error: "customer_not_found" }, 404);
    }

    const currentProgress = (customer.onboarding_progress as Record<string, string>) ?? {};
    currentProgress[step] = new Date().toISOString();

    const { data, error } = await deps.db
      .from("customers")
      .update({ onboarding_progress: currentProgress })
      .eq("customer_id", sessionCustomerId)
      .select("onboarding_progress")
      .single();

    if (error) {
      deps.logger.error({ err: error, customerId: sessionCustomerId }, "failed to update onboarding progress");
      return c.json({ error: "update_failed" }, 500);
    }

    const updatedProgress = (data as { onboarding_progress: Record<string, string> }).onboarding_progress ?? {};
    const nextStep = determineNextStep(updatedProgress);

    return c.json({
      completed_steps: Object.keys(updatedProgress),
      progress: updatedProgress,
      next_step: nextStep,
      onboarding_complete: updatedProgress.complete !== undefined
    }, 200);
  });

  app.post("/api/internal/onboarding/reset", async (c) => {
    const sessionCustomerId = await resolveSessionCustomerId(c, deps);
    if (!sessionCustomerId) {
      return c.json({ error: "unauthorized" }, 401);
    }

    const { error } = await deps.db
      .from("customers")
      .update({ onboarding_progress: {} })
      .eq("customer_id", sessionCustomerId);

    if (error) {
      deps.logger.error({ err: error, customerId: sessionCustomerId }, "failed to reset onboarding progress");
      return c.json({ error: "reset_failed" }, 500);
    }

    return c.json({
      completed_steps: [],
      progress: {},
      next_step: "profile" as OnboardingStep,
      onboarding_complete: false
    }, 200);
  });
}

const STEP_ORDER: OnboardingStep[] = ["profile", "plan", "model", "agent", "complete"];

function determineNextStep(progress: Record<string, string>): OnboardingStep | null {
  for (const step of STEP_ORDER) {
    if (progress[step] === undefined) {
      return step;
    }
  }
  return null;
}