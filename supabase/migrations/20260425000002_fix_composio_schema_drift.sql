-- =============================================================================
-- FORA-155: Fix Composio schema drift and add missing tables
--
-- The baseline schema (20260425000000) created composio_connections with
-- columns that don't match what the TypeScript application code expects.
-- This migration aligns the live schema with the application layer.
--
-- Changes:
--   1. Add customer_id FK to composio_connections (code queries by customer_id)
--   2. Add composio_connected_account_id column (code uses this, not composio_account_id)
--   3. Add toolkit_name column (TypeScript interface expects it)
--   4. Change status default from 'ACTIVE' to 'active' (code uses lowercase)
--   5. Add composio_webhook_events table (used by db/webhook-events.ts)
--   6. Add composio_webhook_deliveries table (used by db/webhook-events.ts)
--   7. Add RLS policies for new webhook tables
--   8. Add index on composio_connections.customer_id
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Fix composio_connections schema
-- ─────────────────────────────────────────────────────────────────────────────

-- Add customer_id FK (the TS code queries .eq("customer_id", customerId))
ALTER TABLE composio_connections
  ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES customers(customer_id);

-- Add composio_connected_account_id (the TS code uses this column name)
-- Copy data from composio_account_id if it exists
ALTER TABLE composio_connections
  ADD COLUMN IF NOT EXISTS composio_connected_account_id TEXT;

UPDATE composio_connections
  SET composio_connected_account_id = composio_account_id
  WHERE composio_connected_account_id IS NULL AND composio_account_id IS NOT NULL;

-- Add toolkit_name (TS interface ComposioConnectionInsert includes it)
ALTER TABLE composio_connections
  ADD COLUMN IF NOT EXISTS toolkit_name TEXT;

-- Fix status default: code uses 'active' not 'ACTIVE'
ALTER TABLE composio_connections
  ALTER COLUMN status SET DEFAULT 'active';

-- Update any existing uppercase status values
UPDATE composio_connections SET status = 'active' WHERE status = 'ACTIVE';
UPDATE composio_connections SET status = 'disconnected' WHERE status = 'DISCONNECTED';

-- Add index on customer_id for the queries in db/composio.ts
CREATE INDEX IF NOT EXISTS idx_composio_connections_customer
  ON composio_connections(customer_id);

-- Add composite index matching the code's query pattern
CREATE INDEX IF NOT EXISTS idx_composio_connections_customer_toolkit
  ON composio_connections(customer_id, toolkit_slug);

-- Add unique index on composio_connected_account_id
CREATE UNIQUE INDEX IF NOT EXISTS idx_composio_connections_connected_account
  ON composio_connections(composio_connected_account_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Add composio_webhook_events table
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
-- 3. Add composio_webhook_deliveries table
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
-- 4. RLS policies for webhook tables
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE composio_webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE composio_webhook_deliveries ENABLE ROW LEVEL SECURITY;

CREATE POLICY cloud_admin_all ON composio_webhook_events
  FOR ALL TO cloud_admin
  USING (true) WITH CHECK (true);

CREATE POLICY cfo_readonly_select ON composio_webhook_events
  FOR SELECT TO cfo_readonly
  USING (true);

CREATE POLICY cloud_admin_all ON composio_webhook_deliveries
  FOR ALL TO cloud_admin
  USING (true) WITH CHECK (true);

CREATE POLICY cfo_readonly_select ON composio_webhook_deliveries
  FOR SELECT TO cfo_readonly
  USING (true);