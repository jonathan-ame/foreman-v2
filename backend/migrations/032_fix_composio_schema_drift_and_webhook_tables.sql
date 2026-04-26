-- =============================================================================
-- FORA-215: Fix Composio schema drift and add missing webhook tables
--
-- Production audit revealed:
--   1. composio_webhook_events and composio_webhook_deliveries do not exist
--      on production (CRIT-1). Migration 030 defined them via
--      CREATE TABLE IF NOT EXISTS but may not have been applied.
--   2. composio_connections is missing 3 columns: customer_id,
--      composio_connected_account_id, toolkit_name (CRIT-2, HIGH-3).
--   3. composio_connections.status default uses 'ACTIVE' (uppercase) but the
--      TypeScript layer expects 'active' (lowercase).
--
-- This migration consolidates supabase/migrations/20260425000002 into the
-- backend migration runner pipeline. All DDL uses IF NOT EXISTS or
-- ADD COLUMN IF NOT EXISTS for idempotency.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Fix composio_connections schema
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE composio_connections
  ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES customers(customer_id);

ALTER TABLE composio_connections
  ADD COLUMN IF NOT EXISTS composio_connected_account_id TEXT;

ALTER TABLE composio_connections
  ADD COLUMN IF NOT EXISTS toolkit_name TEXT;

-- Backfill composio_connected_account_id from composio_account_id where possible
UPDATE composio_connections
  SET composio_connected_account_id = composio_account_id
  WHERE composio_connected_account_id IS NULL AND composio_account_id IS NOT NULL;

-- Fix status default: application code uses lowercase 'active'
ALTER TABLE composio_connections
  ALTER COLUMN status SET DEFAULT 'active';

-- Normalize any existing uppercase status values
UPDATE composio_connections SET status = 'active' WHERE status = 'ACTIVE';
UPDATE composio_connections SET status = 'disconnected' WHERE status = 'DISCONNECTED';

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Add indexes for composio_connections query patterns
-- ─────────────────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_composio_connections_customer
  ON composio_connections(customer_id);

CREATE INDEX IF NOT EXISTS idx_composio_connections_customer_toolkit
  ON composio_connections(customer_id, toolkit_slug);

CREATE UNIQUE INDEX IF NOT EXISTS idx_composio_connections_connected_account
  ON composio_connections(composio_connected_account_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Create composio_webhook_events table (CRIT-1)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS composio_webhook_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trigger_id TEXT NOT NULL,
  trigger_type TEXT NOT NULL,
  toolkit TEXT,
  payload JSONB NOT NULL DEFAULT '{}',
  customer_id UUID REFERENCES customers(customer_id),
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  processing_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed')),
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_webhook_events_trigger_id
  ON composio_webhook_events(trigger_id);

CREATE INDEX IF NOT EXISTS idx_webhook_events_status
  ON composio_webhook_events(processing_status)
  WHERE processing_status IN ('pending', 'processing');

CREATE INDEX IF NOT EXISTS idx_webhook_events_customer
  ON composio_webhook_events(customer_id)
  WHERE customer_id IS NOT NULL;

COMMENT ON TABLE composio_webhook_events IS
  'Incoming Composio webhook events awaiting or completed processing. '
  'Each row is one trigger event received from the Composio platform.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Create composio_webhook_deliveries table (CRIT-1)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS composio_webhook_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  webhook_event_id UUID NOT NULL REFERENCES composio_webhook_events(id),
  handler_type TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'sent', 'delivered', 'failed')),
  attempts INT NOT NULL DEFAULT 0,
  last_attempt_at TIMESTAMPTZ,
  error_message TEXT,
  result JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_webhook_deliveries_event
  ON composio_webhook_deliveries(webhook_event_id);

CREATE INDEX IF NOT EXISTS idx_webhook_deliveries_status
  ON composio_webhook_deliveries(status)
  WHERE status IN ('pending', 'failed');

COMMENT ON TABLE composio_webhook_deliveries IS
  'Individual handler delivery attempts for a webhook event. '
  'Each row tracks one handler (e.g. notification, agent_issue) result.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. RLS policies for webhook tables
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE composio_webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE composio_webhook_deliveries ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS cloud_admin_all ON composio_webhook_events
  FOR ALL TO cloud_admin
  USING (true) WITH CHECK (true);

CREATE POLICY IF NOT EXISTS cfo_readonly_select ON composio_webhook_events
  FOR SELECT TO cfo_readonly
  USING (true);

CREATE POLICY IF NOT EXISTS cloud_admin_all ON composio_webhook_deliveries
  FOR ALL TO cloud_admin
  USING (true) WITH CHECK (true);

CREATE POLICY IF NOT EXISTS cfo_readonly_select ON composio_webhook_deliveries
  FOR SELECT TO cfo_readonly
  USING (true);

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Record migration
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO _migrations (filename)
VALUES ('032_fix_composio_schema_drift_and_webhook_tables.sql')
ON CONFLICT DO NOTHING;