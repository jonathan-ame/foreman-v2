-- Idempotency cache -- provisioning calls return cached result for same key within 24h
CREATE TABLE provisioning_idempotency (
  idempotency_key UUID NOT NULL,
  customer_id UUID NOT NULL,
  result JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours'),
  PRIMARY KEY (idempotency_key, customer_id)
);

CREATE INDEX idx_idempotency_expires ON provisioning_idempotency(expires_at);

COMMENT ON TABLE provisioning_idempotency IS 'Caches provisioning results for 24h to support safe retries.';
