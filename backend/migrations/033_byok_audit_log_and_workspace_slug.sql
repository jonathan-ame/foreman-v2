-- =============================================================================
-- FORA-287: Add byok_key_audit_log table and workspace_slug to byok_keys
--
-- Prerequisite for migration 034 (RLS policies):
--   1. byok_key_audit_log must exist before 034's DO {} block grants permissions
--   2. byok_keys must have workspace_slug for RLS policy reference
--
-- Both gaps were identified during schema verification (FORA-287).
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Add workspace_slug to byok_keys
-- ─────────────────────────────────────────────────────────────────────────────
-- The RLS policies in 034 reference byok_keys.workspace_slug for workspace-
-- scoped access. This column is derived from the customer relationship but
-- must exist on the table for the RLS USING clause to function efficiently.

ALTER TABLE byok_keys
  ADD COLUMN IF NOT EXISTS workspace_slug TEXT;

-- Backfill workspace_slug from customers table
UPDATE byok_keys k
  SET workspace_slug = c.workspace_slug
  FROM customers c
  WHERE k.customer_id = c.customer_id
    AND k.workspace_slug IS NULL;

-- Add index for workspace-scoped RLS queries
CREATE INDEX IF NOT EXISTS idx_byok_keys_workspace_slug
  ON byok_keys(workspace_slug)
  WHERE workspace_slug IS NOT NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Create byok_key_audit_log table
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS byok_key_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_slug TEXT NOT NULL,
  customer_id UUID NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
  key_id UUID REFERENCES byok_keys(id) ON DELETE SET NULL,
  action TEXT NOT NULL CHECK (action IN ('created', 'updated', 'rotated', 'validated', 'invalidated', 'deleted')),
  provider TEXT,
  key_prefix TEXT,
  performed_by TEXT,
  detail JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_byok_key_audit_log_workspace
  ON byok_key_audit_log(workspace_slug);

CREATE INDEX IF NOT EXISTS idx_byok_key_audit_log_customer
  ON byok_key_audit_log(customer_id);

CREATE INDEX IF NOT EXISTS idx_byok_key_audit_log_key
  ON byok_key_audit_log(key_id)
  WHERE key_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_byok_key_audit_log_created
  ON byok_key_audit_log(created_at);

-- Enable RLS (policies added by migration 034)
ALTER TABLE byok_key_audit_log ENABLE ROW LEVEL SECURITY;

-- cloud_admin full access
CREATE POLICY IF NOT EXISTS cloud_admin_all ON byok_key_audit_log
  FOR ALL TO cloud_admin
  USING (true) WITH CHECK (true);

-- cfo_readonly read access
CREATE POLICY IF NOT EXISTS cfo_readonly_select ON byok_key_audit_log
  FOR SELECT TO cfo_readonly
  USING (true);

COMMENT ON TABLE byok_key_audit_log IS
  'Audit log for BYOK key lifecycle events (creation, rotation, validation, deletion). '
  'One row per key action, workspace-scoped for RLS.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Record migration
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO _migrations (filename)
VALUES ('033_byok_audit_log_and_workspace_slug.sql')
ON CONFLICT DO NOTHING;