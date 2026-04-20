import { LegalLayout } from "../../components/LegalLayout";

export function Terms() {
  return (
    <LegalLayout title="Terms of Service" lastUpdated="April 20, 2026">
      <h2>1. Acceptance of terms</h2>
      <p>
        By creating an account or using the Foreman service ("Service"), you agree to these Terms of
        Service ("Terms"). If you do not agree, do not use the Service.
      </p>

      <h2>2. Description of Service</h2>
      <p>
        Foreman provides a multi-tenant AI agent platform. You may create, configure, and deploy AI
        agents to perform tasks on your behalf. The Service routes requests through third-party AI
        model providers.
      </p>

      <h2>3. Accounts</h2>
      <p>
        You must provide accurate information when creating an account. You are responsible for
        maintaining the confidentiality of your credentials and for all activity under your account.
        Notify us immediately of any unauthorized use.
      </p>

      <h2>4. Acceptable use</h2>
      <p>
        You agree to use the Service only in accordance with our{" "}
        <a href="/acceptable-use">Acceptable Use Policy</a>. Prohibited uses include but are not
        limited to: illegal activity, spam, impersonation, attempts to circumvent usage limits, and
        any use that harms other users or third parties.
      </p>

      <h2>5. Subscription and billing</h2>
      <p>
        Subscriptions are billed monthly in advance. Usage-based charges accrue during the billing
        period and are billed at the end of each cycle. All fees are non-refundable except as
        required by law. You may cancel at any time; cancellation takes effect at the end of the
        current billing period.
      </p>

      <h2>6. Intellectual property</h2>
      <p>
        You retain ownership of content you submit. By submitting content, you grant Foreman a
        limited license to process that content solely to provide the Service. Foreman retains all
        rights in the platform, software, and documentation.
      </p>

      <h2>7. Confidentiality and data</h2>
      <p>
        We treat your data as confidential. See our <a href="/privacy">Privacy Policy</a> and{" "}
        <a href="/dpa">Data Processing Agreement</a> for details on how we process personal data.
      </p>

      <h2>8. Disclaimers</h2>
      <p>
        THE SERVICE IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND. WE DO NOT WARRANT THAT THE
        SERVICE WILL BE ERROR-FREE, UNINTERRUPTED, OR THAT AI OUTPUTS WILL BE ACCURATE. AI-generated
        content should be reviewed before acting on it.
      </p>

      <h2>9. Limitation of liability</h2>
      <p>
        TO THE MAXIMUM EXTENT PERMITTED BY LAW, FOREMAN'S TOTAL LIABILITY FOR ANY CLAIM ARISING OUT
        OF THESE TERMS OR THE SERVICE SHALL NOT EXCEED THE AMOUNTS YOU PAID IN THE THREE MONTHS
        PRECEDING THE CLAIM. IN NO EVENT SHALL WE BE LIABLE FOR INDIRECT, INCIDENTAL, SPECIAL, OR
        CONSEQUENTIAL DAMAGES.
      </p>

      <h2>10. Termination</h2>
      <p>
        Either party may terminate the relationship at any time. We reserve the right to suspend or
        terminate accounts that violate these Terms. Upon termination, your right to use the Service
        ceases immediately.
      </p>

      <h2>11. Governing law</h2>
      <p>
        These Terms are governed by the laws of the State of Delaware, USA, without regard to
        conflict of law principles.
      </p>

      <h2>12. Changes</h2>
      <p>
        We may modify these Terms at any time. Material changes will be communicated by email or
        in-app notice at least 14 days before taking effect. Continued use constitutes acceptance.
      </p>
    </LegalLayout>
  );
}
