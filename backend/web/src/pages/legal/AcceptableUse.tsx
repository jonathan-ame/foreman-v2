import { LegalLayout } from "../../components/LegalLayout";

export function AcceptableUse() {
  return (
    <LegalLayout title="Acceptable Use Policy" lastUpdated="April 20, 2026">
      <p>
        This Acceptable Use Policy ("AUP") governs your use of Foreman and applies to all users,
        agents, and automated processes operating through your account.
      </p>

      <h2>1. Permitted uses</h2>
      <p>
        You may use Foreman for lawful business and personal productivity purposes, including
        research, writing, scheduling, outreach, data analysis, and operational automation.
      </p>

      <h2>2. Prohibited uses</h2>
      <p>You may not use Foreman to:</p>
      <ul>
        <li>
          <strong>Illegal activity:</strong> Violate any applicable local, state, national, or
          international law or regulation.
        </li>
        <li>
          <strong>Harmful content:</strong> Generate or distribute content that is defamatory,
          obscene, harassing, hateful, or that incites violence.
        </li>
        <li>
          <strong>Spam and unsolicited messaging:</strong> Send bulk unsolicited communications or
          engage in any activity that would constitute spam.
        </li>
        <li>
          <strong>Impersonation:</strong> Impersonate any person, organization, or entity, or
          misrepresent your affiliation.
        </li>
        <li>
          <strong>Malware and attacks:</strong> Distribute malware, conduct denial-of-service
          attacks, or attempt unauthorized access to systems.
        </li>
        <li>
          <strong>Intellectual property infringement:</strong> Infringe or facilitate infringement
          of third-party intellectual property rights.
        </li>
        <li>
          <strong>Privacy violations:</strong> Collect or process personal data without appropriate
          consent or in violation of privacy laws.
        </li>
        <li>
          <strong>Circumvention:</strong> Attempt to bypass usage limits, rate limits, billing
          mechanisms, or security controls.
        </li>
        <li>
          <strong>High-risk autonomous decisions:</strong> Use AI agents to make autonomous
          decisions with serious real-world consequences without appropriate human oversight
          (e.g., medical decisions, legal advice given as fact, financial transactions above
          reasonable thresholds).
        </li>
      </ul>

      <h2>3. Agent and automation rules</h2>
      <p>
        Automated agents running through your account are subject to this AUP. You are responsible
        for all actions taken by agents authorized under your account.
      </p>

      <h2>4. Enforcement</h2>
      <p>
        Violations of this AUP may result in suspension or termination of your account without
        notice. We reserve the right to investigate suspected violations and cooperate with law
        enforcement.
      </p>

      <h2>5. Reporting violations</h2>
      <p>
        To report a potential violation, contact{" "}
        <a href="mailto:abuse@foreman.company">abuse@foreman.company</a>.
      </p>
    </LegalLayout>
  );
}
