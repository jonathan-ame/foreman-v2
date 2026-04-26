-- =============================================================================
-- FOREMAN PLATFORM — Consolidated Schema DDL
-- FORA-178: Setup Supabase project and schema DDL for platform
-- 
-- This file represents the exact state of the live Neon database as of
-- 2026-04-24. It is the single source of truth for the Foreman platform schema.
-- 
-- Sections:
--   1. Custom ENUM types
--   2. Shared functions
--   3. Core tables (customers, agents, users)
--   4. Session & auth tables
--   5. Composio integration tables
--   6. CRM tables
--   7. Service marketplace tables
--   8. Billing & finance tables
--   9. Analytics & events tables
--  10. Notification tables
--  11. Email tables
--  12. Utility tables
--   13. Row Level Security
--   14. Triggers
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. CUSTOM ENUM TYPES
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TYPE crm_channel_source AS ENUM (
  'outbound_sms', 'outbound_email', 'outbound_call',
  'referral', 'organic_inbound', 'reddit', 'fb_group'
);

CREATE TYPE crm_stage AS ENUM (
  'applied', 'activated', 'paused', 'churned', 'rejected'
);

CREATE TYPE crm_tier AS ENUM (
  'basic', 'standard', 'premium'
);

CREATE TYPE crm_task_type AS ENUM (
  'follow_up', 'call', 'email', 'meeting', 'review', 'custom'
);

CREATE TYPE crm_task_status AS ENUM (
  'pending', 'in_progress', 'completed', 'cancelled'
);

CREATE TYPE campaign_status AS ENUM (
  'draft', 'active', 'paused', 'completed', 'cancelled'
);

CREATE TYPE campaign_outreach_status AS ENUM (
  'pending', 'sent', 'replied', 'accepted', 'declined', 'no_response', 'bounced'
);

CREATE TYPE financial_transaction_category AS ENUM (
  'llm_cost', 'sms_cost', 'hosting', 'saas_tool',
  'payment_processing', 'lead_revenue', 'subscription_revenue',
  'top_up_revenue', 'other'
);

CREATE TYPE financial_transaction_direction AS ENUM (
  'credit', 'debit'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. SHARED FUNCTIONS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_last_modified_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_modified_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. CORE TABLES
-- ─────────────────────────────────────────────────────────────────────────────

-- ── customers ──────────────────────────────────────────────────────────────
CREATE TABLE customers (
  customer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_slug TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,

  stripe_customer_id TEXT UNIQUE,
  current_billing_mode TEXT NOT NULL DEFAULT 'foreman_managed_tier'
    CHECK (current_billing_mode IN (
      'foreman_managed_tier', 'foreman_managed_usage', 'byok'
    )),
  current_tier TEXT
    CHECK (current_tier IS NULL OR current_tier IN ('tier_1', 'tier_2', 'tier_3', 'byok_platform')),
  byok_key_encrypted TEXT,
  byok_fallback_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  byok_using_fallback BOOLEAN NOT NULL DEFAULT FALSE,
  prepaid_balance_cents INTEGER,
  payment_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (payment_status IN ('pending', 'active', 'past_due', 'canceled', 'trialing')),
  agent_approval_mode TEXT NOT NULL DEFAULT 'auto'
    CHECK (agent_approval_mode IN ('auto', 'manual')),
  paperclip_company_id TEXT,
  stripe_subscription_id TEXT,
  stripe_product_id TEXT,
  tokens_consumed_current_period_cents BIGINT,
  tier_allowance_cents BIGINT,
  auth_user_id UUID,

  onboarding_progress JSONB DEFAULT '{}',

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN customers.onboarding_progress IS 'JSONB tracking which onboarding steps the user has completed. Keys: profile, plan, model, agent, complete. Values are ISO timestamps.';

CREATE INDEX idx_customers_workspace_slug ON customers(workspace_slug);
CREATE INDEX idx_customers_payment_status ON customers(payment_status);
CREATE INDEX idx_customers_stripe ON customers(stripe_customer_id) WHERE stripe_customer_id IS NOT NULL;
CREATE INDEX idx_customers_stripe_subscription_id ON customers(stripe_subscription_id) WHERE stripe_subscription_id IS NOT NULL;
CREATE UNIQUE INDEX idx_customers_auth_user_id ON customers(auth_user_id) WHERE auth_user_id IS NOT NULL;

COMMENT ON TABLE customers IS 'One row per Foreman customer. workspace_slug is the multi-tenancy key.';

-- ── agents ──────────────────────────────────────────────────────────────────
CREATE TABLE agents (
  agent_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
  workspace_slug TEXT NOT NULL,
  paperclip_agent_id UUID NOT NULL UNIQUE,
  openclaw_agent_id TEXT NOT NULL,
  display_name TEXT NOT NULL,
  role TEXT NOT NULL
    CHECK (role IN ('ceo', 'marketing_analyst', 'engineer', 'qa', 'designer')),
  model_tier TEXT NOT NULL CHECK (model_tier IN ('open', 'frontier', 'hybrid')),
  model_primary TEXT NOT NULL,
  model_fallbacks JSONB NOT NULL DEFAULT '[]'::jsonb,
  billing_mode_at_provision TEXT NOT NULL,
  provisioned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_modified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  current_status TEXT NOT NULL DEFAULT 'active'
    CHECK (current_status IN ('active', 'paused', 'suspended', 'terminated')),
  total_tokens_input BIGINT NOT NULL DEFAULT 0,
  total_tokens_output BIGINT NOT NULL DEFAULT 0,
  tokens_input_current_period BIGINT NOT NULL DEFAULT 0,
  tokens_output_current_period BIGINT NOT NULL DEFAULT 0,
  surcharge_accrued_current_period_cents INTEGER,
  billing_period_start DATE NOT NULL DEFAULT CURRENT_DATE,
  billing_period_end DATE NOT NULL DEFAULT (CURRENT_DATE + INTERVAL '1 month'),
  last_billed_at TIMESTAMPTZ,
  last_billing_amount_cents INTEGER,
  last_health_check_at TIMESTAMPTZ,
  last_health_check_result TEXT,
  last_task_completed_at TIMESTAMPTZ,
  UNIQUE (workspace_slug, display_name)
);

CREATE INDEX idx_agents_customer ON agents(customer_id);
CREATE INDEX idx_agents_workspace ON agents(workspace_slug);
CREATE INDEX idx_agents_status ON agents(current_status);
CREATE INDEX idx_agents_paperclip ON agents(paperclip_agent_id);

COMMENT ON TABLE agents IS 'Provisioned agents. paperclip_agent_id and openclaw_agent_id reference external systems.';
COMMENT ON COLUMN agents.openclaw_agent_id IS 'Slug used in openclaw agents add <slug>. Distinct from UUID.';

-- ── users ───────────────────────────────────────────────────────────────────
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  descope_user_id TEXT,
  email TEXT,
  phone TEXT,
  display_name TEXT NOT NULL DEFAULT 'User',
  name TEXT,
  role TEXT NOT NULL DEFAULT 'user',
  status TEXT NOT NULL DEFAULT 'active',
  auth_provider TEXT NOT NULL DEFAULT 'descope',
  zip_code TEXT,
  avatar_url TEXT,
  theme_preference TEXT DEFAULT 'auto',
  nylas_grant_id TEXT,
  google_calendar_connected BOOLEAN NOT NULL DEFAULT FALSE,
  magicblocks_contact_id TEXT,
  pending_email TEXT,
  pending_phone TEXT,
  email_confirmed_at TIMESTAMPTZ,
  phone_confirmed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX idx_users_phone ON users(phone) WHERE phone IS NOT NULL;
CREATE UNIQUE INDEX idx_users_descope ON users(descope_user_id) WHERE descope_user_id IS NOT NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. SESSION & AUTH TABLES
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE customer_sessions (
  session_id UUID PRIMARY KEY,
  customer_id UUID NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_customer_sessions_customer_id ON customer_sessions(customer_id);
CREATE INDEX idx_customer_sessions_expires_at ON customer_sessions(expires_at);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. COMPOSIO INTEGRATION TABLES
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE composio_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(customer_id),
  composio_user_id TEXT NOT NULL,
  composio_session_id TEXT NOT NULL,
  mcp_url TEXT NOT NULL,
  mcp_headers JSONB NOT NULL DEFAULT '{}',
  toolkits JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_composio_sessions_customer ON composio_sessions(customer_id);
CREATE INDEX idx_composio_sessions_composio_session_id ON composio_sessions(composio_session_id);

CREATE TABLE composio_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES customers(customer_id),
  composio_account_id TEXT NOT NULL UNIQUE,
  composio_connected_account_id TEXT,
  toolkit_slug TEXT NOT NULL,
  toolkit_name TEXT,
  alias TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  user_id TEXT,
  auth_config_id TEXT,
  analyzed_at TIMESTAMPTZ,
  analysis_issue_id TEXT,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_composio_connections_customer ON composio_connections(customer_id);
CREATE INDEX idx_composio_connections_customer_toolkit ON composio_connections(customer_id, toolkit_slug);
CREATE INDEX idx_composio_connections_status ON composio_connections(status);
CREATE INDEX idx_composio_connections_toolkit ON composio_connections(toolkit_slug);
CREATE INDEX idx_composio_connections_analyzed ON composio_connections(analyzed_at) WHERE analyzed_at IS NULL;
CREATE UNIQUE INDEX idx_composio_connections_connected_account ON composio_connections(composio_connected_account_id);

COMMENT ON TABLE composio_connections IS 'Connected external accounts via Composio. Tracks which toolkits a customer has authenticated with.';

CREATE TABLE composio_triggers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(customer_id),
  composio_trigger_id TEXT NOT NULL,
  trigger_type TEXT NOT NULL,
  toolkit_slug TEXT NOT NULL,
  config JSONB NOT NULL DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_composio_triggers_customer ON composio_triggers(customer_id);
CREATE UNIQUE INDEX idx_composio_triggers_composio_id ON composio_triggers(composio_trigger_id);

COMMENT ON TABLE composio_triggers IS 'Composio trigger subscriptions. Maps external event triggers to Foreman customers for agent-driven automation.';

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

COMMENT ON TABLE composio_webhook_events IS
  'Incoming Composio webhook events awaiting or completed processing.';

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

COMMENT ON TABLE composio_webhook_deliveries IS
  'Individual handler delivery attempts for a webhook event.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. CRM TABLES
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE crm_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id INTEGER,
  user_id INTEGER,
  name TEXT,
  business_name TEXT NOT NULL,
  primary_category TEXT NOT NULL,
  secondary_category TEXT,
  metro TEXT,
  zip_code TEXT NOT NULL,
  star_rating_at_outreach NUMERIC,
  review_count_at_outreach INTEGER,
  tier crm_tier NOT NULL DEFAULT 'basic',
  channel_source crm_channel_source NOT NULL DEFAULT 'organic_inbound',
  crm_stage crm_stage NOT NULL DEFAULT 'applied',
  stage_entered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  objections TEXT,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  utm_content TEXT,
  utm_term TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_crm_contacts_provider_id ON crm_contacts(provider_id);
CREATE INDEX idx_crm_contacts_primary_category ON crm_contacts(primary_category);
CREATE INDEX idx_crm_contacts_metro ON crm_contacts(metro);
CREATE INDEX idx_crm_contacts_tier ON crm_contacts(tier);
CREATE INDEX idx_crm_contacts_channel_source ON crm_contacts(channel_source);
CREATE INDEX idx_crm_contacts_crm_stage ON crm_contacts(crm_stage);
CREATE INDEX idx_crm_contacts_stage_entered_at ON crm_contacts(stage_entered_at);

CREATE TABLE crm_deals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id UUID NOT NULL REFERENCES crm_contacts(id),
  signup_credit_awarded BOOLEAN NOT NULL DEFAULT FALSE,
  signup_credit_cents INTEGER,
  first_top_up_cents INTEGER,
  first_top_up_at TIMESTAMPTZ,
  first_lead_at TIMESTAMPTZ,
  first_lead_outcome TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_crm_deals_contact_id ON crm_deals(contact_id);

CREATE TABLE crm_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id UUID NOT NULL REFERENCES crm_contacts(id),
  parent_task_id UUID REFERENCES crm_tasks(id),
  task_type crm_task_type NOT NULL DEFAULT 'follow_up',
  task_status crm_task_status NOT NULL DEFAULT 'pending',
  title TEXT NOT NULL,
  description TEXT,
  due_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  assigned_to TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_crm_tasks_contact_id ON crm_tasks(contact_id);
CREATE INDEX idx_crm_tasks_task_status ON crm_tasks(task_status);
CREATE INDEX idx_crm_tasks_due_at ON crm_tasks(due_at);
CREATE INDEX idx_crm_tasks_assigned_to ON crm_tasks(assigned_to);

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. SERVICE MARKETPLACE TABLES
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE provider_applicants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  category TEXT NOT NULL,
  metro TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'applied',
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  utm_content TEXT,
  utm_term TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_provider_applicants_status ON provider_applicants(status);
CREATE INDEX idx_provider_applicants_email ON provider_applicants(email);

CREATE TABLE providers (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  metro TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  zip_code TEXT,
  google_place_id TEXT,
  google_rating TEXT,
  google_reviews_count INTEGER,
  google_website TEXT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  account_status TEXT NOT NULL DEFAULT 'active',
  sms_opt_in BOOLEAN NOT NULL DEFAULT FALSE,
  budget_balance_cents INTEGER NOT NULL DEFAULT 0,
  applicant_id UUID REFERENCES provider_applicants(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_providers_user_id ON providers(user_id);
CREATE INDEX idx_providers_category ON providers(category);
CREATE INDEX idx_providers_metro ON providers(metro);
CREATE INDEX idx_providers_active ON providers(active);
CREATE INDEX idx_providers_applicant_id ON providers(applicant_id) WHERE applicant_id IS NOT NULL;

CREATE TABLE service_requests (
  id SERIAL PRIMARY KEY,
  consumer_id INTEGER REFERENCES users(id),
  consumer_email TEXT,
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  metro TEXT NOT NULL,
  zip_code TEXT,
  status TEXT NOT NULL DEFAULT 'submitted',
  qualified_data TEXT,
  urgency TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_service_requests_status ON service_requests(status);
CREATE INDEX idx_service_requests_consumer ON service_requests(consumer_id);

CREATE TABLE outreach_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id INTEGER NOT NULL REFERENCES service_requests(id) ON DELETE CASCADE,
  provider_id INTEGER NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  channel TEXT NOT NULL DEFAULT 'sms',
  status TEXT NOT NULL DEFAULT 'sent',
  sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded_at TIMESTAMPTZ,
  UNIQUE (request_id, provider_id)
);

CREATE INDEX idx_outreach_logs_status ON outreach_logs(status);

CREATE TABLE request_costs (
  request_id INTEGER PRIMARY KEY REFERENCES service_requests(id) ON DELETE CASCADE,
  llm_call_count INTEGER NOT NULL DEFAULT 0,
  llm_cost_cents INTEGER NOT NULL DEFAULT 0,
  outreach_count INTEGER NOT NULL DEFAULT 0,
  outreach_cost_cents INTEGER NOT NULL DEFAULT 0,
  total_cost_cents INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_request_costs_updated_at ON request_costs(updated_at);

CREATE TABLE llm_call_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id INTEGER REFERENCES service_requests(id),
  agent_name TEXT NOT NULL,
  model TEXT NOT NULL,
  input_tokens INTEGER NOT NULL,
  output_tokens INTEGER NOT NULL,
  cost_cents INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_llm_call_log_request_id ON llm_call_log(request_id);
CREATE INDEX idx_llm_call_log_agent_name ON llm_call_log(agent_name);
CREATE INDEX idx_llm_call_log_created_at ON llm_call_log(created_at);

CREATE TABLE lead_pricing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT NOT NULL,
  region TEXT NOT NULL DEFAULT 'utah_county',
  price_cents INTEGER NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (category, region)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 8. BILLING & FINANCE TABLES
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE byok_fallback_events (
  workspace_slug TEXT PRIMARY KEY,
  first_fallback_at TIMESTAMPTZ NOT NULL,
  last_fallback_at TIMESTAMPTZ NOT NULL,
  last_email_notified_at TIMESTAMPTZ,
  fallback_count INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE stripe_webhook_events (
  stripe_event_id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL,
  livemode BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE financial_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category financial_transaction_category NOT NULL,
  direction financial_transaction_direction NOT NULL,
  amount_cents INTEGER NOT NULL,
  description TEXT NOT NULL,
  recorded_by TEXT NOT NULL DEFAULT 'manual',
  transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_financial_transactions_category ON financial_transactions(category);
CREATE INDEX idx_financial_transactions_direction ON financial_transactions(direction);
CREATE INDEX idx_financial_transactions_transaction_date ON financial_transactions(transaction_date);
CREATE INDEX idx_financial_transactions_created_at ON financial_transactions(created_at);

CREATE TABLE hubspot_sync_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crm_contact_id UUID,
  hubspot_contact_id TEXT,
  hubspot_deal_id TEXT,
  direction TEXT NOT NULL,
  action TEXT NOT NULL,
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_hubspot_sync_log_crm_contact_id ON hubspot_sync_log(crm_contact_id);
CREATE INDEX idx_hubspot_sync_log_hubspot_contact_id ON hubspot_sync_log(hubspot_contact_id);
CREATE INDEX idx_hubspot_sync_log_direction ON hubspot_sync_log(direction);
CREATE INDEX idx_hubspot_sync_log_created_at ON hubspot_sync_log(created_at);

-- ─────────────────────────────────────────────────────────────────────────────
-- 9. ANALYTICS & EVENTS TABLES
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE agent_usage_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paperclip_agent_id UUID NOT NULL,
  input_tokens INTEGER NOT NULL DEFAULT 0,
  output_tokens INTEGER NOT NULL DEFAULT 0,
  cost_cents INTEGER NOT NULL DEFAULT 0,
  model TEXT,
  provider TEXT,
  issue_id TEXT,
  occurred_at TIMESTAMPTZ NOT NULL,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_agent_usage_events_agent_occurred ON agent_usage_events(paperclip_agent_id, occurred_at DESC);
CREATE INDEX idx_agent_usage_events_occurred ON agent_usage_events(occurred_at DESC);

CREATE TABLE funnel_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_slug TEXT NOT NULL,
  event_type TEXT NOT NULL
    CHECK (event_type IN ('signup', 'first_agent_running', 'first_task_in_progress')),
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_funnel_events_workspace_type ON funnel_events(workspace_slug, event_type);
CREATE INDEX idx_funnel_events_occurred ON funnel_events(occurred_at DESC);

CREATE TABLE page_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  path TEXT NOT NULL,
  referrer TEXT,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  user_agent TEXT,
  ip_hash TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_page_views_created_at ON page_views(created_at DESC);
CREATE INDEX idx_page_views_path ON page_views(path);

CREATE TABLE nps_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_slug TEXT NOT NULL,
  trigger_type TEXT NOT NULL
    CHECK (trigger_type IN ('post_onboarding', 'quarterly')),
  score INTEGER CHECK (score >= 0 AND score <= 10),
  comment TEXT,
  survey_sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded_at TIMESTAMPTZ,
  email_sent_at TIMESTAMPTZ
);

CREATE INDEX idx_nps_responses_workspace_slug ON nps_responses(workspace_slug);

CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_chat_messages_customer_id_created_at ON chat_messages(customer_id, created_at ASC);

-- ─────────────────────────────────────────────────────────────────────────────
-- 10. NOTIFICATION TABLES
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_slug TEXT NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  read BOOLEAN NOT NULL DEFAULT FALSE,
  reference_id TEXT,
  reference_type TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_customer_created_at ON notifications(workspace_slug, created_at DESC);
CREATE INDEX idx_notifications_kind_created_at ON notifications(type, created_at DESC);

CREATE TABLE task_escalation_state (
  issue_id TEXT PRIMARY KEY,
  workspace_slug TEXT NOT NULL,
  agent_id UUID NOT NULL REFERENCES agents(agent_id),
  rejection_count INTEGER NOT NULL DEFAULT 0,
  escalated_to_frontier BOOLEAN NOT NULL DEFAULT FALSE,
  escalated_at TIMESTAMPTZ,
  frontier_model TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_task_escalation_workspace ON task_escalation_state(workspace_slug);
CREATE INDEX idx_task_escalation_agent ON task_escalation_state(agent_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 11. EMAIL TABLES
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE email_subscribers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  name TEXT,
  company TEXT,
  use_case TEXT
    CHECK (use_case IS NULL OR use_case IN ('solopreneur', 'small_team', 'enterprise', 'technical', 'other')),
  company_size TEXT,
  message TEXT,
  source TEXT NOT NULL DEFAULT 'homepage'
    CHECK (source IN ('homepage', 'blog', 'contact', 'other')),
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  subscribed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  unsubscribed_at TIMESTAMPTZ,
  preferences JSONB DEFAULT '{"community": true, "product_news": true, "launch_updates": true, "tips_resources": true}'::jsonb,
  unsubscribe_token TEXT
);

CREATE INDEX idx_email_subscribers_source ON email_subscribers(source, subscribed_at DESC);
CREATE INDEX idx_email_subscribers_active ON email_subscribers(subscribed_at DESC) WHERE unsubscribed_at IS NULL;
CREATE UNIQUE INDEX idx_email_subscribers_unsubscribe_token ON email_subscribers(unsubscribe_token) WHERE unsubscribe_token IS NOT NULL;

CREATE TABLE email_preferences (
  email TEXT PRIMARY KEY,
  preferences JSONB NOT NULL DEFAULT '{}',
  unsubscribed_all BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE launch_email_sends (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscriber_id UUID NOT NULL REFERENCES email_subscribers(id),
  email_key TEXT NOT NULL,
  segment TEXT NOT NULL,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL DEFAULT 'sent',
  error_message TEXT,
  UNIQUE (subscriber_id, email_key)
);

CREATE INDEX idx_launch_email_sends_subscriber ON launch_email_sends(subscriber_id);
CREATE INDEX idx_launch_email_sends_email_key ON launch_email_sends(email_key);

-- ─────────────────────────────────────────────────────────────────────────────
-- 12. UTILITY TABLES
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE provisioning_log (
  provisioning_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_slug TEXT NOT NULL,
  customer_id UUID NOT NULL,
  agent_name TEXT NOT NULL,
  role TEXT NOT NULL,
  model_tier TEXT NOT NULL,
  billing_mode_at_time TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  duration_ms INTEGER,
  outcome TEXT NOT NULL
    CHECK (outcome IN ('success', 'failed', 'partial', 'partial_with_warning', 'blocked')),
  failed_step TEXT,
  error_code TEXT,
  error_message TEXT,
  rollback_performed BOOLEAN NOT NULL DEFAULT FALSE,
  steps_completed JSONB NOT NULL DEFAULT '[]'::jsonb,
  raw_payload_excerpts JSONB,
  idempotency_key UUID NOT NULL,
  agent_id UUID
);

CREATE INDEX idx_provisioning_log_customer ON provisioning_log(customer_id, started_at DESC);
CREATE INDEX idx_provisioning_log_workspace ON provisioning_log(workspace_slug, started_at DESC);
CREATE INDEX idx_provisioning_log_outcome ON provisioning_log(outcome, started_at DESC);
CREATE INDEX idx_provisioning_log_idempotency ON provisioning_log(idempotency_key);

CREATE TABLE provisioning_idempotency (
  idempotency_key UUID NOT NULL,
  customer_id UUID NOT NULL,
  result JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours'),
  PRIMARY KEY (idempotency_key, customer_id)
);

CREATE INDEX idx_idempotency_expires ON provisioning_idempotency(expires_at);

CREATE TABLE campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category TEXT,
  metro TEXT,
  status campaign_status NOT NULL DEFAULT 'draft',
  target_count INTEGER NOT NULL DEFAULT 0,
  provider_count INTEGER NOT NULL DEFAULT 0,
  notion_database_id TEXT,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_category ON campaigns(category);

CREATE TABLE campaign_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES campaigns(id),
  provider_id UUID NOT NULL REFERENCES provider_applicants(id),
  outreach_status campaign_outreach_status NOT NULL DEFAULT 'pending',
  notion_page_id TEXT,
  contacted_at TIMESTAMPTZ,
  responded_at TIMESTAMPTZ,
  response_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (campaign_id, provider_id)
);

CREATE INDEX idx_campaign_providers_campaign ON campaign_providers(campaign_id);
CREATE INDEX idx_campaign_providers_provider ON campaign_providers(provider_id);
CREATE INDEX idx_campaign_providers_status ON campaign_providers(outreach_status);

CREATE TABLE _migrations (
  filename TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 13. ROW LEVEL SECURITY
-- ─────────────────────────────────────────────────────────────────────────────
-- All public tables have RLS enabled. Backend connects as neondb_owner which
-- owns the tables and bypasses RLS. These policies grant:
--   - cloud_admin: full CRUD on all tables (service-level role)
--   - cfo_readonly: SELECT on financial/billing tables only
-- Non-owner roles without matching policies are blocked by default.

DO $$
DECLARE
  t text;
BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'customers', 'agents', 'customer_sessions', 'chat_messages',
    'composio_sessions', 'composio_connections', 'composio_triggers', 'composio_webhook_events', 'composio_webhook_deliveries',
    'page_views', 'email_subscribers', 'byok_fallback_events',
    'provisioning_log', 'provisioning_idempotency', 'agent_usage_events',
    'funnel_events', 'nps_responses', 'notifications', 'task_escalation_state',
    'stripe_webhook_events', 'launch_email_sends', 'financial_transactions',
    'outreach_logs', 'request_costs', 'llm_call_log', 'hubspot_sync_log',
    'lead_pricing', 'service_requests', 'provider_applicants', 'providers',
    'campaign_providers', 'campaigns', 'crm_contacts', 'crm_deals',
    'crm_tasks', 'email_preferences', 'users'
  ]) LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format(
      'CREATE POLICY cloud_admin_all ON public.%I FOR ALL TO cloud_admin USING (true) WITH CHECK (true)',
      t
    );
    IF t IN ('financial_transactions', 'stripe_webhook_events', 'lead_pricing', 'request_costs', 'agent_usage_events') THEN
      EXECUTE format(
        'CREATE POLICY cfo_readonly_select ON public.%I FOR SELECT TO cfo_readonly USING (true)',
        t
      );
    END IF;
  END LOOP;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 14. TRIGGERS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TRIGGER customers_updated_at
  BEFORE UPDATE ON customers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER agents_updated_at
  BEFORE UPDATE ON agents
  FOR EACH ROW
  EXECUTE FUNCTION update_last_modified_at_column();

CREATE OR REPLACE FUNCTION update_composio_connections_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_composio_connections_updated_at ON composio_connections;
CREATE TRIGGER set_composio_connections_updated_at
  BEFORE UPDATE ON composio_connections
  FOR EACH ROW EXECUTE FUNCTION update_composio_connections_updated_at();

CREATE OR REPLACE FUNCTION update_composio_triggers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_composio_triggers_updated_at ON composio_triggers;
CREATE TRIGGER set_composio_triggers_updated_at
  BEFORE UPDATE ON composio_triggers
  FOR EACH ROW EXECUTE FUNCTION update_composio_triggers_updated_at();

CREATE OR REPLACE FUNCTION update_task_escalation_state_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_task_escalation_state_updated_at ON task_escalation_state;
CREATE TRIGGER set_task_escalation_state_updated_at
  BEFORE UPDATE ON task_escalation_state
  FOR EACH ROW EXECUTE FUNCTION update_task_escalation_state_updated_at();