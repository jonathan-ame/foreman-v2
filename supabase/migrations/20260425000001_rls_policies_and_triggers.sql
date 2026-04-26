-- =============================================================================
-- FORA-178: Apply RLS policies and triggers to live Neon database
-- 
-- This migration was applied directly to the live database on 2026-04-24.
-- It is recorded here for tracking purposes.
--
-- Changes:
--   1. RLS policies for all 35 public tables using Neon-native roles
--      (cloud_admin, cfo_readonly) instead of Supabase roles
--      (service_role, anon, authenticated)
--   2. Missing updated_at triggers for composio_connections,
--      composio_triggers, and task_escalation_state
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. ROW LEVEL SECURITY POLICIES
-- ─────────────────────────────────────────────────────────────────────────────
-- RLS was already enabled on all tables from prior migrations.
-- This step adds the actual policies that were missing.

-- NOTE: Already applied to live DB. DO NOT RE-APPLY without checking for
-- existing policies first.

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. TRIGGERS
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