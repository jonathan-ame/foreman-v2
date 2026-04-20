-- Row-Level Security: multi-tenant isolation keyed on workspace_slug.
-- The backend uses the service role key, which bypasses RLS automatically.
-- These policies protect against accidental anon/authenticated-key access
-- and enforce defense-in-depth for any future client-side Supabase usage.

-- customers: workspace_slug IS the primary key of multi-tenancy
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- Service role bypasses RLS — no explicit policy needed for it.
-- Authenticated users can read their own workspace row.
CREATE POLICY customers_workspace_read ON customers
  FOR SELECT
  TO authenticated
  USING (workspace_slug = current_setting('app.workspace_slug', TRUE));

CREATE POLICY customers_workspace_update ON customers
  FOR UPDATE
  TO authenticated
  USING (workspace_slug = current_setting('app.workspace_slug', TRUE))
  WITH CHECK (workspace_slug = current_setting('app.workspace_slug', TRUE));

-- agents: scoped by workspace_slug
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;

CREATE POLICY agents_workspace_read ON agents
  FOR SELECT
  TO authenticated
  USING (workspace_slug = current_setting('app.workspace_slug', TRUE));

CREATE POLICY agents_workspace_update ON agents
  FOR UPDATE
  TO authenticated
  USING (workspace_slug = current_setting('app.workspace_slug', TRUE))
  WITH CHECK (workspace_slug = current_setting('app.workspace_slug', TRUE));

CREATE POLICY agents_workspace_insert ON agents
  FOR INSERT
  TO authenticated
  WITH CHECK (workspace_slug = current_setting('app.workspace_slug', TRUE));

-- notifications: scoped by workspace_slug
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY notifications_workspace_read ON notifications
  FOR SELECT
  TO authenticated
  USING (workspace_slug = current_setting('app.workspace_slug', TRUE));

CREATE POLICY notifications_workspace_insert ON notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (workspace_slug = current_setting('app.workspace_slug', TRUE));

CREATE POLICY notifications_workspace_update ON notifications
  FOR UPDATE
  TO authenticated
  USING (workspace_slug = current_setting('app.workspace_slug', TRUE))
  WITH CHECK (workspace_slug = current_setting('app.workspace_slug', TRUE));

-- byok_fallback_events: workspace_slug is the PK
ALTER TABLE byok_fallback_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY byok_fallback_workspace_read ON byok_fallback_events
  FOR SELECT
  TO authenticated
  USING (workspace_slug = current_setting('app.workspace_slug', TRUE));

CREATE POLICY byok_fallback_workspace_write ON byok_fallback_events
  FOR ALL
  TO authenticated
  USING (workspace_slug = current_setting('app.workspace_slug', TRUE))
  WITH CHECK (workspace_slug = current_setting('app.workspace_slug', TRUE));

-- provisioning_log: scoped by workspace_slug
ALTER TABLE provisioning_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY provisioning_log_workspace_read ON provisioning_log
  FOR SELECT
  TO authenticated
  USING (workspace_slug = current_setting('app.workspace_slug', TRUE));

-- agent_usage_events: no workspace_slug column; keyed by paperclip_agent_id.
-- RLS left off — only accessible via service role from the backend.
-- Future: add workspace_slug FK if direct client access is needed.
