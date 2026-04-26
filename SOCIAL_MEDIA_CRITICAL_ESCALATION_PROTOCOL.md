# Social Media Critical Mention Escalation Protocol

## Overview
Procedure for handling critical social media mentions requiring immediate response during Foreman launch monitoring.

**Owner:** CMO (primary), escalates to CEO/CTO as needed
**Activation:** Any mention classified as "Critical" per severity definitions
**Response Time Target:** < 15 minutes for acknowledgment

## Severity Classification

### Critical (Immediate Escalation Required)
**Triggers:**
- Mention containing "Foreman" + "bug"/"broken"/"not working"
- Mention containing "Foreman" + "security"/"privacy"/"data leak"
- Mention containing "Foreman" + "scam"/"fraud"/"illegal"
- High-engagement negative sentiment (>100 engagements)
- Major media outlet mention (TechCrunch, VentureBeat, etc.)
- Competitor attack/FUD campaign
- Brand impersonation or phishing attempt

### Important (Response within 2 hours)
**Triggers:**
- "Foreman" + "question"/"help"/"support"
- "Foreman" + "pricing"/"cost"/"expensive"
- "Foreman" + "alternative"/"competitor"/"vs"
- Medium engagement (>50 engagements)
- Industry influencer mention
- Positive viral mention requiring amplification
- Partnership inquiry

### Routine (Acknowledge within 24 hours)
**Triggers:**
- All other Foreman mentions
- Competitive mentions
- Industry trend mentions
- General AI/automation discussions
- Positive feedback

## Escalation Matrix

| Severity | First Responder | Escalate To | Timeframe | Action Required |
|----------|-----------------|-------------|-----------|----------------|
| Critical | CMO | CTO (tech) / CEO (executive) | 5-15 minutes | Technical fix, public response, issue investigation |
| Important | CMO | CEO (if strategic) | 30 minutes | Response drafting, policy clarification, feature request review |
| Routine | CMO | None | 4-24 hours | Acknowledgment, thank you, engagement |

## Notification Protocol

### Free Monitoring Stack (Current)
**Tools:**
- `scripts/social-monitoring-check.sh`: Reddit/HN mentions daily
- Google Alerts: Web/news mentions daily digest
- Manual checks: LinkedIn/Twitter 2x daily

**Escalation Path:**
1. Critical mention identified
2. CMO creates Slack/email alert (or uses temp chat if Slack unavailable)
3. Tag appropriate executive with specific mention link
4. Begin response drafting concurrently

### Paid Tool Stack (When Available)
**Tools:**
- Mention: Real-time alerts with sentiment analysis
- Hootsuite: Multi-platform monitoring with response workflow

**Automated Escalation:**
- Mention → Slack webhook to #critical-alerts
- Hootsuite → Email digest with priority filtering
- Integration with response templates library

## Response Workflow

### Step 1: Acknowledgment (Within 15 minutes)
**Template (Critical):**
> "We're looking into this issue immediately. Thank you for bringing it to our attention. Our team is investigating and will provide an update shortly."

**Template (Important):**
> "Thanks for your question! Let me get you the correct information on that."

### Step 2: Investigation (15-60 minutes)
**Technical Issues:** CTO investigates, provides root cause
**Executive Issues:** CEO reviews, determines strategic response
**Compliance Issues:** Both review, coordinate legal if needed

### Step 3: Response Drafting (60-120 minutes)
**Technical Bug Fix:**
> "We've identified and fixed the issue affecting [feature]. The fix is now live. Thank you for your patience while we resolved this."

**Pricing/Feature Question:**
> "Here's the current pricing for that plan: [details]. The feature you mentioned is/is not included. Let me know if you have more questions!"

**Security Concern:**
> "We take security seriously. Our team has reviewed the concern and confirms [status]. We've also implemented [additional measures]."

### Step 4: Follow-up (24 hours)
**Check:** Verify issue resolved
**Monitor:** Track sentiment after response
**Document:** Add to lessons learned

## Documentation Requirements

### Critical Incident Log
**Format:** Google Sheet or markdown file
**Columns:**
.

| Date | Platform | User | Mention Excerpt | Severity | Response Time | Responder | Outcome | Follow-up |
|------|----------|------|-----------------|----------|---------------|-----------|---------|-----------|

### Sentiment Tracking
**Weekly Report Includes:**
, Number of critical incidents
- Average response time
-Hour severity resolution rate
-Sentiment trend before/after response
-Lessons learned for process improvement

## Team Contact Information

**CMO:** Primary escalation point - [FORA-106](/FORA/issues/FORA-106) assignee
**CTO:** Technical issues - [FORA-172](/FORA/issues/FORA-172) Slack workspace task
**CEO:** Executive/strategic issues - [FORA-171](/FORA/issues/FORA-171) email account task

**Backup Escalation:**
.

If primary unavailable for >30 minutes, escalate to next in chain:
1. CMO → CEO
2. CEO → CTO (technical only)
3. CTO → CEO (strategic only)

## Success Metrics

**Targets:**
- Critical response time: < 15 minutes average
- Important response time: < 2 hours average
- Routine acknowledgment: <; 24 hours average
- Critical resolution rate: 90%+ within 24 hours
- Sentiment improvement: Negative → Neutral/Positive within 48 hours

**Reporting:**
- Daily mention count by severity
- Weekly response time averages
-[Monthly incident review with process improvements

## Revision History

**v1.0 (April 24, 2026):** Initial protocol for launch monitoring
**Next Review:** May I, 2026 (post-launch week 1)
**Owner:** CMO

---
**Linked Resources:**
1. [Response Templates](/CASE_STUDY_RESPONSE_TEMPLATES.md)
2. [Monitoring Setup Status](/SOCIAL_MONITORING_IMPLEMENTATION_STATUS.md)
3. [Daily Report Template](/MONITORING_DAILY_REPORT_TEMPLATE.md)
4. [Tool Setup Guide](/MONITORING_TOOLS_TRIAL_SETUP.md)
5. [Parent Task FORA-106](/FORA/issues/FORA-106)