-- Data Quality Validation Script for Foreman Analytics
-- This script checks data integrity, consistency, and quality across core tables
-- Run this script regularly to monitor data health

-- =============================================================================
-- 1. DATA COMPLETENESS CHECKS (Missing Values)
-- =============================================================================

-- Customers table checks
SELECT 
    'customers_missing_required_fields' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(customer_id) as example_ids
FROM customers 
WHERE workspace_slug IS NULL 
    OR email IS NULL 
    OR display_name IS NULL;

SELECT 
    'customers_without_auth_user' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(customer_id) as example_ids
FROM customers 
WHERE auth_user_id IS NULL;

-- Agent usage events data quality checks
SELECT 
    'agent_usage_events_missing_timestamps' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(id) as example_ids
FROM agent_usage_events 
WHERE occurred_at IS NULL 
    OR recorded_at IS NULL;

SELECT 
    'agent_usage_events_future_dates' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(id) as example_ids
FROM agent_usage_events 
WHERE occurred_at > NOW() 
    OR recorded_at > NOW();

-- =============================================================================
-- 2. DATA CONSISTENCY CHECKS (Referential Integrity, Business Rules)
-- =============================================================================

-- Referential integrity: agents referencing customers
SELECT 
    'agents_with_invalid_customer_reference' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(a.agent_id) as example_ids
FROM agents a
LEFT JOIN customers c ON a.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Agent usage events referencing agents
SELECT 
    'agent_usage_events_with_invalid_agent_reference' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(ue.id) as example_ids
FROM agent_usage_events ue
LEFT JOIN agents a ON ue.paperclip_agent_id = a.paperclip_agent_id
WHERE a.paperclip_agent_id IS NULL;

-- Funnel events referencing customers
SELECT 
    'funnel_events_with_invalid_workspace' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(fe.id) as example_ids
FROM funnel_events fe
LEFT JOIN customers c ON fe.workspace_slug = c.workspace_slug
WHERE c.workspace_slug IS NULL;

-- NPS responses referencing customers
SELECT 
    'nps_responses_with_invalid_workspace' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(nr.id) as example_ids
FROM nps_responses nr
LEFT JOIN customers c ON nr.workspace_slug = c.workspace_slug
WHERE c.workspace_slug IS NULL;

-- =============================================================================
-- 3. BUSINESS LOGIC CHECKS
-- =============================================================================

-- Customers: Payment status vs billing mode consistency
SELECT 
    'customers_with_active_payment_but_no_tier' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(customer_id) as example_ids
FROM customers 
WHERE payment_status IN ('active', 'trialing')
    AND current_billing_mode != 'byok'
    AND current_tier IS NULL;

-- Customers: BYOK mode without key
SELECT 
    'byok_customers_without_encrypted_key' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(customer_id) as example_ids
FROM customers 
WHERE current_billing_mode = 'byok'
    AND byok_key_encrypted IS NULL;

-- Agents: Status vs last activity consistency
SELECT 
    'active_agents_with_no_recent_task' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(agent_id) as example_ids
FROM agents 
WHERE current_status = 'active'
    AND last_task_completed_at < NOW() - INTERVAL '7 days';

-- Agents: Negative token counts
SELECT 
    'agents_with_negative_token_counts' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(agent_id) as example_ids
FROM agents 
WHERE total_tokens_input < 0 
    OR total_tokens_output < 0 
    OR tokens_input_current_period < 0 
    OR tokens_output_current_period < 0;

-- Agent usage events: Negative values
SELECT 
    'agent_usage_events_negative_values' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(id) as example_ids
FROM agent_usage_events 
WHERE input_tokens < 0 
    OR output_tokens < 0 
    OR cost_cents < 0;

-- Agent usage events: Missing required fields
SELECT 
    'agent_usage_events_missing_required_fields' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(id) as example_ids
FROM agent_usage_events 
WHERE paperclip_agent_id IS NULL 
    OR input_tokens IS NULL 
    OR output_tokens IS NULL 
    OR cost_cents IS NULL;

-- Funnel events: Duplicate events per workspace (should have at most one per type)
SELECT 
    'funnel_events_duplicate_per_workspace' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(id) as example_ids
FROM (
    SELECT id, workspace_slug, event_type,
           ROW_NUMBER() OVER (PARTITION BY workspace_slug, event_type ORDER BY occurred_at) as rn
    FROM funnel_events
) dupes
WHERE rn > 1;

-- NPS responses: Invalid scores
SELECT 
    'nps_responses_invalid_scores' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(id) as example_ids
FROM nps_responses 
WHERE score IS NOT NULL AND (score < 0 OR score > 10);

-- =============================================================================
-- 4. TEMPORAL CHECKS (Freshness, Timeliness)
-- =============================================================================

-- Agents: Stale health checks
SELECT 
    'agents_with_stale_health_checks' as check_name,
    COUNT(*) as issue_count,
    ARRAY_AGG(agent_id) as example_ids
FROM agents 
WHERE current_status = 'active'
    AND (last_health_check_at IS NULL OR last_health_check_at < NOW() - INTERVAL '1 hour');

-- Agent usage events: Recent data freshness
SELECT 
    'agent_usage_events_no_recent_data' as check_name,
    CASE WHEN MAX(occurred_at) < NOW() - INTERVAL '1 hour' THEN 1 ELSE 0 END as issue_count,
    ARRAY[]::UUID[] as example_ids
FROM agent_usage_events;

-- Funnel events: Recent signup activity check
SELECT 
    'funnel_events_no_recent_signups' as check_name,
    CASE WHEN MAX(occurred_at) < NOW() - INTERVAL '7 days' THEN 1 ELSE 0 END as issue_count,
    ARRAY[]::UUID[] as example_ids
FROM funnel_events 
WHERE event_type = 'signup';

-- =============================================================================
-- 5. SUMMARY REPORT
-- =============================================================================

-- Create a summary view of all checks
WITH all_checks AS (
    -- Customers table checks
    SELECT 'customers_missing_required_fields' as check_name, COUNT(*) as issue_count FROM customers WHERE workspace_slug IS NULL OR email IS NULL OR display_name IS NULL
    UNION ALL
    SELECT 'customers_without_auth_user', COUNT(*) FROM customers WHERE auth_user_id IS NULL
    UNION ALL
    SELECT 'customers_with_active_payment_but_no_tier', COUNT(*) FROM customers WHERE payment_status IN ('active', 'trialing') AND current_billing_mode != 'byok' AND current_tier IS NULL
    UNION ALL
    SELECT 'byok_customers_without_encrypted_key', COUNT(*) FROM customers WHERE current_billing_mode = 'byok' AND byok_key_encrypted IS NULL
    
    UNION ALL
    -- Agents table checks
    SELECT 'agents_with_invalid_customer_reference', COUNT(*) FROM agents a LEFT JOIN customers c ON a.customer_id = c.customer_id WHERE c.customer_id IS NULL
    UNION ALL
    SELECT 'active_agents_with_no_recent_task', COUNT(*) FROM agents WHERE current_status = 'active' AND last_task_completed_at < NOW() - INTERVAL '7 days'
    UNION ALL
    SELECT 'agents_with_negative_token_counts', COUNT(*) FROM agents WHERE total_tokens_input < 0 OR total_tokens_output < 0 OR tokens_input_current_period < 0 OR tokens_output_current_period < 0
    
    UNION ALL
    -- Agent usage events checks
    SELECT 'agent_usage_events_missing_timestamps', COUNT(*) FROM agent_usage_events WHERE occurred_at IS NULL OR recorded_at IS NULL
    UNION ALL
    SELECT 'agent_usage_events_future_dates', COUNT(*) FROM agent_usage_events WHERE occurred_at > NOW() OR recorded_at > NOW()
    UNION ALL
    SELECT 'agent_usage_events_negative_values', COUNT(*) FROM agent_usage_events WHERE input_tokens < 0 OR output_tokens < 0 OR cost_cents < 0
    UNION ALL
    SELECT 'agent_usage_events_missing_required_fields', COUNT(*) FROM agent_usage_events WHERE paperclip_agent_id IS NULL OR input_tokens IS NULL OR output_tokens IS NULL OR cost_cents IS NULL
    UNION ALL
    SELECT 'agent_usage_events_with_invalid_agent_reference', COUNT(*) FROM agent_usage_events ue LEFT JOIN agents a ON ue.paperclip_agent_id = a.paperclip_agent_id WHERE a.paperclip_agent_id IS NULL
    
    UNION ALL
    -- Funnel events checks
    SELECT 'funnel_events_with_invalid_workspace', COUNT(*) FROM funnel_events fe LEFT JOIN customers c ON fe.workspace_slug = c.workspace_slug WHERE c.workspace_slug IS NULL
    UNION ALL
    SELECT 'funnel_events_duplicate_per_workspace', COUNT(*) FROM (SELECT id, ROW_NUMBER() OVER (PARTITION BY workspace_slug, event_type ORDER BY occurred_at) as rn FROM funnel_events) dupes WHERE rn > 1
    
    UNION ALL
    -- NPS responses checks
    SELECT 'nps_responses_with_invalid_workspace', COUNT(*) FROM nps_responses nr LEFT JOIN customers c ON nr.workspace_slug = c.workspace_slug WHERE c.workspace_slug IS NULL
    UNION ALL
    SELECT 'nps_responses_invalid_scores', COUNT(*) FROM nps_responses WHERE score IS NOT NULL AND (score < 0 OR score > 10)
)
SELECT 
    check_name,
    issue_count,
    CASE 
        WHEN issue_count = 0 THEN 'PASS'
        WHEN issue_count <= 10 THEN 'WARNING'
        ELSE 'FAIL'
    END as status
FROM all_checks
WHERE issue_count > 0
ORDER BY issue_count DESC, check_name;

-- =============================================================================
-- 6. DATA FRESHNESS SUMMARY
-- =============================================================================

SELECT 
    'customers' as table_name,
    COUNT(*) as row_count,
    MAX(created_at) as latest_record,
    AGE(NOW(), MAX(created_at)) as freshness
FROM customers
UNION ALL
SELECT 
    'agents',
    COUNT(*),
    MAX(provisioned_at),
    AGE(NOW(), MAX(provisioned_at))
FROM agents
WHERE current_status = 'active'
UNION ALL
SELECT 
    'agent_usage_events',
    COUNT(*),
    MAX(occurred_at),
    AGE(NOW(), MAX(occurred_at))
FROM agent_usage_events
UNION ALL
SELECT 
    'funnel_events',
    COUNT(*),
    MAX(occurred_at),
    AGE(NOW(), MAX(occurred_at))
FROM funnel_events
UNION ALL
SELECT 
    'nps_responses',
    COUNT(*),
    MAX(COALESCE(responded_at, survey_sent_at)),
    AGE(NOW(), MAX(COALESCE(responded_at, survey_sent_at)))
FROM nps_responses
ORDER BY freshness DESC NULLS LAST; 