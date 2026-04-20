-- NPS survey tracking.
-- One row per survey sent. A workspace may receive multiple surveys over time
-- (post_onboarding + quarterly cadence).

CREATE TABLE IF NOT EXISTS nps_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_slug TEXT NOT NULL,
  trigger_type TEXT NOT NULL
    CHECK (trigger_type IN ('post_onboarding', 'quarterly')),
  score INTEGER CHECK (score BETWEEN 0 AND 10),
  comment TEXT,
  survey_sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded_at TIMESTAMPTZ,
  email_sent_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_nps_responses_workspace
  ON nps_responses(workspace_slug, survey_sent_at DESC);

CREATE INDEX IF NOT EXISTS idx_nps_responses_pending
  ON nps_responses(survey_sent_at) WHERE responded_at IS NULL;

COMMENT ON TABLE nps_responses IS
  'Tracks NPS survey sends and responses. '
  'A row is inserted when a survey email is dispatched; responded_at is set when the customer submits.';
