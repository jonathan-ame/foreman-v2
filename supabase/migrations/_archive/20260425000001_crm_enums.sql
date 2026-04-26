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