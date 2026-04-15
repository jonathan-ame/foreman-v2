ALTER TABLE customers
ADD COLUMN IF NOT EXISTS paperclip_company_id TEXT;

COMMENT ON COLUMN customers.paperclip_company_id IS 'Paperclip company identifier used for native hire/approval API calls.';
