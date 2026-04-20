-- Activation funnel event log.
-- One row per event per workspace. Events are append-only and best-effort.

CREATE TABLE IF NOT EXISTS funnel_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_slug TEXT NOT NULL,
  event_type TEXT NOT NULL
    CHECK (event_type IN ('signup', 'first_agent_running', 'first_task_in_progress')),
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_funnel_events_workspace_type
  ON funnel_events(workspace_slug, event_type);

CREATE INDEX IF NOT EXISTS idx_funnel_events_occurred
  ON funnel_events(occurred_at DESC);

COMMENT ON TABLE funnel_events IS
  'Append-only activation funnel event log. '
  'Each workspace_slug+event_type pair should have at most one row (enforced at application layer). '
  'Used for MRR/activation dashboards and D7/D30 retention calculations.';
