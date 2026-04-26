# Social Media Monitoring Tools Setup Brief

## Overview
Setup instructions for social media monitoring tools required for Foreman v2 launch (April 28, 2026).

**Monitoring Period:** April 21 - May 12, 2026 (3 weeks)
**Primary Purpose:** Track brand mentions, sentiment, engagement, competitive intelligence
**Secondary Purpose:** Rapid response, issue identification, performance tracking

## Required Tools

### 1. Mention (Brand Monitoring)
**Cost:** $99/month (Pro plan)
**URL:** https://mention.com
**Trial:** 14-day free trial available

**Setup Steps:**
1. **Create account** with company email
2. **Create project:** "Foreman v2 Launch"
3. **Add keywords:** (See "Key Terms to Monitor" below)
4. **Configure sources:** Social media, news, blogs, forums, review sites
5. **Set up alerts:** Critical/important/routine (see alert configuration)
6. **Configure dashboard:** Real-time monitoring view
7. **Set up reports:** Daily/weekly automation
8. **Team access:** Add CMO, CEO, Community Manager (if hired)

### 2. Hootsuite/Buffer (Social Management)
**Cost:** $99/month (Pro plan)
**Options:** Hootsuite (better for monitoring) or Buffer (better for scheduling)
**URLs:** https://hootsuite.com or https://buffer.com

**Setup Steps (Hootsuite):**
1. **Create account** with company email
2. **Connect social accounts:**
   - LinkedIn Company Page
   - Twitter/X account
   - (Optional: Facebook, Instagram if relevant)
3. **Create streams:**
   - @mentions and replies
   - Brand keyword search
   - Competitor monitoring
   - Industry hashtags
4. **Configure publishing:** Schedule LinkedIn calendar posts
5. **Set up alerts:** Engagement thresholds
6. **Configure analytics:** Performance dashboards
7. **Team access:** Add CMO, Community Manager

**Setup Steps (Buffer):**
1. **Create account** with company email
2. **Connect social accounts** (same as above)
3. **Create posting schedule:** 10:00 AM EST daily
4. **Upload LinkedIn calendar content**
5. **Configure analytics:**
6. **Team access:** Add CMO, Community Manager

### 3. Slack Integrations
**Cost:** $8/user/month (Pro plan if needed)
**Existing:** Check if Slack workspace exists

**Setup Steps:**
1. **Create channels:**
   - #launch-monitoring (primary)
   - #critical-alerts (emergency)
   - #social-mentions (all mentions)
   - #competitor-watch (competitive intel)
2. **Set up webhooks:**
   - Mention → Slack integration
   - Hootsuite/Buffer → Slack integration
3. **Configure notifications:** Alert routing rules
4. **Create workflows:** Response assignment
5. **Team invites:** CMO, CEO, CTO, Community Manager

### 4. Google Sheets Tracker (Manual Backup)
**Cost:** Free (Google Workspace)
**Purpose:** Manual mention logging backup

**Setup Steps:**
1. **Create spreadsheet:** "Foreman Launch Monitoring Tracker"
2. **Columns:**
   - Date & Time
   - Platform
   - User/Handle
   - Mention Text
   - Sentiment (Positive/Neutral/Negative)
   - Response Needed? (Yes/No)
   - Response Sent? (Yes/No)
   - Response Time (minutes)
   - Notes
   - Escalated? (Yes/No)
3. **Formulas:** Automatic calculations (average response time, sentiment ratio)
4. **Charts:** Visualization of trends
5. **Sharing:** Team access and collaboration

## Key Terms to Monitor

### Brand Terms
- **Primary:** "Foreman", "Foreman AI", "Foreman v2", "foreman.company"
- **Variations:** "ForemanAI", "ForemanV2", "ForemanPlatform"
- **Misspellings:** "Forman", "Foremann", "4man"
- **Hashtags:** #ForemanAI, #ForemanV2, #NoCodeAI

### Product Terms
- "AI agents", "no-code AI", "AI orchestration"
- "AI team", "AI assistant", "AI automation"
- "Paperclip integration", "OpenClaw runtime"
- "BYOK AI", "managed AI operations"

### Competitive Terms
- **Direct competitors:** "LangChain", "CrewAI", "AutoGPT"
- **Category competitors:** "AI automation", "AI workflow"
- **Alternative solutions:** "virtual assistant", "outsourcing"
- **Comparison phrases:** "vs Foreman", "alternatives to Foreman"

### Launch-Specific Terms
- "Foreman launch", "Foreman v2 launch"
- "Foreman case study", "Foreman Runs on Foreman"
- "Foreman waitlist", "Foreman early access"
- "Foreman pricing", "Foreman review"

## Alert Configuration

### Critical Alerts (Immediate Notification)
**Triggers:**
- "Foreman" + "bug" / "broken" / "not working"
- "Foreman" + "security" / "privacy" / "data leak"
- "Foreman" + "scam" / "fraud" / "illegal"
- High-engagement negative sentiment (>100 engagements)
- Major media outlet mention (TechCrunch, VentureBeat, etc.)
- Competitor attack/FUD campaign

**Notification:** Slack #critical-alerts, SMS to CMO/CEO
**Response Time:** < 15 minutes

### Important Alerts (Hourly Digest)
**Triggers:**
- "Foreman" + "question" / "help" / "support"
- "Foreman" + "pricing" / "cost" / "expensive"
- "Foreman" + "alternative" / "competitor" / "vs"
- Medium engagement (>50 engagements)
- Industry influencer mention
- Positive viral mention

**Notification:** Slack #monitoring-hourly, Email digest
**Response Time:** < 2 hours

### Routine Alerts (Daily Digest)
**Triggers:**
- All other Foreman mentions
- Competitive mentions
- Industry trend mentions
- General AI/automation discussions

**Notification:** Morning email report
**Response Time:** < 24 hours

## Monitoring Channels

### Social Platforms
1. **LinkedIn**
   - Company page mentions
   - CEO/executive mentions
   - Relevant groups (AI, SaaS, small business)
   - Hashtag monitoring

2. **Twitter/X**
   - @mentions and replies
   - Hashtag tracking
   - Thread discussions
   - Influencer conversations

3. **Reddit**
   - r/Entrepreneur
   - r/SaaS
   - r/artificial
   - r/smallbusiness
   - r/startups

4. **Discord/Slack**
   - AI/tech communities
   - Startup communities
   - SaaS communities
   - Industry-specific groups

### Community Platforms
5. **Hacker News**
   - Show HN posts
   - Ask HN discussions
   - Comment threads
   - Sentiment trends

6. **Indie Hackers**
   - Product launches
   - Discussion threads
   - Community feedback
   - Feature requests

7. **Product Hunt**
   - Launch page comments
   - Discussion threads
   - Upvote tracking
   - Competitor launches

## Response Protocols

### Response Time Targets
- **Critical issues:** < 15 minutes (bugs, outages, security)
- **Media inquiries:** < 1 hour (journalists, influencers)
- **Customer questions:** < 2 hours (pricing, features, support)
- **General comments:** < 4 hours (social media, community)
- **Negative feedback:** < 2 hours (address promptly)
- **Positive feedback:** < 4 hours (acknowledge, thank)

### Response Templates
See: [CASE_STUDY_RESPONSE_TEMPLATES.md](./CASE_STUDY_RESPONSE_TEMPLATES.md)

### Escalation Matrix
| Issue Type | First Responder | Escalate To | Timeframe |
|------------|-----------------|-------------|-----------|
| Technical Bug | CMO | CTO | 15 minutes |
| Pricing/Feature Question | CMO | CEO | 30 minutes |
| Media Inquiry | CMO | CEO | 15 minutes |
| Security Concern | CMO | CTO | 5 minutes |
| Competitive Threat | CMO | CEO | 1 hour |
| Partnership Inquiry | CMO | CEO | 2 hours |
| Legal/Compliance | CMO | CEO | 15 minutes |
| Negative Viral | CMO | CEO | 30 minutes |

## Daily Monitoring Schedule

### Pre-Launch (April 21-27)
**Daily Tasks:**
- 9:00 AM: Morning scan (all platforms)
- 12:00 PM: Midday check (engagement focus)
- 3:00 PM: Afternoon review (sentiment analysis)
- 6:00 PM: Evening summary (report preparation)

### Launch Day (April 28)
**Hourly Checks:**
- :00: Platform-wide scan
- :30: Engagement response
- Manual continuous monitoring for first 8 hours

### Week 1 Post-Launch (April 29 - May 5)
**Daily Schedule:**
- 8:00 AM: Overnight summary review
- 10:00 AM: Morning engagement
- 1:00 PM: Midday sentiment check
- 4:00 PM: Afternoon responses
- 7:00 PM: Evening summary

## Setup Timeline

### Today (April 21)
1. **Create Mention account** (14-day trial)
2. **Create Hootsuite/Buffer account** (trial)
3. **Configure basic keyword monitoring**
4. **Set up Slack channels** (if workspace exists)

### Tomorrow (April 22)
1. **Complete tool configuration**
2. **Test alert systems**
3. **Train team on monitoring protocols**
4. **Begin baseline monitoring**

### April 23-27
1. **Refine keyword lists**
2. **Adjust alert thresholds**
3. **Practice response protocols**
4. **Baseline data collection**

### Launch Day (April 28)
1. **Activate enhanced monitoring**
2. **Team on-call schedule**
3. **Real-time dashboard visibility**
4. **Escalation procedures active**

## Budget Summary

| Tool | Monthly Cost | Setup Time | Responsibility |
|------|--------------|------------|----------------|
| Mention Pro | $99 | 2 hours | CMO oversees, tech team implements |
| Hootsuite Pro | $99 | 2 hours | CMO oversees, tech/community implements |
| Slack Pro (if needed) | $8/user | 1 hour | Tech team |
| **Total Monthly** | **$206+** | **5 hours** | |

## Success Criteria

### Setup Success (April 22)
- [ ] All tools configured and tested
- [ ] Alerts working correctly
- [ ] Team trained on protocols
- [ ] Baseline monitoring established

### Launch Monitoring Success (April 28)
- [ ] Real-time monitoring operational
- [ ] Team responding within targets
- [ ] Critical alerts routed correctly
- [ ] Sentiment tracking accurate

### Ongoing Success (Weekly)
- [ ] Response time < 2 hours average
- [ ] Sentiment 70%+ positive/neutral
- [ ] All critical issues escalated appropriately
- [ ] Daily/weekly reports generated

## Troubleshooting

### Common Issues & Solutions
1. **Missing mentions:** Expand keyword list, check source configuration
2. **False positives:** Refine keyword combinations, add negative keywords
3. **Alert fatigue:** Adjust thresholds, create digest summaries
4. **Tool integration issues:** Use manual tracking as backup, contact support
5. **Team coordination:** Clear escalation paths, regular check-ins

### Backup Plan
If primary tools fail:
1. **Manual monitoring:** Daily platform checks by team
2. **Google Alerts:** Free alternative for web mentions
3. **Native platform tools:** LinkedIn/Twitter built-in analytics
4. **Spreadsheet tracking:** Manual logging as backup

## Next Steps

### Immediate Actions (Today):
1. **Designate tool setup owner** (CMO or tech team)
2. **Approve budget** ($99/month x 2 tools + Slack if needed)
3. **Provide access credentials** for company accounts
4. **Begin setup** with 14-day trials

### Follow-up Actions (This Week):
1. **Team training** on monitoring protocols
2. **Test runs** with simulated mentions
3. **Adjust configurations** based on testing
4. **Go-live** for baseline monitoring

---

**Document Version:** 1.0  
**Created:** April 21, 2026  
**Owner:** CMO  
**Status:** Ready for implementation  
**Implementation Owner:** TBD (Tech team or CMO with support)