import { Link } from "react-router-dom";

export function Home() {
  return (
    <>
      <section className="hero">
        <div className="hero-inner">
          <h1 className="hero-headline">AI agents for the rest of us</h1>
          <p className="hero-sub">
            Foreman gives solopreneurs and small teams a personal AI workforce — no code, no
            configuration, just results.
          </p>
          <div className="hero-cta">
            <a href="/app" className="button-primary button-lg">
              Get started free
            </a>
            <Link to="/how-it-works" className="button-ghost button-lg">
              See how it works
            </Link>
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
              <h3>Budget-constrained builder</h3>
              <p>Can't afford an agency or full-time staff? Get senior-level execution at a fraction of the cost.</p>
            </div>
            <div className="card">
              <h3>Delegation-ready founder</h3>
              <p>Ready to stop doing everything yourself? Foreman is the Chief of Staff you always needed.</p>
            </div>
          </div>
        </div>
      </section>

      <section className="section-cta">
        <div className="content-inner text-center">
          <h2>Start your AI workforce today</h2>
          <p>No credit card required for the free trial.</p>
          <a href="/app" className="button-primary button-lg">
            Create your first agent
          </a>
        </div>
      </section>
    </>
  );
}
