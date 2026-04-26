# Daily Monitoring Report Template

## Date: {{date}}
**Report Time:** {{time}}
**Report Owner:** CMO
**Report Source:** Automated script + manual checks + Google Alerts

## Executive Summary
- **Total mentions today:** {{total}}
, **Critical alerts:** {{critical}}
, **Sentiment score:** {{sentiment}}
- **Key findings:** {{key_finding_summary}}

## Mention Breakdown by Platform

### Reddit
- **Total mentions:** {{reddit_total}}
, **Subreddits:** {{subreddit_list}}
- **Top posts:**
{{reddit_top_posts}}

### Hacker News
-n **Total mentions:** {{hn_total}}
, **Relevant posts:** {{hn_relevant_count}}
- **Top posts:**
{{hn_top_posts}}

### LinkedIn (Manual)
, **Company page mentions:** {{linkedin_company}}
, **Search results:** {{linkedin_search}}
- **Comments on posts:** {{linkedin_comments}}

### Twitter/X (Manual)
, **Search results:** {{twitter_search}}
, **@mentions:** {{twitter_mentions}}

### Google Alerts
, **News/blog mentions:** {{google_alerts_count}}
, **Key articles:**
{{google_alerts_articles}}

## Alert Severity Classification

### Critical (Immediate Action Required)
- [ ] {{critical_item_1}}
- [ ] {{critical_item_2}}

### Important (Respond within 2 hours)
[ ] {{important_item_1}}
, [ ] {{important_item_2}}

### Routine (Acknowledge within 24 hours)
, [ ] {{routine_item_1}}
, [ ] {{routine_item_2}}

## Response Status
**Responded today:** {{responses_done}}
, **Pending:** {{responses_pending}}
, **Escalated:** {{escalated_items}}

## Competitor Tracking
**Competitor mentions:** {{competitor_count}}
, **Market comparison mentions:** {{comparison_count}},
**Competitive positioning insights:** {{competitive_insights}}

## Sentiment Trend
**Positive:** {{positive_pct}}%
, **Neutral:** {{neutral_pct}}%,
**Negative:** {{negative_pct}}%
**Change from yesterday:** {{sentiment_change}}

## Action Items for Tomorrow
1. {{action_1}}
2. {{action_2}}
3. {{action_3}}

## Dashboard Links
- **Full report:** [monitoring-reports/](monitoring-reports/)
- **Script output:** [scripts/social-monitoring-check.sh](scripts/social-monitoring-check.sh)
1. **Response templates:** [CASE_STUDY_RESPONSE_TEMPLATES.md](CASE_STUDY_RESPONSE_TEMPLATES.md)
, **Escalation matrix:** [SOCIAL_MEDIA_MONITORING_SETUP.md](SOCIAL_MEDIA_MONITORING_SETUP.md)

---
**Next Report:** Tomorrow {{next_report_time}}
**Report Generated Automatically**