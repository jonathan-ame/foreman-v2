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

### 2. Cross-System Reconciliation
**Issue**: No validation between different data sources
**Impact**: Metrics may differ between internal systems and external providers

**Missing Checks:**
- Agent usage events vs billing records
- Stripe subscription status vs internal payment_status
- Funnel events vs actual user activity

### 3. Metric Boundary Validation
**Issue**: No bounds checking for calculated metrics
**Impact**: Impossible values accepted (e.g., churn > 100%, negative MRR)

**Missing Checks:**
- Churn rate 0-100% bounds
- MRR non-negative
- ARPU reasonable range
- Conversion rates 0-100%

### 4. Data Freshness Monitoring
**Issue**: No alerts for stale data pipelines
**Impact**: Decisions made on outdated information

**Missing Checks:**
-. Last update timestamps for all critical tables
-. Pipeline execution time monitoring
-. Data ingestion latency alerts

### 5. Referential Integrity Enforcement
**Issue**: Missing foreign key constraints
**Impact**: Orphaned records and data inconsistencies

**Missing Tables:**
-. `funnel_events` ↔ `customers`
-. `nps_responses` ↔ `customers`
-. `agent_usage_events` ↔ `agents`

## Implementation Recommendations

### Priority 1 - Critical Fixes (Week 1)

1. **Add Foreign Key Constraints**
```sql
-- Add missing foreign keys
ALTER TABLE funnel_events
ADD CONSTRAINT fk_funnel_events_customers
FOREIGN KEY (workspace_slug) 
REFERENCES customers(workspace_slug)
ON DELETE CASCADE;

ALTER TABLE nps_responses
ADD CONSTRAINT fk_nps_responses_customers
FOREIGN KEY (workspace_slug) 
REFERENCES customers(workspace_slug)
ON DELETE CASCADE;
```

2. **Fix Metrics API Calculations**
- Exclude trial customers from MRR
- Use `updated_at` for churn calculations
- Add error handling for all metric queries

### Priority 2 - Data Quality Framework (Week 2)

3. **Implement Data Quality Dashboard**
```sql
-- Daily data quality report
CREATE MATERIALIZED VIEW data_quality_daily AS
SELECT 
  'customers' as table_name,
  COUNT(*) as row_count,
  COUNT(CASE WHEN workspace_slug IS NULL THEN 1 END) as missing_workspace_slug,
  COUNT(CASE WHEN email IS NULL THEN 1 END) as missing_email,
  MAX(updated_at) as last_update
FROM customers
UNION ALL
SELECT 
  'agents',
  COUNT(*),
  COUNT(CASE WHEN customer_id IS NULL THEN 1 END),
  COUNT(CASE WHEN paperclip_agent_id IS NULL THEN 1 END),
  MAX(last_modified_at)
FROM agents
-- ... repeat for all critical tables
```

4. **Add Metric Validation Middleware**
```typescript
// Add to metrics API routes
app.get("/api/internal/metrics/economics", async (c) => {
  const metrics = await calculateEconomics(deps.db);
  const validation = validateMetrics(metrics);
  
  if (validation.errors.length > 0) {
    deps.logger.error({ errors: validation.errors }, "Metric validation failed");
  }
  
  if (validation.warnings.length > 0) {
    deps.logger.warn({ warnings: validation.warnings }, "Metric validation warnings");
  }
  
  return c.json({
    ...metrics,
    _validation: {
      warnings: validation.warnings,
      errors: validation.errors,
      timestamp: new Date().toISOString()
    }
  });
});
```

### Priority 3 - Advanced Monitoring (Week 3-4)

5. **Implement Data Drift Detection**
- Monitor metric distributions for significant changes
- Alert on statistical anomalies
- Track metric correlation over time

6. **Create Reconciliation Jobs**
- Compare Stripe vs internal billing records
- Validate agent usage against provisioning logs
- Audit funnel event accuracy

## Next Steps

### Immediate Actions
1. Run the comprehensive data quality checks script created earlier
2. Implement foreign key constraints for data integrity
3. Fix critical calculation bugs in metrics API

### Short-Term (1-2 Weeks)
1. Add metric boundary validation
2. Implement data freshness monitoring
3. Create data quality dashboard

### Medium-Term (1 Month)
1. Set up automated alerts for data quality issues
2. Implement reconciliation jobs
3. Add data drift detection

### Long-Term (Quarterly)
1. Establish data quality SLA framework
2. Implement data lineage tracking
3. Create self-service data quality tooling