# Metrics API Verification Report

## Overview
Verification of analytics queries and data quality in the Foreman metrics system.

## Issues Found

### 1. MRR Calculation Issues
- **Location**: `backend/src/routes/metrics.ts:65-70`
- **Issue**: MRR calculation assumes static tier pricing but doesn't account for:
  - Tier changes mid-month
  - Prorated billing for new customers
  - Trial periods (trialing customers have $0 MRR)
- **Impact**: Overstated MRR for trial customers and inaccurate for tier changes

### 2. Churn Rate Calculation Logic
- **Location**: `backend/src/routes/metrics.ts:75-79`
- **Issue**: `activeOrCanceledBefore30d` includes customers who canceled more than 30 days ago but excludes those who were never active
- **Impact**: Denominator may be incorrect for churn rate calculation

### 3. D7 Retention Calculation Limitation
- **Location**: `backend/src/db/funnel-events.ts:126-129`
- **Issue**: D7 retention uses a proxy instead of proper join due to missing workspace_slug in agent_usage_events
- **Impact**: Retention metric may be inaccurate

### 4. Missing Error Handling for Dependent Metrics
- **Issue**: If `getFunnelSummary`, `getD7RetainedCount`, or `getNpsStats` fail, the entire endpoint fails
- **Impact**: Partial failures cause complete endpoint failure

## Performance Analysis

### Current Query Pattern
1. Fetches all customers and agents (potentially large datasets)
2. Processes in memory with JavaScript
3. Multiple parallel queries but no pagination

### Scalability Concerns
- Customer and agent tables will grow over time
- In-memory processing limits scalability
- No query optimization for large datasets

## Recommended Improvements

### 1. Database-Level Calculations
```sql
-- Example: Calculate MRR with prorated logic
SELECT 
  SUM(CASE 
    WHEN payment_status = 'trialing' THEN 0
    WHEN current_billing_mode = 'byok' THEN 4900
    WHEN current_tier = 'tier_1' THEN 4900
    WHEN current_tier = 'tier_2' THEN 9900
    WHEN current_tier = 'tier_3' THEN 19900
    ELSE 0
  END) as mrr_cents
FROM customers 
WHERE payment_status IN ('active', 'trialing');
```

### 2. Improved Churn Calculation
```sql
-- Calculate true 30-day churn rate
WITH cohort AS (
  -- Customers active 30+ days ago
  SELECT customer_id 
  FROM customers 
  WHERE payment_status IN ('active', 'trialing')
    AND created_at < NOW() - INTERVAL '30 days'
),
churned AS (
  -- Customers who canceled in last 30 days
  SELECT customer_id 
  FROM customers 
  WHERE payment_status = 'canceled'
    AND updated_at >= NOW() - INTERVAL '30 days'
)
SELECT 
  COUNT(DISTINCT churned.customer_id)::float / 
  NULLIF(COUNT(DISTINCT cohort.customer_id), 0) as churn_rate_30d
FROM cohort
LEFT JOIN churned ON cohort.customer_id = churned.customer_id;
```

### 3. Enhanced D7 Retention with Proper Join
```sql
-- Requires adding workspace_slug to agent_usage_events or joining through agents table
SELECT COUNT(DISTINCT fe.workspace_slug) as d7_retained
FROM funnel_events fe
JOIN agents a ON fe.workspace_slug = a.workspace_slug
JOIN agent_usage_events aue ON a.paperclip_agent_id = aue.paperclip_agent_id
WHERE fe.event_type = 'first_agent_running'
  AND fe.occurred_at < NOW() - INTERVAL '7 days'
  AND aue.occurred_at >= NOW() - INTERVAL '7 days';
```

### 4. Add Indexing Strategy
```sql
-- Recommended indexes for metrics queries
CREATE INDEX IF NOT EXISTS idx_customers_payment_created 
  ON customers(payment_status, created_at);

CREATE INDEX IF NOT EXISTS idx_funnel_events_type_occurred 
  ON funnel_events(event_type, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_agent_usage_events_occurred_agent 
  ON agent_usage_events(occurred_at DESC, paperclip_agent_id);
```

### 5. Error Resilience Pattern
```typescript
// Implement fallback for individual metric failures
const metrics = await Promise.allSettled([
  getMRR(deps.db),
  getCustomerCounts(deps.db),
  getFunnelSummary(deps.db).catch(() => null),
  getD7RetainedCount(deps.db).catch(() => null),
  getNpsStats(deps.db).catch(() => null)
]);

// Process with null safety
const funnelSummary = metrics[2].status === 'fulfilled' ? metrics[2].value : null;
```

## Data Quality Recommendations

### 1. Add Data Freshness Monitoring
```sql
-- Monitor data pipeline freshness
SELECT 
  table_name,
  MAX(last_updated) as latest_data,
  NOW() - MAX(last_updated) as freshness
FROM data_freshness_monitoring
GROUP BY table_name
HAVING NOW() - MAX(last_updated) > INTERVAL '1 hour';
```

### 2. Implement Metric Reconciliation
```sql
-- Reconcile agent usage with billing records
SELECT 
  a.workspace_slug,
  SUM(aue.cost_cents) as calculated_cost,
  SUM(a.surcharge_accrued_current_period_cents) as recorded_cost,
  ABS(SUM(aue.cost_cents) - SUM(a.surcharge_accrued_current_period_cents)) as discrepancy
FROM agent_usage_events aue
JOIN agents a ON aue.paperclip_agent_id = a.paperclip_agent_id
GROUP BY a.workspace_slug
HAVING ABS(SUM(aue.cost_cents) - SUM(a.surcharge_accrued_current_period_cents)) > 100;
```

## Next Steps

### Immediate Actions (High Priority)
1. Fix MRR calculation to exclude trial customers
2. Implement proper churn rate denominator
3. Add error handling for partial metric failures

### Medium-Term Improvements
1. Move calculations to database views/materialized views
2. Add proper indexing for metrics queries
3. Implement data quality alerts

### Long-Term Architecture
1. Create dedicated metrics tables with ETL
2. Implement metric versioning and audit trails
3. Add automated reconciliation checks