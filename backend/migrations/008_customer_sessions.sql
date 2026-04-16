CREATE TABLE IF NOT EXISTS customer_sessions (
  session_id UUID PRIMARY KEY,
  customer_id UUID NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customer_sessions_customer_id
ON customer_sessions(customer_id);

CREATE INDEX IF NOT EXISTS idx_customer_sessions_expires_at
ON customer_sessions(expires_at);
