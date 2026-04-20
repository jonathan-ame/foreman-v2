import { LegalLayout } from "../../components/LegalLayout";

export function DPA() {
  return (
    <LegalLayout title="Data Processing Agreement" lastUpdated="April 20, 2026">
      <p>
        This Data Processing Agreement ("DPA") is incorporated into and forms part of the Foreman{" "}
        <a href="/terms">Terms of Service</a> between Foreman ("Processor") and you ("Controller").
        It governs the processing of personal data as defined under applicable data protection laws
        including the GDPR and CCPA.
      </p>

      <h2>1. Definitions</h2>
      <ul>
        <li>
          <strong>Personal Data:</strong> Any information relating to an identified or identifiable
          natural person processed by Foreman on behalf of the Controller.
        </li>
        <li>
          <strong>Processing:</strong> Any operation performed on Personal Data, including storage,
          retrieval, use, and deletion.
        </li>
        <li>
          <strong>Sub-processor:</strong> A third party engaged by Foreman to process Personal Data
          on the Controller's behalf.
        </li>
      </ul>

      <h2>2. Scope and purpose of processing</h2>
      <p>
        Foreman processes Personal Data solely to provide the Service as described in the Terms and
        as instructed by the Controller. Foreman will not process Personal Data for any other purpose.
      </p>

      <h2>3. Controller obligations</h2>
      <p>
        The Controller is responsible for ensuring there is a lawful basis for processing Personal
        Data, providing required notices to data subjects, and ensuring the instructions given to
        Foreman comply with applicable law.
      </p>

      <h2>4. Processor obligations</h2>
      <p>Foreman agrees to:</p>
      <ul>
        <li>Process Personal Data only on the Controller's documented instructions;</li>
        <li>Ensure personnel authorized to process Personal Data are bound by confidentiality;</li>
        <li>Implement appropriate technical and organizational security measures;</li>
        <li>Assist the Controller in responding to data subject rights requests;</li>
        <li>Notify the Controller without undue delay of any Personal Data breach;</li>
        <li>Delete or return all Personal Data upon termination of the Service.</li>
      </ul>

      <h2>5. Sub-processors</h2>
      <p>
        Foreman currently uses the following categories of sub-processors:
      </p>
      <ul>
        <li>Cloud infrastructure (database, compute, storage)</li>
        <li>Payment processing</li>
        <li>AI model routing (OpenRouter)</li>
        <li>Email delivery</li>
        <li>Error monitoring</li>
      </ul>
      <p>
        Foreman will provide reasonable notice of new sub-processors and maintain data processing
        agreements with all sub-processors imposing substantially equivalent obligations.
      </p>

      <h2>6. International transfers</h2>
      <p>
        Where Personal Data is transferred outside the EEA, Foreman will ensure appropriate
        safeguards are in place, such as Standard Contractual Clauses.
      </p>

      <h2>7. Security measures</h2>
      <p>
        See our <a href="/security">Security page</a> for a description of our technical and
        organizational security measures.
      </p>

      <h2>8. Audit rights</h2>
      <p>
        Foreman will make available information necessary to demonstrate compliance with this DPA and
        allow for audits conducted by the Controller or a mandated auditor, subject to reasonable
        notice and confidentiality obligations.
      </p>

      <h2>9. Governing law</h2>
      <p>
        This DPA is governed by the same law as the Terms of Service.
      </p>
    </LegalLayout>
  );
}
