# NPS Analytics Data Quality Verification

## Overview
Analysis of NPS (Net Promoter Score) analytics implementation for data quality and accuracy.

## Current Implementation Review

### Data Model
- **Table**: `nps_responses`
- **Purpose**: Track NPS survey sends and responses
- **Design**: 
  - One row per survey sent
  - Scores: 0-10 (validated by CHECK constraint)
  - Trigger types: `post_onboarding`, `quarterly`

### Indexes
1. `idx_nps_responses_workspace` (workspace_slug, survey_sent_at DESC)
2. `idx_nps_responses_pending` (survey_sent_at) WHERE responded_at IS NULL

## Data Quality Issues Identified

### 1. Missing Foreign Key Constraint
- **Issue**: No foreign key to `customers(workspace_slug)`
- **Impact**: Orphaned NPS records if workspace is deleted
- **Risk**: Data inconsistency, inaccurate workspace counts

### 2. Incomplete Response Tracking
- **Issue**: `email_sent_at` may be NULL even for email-triggered surveys
- **Impact**: Cannot distinguish between email vs in-app surveys
- **Risk**: Broken email delivery tracking

### 3. Survey Deduplication Logic
- **Issue**: No constraint preventing multiple surveys of same type to same workspace
- **Impact**: Potential survey spam, skewed response rates
- **Risk**: Customer irritation, inaccurate response tracking

### 4. Response Window Logic
- **Issue**: No tracking of survey expiration or valid response window
- **Impact**: Old responses counted equally with recent ones
- **Risk**: Stale NPS scores not reflecting current sentiment

### 5. Missing Response Rate Metrics
- **Issue**: Current implementation only tracks scores, not response rates
- **Impact**: Cannot measure survey effectiveness
- **Risk**: Unaware of declining response rates

## NPS Calculation Analysis

### Current Logic (Lines 108-162)
```typescript
// Issues found:
1. Uses all-time data for NPS calculation
2. No time-based weighting (recent vs old responses)
3. No segmentation by trigger_type
4. No filtering by workspace status (active vs churned)
```

### Statistical Validity Concerns
1. **Small Sample Bias**: NPS with <100 responses has high margin of error
2. **Time Decay**: Responses from 6 months ago may not reflect current sentiment
3. **Selection Bias**: Only captures customers who respond to surveys

## Recommended Improvements

### 1. Add Foreign Key Constraint
```sql
ALTER TABLE nps_responses
ADD CONSTRAINT fk_nps_responses_workspace
FOREIGN KEY (workspace_slug) 
REFERENCES customers(workspace_slug)
ON DELETE CASCADE;
```

### 2. Enhanced Data Model
```sql
-- Add survey validation constraints
ALTER TABLE nps_responses
ADD CONSTRAINT check_email_sent_for_email_trigger
CHECK (trigger_type != 'quarterly' OR email_sent_at IS NOT NULL);

-- Add deduplication constraint (optional, depending on business rules)
-- ALTER TABLE nps_responses
-- ADD CONSTRAINT unique_workspace_trigger_recent
-- EXCLUDE USING gist (
--   workspace_slug WITH =,
--   trigger_type WITH =,
--   date_trunc('day', survey_sent_at) WITH =
-- );
```

### 3. Improved NPS Calculation
```typescript
interface EnhancedNpsStats {
  response_count: number;
  avg_score: number | null;
  promoters: number;
  passives: number;
  detractors: number;
  nps_score: number | null;
  responses_30d: number;
  responses_90d: number;
  response_rate_30d: number | null;
  response_rate_90d: number | null;
  by_trigger_type: {
    post_onboarding: NpsStats;
    quarterly: NpsStats;
  };
}

export async function getEnhancedNpsStats(db: SupabaseClient): Promise<EnhancedNpsStats> {
  const since30d = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
  const since90d = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString();

  // Get all responses with workspace status
  const { data, error } = await db
    .from("nps_responses")
    .select(`
      score, 
      responded_at, 
      survey_sent_at,
      trigger_type,
      workspace_slug,
      customers!inner(payment_status)
    `)
    .not("responded_at", "is", null)
    .gte("customers.payment_status", "active"); // Only active customers

  if (error) {
    throw new Error(`Failed to fetch NPS stats: ${error.message}`);
  }

  // Calculate overall stats with time weighting
  const rows = data || [];
  const recentRows = rows.filter(r => r.responded_at >= since90d);
  
  // Weight recent responses more heavily
  const weightedScores = rows.map(r => {
    const weight = r.responded_at >= since30d ? 2.0 : 
                   r.responded_at >= since90d ? 1.5 : 1.0;
    return { score: r.score, weight };
  }).filter(r => r.score !== null);

  // Calculate response rates
  const { data: surveyCounts } = await db
    .from("nps_responses")
    .select("survey_sent_at, trigger_type")
    .gte("survey_sent_at", since90d);

  // Implementation continues...
}
```

### 4. Response Rate Tracking
```sql
-- Calculate response rates by period
SELECT 
  DATE_TRUNC('month', survey_sent_at) as month,
  trigger_type,
  COUNT(*) as surveys_sent,
  COUNT(responded_at) as responses_received,
  ROUND(COUNT(responded_at)::decimal / NULLIF(COUNT(*), 0) * 100, 1) as response_rate_pct,
  AVG(score) as avg_score,
  SUM(CASE WHEN score >= 9 THEN 1 ELSE 0 END) as promoters,
  SUM(CASE WHEN score <= 6 THEN 1 ELSE 0 END) as detractors
FROM nps_responses
WHERE survey_sent_at >= NOW() - INTERVAL '6 months'
GROUP BY DATE_TRUNC('month', survey_sent_at), trigger_type
ORDER BY month DESC, trigger_type;
```

### 5. Segmentation Analysis
```sql
-- NPS by customer tier
SELECT 
  c.current_tier,
  COUNT(*) as response_count,
  AVG(nr.score) as avg_score,
  SUM(CASE WHEN nr.score >= 9 THEN 1 ELSE 0 END) as promoters,
  SUM(CASE WHEN nr.score <= 6 THEN 1 ELSE 0 END) as detractors,
  ROUND(
    (SUM(CASE WHEN nr.score >= 9 THEN 1 ELSE 0 END) - 
     SUM(CASE WHEN nr.score <= 6 THEN 1 ELSE 0 END))::decimal / 
    NULLIF(COUNT(*), 0) * 100
  ) as nps_score
FROM nps_responses nr
JOIN customers c ON nr.workspace_slug = c.workspace_slug
WHERE nr.responded_at IS NOT NULL
  AND nr.score IS NOT NULL
  AND nr.responded_at >= NOW() - INTERVAL '90 days'
GROUP BY c.current_tier
ORDER BY nps_score DESC;

-- NPS by time since signup
SELECT 
  CASE 
    WHEN AGE(nr.responded_at, c.created_at) < INTERVAL '30 days' THEN '0-30 days'
    WHEN AGE(nr.responded_at, c.created_at) < INTERVAL '90 days' THEN '30-90 days'
    WHEN AGE(nr.responded_at, c.created_at) < INTERVAL '180 days' THEN '90-180 days'
    ELSE '180+ days'
  END as time_since_signup,
  COUNT(*) as response_count,
  AVG(nr.score) as avg_score,
  ROUND(
    (SUM(CASE WHEN nr.score >= 9 THEN 1 ELSE 0 END) - 
     SUM(CASE WHEN nr.score <= 6 THEN 1 ELSE 0 END))::decimal / 
    NULLIF(COUNT(*), 0) * 100
  ) as nps_score
FROM nps_responses nr
JOIN customers c ON nr.workspace_slug = c.workspace_slug
WHERE nr.responded_at IS NOT NULL
  AND nr.score IS NOT NULL
GROUP BY time_since_signup
ORDER BY time_since_signup;
```

## Data Quality Monitoring Queries

### 1. Orphaned NPS Records
```sql
SELECT COUNT(*) as orphaned_responses
FROM nps_responses nr
LEFT JOIN customers c ON nr.workspace_slug = c.workspace_slug
WHERE c.workspace_slug IS NULL;
```

### 2. Incomplete Survey Records
```sql
-- Surveys without email tracking
SELECT 
  trigger_type,
  COUNT(*) as count
FROM nps_responses
WHERE trigger_type = 'quarterly' 
  AND email_sent_at IS NULL
GROUP BY trigger_type;

-- Responses without scores (comment-only responses)
SELECT 
  trigger_type,
  COUNT(*) as comment_only_responses
FROM nps_responses
WHERE responded_at IS NOT NULL
  AND score IS NULL
  AND comment IS NOT NULL
GROUP BY trigger_type;
```

### 3. Survey Spam Detection
```sql
-- Multiple surveys to same workspace in short period
SELECT 
  workspace_slug,
  COUNT(*) as survey_count,
  MIN(survey_sent_at) as first_survey,
  MAX(survey_sent_at) as last_survey,
  MAX(survey_sent_at) - MIN(survey_sent_at) as time_span
FROM nps_responses
WHERE survey_sent_at >= NOW() - INTERVAL '30 days'
GROUP BY workspace_slug
HAVING COUNT(*) > 2
ORDER BY survey_count DESC;
```

## Implementation Priority

### Critical (Week 1)
1. Add foreign key constraint
2. Fix email_sent_at tracking logic
3. Implement response rate metrics

### Important (Week 2)
1. Add time-weighted NPS calculation
2. Implement segmentation analysis
3. Add data quality monitoring

### Enhancement (Month 1)
1. Implement predictive NPS trends
2. Add automated alerting for NPS drops
3. Create NPS dashboard with drill-down