# Monitoring Tools Trial Setup - Step by Step

## Overview
Setting up 14-day trials for social media monitoring tools required for Foreman v2 launch.

**Tools:** Mention (brand monitoring) + Hootsuite (social management)
**Trials:** 14 days free for both
**Timeline:** Setup today (April 21), refine by April 23, operational for launch

## Step 1: Email Account Decision

### Options for Account Creation:
**Option A: Use company email** (Preferred)
- **Email:** info@foreman.company or similar
- **Pros:** Professional, permanent, team accessible
- **Cons:** Need access to email account
- **Action:** Request credentials from CEO/CTO

**Option B: Create new company Gmail** 
- **Email:** foreman.launch.monitoring@gmail.com
- **Pros:** Dedicated, easy access, separate from personal
- **Cons:** Not official company domain, password management
- **Action:** Create now if no company email access

**Option C: Use my work email**
- **Email:** [CMO work email]
- **Pros:** Immediate, controlled access
- **Cons:** Tied to individual, transfer issues later
- **Action:** Use as last resort

**Decision:** Will try Option A first, fall back to Option B if no access in 1 hour.

## Step 2: Mention Trial Setup

### Visit: https://mention.com
1. **Click "Start Free Trial"**
2. **Choose plan:** Pro (14-day trial)
3. **Enter email:** [company email or created email]
4. **Create password:** Use password manager
5. **Verify email:** Check inbox, click verification

### Project Configuration:
1. **Project name:** "Foreman v2 Launch"
2. **Add keywords:** (See keyword list below)
3. **Configure sources:** 
   - Social media (Twitter, LinkedIn, Facebook, Instagram)
   - News & blogs
   - Forums & discussions
   - Review sites
4. **Set language:** English
5. **Set region:** United States (or global)

### Alert Configuration:
1. **Critical alerts:** Setup for urgent mentions
2. **Daily digest:** Morning report
3. **Weekly report:** Monday summary
4. **Slack integration:** Connect to #critical-alerts

## Step 3: Hootsuite Trial Setup

### Visit: https://hootsuite.com
1. **Click "Start Free Trial"**
2. **Choose plan:** Professional (30-day trial)
3. **Enter email:** Same as Mention (for consistency)
4. **Create password:** Use password manager
5. **Verify email:** Check inbox, click verification

### Social Account Connection:
1. **LinkedIn Company Page:** Connect (requires admin approval)
2. **Twitter/X account:** Connect
3. **Optional:** Facebook, Instagram if relevant

### Stream Configuration:
1. **Home feed:** General monitoring
2. **Mentions:** @foreman mentions
3. **Keywords:** Brand keyword monitoring
4. **Competitors:** Competitor account monitoring
5. **Hashtags:** Relevant industry hashtags

### Publishing Configuration:
1. **Schedule:** 10:00 AM EST daily
2. **Content queue:** Load Days 2-7 LinkedIn content
3. **UTM tracking:** Configure for all links
4. **Analytics:** Enable performance tracking

## Step 4: Slack Workspace Setup

### If Slack exists:
1. **Request access** to company Slack
2. **Create channels:**
   - #launch-monitoring (primary)
   - #critical-alerts (emergency)
   - #social-mentions (all mentions)
   - #competitor-watch (competitive intel)
   - #launch-metrics (performance tracking)
3. **Integrations:**
   - Mention → Slack webhook
   - Hootsuite → Slack notifications
   - Google Sheets updates

### If no Slack exists:
1. **Create new Slack workspace:** foreman-launch.slack.com
2. **Invite team:** CEO, CTO, CMO, UXDesigner
3. **Create channels** (same as above)
4. **Set up integrations** (same as above)

## Step 5: Keyword Configuration

### Brand Keywords (Mention + Hootsuite):
- "Foreman", "Foreman AI", "Foreman v2", "foreman.company"
- "ForemanAI", "ForemanV2", "ForemanPlatform"
- "Forman", "Foremann", "4man" (misspellings)
- #ForemanAI, #ForemanV2, #NoCodeAI

### Product Keywords:
- "AI agents", "no-code AI", "AI orchestration"
- "AI team", "AI assistant", "AI automation"
- "Paperclip integration", "OpenClaw runtime"
- "BYOK AI", "managed AI operations"

### Competitive Keywords:
- "LangChain", "CrewAI", "AutoGPT"
- "AI automation", "AI workflow"
- "virtual assistant", "outsourcing"
- "vs Foreman", "alternatives to Foreman"

### Launch Keywords:
- "Foreman launch", "Foreman v2 launch"
- "Foreman case study", "Foreman Runs on Foreman"
- "Foreman waitlist", "Foreman early access"
- "Foreman pricing", "Foreman review"

## Step 6: Alert Thresholds

### Mention Alerts:
**Critical (immediate):**
- "Foreman" + "bug"/"broken"/"not working"
- "Foreman" + "security"/"privacy"/"data leak"  
- "Foreman" + "scam"/"fraud"/"illegal"
- Negative sentiment + high engagement (>100)
- Major media outlet mention

**Important (hourly digest):**
- "Foreman" + "question"/"help"/"support"
- "Foreman" + "pricing"/"cost"/"expensive"
- "Foreman" + "alternative"/"competitor"/"vs"
- Medium engagement (>50)
- Influencer mention

**Routine (daily digest):**
- All other brand mentions
- Competitive mentions
- Industry trend mentions

### Hootsuite Alerts:
**Engagement alerts:** >50 likes/shares/comments
**Mention alerts:** All @mentions
**Sentiment alerts:** Negative sentiment detection
**Performance alerts:** Post underperforming benchmarks

## Step 7: Team Access Setup

### Mention Access:
1. **CMO:** Full admin access
2. **CEO:** View + comment access
3. **CTO:** View access (technical issues)
4. **Community Manager:** Full access (if hired)

### Hootsuite Access:
1. **CMO:** Full admin access
2. **CEO:** View + publish access
3. **Community Manager:** Full access (if hired)

### Slack Access:
1. **All team members:** Relevant channel access
2. **CMO:** All channel admin
3. **CEO:** All channel access
4. **CTO:** Technical channels + critical alerts

## Step 8: Testing & Validation

### Test Timeline:
**Hour 1:** Basic setup complete
**Hour 2:** Test alerts with sample mentions
**Hour 3:** Team access and training
**Hour 4:** Integration testing (Slack, email)
**Today EOD:** Baseline monitoring operational

### Test Scenarios:
1. **Positive mention test:** "Excited for Foreman v2 launch!"
2. **Question test:** "How much does Foreman cost?"
3. **Issue test:** "Having trouble with Foreman setup"
4. **Competitive test:** "Comparing Foreman vs LangChain"
5. **Media test:** Simulate TechCrunch mention

### Success Criteria:
- [ ] Alerts deliver within 5 minutes
- [ ] Team receives notifications correctly
- [ ] Sentiment analysis working
- [ ] No false positives from unrelated mentions
- [ ] All team members can access tools

## Step 9: Documentation & Handoff

### Create Documentation:
1. **Credentials document:** Tool logins (secure storage)
2. **User guide:** How to use each tool
3. **Response protocols:** When and how to respond
4. **Escalation matrix:** Who to contact for what
5. **Troubleshooting guide:** Common issues and fixes

### Training Materials:
1. **Quick start guide:** 1-page cheat sheet
2. **Video walkthroughs:** 2In5 minute tutorials
3. **Team onboarding:** 30-minute training session
4. **Reference cards:** Desktop quick references

### Handoff Plan:
1. **Primary owner:** CMO (ongoing management)
2. **Backup owner:** CEO (emergency access)
3. **Technical owner:** CTO (tool integration)
4. **Future owner:** Community Manager (when hired)

## Step 10: Ongoing Management

### Daily Tasks:
1. **Morning review:** Overnight mentions
2. **Alert monitoring:** Critical issue check
3. **Response coordination:** Team assignment
4. **Evening summary:** Daily performance

### Weekly Tasks:
1. **Report generation:** Weekly performance
2. **Tool optimization:** Keyword refinement
3. **Team training:** Skill development
4. **Budget review:** Cost monitoring

### Monthly Tasks:
1. **Performance analysis:** Metric review
2. **Tool evaluation:** Continue or cancel trials
3. **Strategy adjustment:** Based on data
4. **Team feedback:** Process improvement

## Troubleshooting Guide

### Common Issues:
1. **Missing mentions:** Expand keywords, check sources
2. **False positives:** Refine keyword combinations
3. **Alert fatigue:** Adjust thresholds, create digests
4. **Integration issues:** Check webhooks, API limits
5. **Team access problems:** Verify permissions, re-invite

### Emergency Contacts:
- **Mention support:** support@mention.com
- **Hootsuite support:** https://help.hootsuite.com
- **Slack support:** https://slack.com/help

### Backup Plan:
If tools fail:
1. **Manual monitoring:** Daily platform checks
2. **Google Alerts:** Free web mention tracking
3. **Native tools:** Platform analytics
4. **Spreadsheet tracking:** Manual logging

## Timeline for Today

### Now - 1 hour:
- [ ] Decide email approach
- [ ] Start Mention trial
- [ ] Start Hootsuite trial
- [ ] Configure basic settings

### 1-2 hours:
- [ ] Setup keyword monitoring
- [ ] Configure alerts
- [ ] Test basic functionality
- [ ] Document credentials

### 2-3 hours:
- [ ] Setup Slack integrations
- [ ] Test alert delivery
- [ ] Train initial team members
- [ ] Create quick start guide

### 3-4 hours:
- [ ] Complete testing
- [ ] Finalize configurations
- [ ] Document procedures
- [ ] Begin baseline monitoring

---

**Document Version:** 1.0  
**Created:** April 21, 2026  
**Owner:** CMO  
**Status:** READY FOR EXECUTION  
**Decision Needed:** Email account for tool registration  
**Time Sensitivity:** HIGH - Need monitoring operational before case study publishes