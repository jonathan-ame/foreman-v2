-- Composio webhook event tracking and delivery pipeline (FORA-176).
-- Stores incoming webhook events and their processing outcomes.

CREATE TABLE IF NOT EXISTS composio_webhook_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trigger_id TEXT NOT NULL,
  trigger_type TEXT NOT NULL,
  toolkit TEXT,
  payload JSONB NOT NULL DEFAULT '{}',
  customer_id UUID REFERENCES customers(customer_id),
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  processing_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed')),
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_webhook_events_trigger_id
  ON composio_webhook_events(trigger_id);

CREATE INDEX IF NOT EXISTS idx_webhook_events_status
  ON composio_webhook_events(processing_status)
  WHERE processing_status IN ('pending', 'processing');

CREATE INDEX IF NOT EXISTS idx_webhook_events_customer
  ON composio_webhook_events(customer_id)
  WHERE customer_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS composio_webhook_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  webhook_event_id UUID NOT NULL REFERENCES composio_webhook_events(id),
  handler_type TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'sent', 'delivered', 'failed')),
  attempts INT NOT NULL DEFAULT 0,
  last_attempt_at TIMESTAMPTZ,
  error_message TEXT,
  result JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_webhook_deliveries_event
  ON composio_webhook_deliveries(webhook_event_id);

CREATE INDEX IF NOT EXISTS idx_webhook_deliveries_status
  ON composio_webhook_deliveries(status)
  WHERE status IN ('pending', 'failed');

COMMENT ON TABLE composio_webhook_events IS
  'Incoming Composio webhook events awaiting or completed processing. '
  'Each row is one trigger event received from the Composio platform.';

COMMENT ON TABLE composio_webhook_deliveries IS
  'Individual handler delivery attempts for a webhook event. '
  'Each row tracks one handler (e.g. notification, agent_issue) result.';