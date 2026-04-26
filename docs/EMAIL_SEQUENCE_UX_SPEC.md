# Email Sequence UI/UX Specification

**Issue**: [FORA-105](/FORA/issues/FORA-105)
**Parent**: [FORA-87](/FORA/issues/FORA-87)
**Author**: UXDesigner
**Date**: 2026-04-23

---

## Overview

This document specifies the user interface and experience design for Foreman's waitlist email sequence flow. The technical backend is complete ([FORA-92](/FORA/issues/FORA-92)), including subscriber management, preference/unsubscribe API, and the 12-email launch sequence job. This spec covers the frontend UX layer that ties those capabilities together.

---

## 1. Waitlist Confirmation Experience

### Current State
The `EmailCaptureForm` component shows a generic "You're in!" message after subscription. The `Contact` page shows a generic "Thank you for your interest!" message. Neither provides personalized post-subscription guidance.

### Proposed Enhancement: Waitlist Confirmation Screen

After successful subscription, display a rich confirmation experience with:

**Layout** (on success state of `EmailCaptureForm`):
```
┌──────────────────────────────────────────────┐
│  ✓ You're on the list!                        │
│                                               │
│  Hi {First Name},                             │
│  You're #{position} on the waitlist.          │
│                                               │
│  ┌─────────────────────────────────────┐      │
│  │  WHAT'S NEXT                         │      │
│  │                                      │      │
│  │  📧 Day -3  Teaser & early access    │      │
│  │  📧 Day -1  Last chance reminder     │      │
│  │  🚀 Day 0   Launch + early link      │      │
│  │  📧 Day 1-7 Feature deep dives       │      │
│  └─────────────────────────────────────┘      │
│                                               │
│  ┌─ Share & move up ─────────────────────┐     │
│  │ Share your unique referral link to    │     │
│  │ move up the waitlist:                 │     │
│  │                                       │     │
│  │ foreman.company/?ref={token}    [Copy]│     │
│  └───────────────────────────────────────┘     │
│                                               │
│  [Manage email preferences]                   │
│                                               │
└──────────────────────────────────────────────┘
```

**Implementation Notes**:
- Extend the `success` state in `EmailCaptureForm.tsx` with segment-aware content
- The subscription API already returns `unsubscribe_token` — use it to build the preferences link: `/unsubscribe?email={email}&token={token}`
- Waitlist position is not currently tracked; display a relative indicator ("Early access subscriber") instead of exact position unless backend support is added
- The referral link feature requires a new `referral_token` column on `email_subscribers`; this is optional and can be deferred post-launch

### Segment-Specific Confirmation Messages

| Segment | Source | Confirmation Headline | Confirmation Detail |
|---------|--------|-----------------------|-------------------|
| Solopreneur | Homepage waitlist | "Your AI co-pilot is coming" | "We'll show you how Foreman handles the busywork so you can focus on what matters." |
| Small Team | Homepage "New team" CTA | "Your AI team member is on the way" | "Foreman extends your capacity without the overhead of another hire." |
| Enterprise | Contact form | "Your enterprise evaluation starts now" | "We'll send architecture details and scheduling options for a demo." |
| Technical | Contact form | "Integration details incoming" | "API docs, SDK examples, and deployment guides are in your future inbox." |

---

## 2. Email Preferences Page Enhancement

### Current State
`/unsubscribe` route renders `EmailPreferences.tsx` with:
- Email lookup form (no token)
- Token-authenticated preference toggles (4 categories)
- Unsubscribe-all / resubscribe actions
- "What you'll receive" timeline preview

### Design Issues Identified

1. **Page title says "unsubscribe" but the page does more** — the route `/unsubscribe` is confusing when users just want to change preferences
2. **No visual confirmation after saving preferences** — the save button changes text but there's no toast/inline success message
3. **Timeline preview is static** — doesn't reflect the user's actual segment or current preferences
4. **Mobile layout cramped** — toggle labels and action buttons need more spacing at 320-375px
5. **No link from email footer to this page** — the email sequence includes `?email=x&token=y` links but the page doesn't explain why they're there

### Proposed Enhancements

#### 2a. Dual-route access
- Add `/preferences` as an alias for `/unsubscribe` (existing route still works)
- Update `App.tsx` routing to include both paths
- Show different page titles based on context:
  - If user arrived from email link (has token): "Your email preferences"
  - If user searched by email only: "Manage your email settings"

#### 2b. Save confirmation toast
After successful preference save, show an inline success banner:

```
┌──────────────────────────────────────────┐
│ ✓ Preferences saved                       │
│   Your updates will take effect on the    │
│   next email.                             │
└──────────────────────────────────────────┘
```

- Auto-dismiss after 5 seconds
- Use role="status" for accessibility

#### 2c. Active-preference timeline
Dim timeline items the user has opted out of:

```
  ● Pre-launch  — Launch countdown & early access     [dimmed if launch_updates=false]
  ● Launch day  — Early access link + case study      [dimmed if launch_updates=false]
  ● Day 1-3    — Check-in & results                  [dimmed if product_news=false]
  ● Day 5-7    — Feature deep dives                   [dimmed if tips_resources=false]
  ● Day 10-14  — Last call & re-engagement            [dimmed if community=false]
```

#### 2d. Mobile spacing fix
- Increase `.email-pref-toggle` padding from `10px 14px` to `14px 16px` on viewports < 480px
- Stack `.email-pref-actions` buttons vertically below 480px
- Ensure touch targets are at least 44x44px (WCAG 2.5.5)

---

## 3. User Journey: Waitlist Subscriber Flow

### Complete User Flow Diagram

```
                    ┌─────────┐
                    │  Visit  │
                    │  Site   │
                    └────┬────┘
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
         ┌────────┐ ┌────────┐ ┌────────┐
         │Homepage│ │ Blog   │ │Contact │
         │ CTA    │ │ Post   │ │ Form   │
         └───┬────┘ └───┬────┘ └───┬────┘
             │          │          │
             └──────────┼──────────┘
                        ▼
               ┌─────────────────┐
               │  Email Capture  │
               │  Form Submitted │
               └────────┬────────┘
                        │
                        ▼
               ┌─────────────────┐
               │   POST          │
               │  /api/marketing │
               │  /subscribe     │
               └────────┬────────┘
                        │
              ┌─────────┼─────────┐
              ▼                   ▼
        ┌───────────┐      ┌───────────┐
        │  Success  │      │  Error    │
        │  Screen   │      │  Message  │
        │  +Preview │      │  +Retry   │
        └─────┬─────┘      └───────────┘
              │
              ▼
    ┌──────────────────┐
    │  Segment         │
    │  Classification  │
    │  (A/B/C)         │
    └────────┬─────────┘
             │
    ┌────────┼────────────────────────┐
    ▼        ▼                        ▼
Segment A  Segment B              Segment C
(12 emails) (8 emails)            (4 emails)
    │        │                        │
    ▼        ▼                        ▼
 ┌──────────────────────────────────────────┐
 │         Email Sequence Delivery           │
 │                                          │
 │  P1: Teaser (-3d)    → only A, B         │
 │  P2: Last Chance (-1d) → only A, B      │
 │  P3: Early Access (day 0 6AM) → A, B    │
 │  L1: Launch (day 0 9AM) → A, B, C       │
 │  L2: Case Study (day 0 noon) → A, B     │
 │  L3: Urgency (day 0 6PM) → A, B         │
 │  F1-F6: Follow-ups (day 1-14) → A only  │
 └──────────────────────────────────────────┘
              │
              ▼
    ┌─────────────────┐
    │  Email footer   │
    │  links to:      │
    │                 │
    │  /unsubscribe   │
    │  ?email=&token= │
    └────────┬────────┘
             │
    ┌────────┼──────────────┐
    ▼        ▼              ▼
┌──────┐ ┌──────────┐ ┌──────────┐
│Update│ │Unsubscribe│ │Resubscribe│
│Prefs │ │   All     │ │          │
└──────┘ └──────────┘ └──────────┘
```

### Key Touchpoints

| Touchpoint | Location | User Action | System Response |
|------------|----------|-------------|-----------------|
| Homepage waitlist CTA | Home hero + section-email-capture | Enter email, click "Join the waitlist" | POST /api/marketing/subscribe → success screen with sequence preview |
| Blog sidebar capture | Blog pages | Enter email, click "Subscribe" | POST /api/marketing/subscribe (source=blog) → inline success |
| Contact form | /contact | Fill form + use case dropdown | POST /api/marketing/subscribe (source=contact) → success with segment detail |
| Email preferences | /unsubscribe?email=x&token=y | Toggle prefs, save | PATCH /api/marketing/preferences → confirmation toast |
| Email unsubscribe | Email footer "Unsubscribe" link | Click link | Loads /unsubscribe → one-click unsubscribe-all or manage |
| Email resubscribe | /unsubscribe (unsubscribed state) | Click "Resubscribe to all emails" | POST /api/marketing/resubscribe → reload with active prefs |

---

## 4. Implementation-Ready Design Components

### 4a. Waitlist Confirmation Component

Add to `EmailCaptureForm.tsx` success state:

```tsx
// Props to add to EmailCaptureForm
interface EmailCaptureFormProps {
  // ... existing props
  confirmationVariant?: "default" | "solopreneur" | "small_team" | "enterprise" | "technical";
  unsubscribeToken?: string;
}
```

**Confirmation styles** (add to `style.css`):

```css
.email-capture-confirmation {
  text-align: center;
  padding: 32px 24px;
}

.email-capture-confirmation-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: #ecfdf5;
  color: #059669;
  font-size: 24px;
  margin-bottom: 16px;
}

.email-capture-confirmation-headline {
  font-size: 24px;
  font-weight: 700;
  margin: 0 0 8px;
  color: #1c2733;
}

.email-capture-confirmation-detail {
  color: #4b5563;
  margin: 0 0 24px;
  max-width: 400px;
  margin-left: auto;
  margin-right: auto;
}

.email-capture-next-steps {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 20px;
  margin: 0 auto 24px;
  max-width: 380px;
  text-align: left;
}

.email-capture-next-steps h4 {
  font-size: 13px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #6b7280;
  margin: 0 0 12px;
}

.email-capture-next-step-item {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 8px 0;
  font-size: 14px;
  color: #374151;
}

.email-capture-next-step-icon {
  flex-shrink: 0;
  width: 20px;
  text-align: center;
}

.email-capture-next-step-text strong {
  display: block;
  color: #1c2733;
}

.email-capture-next-step-text span {
  color: #6b7280;
  font-size: 13px;
}

.email-capture-prefs-link {
  display: inline-block;
  font-size: 13px;
  color: #6b7280;
  margin-top: 8px;
}

.email-capture-prefs-link a {
  color: #2563eb;
  text-decoration: underline;
}

/* Mobile */
@media (max-width: 480px) {
  .email-capture-confirmation {
    padding: 24px 16px;
  }
  .email-capture-next-steps {
    padding: 16px;
  }
}
```

### 4b. Preference Save Toast

Add to `EmailPreferences.tsx`:

```tsx
// State addition
const [saveSuccess, setSaveSuccess] = useState(false);

// After successful save in handleSavePreferences:
setSaveSuccess(true);
setTimeout(() => setSaveSuccess(false), 5000);
```

**Toast styles**:

```css
.email-pref-save-toast {
  position: fixed;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%);
  background: #059669;
  color: white;
  padding: 12px 24px;
  border-radius: 8px;
  font-size: 14px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  z-index: 1000;
  animation: toast-slide-up 0.3s ease-out;
}

@keyframes toast-slide-up {
  from {
    opacity: 0;
    transform: translateX(-50%) translateY(16px);
  }
  to {
    opacity: 1;
    transform: translateX(-50%) translateY(0);
  }
}
```

### 4c. Active-preference Timeline (dimmed inactive items)

Update the timeline section in `EmailPreferences.tsx` to conditionally apply an `inactive` class:

```tsx
// Updated timeline item with preference awareness
<div
  className={`email-pref-timeline-item ${
    !isPreferenceActive(key) ? "email-pref-timeline-item--inactive" : ""
  }`}
>
```

**Inactive timeline styles**:

```css
.email-pref-timeline-item--inactive {
  opacity: 0.45;
}

.email-pref-timeline-item--inactive .email-pref-timeline-badge {
  background: #e5e7eb;
  color: #9ca3af;
}

.email-pref-timeline-item--inactive p {
  color: #9ca3af;
}
```

### 4d. Mobile Responsiveness Fixes

```css
@media (max-width: 480px) {
  .email-pref-toggle {
    padding: 14px 16px;
    min-height: 44px;
  }

  .email-pref-actions {
    flex-direction: column;
    gap: 12px;
  }

  .email-pref-actions .button-primary,
  .email-pref-actions .button-ghost {
    width: 100%;
    min-height: 44px;
  }

  .email-pref-card {
    padding: 16px;
  }

  .email-pref-timeline-item {
    padding: 12px 0;
  }
}
```

---

## 5. Email-to-Web Transition Design

### Unsubscribe Link in Emails

The launch email sequence (`launch-email-sequence.ts`) builds HTML emails with an unsubscribe footer. The links use format:
```
https://foreman.company/unsubscribe?email={email}&token={unsubscribe_token}
```

**Landing experience flow**:
1. User clicks unsubscribe link in email
2. Lands on `/unsubscribe?email=x&token=y`
3. `EmailPreferences.tsx` auto-loads preferences via `GET /api/marketing/preferences?email=x&token=y`
4. User sees their full preference panel (authenticated by token)
5. Two primary actions:
   - **Quick unsubscribe**: One-click "Unsubscribe from all" button (prominent, satisfies CAN-SPAM)
   - **Granular control**: Toggle individual categories and save

**Design principle**: The unsubscribe action must be easy and prominent (legal requirement). Granular preferences are the secondary option for users who want to reduce email volume without fully unsubscribing.

### One-Click Unsubscribe UX

When a user arrives from an email link with a valid token, the page should:
1. Immediately load their preferences (current behavior — good)
2. Show the "Unsubscribe from all" button prominently at the top of the actions area
3. Below it, offer "Or manage individual preferences" as a less prominent option
4. After unsubscribing, show clear confirmation with resubscribe option

---

## 6. Accessibility Requirements

| Element | Requirement | WCAG Level |
|---------|-------------|------------|
| Email input fields | Labels visible, `aria-label` on inputs | 2.1 AA |
| Toggle checkboxes | `aria-describedby` for preference labels | 2.1 AA |
| Buttons | Minimum 44x44px touch target | 2.5.5 AA |
| Save toast | `role="status"`, no `alert` (prevents screen reader interruption) | 4.1 AA |
| Error messages | `role="alert"` on error text | 4.1 AA |
| Color contrast | All text meets 4.5:1 ratio against backgrounds | 1.4.3 AA |
| Focus indicators | Visible focus rings on all interactive elements | 2.4.7 AA |
| Skip link | Already present in MarketingLayout | 2.4.1 A |

---

## 7. Design Tokens Reference

Tokens used across email sequence UI components:

| Token | Value | Usage |
|-------|-------|-------|
| `--color-primary` | `#2563eb` | CTA buttons, links |
| `--color-primary-hover` | `#1d4ed8` | Button hover state |
| `--color-success` | `#059669` | Success states, confirmation badges |
| `--color-success-bg` | `#ecfdf5` | Confirmation badge backgrounds |
| `--color-text-primary` | `#1c2733` | Headings, primary text |
| `--color-text-secondary` | `#4b5563` | Body text, descriptions |
| `--color-text-muted` | `#6b7280` | Captions, helper text |
| `--color-surface` | `#ffffff` | Card backgrounds |
| `--color-border` | `#e2e8f0` | Card borders, dividers |
| `--color-surface-alt` | `#f8fafc` | Next-steps card background |
| `--radius-sm` | `8px` | Buttons, inputs |
| `--radius-md` | `12px` | Cards |
| `--radius-lg` | `14px` | Panels |
| `--radius-full` | `50%` | Confirmation badges |
| `--shadow-card` | `0 1px 3px rgba(0,0,0,0.1)` | Cards |
| `--shadow-toast` | `0 4px 12px rgba(0,0,0,0.15)` | Toast notifications |
| `--font-size-sm` | `13px` | Captions, helper text |
| `--font-size-base` | `14px` | Body text |
| `--font-size-lg` | `16px` | Subtitles |
| `--font-size-xl` | `24px` | Page headings |
| `--spacing-xs` | `8px` | Tight spacing |
| `--spacing-sm` | `12px` | Standard gap |
| `--spacing-md` | `16px` | Component padding |
| `--spacing-lg` | `24px` | Section padding |
| `--spacing-xl` | `32px` | Large section padding |

---

## 8. Implementation Priority

| Priority | Component | Effort | Dependency |
|----------|-----------|-------|------------|
| 1 (Critical) | Mobile responsive fixes for email preferences | 2h | None |
| 2 (High) | Save confirmation toast | 1h | None |
| 3 (High) | Active-preference timeline (dimming) | 2h | None |
| 4 (High) | `/preferences` route alias | 0.5h | None |
| 5 (Medium) | Waitlist confirmation screen enhancement | 4h | Needs `unsubscribe_token` from subscribe response (already available) |
| 6 (Medium) | Segment-specific confirmation messages | 3h | Needs `useCase` mapping in EmailCaptureForm |
| 7 (Low) | Referral link display (deferred) | 2h | Needs backend `referral_token` column |

**Total estimated effort**: 14.5 hours
**Post-launch deferrals**: Item 7 (referral links)

---

## 9. Files to Modify

| File | Change |
|------|--------|
| `backend/web/src/components/EmailCaptureForm.tsx` | Add enhanced confirmation screen, segment-aware messaging |
| `backend/web/src/pages/marketing/EmailPreferences.tsx` | Add save toast, active-preference timeline, mobile fixes |
| `backend/web/src/App.tsx` | Add `/preferences` route alias |
| `backend/web/src/style.css` | Add confirmation, toast, timeline, mobile responsive styles |