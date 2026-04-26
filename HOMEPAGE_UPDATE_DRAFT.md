# Homepage Update Draft (FORA-32)

## Current Homepage Content Analysis

### Current Hero Section:
```tsx
<h1 className="hero-headline">AI agents for the rest of us</h1>
<p className="hero-sub">
  Foreman gives solopreneurs and small teams a personal AI workforce — no code, no
  configuration, just results.
</p>
```

### Issues Identified:
1. Tagline is catchy but doesn't communicate value proposition
2. Subhead mentions "no code" but misses other core value pillars
3. No clear articulation of target customer or their problem
4. Missing trust signals and proof points

## Proposed Homepage Hero Update

### Based on Content Brief #1:

```tsx
<section className="hero">
  <div className="hero-inner">
    <h1 className="hero-headline">Your AI Team, Ready in Minutes</h1>
    <p className="hero-sub">
      For solopreneurs and small businesses who need AI agent capabilities but lack technical staff, 
      Foreman is the AI agent orchestration platform that provisions and manages your AI team.
    </p>
    
    <div className="hero-benefits">
      <div className="benefit">
        <span className="benefit-icon">⚡</span>
        <span className="benefit-text">No-code deployment</span>
      </div>
      <div className="benefit">
        <span className="benefit-icon">🛡️</span>
        <span className="benefit-text">Managed operations</span>
      </div>
      <div className="benefit">
        <span className="benefit-icon">📈</span>
        <span className="benefit-text">Scalable team structure</span>
      </div>
    </div>
    
    <div className="hero-cta">
      <a href="/app" className="button-primary button-lg">
        Start 14-Day Free Trial
      </a>
      <Link to="/how-it-works" className="button-ghost button-lg">
        See How It Works
      </Link>
    </div>
    
    <p className="hero-trust">
      <span className="trust-badge">No credit card required</span>
      <span className="trust-badge">SOC 2 compliant</span>
      <span className="trust-badge">GDPR ready</span>
    </p>
  </div>
</section>
```

## New Section: How Foreman Is Different

### To be added after hero, before "moments that matter":

```tsx
<section className="section-different">
  <div className="content-inner">
    <h2 className="section-heading">How Foreman Is Different</h2>
    <p className="section-sub">Built for business owners, not AI engineers</p>
    
    <div className="comparison-grid">
      <div className="comparison-card">
        <h3>Foreman</h3>
        <ul className="feature-list">
          <li>✅ No-code setup</li>
          <li>✅ Managed service</li>
          <li>✅ Business-focused</li>
          <li>✅ Under 5 min setup</li>
          <li>✅ Chief of Staff coordination</li>
        </ul>
      </div>
      
      <div className="comparison-card">
        <h3>LangChain / CrewAI</h3>
        <ul className="feature-list">
          <li>❌ Coding required</li>
          <li>❌ Self-managed</li>
          <li>❌ Developer-focused</li>
          <li>❌ Days-weeks, requires code</li>
          <li>❌ Code-based multi-agent only</li>
        </ul>
      </div>
      
      <div className="comparison-card">
        <h3>Zapier / n8n</h3>
        <ul className="feature-list">
          <li>❌ No coordination</li>
          <li>❌ Trigger-based only</li>
          <li>❌ Fragmented workflows</li>
          <li>✅ Easy setup</li>
          <li>❌ No agent orchestration</li>
        </ul>
      </div>

      <div className="comparison-card">
        <h3>Jasper / Copy.ai</h3>
        <ul className="feature-list">
          <li>❌ Single purpose only</li>
          <li>❌ No coordination</li>
          <li>❌ Content-only scope</li>
          <li>✅ Easy setup</li>
          <li>❌ No business workflows</li>
        </ul>
      </div>
    </div>
  </div>
</section>
```

## Updated "Moments That Matter" Section

### Current section is good but could be enhanced with clearer ICP targeting:

```tsx
<section className="section-triggers">
  <div className="content-inner">
    <h2 className="section-heading">Built for the moments that matter</h2>
    <p className="section-sub">Foreman solves specific problems for real businesses</p>
    
    <div className="cards-grid">
      <div className="card">
        <div className="card-icon">👨‍💼</div>
        <h3>For Solopreneurs</h3>
        <p>Swamped with operational tasks? Delegate to AI agents and focus on what only you can do.</p>
        <ul className="card-points">
          <li>Wearing too many hats</li>
          <li>Limited time for growth</li>
          <li>Can't afford full-time help</li>
        </ul>
      </div>
      
      <div className="card">
        <div className="card-icon">👥</div>
        <h3>For Small Teams</h3>
        <p>Need to scale without hiring? Extend your team's capacity with reliable AI agents.</p>
        <ul className="card-points">
          <li>Inconsistent quality</li>
          <li>Manual processes eat time</li>
          <li>Hard to find good help</li>
        </ul>
      </div>
      
      <div className="card">
        <div className="card-icon">💼</div>
        <h3>For Service Businesses</h3>
        <p>Project work overwhelming? Standardize delivery with AI-assisted workflows.</p>
        <ul className="card-points">
          <li>Client communication overhead</li>
          <li>Quality varies across projects</li>
          <li>Hard to scale capacity</li>
        </ul>
      </div>
    </div>
  </div>
</section>
```

## New Section: Proof Points

### To be added before final CTA:

```tsx
<section className="section-proof">
  <div className="content-inner">
    <h2 className="section-heading">Built for Business Reliability</h2>
    
    <div className="proof-grid">
      <div className="proof-card">
        <h3>Enterprise-Grade Foundation</h3>
        <p>Built on Paperclip, proven at scale for reliable agent orchestration.</p>
      </div>
      
      <div className="proof-card">
        <h3>Production-Ready Runtime</h3>
        <p>Powered by OpenClaw for consistent, high-quality execution.</p>
      </div>
      
      <div className="proof-card">
        <h3>Multi-Provider Flexibility</h3>
        <p>Works with all major AI models via OpenRouter ecosystem.</p>
      </div>
      
      <div className="proof-card">
        <h3>Cost Control Options</h3>
        <p>BYOK (Bring Your Own Key) to optimize expenses.</p>
      </div>
    </div>
  </div>
</section>
```

## Final CTA Section Update

### Update to match new messaging:

```tsx
<section className="section-cta">
  <div className="content-inner text-center">
    <h2>Start your AI workforce today</h2>
    <p>No credit card required for the 14-day free trial.</p>
    <a href="/app" className="button-primary button-lg">
      Create your first agent
    </a>
    <p className="cta-sub">Try Foreman free for 14 days • Cancel anytime</p>
  </div>
</section>
```

## CSS Additions Needed

```css
/* Hero benefits */
.hero-benefits {
  display: flex;
  gap: 20px;
  justify-content: center;
  margin: 24px 0;
  flex-wrap: wrap;
}

.benefit {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 16px;
}

.benefit-icon {
  font-size: 20px;
}

.hero-trust {
  display: flex;
  gap: 16px;
  justify-content: center;
  margin-top: 16px;
  font-size: 14px;
  color: #666;
}

.trust-badge {
  background: #f0f9ff;
  padding: 4px 12px;
  border-radius: 20px;
  border: 1px solid #e0f2fe;
}

/* Comparison grid */
.comparison-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 24px;
  margin-top: 32px;
}

.comparison-card {
  padding: 24px;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  background: white;
}

.feature-list {
  list-style: none;
  padding: 0;
  margin: 16px 0 0;
}

.feature-list li {
  padding: 8px 0;
  border-bottom: 1px solid #f1f5f9;
}

/* Proof points */
.proof-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-top: 32px;
}

.proof-card {
  padding: 20px;
  background: #f8fafc;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

/* Card enhancements */
.card-icon {
  font-size: 32px;
  margin-bottom: 16px;
}

.card-points {
  list-style: none;
  padding: 0;
  margin: 16px 0 0;
  font-size: 14px;
  color: #475569;
}

.card-points li {
  padding: 4px 0;
  position: relative;
  padding-left: 20px;
}

.card-points li:before {
  content: "•";
  position: absolute;
  left: 0;
  color: #3b82f6;
}
```

## Implementation Notes

1. **Priority Order:**
   - First: Hero section update (P0)
   - Second: Proof points section (P0)
   - Third: Comparison section (P1)
   - Fourth: Enhanced cards section (P1)

2. **Dependencies:**
   - CEO approval of messaging
   - Design review of new components
   - Engineering implementation time

3. **Testing Requirements:**
   - Mobile responsiveness of new components
   - Visual consistency with existing design
   - Performance impact assessment

---
*Draft Created: 2026-04-20*  
*Owner: CMO*  
*Status: Ready for CEO Review*  
*Next: Submit for approval, then implement*