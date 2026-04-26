CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  descope_user_id text,
  email text,
  phone text,
  display_name text NOT NULL DEFAULT 'User',
  name text,
  role text NOT NULL DEFAULT 'user',
  status text NOT NULL DEFAULT 'active',
  auth_provider text NOT NULL DEFAULT 'descope',
  zip_code text,
  avatar_url text,
  theme_preference text DEFAULT 'auto',
  nylas_grant_id text,
  google_calendar_connected boolean NOT NULL DEFAULT false,
  magicblocks_contact_id text,
  pending_email text,
  pending_phone text,
  email_confirmed_at timestamptz,
  phone_confirmed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users (email) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone ON users (phone) WHERE phone IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_descope ON users (descope_user_id) WHERE descope_user_id IS NOT NULL;