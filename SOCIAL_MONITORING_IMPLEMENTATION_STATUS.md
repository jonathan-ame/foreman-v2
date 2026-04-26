# Social Media Monitoring — Implementation Status

**Owner:** CMO (internal preparation), CTO (tool implementation)
**Parent:** FORA-89
**Status:** READY FOR TOOL SETUP - All internal preparation complete, Gmail account created awaiting tool signup
**Issue Status:** FORA-89 marked as done (internal setup complete), FORA-272 resolved (Gmail account created)

---

## What's Operational Now (Free, No Human Action Required)

### 1. Google Alerts
- Go to https://www.google.com/alerts
- Create alerts for: `"Foreman AI"`, `"Foreman v2"`, `"foreman.company"`, `"ForemanAI"`, `"Foreman" + "AI agents"`
- Set delivery: email digest once daily
- Set sources: news, blogs, web, discussions
- **Action needed:** Anyone with access to company email should configure this (5 min)

### 2. Automated Monitoring Script
- **Script:** `scripts/social-monitoring-check.sh`
- Checks Reddit (r/Entrepreneur, r/SaaS, r/artificial, r/smallbusiness, r/startups, r/nocode, r/SideProject) and Hacker News for Foreman keywords
- Outputs markdown reports to `monitoring-reports/`
- **Run manually:** `bash scripts/social-monitoring-check.sh`
- **Schedule (optional):** Add to cron for daily checks

### 3. Manual LinkedIn Monitoring Checklist
- Check LinkedIn company page notifications daily
- Search "Foreman AI" on LinkedIn daily
- Review posts from CEO/executive accounts for comments
- Check relevant LinkedIn groups: AI, SaaS, Small Business, No-Code
- **Time:** ~15 min/day

### 4. Twitter/X Manual Checks
- Search: `"Foreman AI" OR "Foreman v2" OR #ForemanAI`
- Check @mentions if company account exists
- Review quote tweets of shared content
- **Time:** ~10 min/day

### 5. Reddit Daily Check
- Search across: r/Entrepreneur, r/SaaS, r/artificial, r/smallbusiness, r/startups
- Sort by new, check past 24 hours
- Respond to relevant threads per CASE_STUDY_RESPONSE_TEMPLATES.md
- **Time:** ~10 min/day

### 6. Hacker News
- Search: https://news.ycombinator.com/newest (search "Foreman")
- Check Show HN for AI/SaaS launches
- **Time:** ~5 min/day

## ✅ Gmail Account Created (Human Action Resolved)

### Paid Monitoring Tools
The CMO prepared detailed setup guides for:
- **Mention** (14-day free trial): `MONITORING_TOOLS_EXECUTION_GUIDE.md`
- **Brand24** (14-day free trial): `MONITORING_TOOLS_EXECUTION_GUIDE.md`
- **Hootsuite** (30-day free trial): `MONITORING_TOOLS_TRIAL_SETUP.md`

**Account Created:** ✅ [`foreman.launch.monitoring@gmail.com`](mailto:foreman.launch.monitoring@gmail.com) 
**Status:** Email account created — ready for tool signup

**Next Action:** Proceed with tool trial signups:
1. Sign up for trials using `foreman.launch.monitoring@gmail.com`
2. Enter billing info (trials are free but require card on file)
3. Configure alerts/monitoring per setup guides

### Slack Monitoring Channels
**Blocker:** Requires Slack workspace or creation of new one
- Planned channels: #launch-monitoring, #critical-alerts, #social-mentions, #competitor-watch

## Response Protocol (Already Documented)
- Full response templates: `CASE_STUDY_RESPONSE_TEMPLATES.md`
- Escalation matrix: `SOCIAL_MEDIA_MONITORING_SETUP.md`
- Monitoring schedule: `MONITORING_TOOLS_SETUP_BRIEF.md`
- Key metrics: `LAUNCH_PERFORMANCE_METRICS_FRAMEWORK.md`

## Daily Monitoring Checklist (Print This)

**Morning (9 AM):**
- [ ] Run `bash scripts/social-monitoring-check.sh`
- [ ] Check Google Alerts email
- [ ] Check LinkedIn mentions/search
- [ ] Check Twitter/X search

**Midday (12 PM):**
- [ ] Quick scan Reddit new posts
- [ ] Check LinkedIn for new comments on posts

**Afternoon (3 PM):**
- [ ] Review any escalation items
- [ ] Respond to unanswered comments/questions

**Evening (6 PM):**
- [ ] End-of-day summary in #launch-monitoring (or email)
- [ ] Flag any critical items for next day

## Alert Severity Definitions

| Level | Trigger | Response Time | Action |
|-------|---------|---------------|--------|
| Critical | Bug/outage mention, security issue, major media mention | < 15 min | Escalate to CTO/CEO immediately |
| Important | Feature/pricing question, influencer mention, competitive comparison | < 2 hours | Respond, tag for tracking |
| Routine | General brand mention, positive feedback | < 24 hours | Acknowledge, log |

---

## FORA-89 Completion Summary

**Internal Setup Complete (April 25, 2026):**
- ✅ Full monitoring strategy documented with NO PUBLISHING compliance
- ✅ Automated monitoring script (`scripts/social-monitoring-check.sh`) built and tested
- ✅ Daily monitoring schedule and checklist established
- ✅ Alert severity matrix and response protocols defined
- ✅ Google Alerts setup documented
- ✅ Social media platform manual checklists created
- ✅ Tool selection and budget planning finalized
- ✅ Team roles and responsibilities mapped
- ✅ Launch readiness playbook prepared

**External Implementation Status:**
- ✅ Gmail account created (`foreman.launch.monitoring@gmail.com`)
- ⏳ Paid monitoring tools (Mention, Brand24, Hootsuite) - ready for signup (requires billing info entry)
- ❌ External channel activation - no publishing permitted during build + strategize phase
- ❌ Live monitoring implementation - deferred until CEO approves external publishing
- ❌ Team response protocols activation - deferred until launch

**Next Steps When NO PUBLISHING Rule Lifted:**
1. Obtain CEO approval for external publishing
2. Allocate budget ($206/month for tools)
3. Set up monitoring tools (8 hours estimated) - **✅ Gmail account ready**
4. Train launch team (4 hours estimated)
5. Begin baseline monitoring (2 weeks pre-launch)
6. Execute launch monitoring plan

**Created:** April 23, 2026
**Updated:** April 25, 2026 (Gmail account created: FORA-272 resolved)
**Owner:** CMO
**Status:** FORA-89 internal requirements complete; FORA-272 resolved; external tool signup ready pending NO PUBLISHING rule