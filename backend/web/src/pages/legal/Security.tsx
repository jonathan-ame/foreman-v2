import { LegalLayout } from "../../components/LegalLayout";

export function Security() {
  return (
    <LegalLayout title="Security" lastUpdated="April 20, 2026">
      <p>
        Security is a core engineering constraint at Foreman, not an afterthought. This page
        describes our current practices and posture.
      </p>

      <h2>Infrastructure</h2>
      <ul>
        <li>
          <strong>Hosting:</strong> Production runs on Railway with managed container deployments.
        </li>
        <li>
          <strong>Database:</strong> Supabase (PostgreSQL) with row-level security (RLS) enforced at
          the database layer, providing per-customer data isolation in our multi-tenant architecture.
        </li>
        <li>
          <strong>Encryption in transit:</strong> All connections use TLS 1.2+.
        </li>
        <li>
          <strong>Encryption at rest:</strong> Data is encrypted at rest by our infrastructure
          providers.
        </li>
      </ul>

      <h2>Authentication and access control</h2>
      <ul>
        <li>
          Authentication is handled by Supabase Auth with support for email/password and OAuth
          providers.
        </li>
        <li>
          Internal API routes require bearer token authentication. Agent API keys are scoped,
          short-lived, and rotated automatically.
        </li>
        <li>
          Database access is governed by RLS policies that prevent cross-tenant data access at the
          query level.
        </li>
      </ul>

      <h2>Multi-tenant isolation</h2>
      <p>
        Each customer operates in an isolated workspace identified by a unique slug. RLS policies
        on all tables enforce that queries return only the requesting customer's data, even if
        application-level access controls fail.
      </p>

      <h2>Dependency and supply-chain security</h2>
      <ul>
        <li>Dependencies are pinned and audited regularly.</li>
        <li>Third-party AI model providers (via OpenRouter) are SOC 2 compliant or equivalent.</li>
      </ul>

      <h2>Error monitoring and logging</h2>
      <p>
        Errors are captured via Sentry. Logs are stored securely and access is restricted to
        authorized personnel. We do not log the content of AI agent task outputs beyond what is
        necessary for debugging.
      </p>

      <h2>Reporting a vulnerability</h2>
      <p>
        If you discover a security vulnerability, please report it responsibly to{" "}
        <a href="mailto:security@foreman.company">security@foreman.company</a>. We will acknowledge
        your report within 48 hours and aim to resolve critical issues within 7 days. We do not
        currently operate a public bug bounty program.
      </p>

      <h2>Compliance</h2>
      <p>
        We are working toward SOC 2 Type II certification. In the meantime, we maintain
        documentation of our controls and are available to discuss our security posture with
        enterprise customers under NDA. Contact{" "}
        <a href="mailto:security@foreman.company">security@foreman.company</a>.
      </p>
    </LegalLayout>
  );
}
