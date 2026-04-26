-- =============================================================================
-- FORA-287: Model routing failover, migration log, and error event tables
--
-- These tables support the model routing infrastructure:
--   1. model_routing_failover_state — per-agent active failover tracking
--   2. model_routing_migration_log  — model change audit trail
--   3. model_routing_error_events   — provider/model error capture
--
-- Identified as missing during schema verification (FORA-287).
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. model_routing_failover_state
-- ─────────────────────────────────────────────────────────────────────────────
-- Tracks which model an agent is currently using after failover.
-- One row per agent. Active failover = primary_restored_at IS NULL.

CREATE TABLE IF NOT EXISTS model_routing_failover_state (
  agent_id UUID NOT NULL REFERENCES agents(agent_id) ON DELETE CASCADE PRIMARY KEY,
  workspace_slug TEXT NOT NULL,
  active_model TEXT NOT NULL,
  primary_model TEXT NOT NULL,
  failover_reason TEXT,
  failover_started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  primary_restored_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_failover_state_workspace
  ON model_routing_failover_state(workspace_slug);

CREATE INDEX IF NOT EXISTS idx_failover_state_active
  ON model_routing_failover_state(agent_id)
  WHERE primary_restored_at IS NULL;

CREATE TRIGGER model_routing_failover_state_updated_at
  BEFORE UPDATE ON model_routing_failover_state
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. model_routing_migration_log
-- ─────────────────────────────────────────────────────────────────────────────
-- Audit trail for model routing changes (tier upgrades, provider swaps, etc.).

CREATE TABLE IF NOT EXISTS model_routing_migration_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID NOT NULL REFERENCES agents(agent_id) ON DELETE CASCADE,
  workspace_slug TEXT NOT NULL,
  from_model TEXT NOT NULL,
  to_model TEXT NOT NULL,
  migration_type TEXT NOT NULL CHECK (migration_type IN (
    'tier_upgrade', 'tier_downgrade', 'provider_swap', 'manual_override', 'health_failover'
  )),
  triggered_by TEXT NOT NULL CHECK (triggered_by IN (
    'health_check', 'admin', 'provisioning', 'escalation', 'manual'
  )),
  provisioning_id UUID,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  outcome TEXT CHECK (outcome IN ('success', 'failed', 'rolled_back')),
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_migration_log_agent
  ON model_routing_migration_log(agent_id);

CREATE INDEX IF NOT EXISTS idx_migration_log_workspace
  ON model_routing_migration_log(workspace_slug);

CREATE INDEX IF NOT EXISTS idx_migration_log_type
  ON model_routing_migration_log(migration_type);

CREATE INDEX IF NOT EXISTS idx_migration_log_started
  ON model_routing_migration_log(started_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. model_routing_error_events
-- ─────────────────────────────────────────────────────────────────────────────
-- Individual provider/model errors that may trigger failover.

CREATE TABLE IF NOT EXISTS model_routing_error_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID NOT NULL REFERENCES agents(agent_id) ON DELETE CASCADE,
  workspace_slug TEXT NOT NULL,
  model TEXT NOT NULL,
  provider TEXT,
  error_type TEXT NOT NULL CHECK (error_type IN (
    'timeout', 'rate_limit', '503_unavailable', 'auth_failure', 'context_overflow', 'unknown'
  )),
  error_code TEXT,
  error_message TEXT,
  request_id TEXT,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_error_events_agent
  ON model_routing_error_events(agent_id);

CREATE INDEX IF NOT EXISTS idx_error_events_workspace
  ON model_routing_error_events(workspace_slug);

CREATE INDEX IF NOT EXISTS idx_error_events_type
  ON model_routing_error_events(error_type);

CREATE INDEX IF NOT EXISTS idx_error_events_occurred
  ON model_routing_error_events(occurred_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. RLS policies for model routing tables
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE model_routing_failover_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE model_routing_migration_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE model_routing_error_events ENABLE ROW LEVEL SECURITY;

-- cloud_admin: full access
CREATE POLICY IF NOT EXISTS cloud_admin_all ON model_routing_failover_state
  FOR ALL TO cloud_admin USING (true) WITH CHECK (true);
CREATE POLICY IF NOT EXISTS cloud_admin_all ON model_routing_migration_log
  FOR ALL TO cloud_admin USING (true) WITH CHECK (true);
CREATE POLICY IF NOT EXISTS cloud_admin_all ON model_routing_error_events
  FOR ALL TO cloud_admin USING (true) WITH CHECK (true);

-- cfo_readonly: read access
CREATE POLICY IF NOT EXISTS cfo_readonly_select ON model_routing_failover_state
  FOR SELECT TO cfo_readonly USING (true);
CREATE POLICY IF NOT EXISTS cfo_readonly_select ON model_routing_migration_log
  FOR SELECT TO cfo_readonly USING (true);
CREATE POLICY IF NOT EXISTS cfo_readonly_select ON model_routing_error_events
  FOR SELECT TO cfo_readonly USING (true);

-- api_authenticated: workspace-scoped access
CREATE POLICY IF NOT EXISTS failover_state_workspace_read ON model_routing_failover_state
  FOR SELECT TO api_authenticated
  USING (workspace_slug = auth_workspace_slug());

CREATE POLICY IF NOT EXISTS migration_log_workspace_read ON model_routing_migration_log
  FOR SELECT TO api_authenticated
  USING (workspace_slug = auth_workspace_slug());

CREATE POLICY IF NOT EXISTS error_events_workspace_read ON model_routing_error_events
  FOR SELECT TO api_authenticated
  USING (workspace_slug = auth_workspace_slug());

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Record migration
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO _migrations (filename)
VALUES ('035_model_routing_tables.sql')
ON CONFLICT DO NOTHING;