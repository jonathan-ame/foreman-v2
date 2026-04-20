-- BYOK fallback tracking: adds per-customer fallback state and dedup event log

ALTER TABLE customers
  ADD COLUMN IF NOT EXISTS byok_using_fallback BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_customers_byok_fallback
  ON customers(current_billing_mode, byok_using_fallback)
  WHERE current_billing_mode = 'byok';

-- One row per workspace: tracks the 24h email-dedup window for BYOK fallback notifications
CREATE TABLE IF NOT EXISTS byok_fallback_events (
  workspace_slug TEXT PRIMARY KEY,
  first_fallback_at TIMESTAMPTZ NOT NULL,
  last_fallback_at TIMESTAMPTZ NOT NULL,
  last_email_notified_at TIMESTAMPTZ,
  fallback_count INTEGER NOT NULL DEFAULT 1
);

COMMENT ON TABLE byok_fallback_events IS
  'Dedup tracking for BYOK fallback notification emails (24h window per workspace).';
