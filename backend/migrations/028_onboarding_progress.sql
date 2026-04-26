-- Onboarding progress tracking for new customer signup flow.
-- Stores which onboarding steps the user has completed as a JSONB object.
-- Steps: profile, plan, model, agent, complete

ALTER TABLE customers
  ADD COLUMN IF NOT EXISTS onboarding_progress JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN customers.onboarding_progress IS
  'JSONB tracking which onboarding steps the user has completed. Keys: profile, plan, model, agent, complete. Values are ISO timestamps.';