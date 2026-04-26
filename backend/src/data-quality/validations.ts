// Data quality validation for Foreman analytics
// This module provides comprehensive data quality checks to ensure
// data integrity and reliability for business intelligence

export interface DataQualityCheck {
  name: string;
  description: string;
  query: string;
  severity: 'critical' | 'warning' | 'info';
  fixAction?: string;
}

export interface DataQualityResult {
  check: DataQualityCheck;
  passed: boolean;
  message?: string;
  count?: number;
  sample?: any[];
  timestamp: Date;
}

export interface DimensionValidation {
  dimension: string;
  description: string;
  checks: DataQualityCheck[];
}

/**
 * Core data quality dimensions for Foreman analytics
 */
export const DATA_QUALITY_DIMENSIONS: DimensionValidation[] = [
  {
    dimension: 'Referential Integrity',
    description: 'Ensures foreign key relationships are valid',
    checks: [
      {
        name: 'Agents with invalid customer reference',
        description: 'Agents should reference existing customers',
        query: `
          SELECT COUNT(*) as invalid_count, 
                 ARRAY_AGG(agent_id) as sample_agent_ids
          FROM agents a
          WHERE NOT EXISTS (
            SELECT 1 FROM customers c WHERE c.customer_id = a.customer_id
          )
        `,
        severity: 'critical',
        fixAction: 'Review orphaned agents and link to valid customers or remove'
      },
      {
        name: 'Agent usage events with invalid paperclip_agent_id',
        description: 'Usage events should reference existing paperclip agents',
        query: `
          SELECT COUNT(*) as invalid_count,
                 ARRAY_AGG(DISTINCT paperclip_agent_id) as sample_agent_ids
          FROM agent_usage_events aue
          WHERE NOT EXISTS (
            SELECT 1 FROM agents a WHERE a.paperclip_agent_id = aue.paperclip_agent_id
          )
        `,
        severity: 'warning',
        fixAction: 'Validate agent usage events syncing process'
      },
      {
        name: 'Funnel events with invalid workspace_slug',
        description: 'Funnel events should reference existing workspaces',
        query: `
          SELECT COUNT(*) as invalid_count,
                 ARRAY_AGG(DISTINCT workspace_slug) as sample_workspaces
          FROM funnel_events fe
          WHERE NOT EXISTS (
            SELECT 1 FROM customers c WHERE c.workspace_slug = fe.workspace_slug
          )
        `,
        severity: 'warning',
        fixAction: 'Review funnel event creation logic'
      }
    ]
  },
  {
    dimension: 'Data Completeness',
    description: 'Ensures required fields are populated',
    checks: [
      {
        name: 'Customers missing required email',
        description: 'All customers must have an email address',
        query: `
          SELECT COUNT(*) as incomplete_count,
                 ARRAY_AGG(customer_id) as sample_customers
          FROM customers
          WHERE email IS NULL OR email = ''
        `,
        severity: 'critical',
        fixAction: 'Update customer records with valid email'
      },
      {
        name: 'Customers missing workspace_slug',
        description: 'All customers must have a workspace slug',
        query: `
          SELECT COUNT(*) as incomplete_count,
                 ARRAY_AGG(customer_id) as sample_customers
          FROM customers
          WHERE workspace_slug IS NULL OR workspace_slug = ''
        `,
        severity: 'critical',
        fixAction: 'Generate missing workspace slugs'
      },
      {
        name: 'Agents missing required fields',
        description: 'Agents must have all required fields populated',
        query: `
          SELECT COUNT(*) as incomplete_count,
                 ARRAY_AGG(agent_id) as sample_agents
          FROM agents
          WHERE workspace_slug IS NULL OR workspace_slug = ''
             OR paperclip_agent_id IS NULL
             OR openclaw_agent_id IS NULL
             OR display_name IS NULL OR display_name = ''
             OR model_tier IS NULL OR model_tier = ''
             OR model_primary IS NULL OR model_primary = ''
        `,
        severity: 'critical',
        fixAction: 'Review agent provisioning process'
      },
      {
        name: 'Agent usage events missing required cost_cents',
        description: 'Usage events should have cost tracking',
        query: `
          SELECT COUNT(*) as incomplete_count,
                 ARRAY_AGG(id) as sample_events
          FROM agent_usage_events
          WHERE cost_cents IS NULL
        `,
        severity: 'warning',
        fixAction: 'Investigate usage event cost calculation'
      }
    ]
  },
  {
    dimension: 'Data Consistency',
    description: 'Ensures data follows business rules and constraints',
    checks: [
      {
        name: 'Customers with invalid payment_status',
        description: 'Payment status must be one of predefined values',
        query: `
          SELECT COUNT(*) as inconsistent_count,
                 ARRAY_AGG(customer_id) as sample_customers,
                 payment_status
          FROM customers
          WHERE payment_status NOT IN ('pending', 'active', 'past_due', 'canceled', 'trialing')
          GROUP BY payment_status
        `,
        severity: 'critical',
        fixAction: 'Fix invalid payment_status values'
      },
      {
        name: 'Agents with invalid current_status',
        description: 'Agent status must be one of predefined values',
        query: `
          SELECT COUNT(*) as inconsistent_count,
                 ARRAY_AGG(agent_id) as sample_agents,
                 current_status
          FROM agents
          WHERE current_status NOT IN ('active', 'paused', 'suspended', 'terminated')
          GROUP BY current_status
        `,
        severity: 'critical',
        fixAction: 'Fix invalid agent status values'
      },
      {
        name: 'Agent cost tracking mismatch',
        description: 'Total tokens should be sum of period tokens plus previous total',
        query: `
          SELECT COUNT(*) as mismatch_count,
                 ARRAY_AGG(agent_id) as sample_agents
          FROM agents a
          WHERE (
            -- Check if total_tokens_input is suspiciously lower than current period tokens
            total_tokens_input 