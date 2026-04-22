-- Email subscribers captured from marketing site forms.
-- One row per unique email; upsert on duplicate.

CREATE TABLE IF NOT EXISTS email_subscribers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  name TEXT,
  company TEXT,
  use_case TEXT
    CHECK (use_case IS NULL OR use_case IN (
      'solopreneur', 'small_team', 'enterprise', 'technical', 'other'
    )),
  company_size TEXT,
  message TEXT,
  source TEXT NOT NULL DEFAULT 'homepage'
    CHECK (source IN ('homepage', 'blog', 'contact', 'other')),
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  subscribed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  unsubscribed_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_email_subscribers_email
  ON email_subscribers(email);

CREATE INDEX IF NOT EXISTS idx_email_subscribers_source
  ON email_subscribers(source, subscribed_at DESC);

CREATE INDEX IF NOT EXISTS idx_email_subscribers_active
  ON email_subscribers(subscribed_at DESC) WHERE unsubscribed_at IS NULL;

COMMENT ON TABLE email_subscribers IS
  'Marketing leads captured from the website. '
  'Rows are upserted on email; unsubscribed_at is set when a lead opts out.';
