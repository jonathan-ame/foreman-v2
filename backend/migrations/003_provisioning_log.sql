-- Provisioning audit log -- one row per call to provisionForemanAgent
CREATE TABLE provisioning_log (
  provisioning_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_slug TEXT NOT NULL,
  customer_id UUID NOT NULL,
  agent_name TEXT NOT NULL,
  role TEXT NOT NULL,
  model_tier TEXT NOT NULL,
  billing_mode_at_time TEXT NOT NULL,

  -- Timing
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  duration_ms INTEGER,

  -- Outcome
  outcome TEXT NOT NULL CHECK (outcome IN (
    'success', 'failed', 'partial', 'partial_with_warning', 'blocked'
  )),
  failed_step TEXT,
  error_code TEXT,
  error_message TEXT,
  rollback_performed BOOLEAN NOT NULL DEFAULT FALSE,
  steps_completed JSONB NOT NULL DEFAULT '[]'::jsonb,
  raw_payload_excerpts JSONB,

  -- Cross-references
  idempotency_key UUID NOT NULL,
  agent_id UUID  -- nullable; null for failures before agent creation
);

CREATE INDEX idx_provisioning_log_customer ON provisioning_log(customer_id, started_at DESC);
CREATE INDEX idx_provisioning_log_workspace ON provisioning_log(workspace_slug, started_at DESC);
CREATE INDEX idx_provisioning_log_outcome ON provisioning_log(outcome, started_at DESC);
CREATE INDEX idx_provisioning_log_idempotency ON provisioning_log(idempotency_key);

COMMENT ON TABLE provisioning_log IS 'Audit log for every provisionForemanAgent call. Append-only.';
