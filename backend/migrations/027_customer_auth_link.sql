-- Link customers to Supabase Auth users.
-- Neon Auth (Better Auth compatible) provisioned; this adds the FK column
-- so that after signup we can map auth.users → customers.

ALTER TABLE customers
  ADD COLUMN IF NOT EXISTS auth_user_id UUID;

CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_auth_user_id
  ON customers(auth_user_id) WHERE auth_user_id IS NOT NULL;

COMMENT ON COLUMN customers.auth_user_id IS
  'References the Neon Auth / Better Auth user. NULL for legacy rows created via dev-login.';