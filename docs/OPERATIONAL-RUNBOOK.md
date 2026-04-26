# Foreman Operational Runbook

**Last updated:** 2026-04-22  
**Owner:** CTO

## Service Architecture

Foreman v2 is a multi-service platform with these components:

| Service | Port | Role |
|---------|------|------|
| Foreman Backend | 8080 | API server, billing, provisioning, jobs |
| Paperclip Server | 3125 | Agent orchestration and heartbeat management |
| OpenClaw Gateway | 18789 | Local AI agent runtime |
| Supabase | (hosted) | PostgreSQL database, auth |
| Railway | (hosted) | Production deployment |

## Health Check Endpoints

### Liveness (is the process alive?)

```
GET /api/internal/monitoring/liveness
```

Returns `200` with `{ alive: true, uptime_seconds, timestamp }` if the Node process is running. Use this for container restart decisions.

### Readiness (can the service handle traffic?)

```
GET /api/internal/monitoring/readiness
```

Returns `200` when all critical dependencies (Supabase, Paperclip, OpenClaw) are reachable. Returns `503` when any critical dependency is down. Use this for load balancer routing decisions.

### Integration Health (detailed dependency check)

```
GET /api/internal/health/integration
```

Returns detailed status of each integration:
- `backend_self` — API server itself
- `supabase` — database connectivity + latency
- `paperclip_api` — orchestration server
- `openclaw_gateway` — AI runtime
- `openrouter` — LLM provider availability
- `active_agents` — agent status counts
- `token_sync` — usage reconciliation state

Status values: `ok`, `degraded`, `down`.

### Credential Health

```
GET /api/internal/health/credentials
```

Shows which API keys and secrets are resolved, deferred, or missing.

### Monitoring Dashboard (consolidated view)

```
GET /api/internal/monitoring/dashboard
```

Single endpoint that combines system health, business metrics, agent status, funnel data, and NPS. Intended for dashboard rendering.

## Scheduled Monitoring Jobs

| Job | Schedule | Purpose |
|-----|----------|---------|
| `monitoring_alerts` | Every 2 min | Evaluates alert rules, fires notifications on critical issues |
| `agent_health_check` | Every 5 min | Checks agent gateway connectivity, auto-pauses after 3 failures |
| `byok_key_health_check` | Hourly | Validates customer-provided API keys |
| `daily_ops_report` | Daily 08:00 UTC | Email with system + business metrics summary |
| `weekly_ceo_review` | Monday 09:00 UTC | Detailed weekly business review email |
| `paperclip_usage_reconcile` | Every 4 hours | Syncs token usage between Paperclip and Foreman DB |

## Alert Rules

The `monitoring_alerts` job evaluates these rules every 2 minutes:

| Alert | Severity | Condition |
|-------|----------|-----------|
| `supabase_connectivity` | **Critical** | Database query fails or latency >2s (warning) |
| `paperclip_api` | **Critical** | Paperclip ping fails |
| `openclaw_gateway` | **Critical** | Gateway reports not running |
| `paused_agents` | **Warning** | >50% of agents paused, or >3 agents paused |
| `form_submission_drop` | **Warning** | Zero new subscribers in 7d (when active subscribers exist) |
| `site_traffic_drop` | **Warning** | Zero page views in 7d, or zero in 24h after prior traffic |

### Alert cooldown

Each alert has a 15-minute cooldown between notifications to prevent alert fatigue. Critical alerts also write a notification to the DB.

## Incident Response

### Backend is down (health check fails)

1. Check Railway dashboard for deployment status
2. Verify `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` are set
3. Check logs: `railway logs --deploy`
4. If OOM, increase memory allocation
5. If crash loop, check recent deployment diff and consider rollback

### Supabase is unreachable

1. Check Supabase status page (status.supabase.com)
2. Verify `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` are correct
3. Check network connectivity from Railway
4. If Supabase outage, wait for resolution — no local fix

### Paperclip server is down

1. Check if Paperclip process is running: `curl http://127.0.0.1:3125/health`
2. If local: `launchctl kickstart -k gui/$(id -u)/ai.foreman.paperclip`
3. If hosted: check Railway/deployment status
4. After restart, agents resume on next heartbeat

### OpenClaw gateway is down

1. Check gateway status: `openclaw gateway status`
2. Restart: `openclaw gateway restart`
3. Sync gateway token: `./scripts/sync-gateway-token.sh`
4. Verify: `curl http://127.0.0.1:18789`

### All agents paused

1. Check `/api/internal/health/integration` for OpenClaw/Paperclip status
2. If gateway was restarted, run `sync-gateway-token.sh`
3. Agents auto-recover on next health check when gateway returns
4. Manual recovery: update agent status via DB

### Stripe webhook failures

1. Check Stripe dashboard for webhook delivery status
2. Verify `STRIPE_WEBHOOK_SECRET` matches current endpoint signing key
3. Replay failed events from Stripe dashboard
4. Check logs for `stripe-webhook` errors

## Escalation Procedures

| Severity | Response Time | Escalation Path |
|----------|---------------|-----------------|
| Critical | 15 minutes | CTO → CEO |
| Warning | 4 hours | CTO investigates |
| Info | Next business day | Review in daily report |

### Critical incident flow

1. Alert fires via `monitoring_alerts` job
2. Notification written to DB (visible in dashboard)
3. CTO receives daily ops report with alert summary
4. If unresolved, weekly CEO review highlights the issue
5. Board escalation via Paperclip approval if business impact

## Key Metrics to Monitor

### System Health
- Integration health status (target: `ok`)
- Backend uptime (target: >99.9%)
- Supabase latency (target: <500ms)
- Agent active/paused ratio (target: <5% paused)

### Site Traffic
- Page views 24h / 7d / 30d (via `page_views` table)
- Unique visitors 24h (hashed IP dedup)
- Top pages and traffic sources
- Tracking endpoint: `POST /api/marketing/pageview`

### Form Submissions
- New subscribers 24h / 7d / 30d (via `email_subscribers` table)
- Submissions by source (homepage, blog, contact, other)
- Subscriber notification emails sent on creation

### Business Health
- MRR growth (target: MoM growth)
- Churn rate 30d (target: <5%)
- Funnel conversion: signup → first agent → first task
- NPS score (target: >50)

### Operational
- Job execution success rate (target: >99%)
- Token usage reconciliation drift (target: 0%)
- Email delivery rate (target: >95%)

## Post-Launch Monitoring (First 30 Days)

### Week 1: Intensive Monitoring

**Daily cadence:**
- 08:00 UTC: Daily ops report email (system + traffic + subscribers + revenue + funnel)
- Every 2 min: Monitoring alerts auto-evaluate (all 6 alert rules)
- Every 5 min: Agent health check with auto-pause on 3 failures
- Hourly: BYOK key health validation
- Manual: Check `/api/internal/monitoring/dashboard` for real-time status

**On-call expectations:**
- CTO monitors critical alerts (15-min response)
- CEO receives daily ops + weekly review emails
- CMO monitors social mentions per `MONITORING_TOOLS_SETUP_BRIEF.md`

**Launch day (April 28) enhanced monitoring:**
- Run `scripts/post-launch-health-check.sh` every hour for first 8 hours
- Verify all alert rules are firing correctly
- Confirm daily ops report email delivery
- Monitor `page_views` table for traffic spike

### Week 2-4: Standard Monitoring

- Daily ops report at 08:00 UTC continues
- Weekly CEO review every Monday at 09:00 UTC
- Adjust alert thresholds based on baseline data
- Review page view tracking accuracy vs GA4 (if configured)
- Refine subscriber source attribution

### Metric Targets (Week 1 Post-Launch)

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Site uptime | >99.9% | Any 503 response |
| Page views (7d) | >1,000 | Zero views in 7d |
| New subscribers (7d) | >50 | Zero submissions in 7d |
| Funnel signups (7d) | >50 | N/A |
| Integration health | `ok` | `degraded` or `down` |
| Agent pause ratio | <5% | >50% paused or >3 paused |

## Page View Tracking

### Architecture

Client-side JavaScript calls `POST /api/marketing/pageview` with:
- `path` (required): page URL path
- `referrer`, `utmSource`, `utmMedium`, `utmCampaign` (optional)

The backend:
1. Hashes the client IP (SHA-256, first 16 chars) for privacy-compliant unique visitor counting
2. Stores in `page_views` Supabase table
3. Daily/weekly reports aggregate via `getPageViewStats()`

### Frontend Integration

Add to the marketing site React app:

```javascript
fetch('/api/marketing/pageview', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    path: window.location.pathname,
    referrer: document.referrer,
    utmSource: new URLSearchParams(window.location.search).get('utm_source'),
    utmMedium: new URLSearchParams(window.location.search).get('utm_medium'),
    utmCampaign: new URLSearchParams(window.location.search).get('utm_campaign'),
  }),
}).catch(() => {});
```

### Data Retention

Page views accumulate indefinitely. Consider adding a 90-day partition or cleanup job if table grows large.

## Reporting Schedule

| Report | Frequency | Recipient | Content |
|--------|-----------|-----------|---------|
| Daily Ops | Daily 08:00 UTC | CEO | System status, site traffic, form submissions, MRR, agents, funnel, NPS |
| Weekly Review | Monday 09:00 UTC | CEO | Site traffic, form submissions, revenue, churn, activation, NPS with WoW trends |
| Alert Notifications | Real-time | Dashboard | Critical/warning system + business alerts with 15-min cooldown |

## Local Stack Monitoring

For local development, use the stack health script:

```bash
./scripts/foreman-stack-health.sh
```

This checks:
- OpenClaw config integrity and auto-restores on drift
- OpenClaw gateway availability with auto-restart
- Paperclip server availability with LaunchAgent kickstart
