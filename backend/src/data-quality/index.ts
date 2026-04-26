import { Kysely } from 'kysely';

/**
 * Database type definitions for validation
 */
export interface Database {
  customers: {
    customer_id: string;
    workspace_slug: string;
    email: string;
    display_name: string;
    stripe_customer_id: string | null;
    current_billing_mode: string;
    current_tier: string | null;
    byok_key_encrypted: string | null;
    byok_fallback_enabled: boolean;
    prepaid_balance_cents: number | null;
    payment_status: string;
    agent_approval_mode: string;
    tokens_consumed_current_period_cents: number | null;
    tier_allowance_cents: number | null;
    created_at: Date;
    updated_at: Date;
  };
  agents: {
    agent_id: string;
    customer_id: string;
    workspace_slug: string;
    paperclip_agent_id: string;
    openclaw_agent_id: string;
    display_name: string;
    role: string;
    model_tier: string;
    model_primary: string;
    model_fallbacks: any[];
    billing_mode_at_provision: string;
    provisioned_at: Date;
    last_modified_at: Date;
    current_status: string;
    total_tokens_input: number;
    total_tokens_output: number;
    tokens_input_current_period: number;
    tokens_output_current_period: number;
    surcharge_accrued_current_period_cents: number | null;
    billing_period_start: Date;
    billing_period_end: Date;
    last_billed_at: Date | null;
    last_billing_amount_cents: number | null;
    last_health_check_at: Date | null;
    last_health_check_result: string | null;
    last_task_completed_at: Date | null;
  };
  funnel_events: {
    id: string;
    workspace_slug: string;
    event_type: string;
    occurred_at: Date;
  };
  nps_responses: {
    id: string;
    workspace_slug: string;
    trigger_type: string;
    score: number | null;
    comment: string | null;
    survey_sent_at: Date;
    responded_at: Date | null;
    email_sent_at: Date | null;
  };
  agent_usage_events: {
    id: string;
    paperclip_agent_id: string;
    input_tokens: number;
    output_tokens: number;
    cost_cents: number;
    model: string | null;
    provider: string | null;
    issue_id: string | null;
    occurred_at: Date;
    recorded_at: Date;
  };
}

/**
 * Run all data quality checks
 */
export async function runDataQualityChecks(
  db: Kysely