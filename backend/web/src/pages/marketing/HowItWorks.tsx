const steps = [
  {
    num: "01",
    title: "Describe what you need",
    body: "Tell Foreman what kind of help you want — sales outreach, research, scheduling, writing, ops work. No code, no config. Get from idea to action in minutes.",
  },
  {
    num: "02",
    title: "Foreman builds your agent",
    body: "Your Chief of Staff spins up a specialized AI agent with the right tools and instructions for the job. No technical expertise required.",
  },
  {
    num: "03",
    title: "Review and approve",
    body: "Your agent proposes a plan. You approve, edit, or redirect. Stay in control while the agent does the work.",
  },
  {
    num: "04",
    title: "Watch it run",
    body: "Tasks execute autonomously. Check your Inbox for decisions that need your sign‑off, or let it run on autopilot. Get 10+ hours back each week.",
  },
];

export function HowItWorks() {
  return (
    <>
      <section className="page-hero">
        <div className="content-inner text-center">
          <h1>How Foreman works</h1>
          <p>Your personal AI workforce, running in four steps.</p>
        </div>
      </section>

      <section className="steps-section">
        <div className="content-inner">
          <div className="steps">
            {steps.map((step) => (
              <div key={step.num} className="step">
                <div className="step-num">{step.num}</div>
                <div className="step-content">
                  <h3>{step.title}</h3>
                  <p>{step.body}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="section-cta">
        <div className="content-inner text-center">
          <h2>Ready to try it?</h2>
          <a href="/app" className="button-primary button-lg">
            Start for free
          </a>
        </div>
      </section>
    </>
  );
}
