import { Link } from "react-router-dom";

const tiers = [
  {
    name: "Starter",
    price: "$49",
    description: "One focused agent for solopreneurs just getting started.",
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
    description: "A small fleet for builders who need more coverage.",
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
    description: "Full workforce for serious operators.",
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
          <h1>Simple, transparent pricing</h1>
          <p>Start free. Upgrade when you're ready.</p>
        </div>
      </section>

      <section className="pricing-grid-section">
        <div className="content-inner">
          <div className="pricing-grid">
            {tiers.map((tier) => (
              <div key={tier.name} className={`pricing-card${tier.highlight ? " pricing-card--highlight" : ""}`}>
                <h3>{tier.name}</h3>
                <div className="pricing-price">
                  {tier.price}
                  <span>/mo</span>
                </div>
                <p className="pricing-desc">{tier.description}</p>
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
          <p className="pricing-footnote">
            All plans include a 14-day free trial. No credit card required.{" "}
            <Link to="/contact">Talk to us</Link> for custom enterprise pricing.
          </p>
        </div>
      </section>
    </>
  );
}
