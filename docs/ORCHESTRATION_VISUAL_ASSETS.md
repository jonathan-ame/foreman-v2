# Orchestration Platform Visual Assets

**Date:** April 24, 2026
**Task:** FORA-147 — Create orchestration platform visual assets for marketing site
**Status:** Ready for CMO/CTO review
**Parent:** FORA-146 → FORA-133 (Marketing and positioning for agent orchestration platform)

---

## Asset Inventory

### 1. Chief of Staff Flow Diagram

**File:** `backend/web/public/orchestration-flow.svg`
**Dimensions:** 960×420px (viewBox), responsive via CSS `width: 100%`
**Placement:** Homepage, `.section-orchestration` (between hero and "Built for four moments")
**Code Reference:** `backend/web/src/pages/marketing/Home.tsx` lines 34–69

**Flow Steps:**
| # | Label | Color | Description |
|---|-------|-------|-------------|
| 1 | You Describe | Blue (#2563eb) | Natural language request — "I need a blog post about our new feature" |
| 2 | Chief of Staff | Teal (#0d9488) | Auto-coordinated — assigns the right agent & creates a plan |
| 3 | You Approve | Amber (#f59e0b) | Full oversight — review the plan card & give sign-off |
| 4 | Agent Executes | Blue (#2563eb) | Hands-off delivery — assigned agent does the work autonomously |
| 5 | In Your Inbox | Teal (#0d9488) | Results, decisions & sign-offs in one place |

**Legend Bar:** Color-coded legend at base of SVG (You / Chief of Staff / Approval Gate / Agent Work / Inbox Results)

**Annotation Box:** "You talk to one point of contact. Foreman handles the rest." — reinforces the orchestration value prop.

**Design Tokens:**
- Card radius: 14px
- Card shadow: `feDropShadow dx=0 dy=2 stdDeviation=4 flood-opacity=0.08`
- Header gradient: Blue `#2563eb→#1d4ed8`, Teal `#0d9488→#0f766e`, Amber `#f59e0b→#d97706`
- Step number badges: Semi-transparent white circles on gradient headers
- Arrow style: Dashed lines with arrowhead markers (Blue and Teal)
- Font: Inter, system-ui, -apple-system, sans-serif

### 2. Homepage Section Implementation

**Code Reference:** `backend/web/src/pages/marketing/Home.tsx` lines 34–69
**CSS Reference:** `backend/web/src/style.css` lines 559–624

**Section Structure:**
```
section.section-orchestration
  h2 "Delegate to AI the Way You Delegate to People"
  p  "Describe what you need. Foreman assigns the right agent..."
  div.orchestration-diagram
    img[orchestration-flow.svg]
  div.orchestration-value-props
    div.orchestration-value 🎯 One Point of Contact
    div.orchestration-value ✅ Approval Before Action
    div.orchestration-value 📥 Unified Inbox
```

**Value Prop Cards:**

| Icon | Title | Copy | Maps to |
|------|-------|------|---------|
| 🎯 | One Point of Contact | Your Chief of Staff agent coordinates everything — no juggling multiple tools | Value Pillar 1: Chief of Staff Coordination |
| ✅ | Approval Before Action | Review every plan before it runs. AI without oversight is a liability | Value Pillar 2: Plan-Card Approval Flow |
| 📥 | Unified Inbox | All agent decisions, completed tasks, and sign-offs in one place | Value Pillar 3: Unified Inbox |

### 3. Social Media Marketing Visuals

**Directory:** `backend/web/public/social/linkedin/`

Existing 7-day LinkedIn launch sequence with pre/post templates:
- `day1-problem-awareness.svg` through `day7-before-after.svg`
- `template-quote.svg`, `template-metrics.svg`, `template-general.svg`
- `launch-announcement.svg`

**Note:** All social templates use the same Inter font family and brand palette (Blue #2563eb, Teal #0d9488, Amber #f59e0b). The orchestration flow diagram can be adapted into a 1080×1080 social format for Day 3 (AI for Business) or a dedicated orchestration post.

---

## Brand Kit Alignment

### Color Palette (Design System Tokens)

| Token | Hex | Usage | Context |
|-------|-----|-------|---------|
| Primary Blue | `#2563eb` | Brand primary, "You" actions, CTAs | Tailwind blue-600 |
| Primary Blue Dark | `#1d4ed8` | Blue gradient end, hover states | Tailwind blue-700 |
| Teal | `#0d9488` | Chief of Staff, Inbox, coordination | Tailwind teal-600 |
| Teal Dark | `#0f766e` | Teal gradient end, hover states | Tailwind teal-700 |
| Amber | `#f59e0b` | Approval gate, decision moments | Tailwind amber-500 |
| Amber Dark | `#d97706` | Amber gradient end, hover states | Tailwind amber-600 |
| Neutral Dark | `#1c2733` | Headlines, body text | Foreman brand slate |
| Neutral Mid | `#64748b` | Subtitles, captions, card labels | Tailwind slate-500 |
| Neutral Light BG | `#f8fafc` | Card backgrounds, section fills | Tailwind slate-50 |
| Border Light | `#e2e8f0` | Card borders, dividers | Tailwind slate-200 |
| Blue Light BG | `#eff6ff` | Icon backgrounds, highlights | Tailwind blue-50 |

### Typography

| Element | Font | Size | Weight |
|---------|------|------|--------|
| SVG Title | Inter | 20px | 800 (extra-bold) |
| SVG Subtitle | Inter | 13px | 400 (regular) |
| Section Heading | Inter | 28px | 700 (bold) |
| Value Prop Title | Inter | 15px | 700 (bold) |
| Value Prop Body | Inter | 14px | 400 (regular) |
| SVG Caption | Inter | 9px | 400 (regular) |

### Spacing & Layout

| Component | Value |
|-----------|-------|
| Section padding | 72px vertical |
| Content max-width | 960px (SVG), 1200px (cards) |
| Value prop grid gap | 24px |
| Value prop card padding | 20px |
| Card border radius | 12px |
| SVG card border radius | 14px |
| Icon container | 40×40px, border-radius 10px |

### Interaction States

| State | Effect |
|-------|--------|
| Value card hover | `translateY(-2px)`, `box-shadow: 0 8px 24px rgba(0,0,0,0.08)` |
| Transition | `transform 0.2s, box-shadow 0.2s` |

### Alignment with Existing Patterns

| New Component | Existing Pattern | Consistency |
|----------------|------------------|-------------|
| `.orchestration-value` | `.proof-card` | Same hover pattern, border radius, padding |
| `.orchestration-diagram-img` | `.blog-header-img` | Full-width responsive images |
| SVG card style | Marketing card patterns | Same shadow, radius, font stack |
| Color tokens | Tailwind + Foreman brand | Directly maps to Tailwind utilities |

---

## Implementation Priority Matrix

| Asset | Priority | Status | Notes |
|-------|----------|--------|-------|
| Orchestration flow SVG | P0 (launch blocker) | ✅ Done | `public/orchestration-flow.svg` |
| Homepage orchestra section | P0 (launch blocker) | ✅ Done | `Home.tsx` lines 34–69 |
| CSS orchestration styles | P0 (launch blocker) | ✅ Done | `style.css` lines 559–624 |
| Brand kit / design tokens doc | P1 (launch week) | ✅ Done | This document |
| Social visual (orchestration) | P2 (post-launch) | 📋 Backlog | Adapt SVG to 1080×1080 LinkedIn format |
| Email sequence visual | P2 (post-launch) | 📋 Backlog | Add flow diagram to welcome email |
| Comparison page visual | P3 (post-launch) | 📋 Backlog | Foreman vs. LangChain/Zapier visual |

---

## File Manifest

```
backend/web/public/orchestration-flow.svg     — 5-step orchestration flow diagram (SVG)
backend/web/src/pages/marketing/Home.tsx      — Homepage with orchestra section
backend/web/src/style.css                     — All orchestration CSS classes
docs/ORCHESTRATION_VISUAL_ASSETS.md           — This document
ORCHESTRATION_PLATFORM_POSITIONING.md         — Positioning source (CMO)
BRAND_VOICE_GUIDELINES.md                    — Brand voice reference (CMO)
```