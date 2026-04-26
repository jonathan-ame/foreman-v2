import { Link } from "react-router-dom";
import { EmailCaptureForm } from "../../components/EmailCaptureForm";
import { trackSignupStarted } from "../../utils/analytics";

export function Home() {
  return (
    <>
       <section className="hero">
        <div className="hero-inner">
          <h1 className="hero-headline">Delegate to AI the Way You Delegate to People</h1>
          <p className="hero-sub">
            Describe what you need. Foreman assigns the right agent, creates a plan, and executes — with your sign‑off at every step.
          </p>
          <div className="hero-cta">
            <a
              href="/app"
              className="button-primary button-lg"
              onClick={() => trackSignupStarted("hero")}
            >
              Start 14-Day Free Trial
            </a>
            <Link to="/how-it-works" className="button-ghost button-lg">
              See how it works
            </Link>
          </div>
          <p className="hero-trust">
            <span className="trust-badge">No credit card required</span>
            <span className="trust-badge">Enterprise security</span>
            <span className="trust-badge">GDPR-ready docs</span>
          </p>
        </div>
      </section>

      <section className="section-orchestration">
        <div className="content-inner text-center">
          <h2 className="section-heading">Delegate to AI the Way You Delegate to People</h2>
          <p className="section-sub">Describe what you need. Foreman assigns the right agent, creates a plan, and executes — with your sign-off at every step.</p>
          <div className="orchestration-diagram">
            <img
              src="/orchestration-flow.svg"
              alt="How Foreman orchestrates your AI workforce: You describe a need, Chief of Staff assigns an agent and creates a plan, you approve the plan card, the agent executes, and results arrive in your inbox"
              className="orchestration-diagram-img"
            />
          </div>
          <div className="orchestration-value-props">
            <div className="orchestration-value">
              <span className="orchestration-value-icon">🎯</span>
              <div>
                <strong>One Point of Contact</strong>
                <p>Your Chief of Staff agent coordinates everything — no juggling multiple tools</p>
              </div>
            </div>
            <div className="orchestration-value">
              <span className="orchestration-value-icon">✅</span>
              <div>
                <strong>Approval Before Action</strong>
                <p>Review every plan before it runs. AI without oversight is a liability</p>
              </div>
            </div>
            <div className="orchestration-value">
              <span className="orchestration-value-icon">📥</span>
              <div>
                <strong>Unified Inbox</strong>
                <p>All agent decisions, completed tasks, and sign-offs in one place</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="section-triggers">
        <div className="content-inner">
          <h2 className="section-heading">Built for four moments that matter</h2>
          <div className="cards-grid">
            <div className="card">
              <h3>Swamped solopreneur</h3>
              <p>You're doing the work of five people. Foreman handles the repetitive tasks so you can focus on what only you can do.</p>
            </div>
            <div className="card">
              <h3>New small team</h3>
              <p>Just hired your first person? Foreman extends your capacity without the overhead of managing another headcount.</p>
            </div>
            <div className="card">
              <h3>Budget‑constrained builder</h3>
              <p>Can't afford an agency or full‑time staff? Get senior‑level execution at a fraction of the cost.</p>
            </div>
            <div className="card">
              <h3>Delegation‑ready founder</h3>
              <p>Ready to stop doing everything yourself? Foreman is the Chief of Staff you always needed.</p>
            </div>
          </div>
        </div>
      </section>

      <section className="section-proof">
        <div className="content-inner">
          <h2 className="section-heading">Built for Business Reliability</h2>
          <p className="section-sub">Enterprise‑grade technology made accessible for every business</p>
          
          <div className="proof-grid">
            <div className="proof-card">
              <h3>Enterprise‑Grade Foundation</h3>
              <p>Built on Paperclip, proven at scale for reliable agent orchestration.</p>
            </div>
            
            <div className="proof-card">
              <h3>Production‑Ready Runtime</h3>
              <p>Powered by OpenClaw for consistent, high‑quality execution.</p>
            </div>
            
            <div className="proof-card">
              <h3>Multi‑Provider Flexibility</h3>
              <p>Works with all major AI models via OpenRouter ecosystem.</p>
            </div>
            
            <div className="proof-card">
              <h3>Cost Control Options</h3>
              <p>BYOK (Bring Your Own Key) to optimize expenses.</p>
            </div>
          </div>
        </div>
      </section>

      <section className="section-cta">
        <div className="content-inner text-center">
          <h2>Start your AI workforce today</h2>
          <p>No credit card required for the 14‑day free trial.</p>
          <a
            href="/app"
            className="button-primary button-lg"
            onClick={() => trackSignupStarted("bottom-cta")}
          >
            Create your first agent
          </a>
          <p className="cta-sub">Try Foreman free for 14 days • Cancel anytime</p>
        </div>
      </section>

      <section className="section-email-capture">
        <div className="content-inner">
          <EmailCaptureForm
            source="homepage"
            headline="Get early access to Foreman"
            subtext="Join the waitlist and be the first to know when we launch. Early subscribers get priority access."
            buttonText="Join the waitlist"
            variant="card"
            showSequencePreview
          />
        </div>
      </section>
    </>
  );
}
