-- Customers table -- one row per Foreman customer (workspace)
CREATE TABLE customers (
  customer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_slug TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,

  -- Billing state
  stripe_customer_id TEXT UNIQUE,
  current_billing_mode TEXT NOT NULL DEFAULT 'foreman_managed_tier'
    CHECK (current_billing_mode IN (
      'foreman_managed_tier',
      'foreman_managed_usage',
      'byok'
    )),
  current_tier TEXT
    CHECK (current_tier IS NULL OR current_tier IN ('tier_1', 'tier_2', 'tier_3')),
  byok_key_encrypted TEXT,
  byok_fallback_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  prepaid_balance_cents INTEGER,
  payment_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (payment_status IN ('pending', 'active', 'past_due', 'canceled', 'trialing')),

  -- Sub-agent approval
  agent_approval_mode TEXT NOT NULL DEFAULT 'auto'
    CHECK (agent_approval_mode IN ('auto', 'manual')),

  -- Lifecycle
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_customers_workspace_slug ON customers(workspace_slug);
CREATE INDEX idx_customers_payment_status ON customers(payment_status);
CREATE INDEX idx_customers_stripe ON customers(stripe_customer_id) WHERE stripe_customer_id IS NOT NULL;

-- updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER customers_updated_at
  BEFORE UPDATE ON customers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE customers IS 'One row per Foreman customer. workspace_slug is the multi-tenancy key.';
