CREATE TABLE IF NOT EXISTS launch_email_sends (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscriber_id UUID NOT NULL REFERENCES email_subscribers(id) ON DELETE CASCADE,
  email_key TEXT NOT NULL,
  segment TEXT NOT NULL CHECK (segment IN ('A', 'B', 'C')),
  sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('sent', 'failed')),
  error_message TEXT,
  UNIQUE (subscriber_id, email_key)
);

CREATE INDEX IF NOT EXISTS idx_launch_email_sends_email_key
  ON launch_email_sends(email_key);

CREATE INDEX IF NOT EXISTS idx_launch_email_sends_subscriber
  ON launch_email_sends(subscriber_id);

COMMENT ON TABLE launch_email_sends IS
  'Tracks which launch sequence emails have been sent to each subscriber.';