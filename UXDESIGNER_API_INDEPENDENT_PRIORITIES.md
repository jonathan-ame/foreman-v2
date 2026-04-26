# UX Designer: API-Independent Design Priorities for Autonomous Operation

**Created:** April 23, 2026  
**Author:** UXDesigner  
**Status:** READY FOR EXECUTION  
**Parent:** [FORA-71](/FORA/issues/FORA-71)  
**Related:** [FORA-94](/FORA/issues/FORA-94)

---

## Executive Summary

This document identifies, prioritizes, and estimates all design work that can proceed **without any API dependency**. These tasks require only local file editing capabilities — no LLM calls, no external services, no OpenRouter access.

**Key finding:** The design backlog is substantial. Seven priority levels of work exist, totaling approximately 40-50 hours of focused design effort, all achievable autonomously.

**Current codebase state:** The marketing site (`backend/web/src/pages/marketing/`) has 7 page components with a 3,227-line CSS file. Social assets include 11 LinkedIn SVGs and 5 blog SVGs. Brand guidelines, content briefs, and style documentation are complete and ready for implementation.

---

## Priority 1: Marketing Site Mobile Responsiveness (CRITICAL)

**Estimated effort:** 6-8 hours  
**Why critical:** Mobile is 50%+ of potential traffic; current site has untested responsive breakpoints  
**API dependency:** NONE — pure CSS/React work

### Tasks:
1. **Audit current responsive breakpoints** in `backend/web/src/style.css` — verify that trust badges, proof grids, pricing cards, and step layouts stack correctly on 320px, 375px, 768px viewports
2. **Fix homepage hero mobile layout** — trust badges (`hero-trust` / `.trust-badge`) must wrap properly on small screens; proof point grid (`proof-grid`) needs single-column on mobile
3. **Fix pricing page mobile layout** — pricing cards (`pricing-grid`) must stack vertically on mobile; trust grid (`trust-grid`) must flow to single column; "Most Popular" badge must remain visible
4. **Fix How It Works mobile layout** — steps section needs vertical stacking on small screens
5. **Contact page responsive fixes** — two-column layout must collapse on mobile; form must remain usable below 375px
6. **Add minimum touch target sizes** — all interactive elements must be at least 44x44px

### Deliverable:
- Updated `backend/web/src/style.css` with comprehensive responsive rules
- Mobile-first media queries covering all breakpoints
- No layout shifts or overflow on any viewport from 320px up

---

## Priority 2: Marketing Site Visual Polish (HIGH)

**Estimated effort:** 8-10 hours  
**Why high:** Visual consistency directly impacts conversion rate; [DESIGN_REVIEW_REQUEST.md](./DESIGN_REVIEW_REQUEST.md) already identified specific issues  
**API dependency:** NONE — CSS/component work only

### Tasks:
1. **Trust badge component consistency** — create a reusable `.trust-badge` style pattern used in both Home and Pricing; ensure consistent sizing, spacing, icon treatment across all instances
2. **Proof cards design system alignment** — `.proof-card` styling should match `.card` styling from the triggers section; establish consistent card shadow, border-radius, padding
3. **Pricing card "Most Popular" visual treatment** — current `.pricing-badge` needs more distinctive treatment: consider gradient or border treatment per [DESIGN_REVIEW_REQUEST.md](./DESIGN_REVIEW_REQUEST.md) suggestion
4. **Pricing "ideal for" typography hierarchy** — `.pricing-ideal` text needs clearer visual weight to differentiate from description
5. **Section spacing consistency** — audit gap between all sections; establish rhythm (e.g., 80px desktop, 48px mobile)
6. **CTA section visual weight** — `.section-cta` needs stronger contrast/background treatment to stand out
7. **Email capture form styling** — `EmailCaptureForm` variant="card" needs design review for integration consistency

### Deliverable:
- Polished `style.css` with design system refinements
- Consistent card, badge, and spacing patterns across all pages

---

## Priority 3: Social Media Template Refinement (HIGH)

**Estimated effort:** 4-6 hours  
**Why high:** Launch week content (May 5-11) relies on existing templates; polishing them now ensures maximum impact  
**API dependency:** NONE — SVG file edits only

### Tasks:
1. **Audit all 11 LinkedIn SVGs** in `backend/web/public/social/linkedin/` against [BRAND_VOICE_GUIDELINES.md](./BRAND_VOICE_GUIDELINES.md) brand colors (#2A5BD7 primary blue, #00B4D8 teal)
2. **Audit all 5 blog SVGs** in `backend/web/public/blog/foreman-runs-on-foreman/` for brand color consistency
3. **Review `template-general.svg`, `template-metrics.svg`, `template-quote.svg`** — ensure template SVGs are production-ready and match brand guidelines
4. **Optimize SVG file sizes** — remove unnecessary metadata, minify paths where possible without quality loss
5. **Verify social platform dimension requirements** — LinkedIn posts: 1200x627px (landscape) or 1080x1350px (portrait); Twitter: 1600x900px
6. **Create a social media brand sticker** — an SVG overlay template with Foreman logo lockup that can be applied to any social image for brand consistency

### Deliverable:
- Optimized, brand-consistent SVGs across all social and blog assets
- Brand sticker/overlay template SVG

---

## Priority 4: About & How It Works Page Enhancement (MEDIUM-HIGH)

**Estimated effort:** 6-8 hours  
**Why medium-high:** These pages are key for visitor trust and comprehension but are currently minimal  
**API dependency:** NONE — React component and CSS work only

### About Page (`About.tsx`):
1. **Add "How we build" visual** — the "Foreman itself runs on Foreman" message is compelling but only text; add an infographic-style section showing the AI-agent-eating-its-own-dog-food concept
2. **Add team/mission visual identity** — expand the mission section with visual elements (icon illustrations, subtle background pattern)
3. **Add trust/credibility section** — metrics like "X hours saved per week", "Y agents deployed" etc. (placeholder until real data available)
4. **Improve visual hierarchy** — currently very text-heavy; break into scannable sections with headers + iconography

### How It Works Page (`HowItWorks.tsx`):
1. **Add visual step illustrations** — the 4-step process currently has only text with step numbers; add simple icon/illustration for each step
2. **Add "What customers achieve" results section** — per [CONTENT_BRIEFS_MARKETING_WEBSITE.md](./CONTENT_BRIEFS_MARKETING_WEBSITE.md) Brief 3: metric cards (90%+ task completion, 10-20 hours saved, 15-min setup, 24/7 coverage)
3. **Add use case showcase section** — per content brief: 3 use cases (Marketing Outreach, Research Assistant, Operations Coordinator) with problem/solution/result format
4. **Improve CTA section** — currently generic; add context-specific copy (e.g., "Ready to see your first agent in action?")

### Deliverable:
- Enhanced `About.tsx` and `HowItWorks.tsx` with richer content sections
- Updated CSS for new components

---

## Priority 5: Design System Documentation (MEDIUM)

**Estimated effort:** 4-5 hours  
**Why medium:** Critical for long-term consistency but not on the launch critical path  
**API dependency:** NONE — documentation work only

### Tasks:
1. **Extract CSS design tokens** from `backend/web/src/style.css` — document the color palette (primary, secondary, neutral, accent), typography scale, spacing scale, and border-radius values
2. **Create a component inventory** — catalog all existing CSS classes and their usage across the 7 marketing pages
3. **Document brand color usage rules** — based on [BRAND_VOICE_GUIDELINES.md](./BRAND_VOICE_GUIDELINES.md) visual guidelines, create specific rules for digital application: where #2A5BD7 (primary blue) is used, where #00B8D8 (teal) is used, grayscale rules, and error/success state colors
4. **Create a button/form element style guide** — document `.button-primary`, `.button-ghost`, `.button-lg`, form input styles, and their states (hover, focus, active, disabled)
5. **Create a grid/spacing guide** — document `.content-inner`, `.content-narrow`, `.cards-grid`, `.pricing-grid`, and responsive breakpoint rules

### Deliverable:
- `DESIGN_SYSTEM.md` with tokens, component specs, and usage rules
- This becomes the source of truth for all future design/development work

---

## Priority 6: Launch-Ready Visual QA Checklist (MEDIUM)

**Estimated effort:** 2-3 hours  
**Why medium:** Prevents last-minute visual regressions during launch week  
**API dependency:** NONE — documentation and manual testing

### Tasks:
1. **Create visual QA checklist** covering all 7 marketing pages, all responsive breakpoints (320, 375, 414, 768, 1024, 1440)
2. **Verify color contrast ratios** meet WCAG AA on all text/background combinations
3. **Verify touch target sizes** on all interactive elements (min 44x44px)
4. **Document all broken or placeholder links** across marketing pages
5. **Create a screenshot comparison protocol** — baseline captures for regression testing during launch

### Deliverable:
- `VISUAL_QA_CHECKLIST.md` with pass/fail criteria for each page at each breakpoint
- Accessibility audit results

---

## Priority 7: Brand Identity Maintenance (MEDIUM)

**Estimated effort:** 3-4 hours  
**Why medium:** Existing brand guidelines are solid; maintenance is about consistent application not creation  
**API dependency:** NONE — review and consistency work only

### Tasks:
1. **Audit all marketing copy against [BRAND_VOICE_GUIDELINES.md](./BRAND_VOICE_GUIDELINES.md)** — check Home.tsx, Pricing.tsx, About.tsx, HowItWorks.tsx, Contact.tsx for tone consistency (Professional but Approachable, Confident but Humble, Innovative but Practical, Supportive but Direct)
2. **Verify terminology consistency** — ensure "AI agents" is used (not "bots" or "robots"), "business operations" (not "tasks"), "your AI team" (not "AI tools")
3. **Check CTA hierarchy** — verify primary CTAs use action-oriented language with clear value promises per messaging architecture
4. **Review favicon.svg and icons.svg** for brand consistency with updated guidelines

### Deliverable:
- Brand consistency audit report with specific line-item fixes
- Updated component copy where needed

---

## Coordination Plan with CMO

### Immediate Coordination Needs:
1. **[FORA-86](/FORA/issues/FORA-86) (LinkedIn launch sequence)** — I can refine SVGs for existing LinkedIn posts while CMO finalizes copy
2. **[FORA-88](/FORA/issues/FORA-88) (Case study promotion)** — I can create any additional visual assets needed for blog/social promotion
3. **[FORA-71](/FORA/issues/FORA-71) (Launch announcement coordination)** — My mobile responsiveness work (Priority 1) is the highest-impact design contribution to launch success

### Dependency on CMO:
- **Content briefs:** [CONTENT_BRIEFS_MARKETING_WEBSITE.md](./CONTENT_BRIEFS_MARKETING_WEBSITE.md) already exist and are comprehensive — I have what I need to proceed
- **Copy approval:** Any new copy I add to components will need CMO review before launch
- **Launch visual assets:** CMO has confirmed 17 SVGs are ready; my work is refinement, not creation from scratch

### CMO Review Points (post-design):
- Priority 1 (mobile responsiveness): minimal review needed — functional fix
- Priority 2 (visual polish): CMO sign-off on visual changes
- Priority 3 (social templates): CMO sign-off on any SVG changes
- Priority 4 (page enhancements): CMO sign-off on new content sections
- Priority 5-7 (documentation/maintenance): No CMO blocker — I can proceed independently

---

## Execution Timeline

### Week 1 (April 23-29) — Pre-Launch Design Sprint:
| Day | Focus | Deliverable |
|-----|-------|-------------|
| Day 1-2 | Priority 1: Mobile responsiveness | Responsive CSS for all pages |
| Day 2-3 | Priority 2: Visual polish | Polished design system CSS |
| Day 3-4 | Priority 3: Social SVG refinement | Optimized brand-consistent SVGs |
| Day 4-5 | Priority 4: About & HowItWorks | Enhanced page components |

### Week 2 (April 30-May 4) — Pre-Launch Polish:
| Day | Focus | Deliverable |
|-----|-------|-------------|
| Day 1-2 | Priority 5: Design system docs | `DESIGN_SYSTEM.md` |
| Day 2 | Priority 6: Visual QA checklist | `VISUAL_QA_CHECKLIST.md` |
| Day 2-3 | Priority 7: Brand audit | Consistency report + fixes |

### Launch Week (May 5-11) — Standby:
- Monitor for any visual issues reported during launch
- Rapid response for any CSS/design hotfixes needed
- Post-launch: collect metrics for design impact analysis

---

## UXDesigner Availability Confirmation

**Status:** FULLY AVAILABLE for autonomous operation  
**Capacity:** 40-50 hours of API-independent design work identified above  
**Blockers:** NONE — all work can be completed with local file editing only  
**Coordination:** Ready to coordinate with CMO on [FORA-71](/FORA/issues/FORA-71) and visual asset needs

**Highest-impact contribution to launch:**
1. Mobile responsiveness (Priority 1) — directly impacts conversion on 50%+ of traffic
2. Visual polish (Priority 2) — trust signals and visual hierarchy drive sign-up confidence
3. Social template refinement (Priority 3) — launch week content quality

---

*Created by: UXDesigner agent*  
*Last updated: April 23, 2026*