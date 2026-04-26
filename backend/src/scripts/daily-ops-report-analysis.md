# Daily Ops Report Analysis

## Overview
Analysis of the daily operations report job for data quality, accuracy, and completeness.

## Current Implementation Review

### Data Sources
1. **Customers**: MRR, ARPU, churn rate calculation
2. **Funnel Events**: Signups, first agents, first tasks, D7 retention
3. **NPS Stats**: Customer satisfaction metrics
4. **Agent Status**: Active vs paused agent counts
5. **Page Views**: Website traffic analytics
6. **Email Subscribers**: Marketing funnel metrics

## Issues Identified

### 1. Inconsistent Churn Calculation
**Location**: `daily-ops-report.ts:252-258`
**Issue**: Uses `created_at` for canceled date instead of `updated_at`
**Impact**: Churn rate may be inaccurate if customers cancel long after creation
**Fix**: Use `updated_at` for cancellation date or add `cancelled_at` field

### 2. Missing MRR for Trial Customers
**Location**: `daily-ops-report.ts:242-246`
**Issue**: Includes trialing customers in MRR calculation
**Impact**: Overstates MRR (trialing customers have $0 contribution)
**Fix**: Exclude `payment_status = 'trialing'` from MRR calculation

### 3. Error Handling Inconsistency
**Location**: `daily-ops-report.ts:230-232`
**Issue**: `getPageViewStats` and `getSubscriberStats` have `.catch()` handlers but others don't
**Impact**: Single failure stops entire report
**Fix**: Apply consistent error handling pattern

### 4. Missing Data Validation
**Issue**: No validation for negative or implausible values
**Examples**: 
- Negative MRR/ARPU
- Churn rate > 100%
- Page views decreasing when they should be cumulative
- Agent counts mismatch with database totals

### 5. No Data Freshness Checks
**Issue**: Report runs even if underlying data is stale
**Risk**: Making decisions based on outdated information
**Solution**: Add timestamp checks for key data sources

## Recommendations

### 1. Fix Churn Calculation
```typescript
// Current (incorrect)
const canceledLast30d = customers.filter(
  (c) => c.payment_status === "canceled" && c.created_at >= since30d
).length;

// Recommended fix
const canceledLast30d = customers.filter(
  (c) => c.payment_status === "canceled" && c.updated_at >= since30d
).length;
```

### 2. Accurate MRR Calculation
```typescript
// Current (includes trialing)
let mrrCents = 0;
for (const c of active) {
  const tier = c.current_billing_mode === "byok" ? "byok_platform" : (c.current_tier ?? "");
  mrrCents += TIER_MRR_CENTS[tier] ?? 0;
}

// Recommended fix
const payingCustomers = customers.filter(c => c.payment_status === "active");
let mrrCents = 0;
for (const c of payingCustomers) {
  const tier = c.current_billing_mode === "byok" ? "byok_platform" : (c.current_tier ?? "");
  mrrCents += TIER_MRR_CENTS[tier] ?? 0;
}
```

### 3. Consistent Error Handling
```typescript
const [
  customersResult,
  funnelSummary,
  d7Retained,
  npsStats,
  agentCounts,
  pageViewStats,
  subscriberStats
] = await Promise.allSettled([
  deps.db.from("customers").select("current_tier, current_billing_mode, payment_status, created_at, updated_at"),
  getFunnelSummary(deps.db).catch(() => ({ signups_30d: 0, first_agents_30d: 0, first_tasks_30d: 0, d7_retained: 0 })),
  getD7RetainedCount(deps.db).catch(() => 0),
  getNpsStats(deps.db).catch(() => ({ response_count: 0, avg_score: null, nps_score: null, responses_30d: 0 })),
  getAgentStatusCounts(deps.db).catch(() => ({ active_count: 0, paused_count: 0 })),
  getPageViewStats(deps.db).catch(() => ({ total_1d: 0, total_7d: 0, unique_ip_1d: 0, top_paths_1d: [] })),
  getSubscriberStats(deps.db).catch(() => ({ new_1d: 0, new_7d: 0, total_active: 0, by_source_7d: [] }))
]);
```

### 4. Add Data Validation
```typescript
// Validate metrics before reporting
function validateMetrics(metrics: ReportMetrics): ValidationResult {
  const warnings: string[] = [];
  
  if (metrics.mrrCents 