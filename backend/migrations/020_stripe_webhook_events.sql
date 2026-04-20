-- Idempotency table for Stripe webhook events.
-- Prevents double-processing if Stripe retries a delivery.
CREATE TABLE IF NOT EXISTS stripe_webhook_events (
  stripe_event_id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL,
  livemode BOOLEAN NOT NULL,
  processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stripe_webhook_events_processed_at
  ON stripe_webhook_events(processed_at DESC);

COMMENT ON TABLE stripe_webhook_events IS
  'Dedup log for processed Stripe webhook events. Pruned after 30 days.';
