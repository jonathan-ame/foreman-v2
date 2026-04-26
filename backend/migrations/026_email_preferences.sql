-- Email preferences and unsubscribe token for subscriber preference management.

ALTER TABLE email_subscribers ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{"launch_updates":true,"product_news":true,"tips_resources":true,"community":true}'::jsonb;
ALTER TABLE email_subscribers ADD COLUMN IF NOT EXISTS unsubscribe_token TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_email_subscribers_unsubscribe_token
  ON email_subscribers(unsubscribe_token) WHERE unsubscribe_token IS NOT NULL;

-- Backfill unsubscribe tokens for existing subscribers
UPDATE email_subscribers
SET unsubscribe_token = gen_random_uuid()::text
WHERE unsubscribe_token IS NULL;

COMMENT ON COLUMN email_subscribers.preferences IS
  'JSON object of email category opt-ins: launch_updates, product_news, tips_resources, community';
COMMENT ON COLUMN email_subscribers.unsubscribe_token IS
  'Unique token for authenticated unsubscribe/preferences links';