-- =============================================================================
-- FORA-215: Neon-native RLS policies and auth helper function
--
-- Production audit revealed (CRIT-3, CRIT-4, HIGH-2, HIGH-4):
--   1. No authenticated-user RLS policies exist on production.
--      Only cloud_admin_all and cfo_readonly_select are present.
--   2. auth_workspace_slug() function does not exist on production.
--   3. Supabase-native roles (service_role, anon, authenticated) do not exist
--      on bare Neon. Migration 031 references these roles and will fail.
--
-- Resolution: Neon-native approach
--   - Create custom PostgreSQL roles: api_service, api_anon, api_authenticated
--   - Create auth_workspace_slug() using current_setting('app.workspace_slug')
--     (the backend Hono API sets this session variable per request)
--   - Apply workspace-scoped RLS policies for api_authenticated
--   - Apply blanket access policies for api_service (defense-in-depth)
--   - Apply deny-all policies for api_anon
--   - Grant role membership so the Neon connection string roles can switch context
--
-- Prerequisites: Migration 032 must be applied first (webhook tables).
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Create Neon-native roles (HIGH-4)
-- ─────────────────────────────────────────────────────────────────────────────
-- These roles mirror the Supabase concepts but work on bare Neon:
--   api_service      ≈ Supabase service_role (backend bypass)
--   api_anon         ≈ Supabase anon key (unauthenticated, deny all)
--   api_authenticated ≈ Supabase authenticated (workspace-scoped access)

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'api_service') THEN
    CREATE ROLE api_service NOINHERIT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'api_anon') THEN
    CREATE ROLE api_anon NOINHERIT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'api_authenticated') THEN
    CREATE ROLE api_authenticated NOINHERIT;
  END IF;
END $$;

-- Grant api_authenticated membership to api_anon (fallback chain)
GRANT api_anon TO api_authenticated;

-- Grant schema USAGE so roles can resolve table references
GRANT USAGE ON SCHEMA public TO api_service, api_anon, api_authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Auth helper: auth_workspace_slug() (CRIT-4)
-- ─────────────────────────────────────────────────────────────────────────────
-- Resolves the current workspace_slug from the session variable set by the
-- backend Hono API. The backend sets `app.workspace_slug` via SET LOCAL
-- at the start of each request context.
--
-- For Neon Auth direct-client scenarios, fails open to NULL (which blocks
-- all workspace-scoped rows — safe default).

CREATE OR REPLACE FUNCTION auth_workspace_slug()
RETURNS TEXT AS $$
  SELECT current_setting('app.workspace_slug', TRUE);
$$ LANGUAGE sql STABLE SECURITY DEFINER;

COMMENT ON FUNCTION auth_workspace_slug() IS
  'Resolves the workspace_slug for the current request context. '
  'The backend Hono API sets app.workspace_slug via SET LOCAL per request. '
  'Returns NULL when no workspace context is available (safe deny-all default).';

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Grant table permissions to custom roles
-- ─────────────────────────────────────────────────────────────────────────────
-- api_service needs full access (bypass via RLS policy)
-- api_authenticated needs SELECT/INSERT/UPDATE/DELETE on workspace-scoped tables
-- api_anon gets nothing (RLS denies all)
--
-- NOTE: Uses DO block with EXISTS checks so missing tables are skipped
-- gracefully instead of aborting the entire transaction.

DO $$
DECLARE
  t text;
BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'customers', 'agents', 'customer_sessions', 'chat_messages',
    'composio_sessions', 'composio_connections', 'composio_triggers',
    'composio_webhook_events', 'composio_webhook_deliveries',
    'page_views', 'email_subscribers', 'byok_fallback_events',
    'byok_keys', 'byok_key_audit_log',
    'provisioning_log', 'provisioning_idempotency', 'agent_usage_events',
    'funnel_events', 'nps_responses', 'notifications', 'task_escalation_state',
    'stripe_webhook_events', 'launch_email_sends', 'financial_transactions',
    'outreach_logs', 'request_costs', 'llm_call_log', 'hubspot_sync_log',
    'lead_pricing', 'service_requests', 'provider_applicants', 'providers',
    'campaign_providers', 'campaigns', 'crm_contacts', 'crm_deals',
    'crm_tasks', 'email_preferences', 'users'
  ]) LOOP
    -- Skip tables that don't exist yet (e.g. byok_key_audit_log added in 033)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t) THEN
      EXECUTE format('GRANT ALL ON public.%I TO api_service', t);
      EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO api_authenticated', t);
    END IF;
  END LOOP;
END $$;

-- api_anon: no table grants (deny all unauthenticated access)

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Enable RLS on all tables + api_service blanket access policies
-- ─────────────────────────────────────────────────────────────────────────────
-- RLS must be enabled per-table before policies can take effect.
-- Even though api_service could bypass RLS via role ownership, explicit
-- policy documents intent and provides an audit trail.

DO $$
DECLARE
  t text;
BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'customers', 'agents', 'customer_sessions', 'chat_messages',
    'composio_sessions', 'composio_connections', 'composio_triggers',
    'composio_webhook_events', 'composio_webhook_deliveries',
    'page_views', 'email_subscribers', 'byok_fallback_events',
    'byok_keys', 'byok_key_audit_log',
    'provisioning_log', 'provisioning_idempotency', 'agent_usage_events',
    'funnel_events', 'nps_responses', 'notifications', 'task_escalation_state',
    'stripe_webhook_events', 'launch_email_sends', 'financial_transactions',
    'outreach_logs', 'request_costs', 'llm_call_log', 'hubspot_sync_log',
    'lead_pricing', 'service_requests', 'provider_applicants', 'providers',
    'campaign_providers', 'campaigns', 'crm_contacts', 'crm_deals',
    'crm_tasks', 'email_preferences', 'users'
  ]) LOOP
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t) THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
      EXECUTE format(
        'CREATE POLICY IF NOT EXISTS api_service_all ON public.%I FOR ALL TO api_service USING (true) WITH CHECK (true)',
        t
      );
    END IF;
  END LOOP;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. RLS POLICIES: api_anon deny-all (defense-in-depth)
-- ───────────────────────────────────────────────────────────────────────------

DO $$
DECLARE
  t text;
BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'customers', 'agents', 'customer_sessions', 'chat_messages',
    'composio_sessions', 'composio_connections', 'composio_triggers',
    'composio_webhook_events', 'composio_webhook_deliveries',
    'page_views', 'email_subscribers', 'byok_fallback_events',
    'byok_keys', 'byok_key_audit_log',
    'provisioning_log', 'provisioning_idempotency', 'agent_usage_events',
    'funnel_events', 'nps_responses', 'notifications', 'task_escalation_state',
    'stripe_webhook_events', 'launch_email_sends', 'financial_transactions',
    'outreach_logs', 'request_costs', 'llm_call_log', 'hubspot_sync_log',
    'lead_pricing', 'service_requests', 'provider_applicants', 'providers',
    'campaign_providers', 'campaigns', 'crm_contacts', 'crm_deals',
    'crm_tasks', 'email_preferences', 'users'
  ]) LOOP
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t) THEN
      EXECUTE format(
        'CREATE POLICY IF NOT EXISTS api_anon_deny_all ON public.%I FOR SELECT TO api_anon USING (false)',
        t
      );
    END IF;
  END LOOP;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. RLS POLICIES: api_authenticated workspace-scoped access (HIGH-2)
-- ─────────────────────────────────────────────────────────────────────────────
-- These use auth_workspace_slug() to isolate data per workspace.
-- The backend sets app.workspace_slug per request context.

-- customers: read + update own workspace
CREATE POLICY IF NOT EXISTS customers_workspace_read ON customers
  FOR SELECT TO api_authenticated
  USING (workspace_slug = auth_workspace_slug());

CREATE POLICY IF NOT EXISTS customers_workspace_update ON customers
  FOR UPDATE TO api_authenticated
  USING (workspace_slug = auth_workspace_slug())
  WITH CHECK (workspace_slug = auth_workspace_slug());

-- agents: read, update, insert scoped to workspace
CREATE POLICY IF NOT EXISTS agents_workspace_read ON agents
  FOR SELECT TO api_authenticated
  USING (workspace_slug = auth_workspace_slug());

CREATE POLICY IF NOT EXISTS agents_workspace_update ON agents
  FOR UPDATE TO api_authenticated
  USING (workspace_slug = auth_workspace_slug())
  WITH CHECK (workspace_slug = auth_workspace_slug());

CREATE POLICY IF NOT EXISTS agents_workspace_insert ON agents
  FOR INSERT TO api_authenticated
  WITH CHECK (workspace_slug = auth_workspace_slug());

-- chat_messages: read/insert scoped via customer_id -> workspace
CREATE POLICY IF NOT EXISTS chat_messages_workspace_read ON chat_messages
  FOR SELECT TO api_authenticated
  USING (customer_id IN (
    SELECT customer_id FROM customers WHERE workspace_slug = auth_workspace_slug()
  ));

CREATE POLICY IF NOT EXISTS chat_messages_workspace_insert ON chat_messages
  FOR INSERT TO api_authenticated
  WITH CHECK (customer_id IN (
    SELECT customer_id FROM customers WHERE workspace_slug = auth_workspace_slug()
  ));

-- notifications: read, insert, update scoped to workspace
CREATE POLICY IF NOT EXISTS notifications_workspace_read ON notifications
  FOR SELECT TO api_authenticated
  USING (workspace_slug = auth_workspace_slug());

CREATE POLICY IF NOT EXISTS notifications_workspace_insert ON notifications
  FOR INSERT TO api_authenticated
  WITH CHECK (workspace_slug = auth_workspace_slug());

CREATE POLICY IF NOT EXISTS notifications_workspace_update ON notifications
  FOR UPDATE TO api_authenticated
  USING (workspace_slug = auth_workspace_slug())
  WITH CHECK (workspace_slug = auth_workspace_slug());

-- task_escalation_state: read, update scoped to workspace
CREATE POLICY IF NOT EXISTS task_escalation_workspace_read ON task_escalation_state
  FOR SELECT TO api_authenticated
  USING (workspace_slug = auth_workspace_slug());

CREATE POLICY IF NOT EXISTS task_escalation_workspace_update ON task_escalation_state
  FOR UPDATE TO api_authenticated
  USING (workspace_slug = auth_workspace_slug())
  WITH CHECK (workspace_slug = auth_workspace_slug());

-- byok_fallback_events: workspace_slug is the PK
CREATE POLICY IF NOT EXISTS byok_fallback_workspace_read ON byok_fallback_events
  FOR SELECT TO api_authenticated
  USING (workspace_slug = auth_workspace_slug());

CREATE POLICY IF NOT EXISTS byok_fallback_workspace_write ON byok_fallback_events
  FOR ALL TO api_authenticated
  USING (workspace_slug = auth_workspace_slug())
  WITH CHECK (workspace_slug = auth_workspace_slug());

-- byok_keys: workspace-scoped key management (matches BYOK migration 033)
CREATE POLICY IF NOT EXISTS api_authenticated_byok_keys_select ON byok_keys
  FOR SELECT TO api_authenticated
  USING (workspace_slug = auth_workspace_slug());

CREATE POLICY IF NOT EXISTS api_authenticated_byok_keys_insert ON byok_keys
  FOR INSERT TO api_authenticated
  WITH CHECK (workspace_slug = auth_workspace_slug());

CREATE POLICY IF NOT EXISTS api_authenticated_byok_keys_update ON byok_keys
  FOR UPDATE TO api_authenticated
  USING (workspace_slug = auth_workspace_slug())
  WITH CHECK (workspace_slug = auth_workspace_slug());

CREATE POLICY IF NOT EXISTS api_authenticated_byok_keys_delete ON byok_keys
  FOR DELETE TO api_authenticated
  USING (workspace_slug = auth_workspace_slug());

-- byok_key_audit_log: workspace-scoped read-only
CREATE POLICY IF NOT EXISTS api_authenticated_byok_audit_select ON byok_key_audit_log
  FOR SELECT TO api_authenticated
  USING (workspace_slug = auth_workspace_slug());

-- provisioning_log: read scoped to workspace
CREATE POLICY IF NOT EXISTS provisioning_log_workspace_read ON provisioning_log
  FOR SELECT TO api_authenticated
  USING (workspace_slug = auth_workspace_slug());

-- funnel_events: read scoped to workspace
CREATE POLICY IF NOT EXISTS funnel_events_workspace_read ON funnel_events
  FOR SELECT TO api_authenticated
  USING (workspace_slug = auth_workspace_slug());

-- nps_responses: read scoped to workspace
CREATE POLICY IF NOT EXISTS nps_responses_workspace_read ON nps_responses
  FOR SELECT TO api_authenticated
  USING (workspace_slug = auth_workspace_slug());

-- composio_sessions: read scoped via customer_id -> workspace
CREATE POLICY IF NOT EXISTS composio_sessions_workspace_read ON composio_sessions
  FOR SELECT TO api_authenticated
  USING (customer_id IN (
    SELECT customer_id FROM customers WHERE workspace_slug = auth_workspace_slug()
  ));

-- composio_connections: now has customer_id; workspace-scoped read
CREATE POLICY IF NOT EXISTS composio_connections_workspace_read ON composio_connections
  FOR SELECT TO api_authenticated
  USING (customer_id IN (
    SELECT customer_id FROM customers WHERE workspace_slug = auth_workspace_slug()
  ));

-- composio_triggers: read scoped via customer_id -> workspace
CREATE POLICY IF NOT EXISTS composio_triggers_workspace_read ON composio_triggers
  FOR SELECT TO api_authenticated
  USING (customer_id IN (
    SELECT customer_id FROM customers WHERE workspace_slug = auth_workspace_slug()
  ));

-- composio_webhook_events: workspace-scoped read
CREATE POLICY IF NOT EXISTS webhook_events_workspace_read ON composio_webhook_events
  FOR SELECT TO api_authenticated
  USING (customer_id IN (
    SELECT customer_id FROM customers WHERE workspace_slug = auth_workspace_slug()
  ));

-- composio_webhook_deliveries: workspace-scoped read (via event -> customer)
CREATE POLICY IF NOT EXISTS webhook_deliveries_workspace_read ON composio_webhook_deliveries
  FOR SELECT TO api_authenticated
  USING (webhook_event_id IN (
    SELECT id FROM composio_webhook_events WHERE customer_id IN (
      SELECT customer_id FROM customers WHERE workspace_slug = auth_workspace_slug()
    )
  ));

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. Record migration
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO _migrations (filename)
VALUES ('034_neon_native_rls_and_auth.sql')
ON CONFLICT DO NOTHING;