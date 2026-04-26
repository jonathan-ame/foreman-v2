-- Composio integration tables.
-- Tracks sessions, connected accounts, and triggers for the Composio
-- external-toolkit integration (FORA-76).

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

CREATE TABLE IF NOT EXISTS composio_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(customer_id),
  composio_connected_account_id TEXT NOT NULL,
  toolkit_slug TEXT NOT NULL,
  toolkit_name TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
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

CREATE INDEX IF NOT EXISTS idx_composio_connections_customer
  ON composio_connections(customer_id);

CREATE INDEX IF NOT EXISTS idx_composio_connections_toolkit
  ON composio_connections(customer_id, toolkit_slug);

CREATE UNIQUE INDEX IF NOT EXISTS idx_composio_connections_composio_id
  ON composio_connections(composio_connected_account_id);

CREATE INDEX IF NOT EXISTS idx_composio_triggers_customer
  ON composio_triggers(customer_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_composio_triggers_composio_id
  ON composio_triggers(composio_trigger_id);

COMMENT ON TABLE composio_sessions IS
  'Composio integration sessions. Each row maps a Foreman customer to a Composio '
  'session with MCP endpoint details for agent tool access.';

COMMENT ON TABLE composio_connections IS
  'Connected external accounts via Composio. Tracks which toolkits a customer '
  'has authenticated with (GitHub, Slack, Gmail, etc.).';

COMMENT ON TABLE composio_triggers IS
  'Composio trigger subscriptions. Maps external event triggers (webhook/polling) '
  'to Foreman customers for agent-driven automation.';
