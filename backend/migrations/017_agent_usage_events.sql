-- Append-only usage event log per agent.
-- Allows reconciliation of agent counter columns (total_tokens_input, etc.)
-- if a counter increment failed silently or the backend was briefly unavailable.

CREATE TABLE IF NOT EXISTS agent_usage_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paperclip_agent_id UUID NOT NULL,
  input_tokens INTEGER NOT NULL DEFAULT 0,
  output_tokens INTEGER NOT NULL DEFAULT 0,
  cost_cents INTEGER NOT NULL DEFAULT 0,
  model TEXT,
  provider TEXT,
  issue_id TEXT,
  occurred_at TIMESTAMPTZ NOT NULL,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agent_usage_events_agent_occurred
  ON agent_usage_events(paperclip_agent_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_agent_usage_events_occurred
  ON agent_usage_events(occurred_at DESC);

COMMENT ON TABLE agent_usage_events IS
  'Append-only log of every usage event received from the token-meter plugin. '
  'Used to reconcile agent counter columns against the raw event stream.';
