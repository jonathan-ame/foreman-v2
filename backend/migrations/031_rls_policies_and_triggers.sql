-- =============================================================================
-- FORA-178: Apply missing RLS policies, trigger functions, and triggers
-- 
-- Production state before this migration:
--   - RLS ENABLED on all 36 public tables (no policies exist)
--   - backend/migrations/018_rls.sql was NEVER applied to the Neon production DB
--   - Missing triggers: composio_connections, composio_triggers, task_escalation_state
--   - Missing trigger functions: update_composio_connections_updated_at,
--     update_composio_triggers_updated_at, update_task_escalation_state_updated_at
--
-- This migration provides:
--   1. service_role_all policy (bypass already implicit, explicit for clarity)
--   2. anon_read_none policy (blocks all anon/authenticated direct access by default)
--   3. authenticated workspace-scoped policies for customer-facing tables
--   4. Missing trigger functions and triggers
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. RLS POLICIES: service_role blanket access
-- ─────────────────────────────────────────────────────────────────────────────

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
      'CREATE POLICY IF NOT EXISTS service_role_all ON public.%I FOR ALL TO service_role USING (true) WITH CHECK (true)',
      t
    );
  END LOOP;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. RLS POLICIES: anon blocked (defense-in-depth)
-- ─────────────────────────────────────────────────────────────────────────────

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
      'CREATE POLICY IF NOT EXISTS anon_read_none ON public.%I FOR SELECT TO anon USING (false)',
      t
    );
  END LOOP;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. RLS POLICIES: authenticated workspace-scoped access
--    These use auth.jwt() -> 'sub' to resolve the Neon Auth user ID,
--    then join through customers.auth_user_id to determine workspace_slug.
--    This enables direct client-side Supabase queries from authenticated users.
-- ─────────────────────────────────────────────────────────────────────────────

-- Helper function: resolve workspace_slug from the authenticated JWT's sub claim
CREATE OR REPLACE FUNCTION auth_workspace_slug()
RETURNS TEXT AS $$
  SELECT c.workspace_slug
  FROM customers c
  WHERE c.auth_user_id = (auth.jwt() -> 'sub')::uuid
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

COMMENT ON FUNCTION auth_workspace_slug() IS 'Resolves the workspace_slug for the currently authenticated Neon Auth user. Returns NULL if no matching customer row exists.';

-- customers: read + update own workspace
CREATE POLICY customers_workspace_read ON customers
  FOR SELECT TO authenticated
  USING (workspace_slug = auth_workspace_slug());

CREATE POLICY customers_workspace_update ON customers
  FOR UPDATE TO authenticated
  USING (workspace_slug = auth_workspace_slug())
  WITH CHECK (workspace_slug = auth_workspace_slug());

-- agents: read + update scoped to workspace
CREATE POLICY agents_workspace_read ON agents
  FOR SELECT TO authenticated
  USING (workspace_slug = auth_workspace_slug());

CREATE POLICY agents_workspace_update ON agents
  FOR UPDATE TO authenticated
  USING (workspace_slug = auth_workspace_slug())
  WITH CHECK (workspace_slug = auth_workspace_slug());

CREATE POLICY agents_workspace_insert ON agents
  FOR INSERT TO authenticated
  WITH CHECK (workspace_slug = auth_workspace_slug());

-- chat_messages: read/insert scoped via customer_id → workspace
CREATE POLICY chat_messages_workspace_read ON chat_messages
  FOR SELECT TO authenticated
  USING (customer_id IN (
    SELECT customer_id FROM customers WHERE workspace_slug = auth_workspace_slug()
  ));

CREATE POLICY chat_messages_workspace_insert ON chat_messages
  FOR INSERT TO authenticated
  WITH CHECK (customer_id IN (
    SELECT customer_id FROM customers WHERE workspace_slug = auth_workspace_slug()
  ));

-- notifications: read/insert/update scoped to workspace
CREATE POLICY notifications_workspace_read ON notifications
  FOR SELECT TO authenticated
  USING (workspace_slug = auth_workspace_slug());

CREATE POLICY notifications_workspace_insert ON notifications
  FOR INSERT TO authenticated
  WITH CHECK (workspace_slug = auth_workspace_slug());

CREATE POLICY notifications_workspace_update ON notifications
  FOR UPDATE TO authenticated
  USING (workspace_slug = auth_workspace_slug())
  WITH CHECK (workspace_slug = auth_workspace_slug());

-- task_escalation_state: read/update scoped to workspace
CREATE POLICY task_escalation_workspace_read ON task_escalation_state
  FOR SELECT TO authenticated
  USING (workspace_slug = auth_workspace_slug());

CREATE POLICY task_escalation_workspace_update ON task_escalation_state
  FOR UPDATE TO authenticated
  USING (workspace_slug = auth_workspace_slug())
  WITH CHECK (workspace_slug = auth_workspace_slug());

-- byok_fallback_events: workspace_slug is PK
CREATE POLICY byok_fallback_workspace_read ON byok_fallback_events
  FOR SELECT TO authenticated
  USING (workspace_slug = auth_workspace_slug());

CREATE POLICY byok_fallback_workspace_write ON byok_fallback_events
  FOR ALL TO authenticated
  USING (workspace_slug = auth_workspace_slug())
  WITH CHECK (workspace_slug = auth_workspace_slug());

-- provisioning_log: read scoped to workspace
CREATE POLICY provisioning_log_workspace_read ON provisioning_log
  FOR SELECT TO authenticated
  USING (workspace_slug = auth_workspace_slug());

-- funnel_events: read scoped to workspace
CREATE POLICY funnel_events_workspace_read ON funnel_events
  FOR SELECT TO authenticated
  USING (workspace_slug = auth_workspace_slug());

-- nps_responses: read scoped to workspace
CREATE POLICY nps_responses_workspace_read ON nps_responses
  FOR SELECT TO authenticated
  USING (workspace_slug = auth_workspace_slug());

-- composio_sessions: read scoped via customer_id → workspace
CREATE POLICY composio_sessions_workspace_read ON composio_sessions
  FOR SELECT TO authenticated
  USING (customer_id IN (
    SELECT customer_id FROM customers WHERE workspace_slug = auth_workspace_slug()
  ));

-- composio_connections: no customer_id FK in current schema; service_role only
-- composio_triggers: read scoped via customer_id → workspace
CREATE POLICY composio_triggers_workspace_read ON composio_triggers
  FOR SELECT TO authenticated
  USING (customer_id IN (
    SELECT customer_id FROM customers WHERE workspace_slug = auth_workspace_slug()
  ));

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. MISSING TRIGGER FUNCTIONS AND TRIGGERS
-- ─────────────────────────────────────────────────────────────────────────────

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