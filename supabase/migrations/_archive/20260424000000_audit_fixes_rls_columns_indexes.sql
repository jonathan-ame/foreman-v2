-- =============================================================================
-- FORA-155: Database audit for platform completion
-- Migration: Audit fixes — RLS, missing columns, indexes, triggers
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. MISSING TABLES: composio_sessions and composio_triggers
-- ─────────────────────────────────────────────────────────────────────────────
-- The local migration 20260422000000_composio_integration.sql defines 3 tables
-- but only composio_connections exists in the live DB. Create the other two.

CREATE TABLE IF NOT EXISTS composio_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(customer_id),
  composio_user_id TEXT NOT NULL,
  composio_session_id TEXT NOT NULL,
  mcp_url TEXT NOT NULL,
  mcp_headers JSONB NOT NULL DEFAULT '{}',
  toolkits JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS composio_triggers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(customer_id),
  composio_trigger_id TEXT NOT NULL,
  trigger_type TEXT NOT NULL,
  toolkit_slug TEXT NOT NULL,
  config JSONB NOT NULL DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_composio_sessions_customer
  ON composio_sessions(customer_id);
CREATE INDEX IF NOT EXISTS idx_composio_sessions_composio_session_id
  ON composio_sessions(composio_session_id);
CREATE INDEX IF NOT EXISTS idx_composio_triggers_customer
  ON composio_triggers(customer_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_composio_triggers_composio_id
  ON composio_triggers(composio_trigger_id);

COMMENT ON TABLE composio_sessions IS
  'Composio integration sessions. Each row maps a Foreman customer to a Composio session with MCP endpoint details.';
COMMENT ON TABLE composio_triggers IS
  'Composio trigger subscriptions. Maps external event triggers to Foreman customers for agent-driven automation.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. ROW LEVEL SECURITY
-- ─────────────────────────────────────────────────────────────────────────────
-- CRITICAL: No RLS policies existed on ANY public table. The backend uses
-- SUPABASE_SERVICE_KEY which bypasses RLS, so backend writes are unaffected.
-- These policies block unauthenticated / anon direct DB access while keeping
-- service_role fully operational.

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE composio_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE composio_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE composio_triggers ENABLE ROW LEVEL SECURITY;
ALTER TABLE page_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE byok_fallback_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE provisioning_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE provisioning_idempotency ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_usage_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE funnel_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE nps_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_escalation_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe_webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE launch_email_sends ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE outreach_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE request_costs ENABLE ROW LEVEL SECURITY;
ALTER TABLE llm_call_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE hubspot_sync_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE provider_applicants ENABLE ROW LEVEL SECURITY;
ALTER TABLE providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Service-role full access policies (backend uses service_role key)
-- Deny anon and authenticated users by default

DO $$
DECLARE
  t text;
BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'customers', 'agents', 'customer_sessions', 'chat_messages',
    'composio_sessions', 'composio_connections', 'composio_triggers',
    'page_views', 'email_subscribers', 'byok_fallback_events',
    'provisioning_log', 'provisioning_idempotency', 'agent_usage_events',
    'funnel_events', 'nps_responses', 'notifications', 'task_escalation_state',
    'stripe_webhook_events', 'launch_email_sends', 'financial_transactions',
    'outreach_logs', 'request_costs', 'llm_call_log', 'hubspot_sync_log',
    'lead_pricing', 'service_requests', 'provider_applicants', 'providers',
    'campaign_providers', 'campaigns', 'crm_contacts', 'crm_deals',
    'crm_tasks', 'email_preferences', 'users'
  ]) LOOP
    EXECUTE format(
      'CREATE POLICY service_role_all ON public.%I FOR ALL TO service_role USING (true) WITH CHECK (true)',
      t
    );
    EXECUTE format(
      'CREATE POLICY anon_read_none ON public.%I FOR SELECT TO anon, authenticated USING (false)',
      t
    );
  END LOOP;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. MISSING COLUMNS
-- ─────────────────────────────────────────────────────────────────────────────
-- notifications: code inserts reference_id and reference_type but they don't
-- exist in the live schema yet
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS reference_id text;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS reference_type text;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. MISSING INDEXES
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_nps_responses_workspace_slug
  ON nps_responses (workspace_slug);

CREATE INDEX IF NOT EXISTS idx_funnel_events_workspace_slug
  ON funnel_events (workspace_slug);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. MISSING updated_at AUTO-UPDATE TRIGGERS
-- ─────────────────────────────────────────────────────────────────────────────
-- These tables have updated_at columns but no trigger to auto-set them on UPDATE

CREATE OR REPLACE FUNCTION update_composio_connections_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_composio_connections_updated_at ON composio_connections;
CREATE TRIGGER set_composio_connections_updated_at
  BEFORE UPDATE ON composio_connections
  FOR EACH ROW EXECUTE FUNCTION update_composio_connections_updated_at();

CREATE OR REPLACE FUNCTION update_composio_triggers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_composio_triggers_updated_at ON composio_triggers;
CREATE TRIGGER set_composio_triggers_updated_at
  BEFORE UPDATE ON composio_triggers
  FOR EACH ROW EXECUTE FUNCTION update_composio_triggers_updated_at();

CREATE OR REPLACE FUNCTION update_task_escalation_state_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_task_escalation_state_updated_at ON task_escalation_state;
CREATE TRIGGER set_task_escalation_state_updated_at
  BEFORE UPDATE ON task_escalation_state
  FOR EACH ROW EXECUTE FUNCTION update_task_escalation_state_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. MIGRATION TRACKING
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS _migrations (
  name text PRIMARY KEY,
  applied_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO _migrations (name) VALUES ('20260424000000_audit_fixes_rls_columns_indexes.sql')
  ON CONFLICT (name) DO NOTHING;