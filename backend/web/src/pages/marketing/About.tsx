export function About() {
  return (
    <>
      <section className="page-hero">
        <div className="content-inner text-center">
          <h1>About Foreman</h1>
        </div>
      </section>

      <section className="prose-section">
        <div className="content-inner content-narrow">
          <h2>Our mission</h2>
          <p>
            We believe the gap between a solopreneur and a funded startup is mostly about bandwidth,
            not ideas or talent. Foreman exists to close that gap — giving anyone access to an AI
            workforce that can handle the operational work of a 10-person team.
          </p>

          <h2>Why "AI agents for the rest of us"?</h2>
          <p>
            Most AI tools are built for developers or enterprise buyers. Foreman is built for the
            freelancer, the founder, the consultant, and the small-team operator who doesn't have an
            engineering department — but does have high standards and real work to get done.
          </p>

           <h2>How we build</h2>
          <p>
            Foreman itself runs on Foreman. Our own AI agents handle research, outbound, scheduling,
            and internal ops. Every feature we ship is one we've used ourselves.
          </p>

          <h2>Our orchestration philosophy</h2>
          <p>
            We believe AI agents should work *together*, not in isolation. Your Chief of Staff agent coordinates
            work across your AI workforce, ensuring you stay in control while delegating effectively. Unlike workflow
            builders that require manual chaining, Foreman's coordinated approach mirrors how you'd manage a human team —
            with role-based delegation and plan‑card approval before execution.
          </p>
        </div>
      </section>
    </>
  );
}
