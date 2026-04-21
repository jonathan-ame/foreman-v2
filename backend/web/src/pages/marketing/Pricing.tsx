import { Link } from "react-router-dom";

const tiers = [
  {
    name: "Starter",
    price: "$49",
    description: "Perfect for solopreneurs testing AI delegation.",
    idealFor: "Getting started with one focused agent",
    badge: null,
    features: [
      "1 AI agent",
      "Standard task throughput",
      "OpenRouter-powered (DeepSeek v3 + Qwen 2.5)",
      "Projects, Inbox, Settings",
      "Email support",
    ],
    cta: "Start free trial",
    highlight: false,
  },
  {
    name: "Growth",
    price: "$99",
    description: "Most popular for small teams with multiple needs.",
    idealFor: "Replaces $500+/month in freelance help",
    badge: "MOST POPULAR",
    features: [
      "Up to 5 AI agents",
      "Increased task throughput",
      "Chief of Staff with plan approval",
      "Team org chart view",
      "Priority support",
    ],
    cta: "Start free trial",
    highlight: true,
  },
  {
    name: "Scale",
    price: "$199",
    description: "For businesses ready for full AI workforce.",
    idealFor: "Alternative to $2,000+/month full-time hire",
    badge: null,
    features: [
      "Unlimited agents",
      "Maximum throughput",
      "Custom agent instructions",
      "Usage-based billing available",
      "BYOK (bring your own keys)",
      "Dedicated support",
    ],
    cta: "Start free trial",
    highlight: false,
  },
];

export function Pricing() {
  return (
    <>
      <section className="page-hero">
        <div className="content-inner text-center">
          <h1>Simple pricing that scales with your business</h1>
          <p>Start for less than your phone bill, scale as you grow. No long‑term contracts, cancel anytime.</p>
          <div className="page-hero-trust">
            <span className="trust-badge">14-day free trial</span>
            <span className="trust-badge">No credit card required</span>
            <span className="trust-badge">SOC 2 compliant</span>
          </div>
        </div>
      </section>

      <section className="pricing-grid-section">
        <div className="content-inner">
          <div className="pricing-grid">
            {tiers.map((tier) => (
              <div key={tier.name} className={`pricing-card${tier.highlight ? " pricing-card--highlight" : ""}`}>
                <div className="pricing-card-header">
                  <h3>{tier.name}</h3>
                  {tier.badge && (
                    <span className="pricing-badge">{tier.badge}</span>
                  )}
                </div>
                <div className="pricing-price">
                  {tier.price}
                  <span>/mo</span>
                </div>
                <p className="pricing-desc">{tier.description}</p>
                {tier.idealFor && (
                  <p className="pricing-ideal">{tier.idealFor}</p>
                )}
                <ul className="pricing-features">
                  {tier.features.map((f) => (
                    <li key={f}>{f}</li>
                  ))}
                </ul>
                <a href="/app" className={tier.highlight ? "button-primary" : "button-ghost"}>
                  {tier.cta}
                </a>
              </div>
            ))}
          </div>
          <div className="pricing-trust">
            <h3>Your investment is protected</h3>
            <div className="trust-grid">
              <div className="trust-item">
                <div className="trust-icon">🔒</div>
                <div className="trust-text">
                  <strong>14-day free trial</strong>
                  <p>Try everything risk-free, no credit card needed</p>
                </div>
              </div>
              <div className="trust-item">
                <div className="trust-icon">🛡️</div>
                <div className="trust-text">
                  <strong>SOC 2 compliant</strong>
                  <p>Enterprise-grade security for your data</p>
                </div>
              </div>
              <div className="trust-item">
                <div className="trust-icon">💳</div>
                <div className="trust-text">
                  <strong>PCI compliant billing</strong>
                  <p>Secure payment processing</p>
                </div>
              </div>
              <div className="trust-item">
                <div className="trust-icon">📞</div>
                <div className="trust-text">
                  <strong>24-hour support</strong>
                  <p>Email support with fast response times</p>
                </div>
              </div>
              <div className="trust-item">
                <div className="trust-icon">🔑</div>
                <div className="trust-text">
                  <strong>BYOK (Bring Your Own Key)</strong>
                  <p>Use your own API keys to control costs</p>
                </div>
              </div>
            </div>
          </div>
          <p className="pricing-footnote">
            All plans include a 14-day free trial. No credit card required.{" "}
            <Link to="/contact">Talk to us</Link> for custom enterprise pricing.
          </p>
        </div>
      </section>
    </>
  );
}
