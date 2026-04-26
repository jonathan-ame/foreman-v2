-- Data Quality Dashboard Views
-- These materialized views provide daily data quality monitoring

-- Main data quality summary view
CREATE MATERIALIZED VIEW IF NOT EXISTS data_quality_daily AS
SELECT 
  'customers' as table_name,
  COUNT(*) as row_count,
  COUNT(CASE WHEN workspace_slug IS NULL THEN 1 END) as missing_workspace_slug,
  COUNT(CASE WHEN email IS NULL THEN 1 END) as missing_email,
  COUNT(CASE WHEN display_name IS NULL THEN 1 END) as missing_display_name,
  COUNT(CASE WHEN auth_user_id IS NULL THEN 1 END) as missing_auth_user_id,
  MAX(updated_at) as last_update,
  NOW() as check_timestamp
FROM customers
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
UNION ALL
SELECT 
  'agents',
  COUNT(*),
  COUNT(CASE WHEN customer_id IS NULL THEN 1 END),
  COUNT(CASE WHEN paperclip_agent_id IS NULL THEN 1 END),
  NULL::BIGINT,
  MAX(last_modified_at),
  NOW()
FROM agents
WHERE provisioned_at >= CURRENT_DATE - INTERVAL '30 days'
UNION ALL
SELECT 
  'agent_usage_events',
  COUNT(*),
  COUNT(CASE WHEN paperclip_agent_id IS NULL THEN 1 END),
  COUNT(CASE WHEN input_tokens IS NULL OR output_tokens IS NULL OR cost_cents IS NULL THEN 1 END),
  COUNT(CASE WHEN occurred_at IS NULL OR recorded_at IS NULL THEN 1 END),
  MAX(recorded_at),
  NOW()
FROM agent_usage_events
WHERE recorded_at >= CURRENT_DATE - INTERVAL '30 days'
UNION ALL
SELECT 
  'funnel_events',
  COUNT(*),
  COUNT(CASE WHEN workspace_slug IS NULL THEN 1 END),
  COUNT(CASE WHEN event_type IS NULL THEN 1 END),
  COUNT(CASE WHEN occurred_at IS NULL THEN 1 END),
  MAX(occurred_at),
  NOW()
FROM funnel_events
WHERE occurred_at >= CURRENT_DATE - INTERVAL '30 days'
UNION ALL
SELECT 
  'nps_responses',
  COUNT(*),
  COUNT(CASE WHEN workspace_slug IS NULL THEN 1 END),
  COUNT(CASE WHEN survey_type IS NULL THEN 1 END),
  COUNT(CASE WHEN survey_sent_at IS NULL THEN 1 END),
  MAX(COALESCE(responded_at, survey_sent_at)),
  NOW()
FROM nps_responses
WHERE survey_sent_at >= CURRENT_DATE - INTERVAL '30 days';

-- Data freshness monitoring view
CREATE MATERIALIZED VIEW IF NOT EXISTS data_freshness_monitoring AS
SELECT 
  'customers' as table_name,
  COUNT(*) as total_rows,
  MAX(created_at) as latest_record,
  AGE(NOW(), MAX(created_at)) as freshness_age,
  CASE 
    WHEN AGE(NOW(), MAX(created_at)) 