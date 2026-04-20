-- Track which notification rows have been emailed to the workspace owner.
ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS email_sent_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_notifications_pending_email
  ON notifications(workspace_slug, created_at)
  WHERE email_sent_at IS NULL;
