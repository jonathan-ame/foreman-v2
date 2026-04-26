# Funnel Events Data Model Analysis

## Current Implementation Review

### Data Model
- **Table**: `funnel_events`
- **Purpose**: Track workspace activation funnel (signup → first agent → first task)
- **Design**: Append-only, deduplicated at application layer
- **Indexes**: 
  - `idx_funnel_events_workspace_type` (workspace_slug, event_type)
  - `idx_funnel_events_occurred` (occurred_at DESC)

### Strengths
1. Simple, denormalized structure
2. Efficient for counting events by type/time
3. Application-layer deduplication prevents duplicates

### Limitations
1. **No foreign key constraint** to customers table
2. **Application-layer deduplication** can fail under race conditions
3. **Missing workspace-level metadata** (customer_id, etc.)

## D7 Retention Calculation Issues

### Current Logic (Flawed)
```typescript
// Problem: Returns count of eligible workspaces if ANY usage exists
return (usageData ?? []).length > 0 ? workspaceSlugs.length : 0;
```

### Issues Identified
1. **False Positives**: Any usage event gives credit to ALL eligible workspaces
2. **No Workspace Mapping**: Can't determine which workspaces actually had usage
3. **Proxy Metric**: Returns eligible count, not actual retained count

### Root Cause
- `agent_usage_events` table lacks `workspace_slug`
- Need to join through `agents` table: `funnel_events` ↔ `customers` ↔ `agents` ↔ `agent_usage_events`

## Improved Implementation

### Option 1: Database View (Recommended)
```sql
-- Create a view for accurate D7 retention
CREATE OR REPLACE VIEW d7_retention_workspaces AS
SELECT DISTINCT fe.workspace_slug
FROM funnel_events fe
JOIN customers c ON fe.workspace_slug = c.workspace_slug
JOIN agents a ON c.customer_id = a.customer_id
JOIN agent_usage_events aue ON a.paperclip_agent_id = aue.paperclip_agent_id
WHERE fe.event_type = 'first_agent_running'
  AND fe.occurred_at < NOW() - INTERVAL '7 days'
  AND aue.occurred_at >= NOW() - INTERVAL '7 days';
```

### Option 2: Enhanced Query Function
```typescript
export async function getAccurateD7RetainedCount(db: SupabaseClient): Promise<number> {
  const cutoff7d = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
  
  // Use a single, optimized query with proper joins
  const { data, error } = await db
    .from('funnel_events')
    .select(`
      workspace_slug,
      customers!inner(customer_id),
      agents!inner(
        paperclip_agent_id,
        agent_usage_events!inner(
          paperclip_agent_id
        )
      )
    `)
    .eq('event_type', 'first_agent_running')
    .lt('funnel_events.occurred_at', cutoff7d)
    .gte('agent_usage_events.occurred_at', cutoff7d);

  if (error) {
    throw new Error(`Failed to fetch D7 retention: ${error.message}`);
  }

  // Count distinct workspaces
  const workspaceSet = new Set<string>();
  (data ?? []).forEach((row: any) => {
    if (row.workspace_slug) workspaceSet.add(row.workspace_slug);
  });
  
  return workspaceSet.size;
}
```

### Option 3: Database Function
```sql
CREATE OR REPLACE FUNCTION get_d7_retained_count()
RETURNS INTEGER AS $$
  SELECT COUNT(DISTINCT fe.workspace_slug)
  FROM funnel_events fe
  JOIN customers c ON fe.workspace_slug = c.workspace_slug
  JOIN agents a ON c.customer_id = a.customer_id
  JOIN agent_usage_events aue ON a.paperclip_agent_id = aue.paperclip_agent_id
  WHERE fe.event_type = 'first_agent_running'
    AND fe.occurred_at < NOW() - INTERVAL '7 days'
    AND aue.occurred_at >= NOW() - INTERVAL '7 days';
$$ LANGUAGE sql STABLE;
```

## Data Quality Recommendations

### 1. Add Foreign Key Constraint
```sql
ALTER TABLE funnel_events
ADD CONSTRAINT fk_funnel_events_workspace
FOREIGN KEY (workspace_slug) 
REFERENCES customers(workspace_slug)
ON DELETE CASCADE;
```

### 2. Database-Level Deduplication
```sql
-- Add unique constraint to prevent duplicates
ALTER TABLE funnel_events
ADD CONSTRAINT unique_workspace_event_type 
UNIQUE (workspace_slug, event_type);

-- Or use upsert pattern
INSERT INTO funnel_events (workspace_slug, event_type)
VALUES ('workspace-123', 'signup')
ON CONFLICT (workspace_slug, event_type) DO NOTHING;
```

### 3. Add Missing Indexes
```sql
-- For retention queries
CREATE INDEX IF NOT EXISTS idx_funnel_events_type_occurred_workspace
ON funnel_events(event_type, occurred_at DESC, workspace_slug);

-- For customer joins
CREATE INDEX IF NOT EXISTS idx_customers_workspace_slug
ON customers(workspace_slug);
```

### 4. Enhanced Funnel Analysis Queries

#### Weekly Funnel Conversion
```sql
SELECT 
  DATE_TRUNC('week', occurred_at) as week,
  COUNT(DISTINCT workspace_slug) as signups,
  COUNT(DISTINCT CASE WHEN event_type = 'first_agent_running' THEN workspace_slug END) as agent_activations,
  COUNT(DISTINCT CASE WHEN event_type = 'first_task_in_progress' THEN workspace_slug END) as task_activations,
  ROUND(
    COUNT(DISTINCT CASE WHEN event_type = 'first_agent_running' THEN workspace_slug END)::decimal /
    NULLIF(COUNT(DISTINCT workspace_slug), 0) * 100, 2
  ) as signup_to_agent_pct,
  ROUND(
    COUNT(DISTINCT CASE WHEN event_type = 'first_task_in_progress' THEN workspace_slug END)::decimal /
    NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'first_agent_running' THEN workspace_slug END), 0) * 100, 2
  ) as agent_to_task_pct
FROM funnel_events
WHERE occurred_at >= NOW() - INTERVAL '90 days'
GROUP BY DATE_TRUNC('week', occurred_at)
ORDER BY week DESC;
```

#### Time-to-Event Analysis
```sql
SELECT 
  fe1.workspace_slug,
  fe1.occurred_at as signup_time,
  fe2.occurred_at as first_agent_time,
  EXTRACT(EPOCH FROM (fe2.occurred_at - fe1.occurred_at)) / 3600 as hours_to_agent,
  fe3.occurred_at as first_task_time,
  EXTRACT(EPOCH FROM (fe3.occurred_at - fe2.occurred_at)) / 3600 as hours_to_task
FROM funnel_events fe1
LEFT JOIN funnel_events fe2 ON fe1.workspace_slug = fe2.workspace_slug 
  AND fe2.event_type = 'first_agent_running'
LEFT JOIN funnel_events fe3 ON fe1.workspace_slug = fe3.workspace_slug 
  AND fe3.event_type = 'first_task_in_progress'
WHERE fe1.event_type = 'signup'
ORDER BY fe1.occurred_at DESC;
```

## Implementation Priority

### Immediate (Fix Critical Bug)
1. Replace current D7 retention with accurate calculation
2. Add proper error handling for join failures

### Short-term (1-2 Weeks)
1. Add foreign key constraint
2. Implement database-level deduplication
3. Create materialized view for funnel metrics

### Medium-term (1 Month)
1. Add comprehensive funnel analysis queries
2. Implement time-series tracking
3. Add data quality alerts for missing funnel events

### Long-term (Quarterly)
1. Consider event tracking redesign (event sourcing)
2. Implement real-time funnel analytics
3. Add predictive analytics for conversion rates