-- Multi-provider BYOK keys table
-- Replaces the single byok_key_encrypted column on customers with per-provider keys

CREATE TABLE IF NOT EXISTS byok_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
  provider TEXT NOT NULL CHECK (provider IN ('openrouter', 'together', 'deepinfra', 'dashscope', 'openai')),
  key_encrypted TEXT NOT NULL,
  key_prefix TEXT NOT NULL,
  label TEXT,
  is_valid BOOLEAN NOT NULL DEFAULT TRUE,
  last_validated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(customer_id, provider)
);

CREATE INDEX IF NOT EXISTS idx_byok_keys_customer_id ON byok_keys(customer_id);
CREATE INDEX IF NOT EXISTS idx_byok_keys_provider ON byok_keys(provider) WHERE is_valid = TRUE;

-- updated_at trigger for byok_keys
CREATE OR REPLACE FUNCTION update_byok_keys_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER byok_keys_updated_at
  BEFORE UPDATE ON byok_keys
  FOR EACH ROW
  EXECUTE FUNCTION update_byok_keys_updated_at();

COMMENT ON TABLE byok_keys IS 'Customer BYOK (Bring Your Own Key) API keys, encrypted at rest. One row per customer+provider.';