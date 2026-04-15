-- Agents table -- one row per provisioned agent
CREATE TABLE agents (
  agent_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
  workspace_slug TEXT NOT NULL,

  -- External system IDs
  paperclip_agent_id UUID NOT NULL UNIQUE,
  openclaw_agent_id TEXT NOT NULL,

  -- Identity
  display_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('ceo')),  -- v1: CEO only

  -- Configuration
  model_tier TEXT NOT NULL CHECK (model_tier IN ('open', 'frontier', 'hybrid')),
  model_primary TEXT NOT NULL,
  model_fallbacks JSONB NOT NULL DEFAULT '[]'::jsonb,
  billing_mode_at_provision TEXT NOT NULL,

  -- Lifecycle
  provisioned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_modified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  current_status TEXT NOT NULL DEFAULT 'active'
    CHECK (current_status IN ('active', 'paused', 'suspended', 'terminated')),

  -- Cost tracking (lifetime)
  total_tokens_input BIGINT NOT NULL DEFAULT 0,
  total_tokens_output BIGINT NOT NULL DEFAULT 0,

  -- Cost tracking (current billing period)
  tokens_input_current_period BIGINT NOT NULL DEFAULT 0,
  tokens_output_current_period BIGINT NOT NULL DEFAULT 0,
  surcharge_accrued_current_period_cents INTEGER,
  billing_period_start DATE NOT NULL DEFAULT CURRENT_DATE,
  billing_period_end DATE NOT NULL DEFAULT (CURRENT_DATE + INTERVAL '1 month'),
  last_billed_at TIMESTAMPTZ,
  last_billing_amount_cents INTEGER,

  -- Health
  last_health_check_at TIMESTAMPTZ,
  last_health_check_result TEXT,
  last_task_completed_at TIMESTAMPTZ,

  -- Uniqueness within a workspace
  UNIQUE (workspace_slug, display_name)
);

CREATE INDEX idx_agents_customer ON agents(customer_id);
CREATE INDEX idx_agents_workspace ON agents(workspace_slug);
CREATE INDEX idx_agents_status ON agents(current_status);
CREATE INDEX idx_agents_paperclip ON agents(paperclip_agent_id);

CREATE TRIGGER agents_updated_at
  BEFORE UPDATE ON agents
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE agents IS 'Provisioned agents. paperclip_agent_id and openclaw_agent_id reference external systems.';
COMMENT ON COLUMN agents.openclaw_agent_id IS 'Slug used in `openclaw agents add <slug>`. Distinct from UUID.';
