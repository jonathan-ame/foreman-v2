// Link is imported for potential future use
import { trackSignupStarted } from "../../utils/analytics";

type CompetitorCategory = {
  name: string;
  description: string;
  examples: string[];
};

type ComparisonDimension = {
  label: string;
  foreman: string;
  foremanDetail?: string;
  devFrameworks: string;
  workflowBuilders: string;
  singlePurposeTools: string;
};

const categories: CompetitorCategory[] = [
  {
    name: "Developer Frameworks",
    description: "Built for engineers who write code",
    examples: ["LangChain", "CrewAI"],
  },
  {
    name: "Workflow Builders",
    description: "Trigger-based automation tools",
    examples: ["Zapier", "n8n"],
  },
  {
    name: "Single-Purpose AI",
    description: "One tool, one job",
    examples: ["Jasper", "Copy.ai"],
  },
];

const dimensions: ComparisonDimension[] = [
  {
    label: "Setup Time",
    foreman: "15 minutes",
    foremanDetail: "No code, describe what you need",
    devFrameworks: "Days \u2013 Weeks",
    workflowBuilders: "Minutes",
    singlePurposeTools: "Minutes",
  },
  {
    label: "Coordination",
    foreman: "Chief of Staff agent",
    foremanDetail: "One point of contact coordinates everything",
    devFrameworks: "Manual chaining",
    workflowBuilders: "Trigger-based",
    singlePurposeTools: "None",
  },
  {
    label: "Human Oversight",
    foreman: "Plan cards + Unified inbox",
    foremanDetail: "Review and approve before execution",
    devFrameworks: "Logs only",
    workflowBuilders: "Run history",
    singlePurposeTools: "None",
  },
  {
    label: "Agent Variety",
    foreman: "Role-based org",
    foremanDetail: "CEO, Chief of Staff, Marketing, Sales, Ops",
    devFrameworks: "Custom chains",
    workflowBuilders: "Connectors",
    singlePurposeTools: "Single function",
  },
  {
    label: "Target User",
    foreman: "Business owner",
    foremanDetail: "Non-technical founders and small teams",
    devFrameworks: "Developer",
    workflowBuilders: "Ops / automation",
    singlePurposeTools: "Content marketer",
  },
  {
    label: "Ongoing Management",
    foreman: "Managed operations",
    foremanDetail: "We run the infrastructure, you run the business",
    devFrameworks: "Self-hosted",
    workflowBuilders: "Managed but limited",
    singlePurposeTools: "N/A",
  },
];

const topDifferentiators = [
  {
    title: "Chief of Staff Coordination",
    description:
      "One AI agent coordinates your entire workforce. No juggling five tools or five dashboards.",
    icon: "\uD83C\uDFAF",
  },
  {
    title: "Plan-Card Approval Flow",
    description:
      "See the plan before any agent acts. AI without oversight is a liability.",
    icon: "\u2705",
  },
  {
    title: "Unified Inbox",
    description:
      "All decisions, completions, and sign-offs in one place. No context switching.",
    icon: "\uD83D\uDCE5",
  },
  {
    title: "Org Chart That Grows",
    description:
      "Start with CEO + Chief of Staff. Add Marketing, Sales, Ops agents when you need them.",
    icon: "\uD83D\uDCCA",
  },
];

const battleCards = [
  {
    vs: "LangChain / CrewAI",
    objection: "\u201CWhy not build custom with LangChain?\u201D",
    response:
      "LangChain requires Python coding and ongoing AI infrastructure management. Foreman gives you pre-configured agents with managed operations \u2014 focus on business growth, not AI engineering.",
    winTheme: "Accessibility over flexibility",
    proof: "15-minute setup vs. weeks of development",
  },
  {
    vs: "Zapier / n8n",
    objection: "\u201CI already automate workflows with Zapier.\u201D",
    response:
      "Zapier connects apps with triggers. Foreman coordinates AI agents that reason, plan, and execute multi-step work \u2014 with human approval at every step. Triggers are reactive; agents are proactive.",
    winTheme: "Intelligence over automation",
    proof: "Coordinated multi-step work vs. single trigger chains",
  },
  {
    vs: "Jasper / Copy.ai",
    objection: "\u201CJasper already writes my marketing content.\u201D",
    response:
      "Jasper writes one type of content. Foreman coordinates multiple agents across research, outreach, writing, and operations \u2014 all working together as a team, not isolated tools.",
    winTheme: "Orchestration over isolation",
    proof: "Multi-agent coordination vs. single-function output",
  },
];

export function Compare() {
  return (
    <>
      <section className="page-hero">
        <div className="content-inner text-center">
          <h1>Foreman vs. the Alternatives</h1>
          <p className="page-hero-sub">
            Developer frameworks need engineers. Workflow builders need
            trigger-chains. Single tools do one thing. Foreman gives you a
            managed AI workforce with a Chief of Staff who coordinates
            everything.
          </p>
        </div>
      </section>

      <section className="section-comparison-intro">
        <div className="content-inner">
          <div className="compare-categories">
            {categories.map((cat) => (
              <div key={cat.name} className="compare-category-card">
                <h3>{cat.name}</h3>
                <p>{cat.description}</p>
                <span className="compare-category-examples">
                  {cat.examples.join(" \u00B7 ")}
                </span>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="section-comparison-table">
        <div className="content-inner">
          <h2 className="section-heading">
            How Foreman compares across key dimensions
          </h2>

          <div className="comparison-table-wrapper">
            <table className="comparison-table">
              <thead>
                <tr>
                  <th className="dimension-label">Dimension</th>
                  <th className="foreman-col">
                    <span className="col-badge foreman-badge">Foreman</span>
                  </th>
                  <th>Developer Frameworks</th>
                  <th>Workflow Builders</th>
                  <th>Single-Purpose AI</th>
                </tr>
              </thead>
              <tbody>
                {dimensions.map((d) => (
                  <tr key={d.label}>
                    <td className="dimension-label">{d.label}</td>
                    <td className="foreman-col">
                      <strong>{d.foreman}</strong>
                      {d.foremanDetail && (
                        <span className="foreman-detail">
                          {d.foremanDetail}
                        </span>
                      )}
                    </td>
                    <td>{d.devFrameworks}</td>
                    <td>{d.workflowBuilders}</td>
                    <td>{d.singlePurposeTools}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="comparison-cards">
            {dimensions.map((d) => (
              <div key={d.label} className="comparison-card">
                <h4>{d.label}</h4>
                <div className="comparison-card-cols">
                  <div className="comparison-card-col comparison-card-foreman">
                    <span className="comparison-card-badge">Foreman</span>
                    <strong>{d.foreman}</strong>
                    {d.foremanDetail && <p>{d.foremanDetail}</p>}
                  </div>
                  <div className="comparison-card-col">
                    <span className="comparison-card-label">
                      Dev Frameworks
                    </span>
                    <p>{d.devFrameworks}</p>
                  </div>
                  <div className="comparison-card-col">
                    <span className="comparison-card-label">
                      Workflow Builders
                    </span>
                    <p>{d.workflowBuilders}</p>
                  </div>
                  <div className="comparison-card-col">
                    <span className="comparison-card-label">
                      Single-Purpose AI
                    </span>
                    <p>{d.singlePurposeTools}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="section-differentiators">
        <div className="content-inner text-center">
          <h2 className="section-heading">
            What makes Foreman different
          </h2>
          <div className="orchestration-value-props">
            {topDifferentiators.map((d) => (
              <div key={d.title} className="orchestration-value">
                <span className="orchestration-value-icon">{d.icon}</span>
                <div>
                  <strong>{d.title}</strong>
                  <p>{d.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="section-battle-cards">
        <div className="content-inner">
          <h2 className="section-heading">
            Common objections, honest answers
          </h2>
          <div className="battle-cards-grid">
            {battleCards.map((card) => (
              <div key={card.vs} className="battle-card">
                <h3>{card.vs}</h3>
                <p className="battle-card-objection">{card.objection}</p>
                <p className="battle-card-response">{card.response}</p>
                <div className="battle-card-win">
                  <strong>Win theme:</strong> {card.winTheme}
                </div>
                <p className="battle-card-proof">{card.proof}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="section-cta">
        <div className="content-inner text-center">
          <h2>Try Foreman free for 14 days</h2>
          <p>
            No credit card required. Set up your first agent in 15 minutes.
          </p>
          <a
            href="/app"
            className="button-primary button-lg"
            onClick={() => trackSignupStarted("compare-bottom-cta")}
          >
            Start your free trial
          </a>
          <p className="cta-sub">
            Foreman: your AI workforce, managed from one screen
          </p>
        </div>
      </section>
    </>
  );
}