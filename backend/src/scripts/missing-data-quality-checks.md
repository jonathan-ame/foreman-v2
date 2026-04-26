# Missing Data Quality Checks - Summary & Recommendations

## Overview
Identified gaps in data quality monitoring across the Foreman analytics system. This document outlines critical missing checks and provides implementation recommendations.

## Critical Missing Checks

### 1. Temporal Consistency Checks
**Issue**: No validation of time-based logic across metrics
**Impact**: Inconsistent reporting periods lead to misleading trends

**Missing Checks:**
- MRR monthly consistency (should match Stripe records)
- Churn rate alignment between different calculation methods
- Date range validation for all time-series metrics

**Recommendation:**
```sql
-- Monthly MRR reconciliation
SELECT 
  DATE_TRUNC('month', created_at) as month,
  SUM(CASE 
    WHEN payment_status = 'active' AND current_billing_mode = 'byok' THEN 4900
    WHEN payment_status = 'active' AND current_tier = 'tier_1' THEN 4900
    WHEN payment_status = 'active' AND current_tier = 'tier_2' THEN 9900
    WHEN payment_status = 'active' AND current_tier = 'tier_3' THEN 19900
    ELSE 0
  END) as calculated_mrr_cents,
  -- Compare with Stripe records if available
FROM customers
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;
```

### 2. Cross-System Reconciliation
**Issue**: No validation between different data sources
**Impact**: Metrics may differ between internal systems and external providers

**Missing Checks:**
- Agent usage events vs billing records
- Stripe subscription status vs internal payment_status
- Funnel events vs actual user activity

**Recommendation:**
```sql
-- Agent usage vs billing reconciliation
SELECT 
  a.workspace_slug,
  SUM(aue.cost_cents) as usage_cost_cents,
  SUM(a.surcharge_accrued_current_period_cents) as billed_cost_cents,
  ABS(SUM(aue.cost_cents) - SUM(a.surcharge_accrued_current_period_cents)) as discrepancy_cents
FROM agent_usage_events aue
JOIN agents a ON aue.paperclip_agent_id = a.paperclip_agent_id
WHERE aue.occurred_at >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY a.workspace_slug
HAVING ABS(SUM(aue.cost_cents) - SUM(a.surcharge_accrued_current_period_cents)) > 1000;
```

### 3. Metric Boundary Validation
**Issue**: No bounds checking for calculated metrics
**Impact**: Impossible values accepted (e.g., churn > 100%, negative MRR)

**Missing Checks:**
- Churn rate 0-100% bounds
- MRR non-negative
- ARPU reasonable range
- Conversion rates 0-100%

**Recommendation:**
```typescript
interface MetricBounds {
  min: number;
  max: number;
  description: string;
}

const METRIC_BOUNDS: Record string, MetricBounds> = {
  churn_rate_30d_pct: { min: 0, max: 100, description: 'Churn rate percentage' },
  mrr_cents: { min: 0, max: 100000000, description: 'MRR in cents' },
  arpu_cents: { min: 0, max: 50000, description: 'ARPU in cents' },
  nps_score: { min: -100, max: 100, description: 'Net Promoter Score' },
};

function validateMetricBounds(metricName: string, value: number): ValidationResult {
  const bounds = METRIC_BOUNDS[metricName];
  if (!bounds) return { valid: true };
  
  if (value 