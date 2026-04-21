# Analytics Implementation Specification (FORA-32)

## Overview
Implement analytics tracking for marketing website to measure conversion rates, user behavior, and campaign performance.

## Required Tracking

### 1. Page Views
Track all page views on marketing website:
- Homepage (`/`)
- Pricing (`/pricing`)
- How It Works (`/how-it-works`)
- About (`/about`)
- Contact (`/contact`)
- Blog (`/blog`)
- Legal pages (Privacy, Terms, etc.)

### 2. Conversion Events
**Primary Conversion:** Visitor → Signup
- Event: `signup_started` (when user clicks "Start 14-Day Free Trial" or "Get Started")
- Event: `signup_completed` (when user successfully creates account)
- Properties: `source` (which page/button), `tier_selected` (if applicable)

**Secondary Conversions:**
- Event: `pricing_viewed` (when user views pricing page)
- Event: `how_it_works_viewed` (when user views how it works page)
- Event: `contact_clicked` (when user clicks contact link)
- Event: `blog_viewed` (when user views blog)

### 3. User Journey Tracking
- Session duration and pages per session
- Path analysis (common navigation paths)
- Exit pages (where users leave)
- Scroll depth (percentage of page viewed)
- Time on page for key pages

### 4. Campaign Tracking
- UTM parameter capture (source, medium, campaign, term, content)
- Referrer tracking
- Landing page performance

## Implementation Requirements

### Analytics Platform
**Primary:** Google Analytics 4 (GA4)
**Secondary:** Segment.com (if available)
**Backup:** Custom event logging to our database

### GA4 Implementation:
```javascript
// Example GA4 event tracking
gtag('event', 'signup_started', {
  'page_location': window.location.href,
  'page_title': document.title,
  'button_text': 'Start 14-Day Free Trial',
  'page_path': '/'
});

// Page view tracking (should be automatic with GA4 setup)
```

### Required Tags/Events:
1. **GA4 Configuration Tag** - Standard GA4 setup
2. **Conversion Events** - Custom events for signup funnel
3. **Enhanced Ecommerce** - For pricing page engagement
4. **Scroll Tracking** - For content engagement measurement
5. **Form Tracking** - For contact form interactions

### Data Layer Requirements:
```javascript
window.dataLayer = window.dataLayer || [];
window.dataLayer.push({
  'event': 'signup_started',
  'user_properties': {
    'page_type': 'marketing',
    'user_type': 'visitor'
  },
  'event_properties': {
    'button_location': 'hero',
    'cta_text': 'Start 14-Day Free Trial'
  }
});
```

## Technical Implementation

### Files to Update:
1. `index.html` - Add GA4 script tag
2. React components - Add event tracking to buttons/links
3. Possibly create `analytics.ts` utility file

### Button Tracking Example:
```tsx
// In Home.tsx
const handleCtaClick = () => {
  // GA4 event
  if (window.gtag) {
    window.gtag('event', 'signup_started', {
      'page_location': window.location.href,
      'button_location': 'hero',
      'cta_text': 'Start 14-Day Free Trial'
    });
  }
  
  // Navigate to app
  window.location.href = '/app';
};

// Usage
<a href="/app" className="button-primary button-lg" onClick={handleCtaClick}>
```

### Page View Tracking:
Should be handled automatically by GA4 with proper router integration. May need to implement in React Router.

## Performance Requirements

### Load Time Impact:
- Analytics scripts must not block page render
- Use async/defer attributes
- Consider lazy loading for non-critical analytics

### Privacy Compliance:
- Must respect Do Not Track headers
- Must comply with GDPR/CCPA
- Cookie consent integration if needed
- Data anonymization where required

## Testing & Validation

### Pre-Launch Checklist:
- [ ] GA4 property created and configured
- [ ] All events firing correctly in GA4 debug view
- [ ] Conversion events properly tagged
- [ ] UTM parameters being captured
- [ ] Page views tracking correctly
- [ ] No console errors from analytics scripts
- [ ] Performance impact < 100ms

### Test Events to Verify:
1. Homepage CTA click → `signup_started` event
2. Pricing page view → `pricing_viewed` event  
3. Navigation between pages → page_view events
4. Scroll depth → engagement events

## Monitoring & Alerting

### Success Metrics to Monitor:
- **Conversion Rate:** > 5% visitor to signup
- **Event Volume:** Expected ~1000 events/day at launch
- **Data Quality:** < 1% missing or malformed events
- **Performance:** < 100ms added load time

### Alerting Setup:
- Monitor for sudden drop in event volume
- Alert if conversion rate drops below 2%
- Daily report of top converting pages
- Weekly funnel analysis

## Timeline & Dependencies

### Phase 1: Basic Implementation (Day 1)
1. GA4 script added to index.html
2. Basic page view tracking
3. Primary conversion event (signup_started)

### Phase 2: Enhanced Tracking (Day 2)
1. All conversion events implemented
2. User journey tracking
3. Campaign parameter capture

### Phase 3: Optimization (Day 3)
1. Performance optimization
2. Testing and validation
3. Documentation and handoff

### Dependencies:
1. **GA4 Property:** Need GA4 property ID
2. **Access:** Need access to GA4 console for configuration
3. **Approval:** CEO approval for tracking implementation
4. **Legal Review:** Privacy policy may need updates

## Next Steps

### Immediate Actions (Engineering):
1. Create GA4 property if not exists
2. Add GA4 script to index.html
3. Implement basic page view tracking
4. Add conversion event to primary CTA

### Follow-up Actions (CMO):
1. Configure GA4 goals and conversions
2. Set up dashboards and reports
3. Define baseline metrics
4. Create monitoring alerts

---
*Spec Created: 2026-04-20*  
*Owner: CMO*  
*Assigned To: Engineering Specialist*  
*Priority: High (Phase 1 of FORA-32)*  
*Due Date: EOD Tomorrow*