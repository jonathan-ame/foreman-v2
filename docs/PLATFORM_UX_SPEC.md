# Foreman Platform UX and Interface Design Spec

**Issue**: FORA-115
**Parent**: FORA-113 — Foreman platform development
**Target audience**: Non-technical business users who don't spend time setting up agent workflows on their own
**Date**: 2026-04-23

---

## 1. Design Principles

1. **Progressive disclosure** — Show only what's needed at each step. Never overwhelm.
2. **Smart defaults** — Every choice has a recommended option pre-selected. Users can accept defaults and be done fast.
3. **Plain language** — No jargon (no "API key", "OpenRouter", "model tier"). Business users don't know or care about these terms.
4. **Confidence through clarity** — Explain what happens next, what each option means for their business, and how much it costs.
5. **Zero-friction path** — The fastest path from signup to a working agent should be under 90 seconds with OAuth.

---

## 2. Signup/Login Redesign

### Current Issues
- Auth page is functionally fine but lacks brand warmth and trust signals
- No social proof or value proposition on the auth screen
- Forgot password route doesn't exist yet

### Changes

#### 2.1 Split-screen Auth Layout
- **Left panel** (hidden on mobile): Brand illustration with tagline, key value props, and a rotating testimonial
- **Right panel**: Auth form (current functionality preserved)

#### 2.2 Trust Enhancements
- Add "14-day free trial • No credit card required" below the Foreman logo
- Add small lock icon next to "Sign in" button
- Show password strength indicator on signup (color bar: red → yellow → green)

#### 2.3 Forgot Password Flow
- Add `/forgot-password` route in App.tsx
- Simple form: email input → "Send reset link" → confirmation screen
- Backend: `POST /api/internal/auth/forgot-password` (placeholder — can work with existing session system)

#### 2.4 Mobile Optimization
- On ≤640px: hide left panel, show compact logo at top
- Ensure touch targets ≥44px on all buttons
- OAuth buttons stack vertically on mobile

---

## 3. Onboarding Wizard Improvements

### Current Issues
- "API key" terminology is confusing for non-technical users
- BYOK step feels like a developer feature forced onto business users
- No explanation of what the model choice means in practical terms
- The review step doesn't build confidence about what comes next

### Changes

#### 3.1 Step: Model Selection — Rewrite Copy
**Before**: "How capable should your agent be?" with "Efficient / Smart / Frontier"
**After**: "How smart should your agent be?" with:

| Option | Title | Description | Price hint |
|--------|-------|-------------|------------|
| Standard | Good for simple tasks | Open-source models, lowest cost | Included in all plans |
| Smart (Recommended) | Best balance of speed and smarts | Mixes models for quality and cost | Small usage surcharge |
| Premium | Top reasoning, best for complex work | Most advanced models available | Higher usage cost |

#### 3.2 Step: API Key — Rename and De-emphasize
**Before**: "How should your agent access AI models?" with technical "Use Foreman's key / Bring my own OpenRouter key"
**After**: "How would you like to connect?" with:

| Option | Title | Description |
|--------|-------|-------------|
| Simple setup (Recommended) | We handle everything — just start using your agent | Includes a small usage fee in your plan |
| Advanced: Use your own key | Lower cost if you already have an API key from OpenRouter | You manage your own key and costs |

When "Advanced" is selected, show a collapsible explanation:
> "This option is for users who already have an OpenRouter API key. If you're not sure, choose Simple setup — you can always switch later in Settings."

#### 3.3 BYOK Available in All Plans
The pricing page currently lists BYOK only in the Scale ($199/mo) tier. Per CEO requirement:
- **BYOK should be available in all pricing tiers** (Starter, Growth, Scale)
- Update `Pricing.tsx` to move "BYOK (bring your own keys)" from Scale-only to all tiers
- Keep the pricing page description accurate: "Use your own keys to reduce costs" — available on every plan

#### 3.4 Review Step — Confidence Builder
Add a "What happens next" section below the summary:

```
After you click Launch:
1. Your agent is created and starts running immediately
2. You can chat with it from your dashboard
3. Give it any task — it will work on it and ask for your approval on important decisions
```

#### 3.5 Success Screen — First Task Prompt Enhancement
- Pre-populate suggested first tasks based on role selection:
  - Company leadership: "Review our current strategy and suggest priorities for this quarter"
  - Project management: "Create a project plan for our next product launch"
  - Writing & content: "Draft a blog post about our product"
  - Engineering support: "Review our codebase and identify the top 3 areas for improvement"
  - General assistant: "Help me organize my tasks for this week"
- Show 2-3 clickable suggestion chips below the textarea

---

## 4. Post-Onboarding: First-Time Dashboard Experience

### 4.1 Dashboard Welcome Banner
For first-time users (no previous chat messages), show a dismissible welcome banner:

```
Welcome to Foreman! Your agent [name] is ready.
Try asking it something from the suggestions below, or type your own task.
```

With 3 clickable suggestion chips that match the role-based suggestions from the wizard.

### 4.2 Empty State for Team Page
Current: "Your CEO hasn't hired any agents yet."
Improved: "Grow your team — ask your Chief of Staff to hire agents for specific roles like marketing, engineering, or design."

With a "Suggest a hire" button that opens a pre-filled chat message to the Chief of Staff.

---

## 5. Design Tokens and Component System

To ensure consistency as the platform grows, establish these design tokens in `style.css`:

### 5.1 Color Tokens
```css
:root {
  /* Primary */
  --color-primary: #2563eb;
  --color-primary-hover: #1d4ed8;
  --color-primary-light: #eff6ff;
  
  /* Surfaces */
  --color-surface: #ffffff;
  --color-surface-raised: #f8fafc;
  --color-surface-overlay: #f1f5f9;
  --color-background: #f5f7fb;
  
  /* Text */
  --color-text-primary: #1c2733;
  --color-text-secondary: #64748b;
  --color-text-muted: #94a3b8;
  --color-text-inverse: #ffffff;
  
  /* Feedback */
  --color-success: #16a34a;
  --color-success-light: #f0fdf4;
  --color-error: #dc2626;
  --color-error-light: #fef2f2;
  --color-warning: #d97706;
  --color-warning-light: #fffbeb;
  
  /* Borders */
  --color-border: #e2e8f0;
  --color-border-hover: #cbd5e1;
}
```

### 5.2 Spacing Scale
```css
:root {
  --space-1: 4px;
  --space-2: 8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-5: 20px;
  --space-6: 24px;
  --space-8: 32px;
  --space-10: 40px;
  --space-12: 48px;
}
```

### 5.3 Typography Scale
```css
:root {
  --text-xs: 0.75rem;    /* 12px */
  --text-sm: 0.875rem;    /* 14px */
  --text-base: 1rem;      /* 16px */
  --text-lg: 1.125rem;    /* 18px */
  --text-xl: 1.25rem;     /* 20px */
  --text-2xl: 1.5rem;     /* 24px */
  --text-3xl: 1.875rem;   /* 30px */
  --text-4xl: 2.25rem;    /* 36px */
}
```

### 5.4 Border Radius
```css
:root {
  --radius-sm: 6px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-full: 9999px;
}
```

---

## 6. Accessibility Requirements

- All interactive elements have visible focus rings (2px solid var(--color-primary) with 2px offset)
- Color contrast ratio ≥ 4.5:1 for all text (WCAG AA)
- Touch targets ≥ 44x44px on mobile
- Screen reader labels on all form inputs, buttons, and interactive elements
- Error messages associated with inputs via `aria-describedby`
- No information conveyed by color alone
- Keyboard navigation works for all wizard steps and dashboard pages

---

## 7. Responsive Breakpoints

| Breakpoint | Target |
|-----------|--------|
| ≤480px | Small phones |
| 481–640px | Large phones |
| 641–768px | Tablets (portrait) |
| 769–1024px | Tablets (landscape) / small laptops |
| ≥1025px | Desktop |

---

## 8. Implementation Priority

| Priority | Item | Impact | Effort |
|----------|------|--------|--------|
| P0 | Pricing page: BYOK in all tiers | Business-critical | Low |
| P0 | Wizard copy: rename API key step, model step | User confusion | Low |
| P1 | Design tokens in style.css | Foundation | Medium |
| P1 | First-task suggestions in wizard | Activation rate | Medium |
| P1 | "What happens next" in review step | Confidence | Low |
| P2 | Forgot password flow | Support burden | Medium |
| P2 | Dashboard welcome banner + suggestions | Activation | Medium |
| P2 | Team page empty state improvement | Engagement | Low |
| P3 | Split-screen auth layout | Brand polish | High |