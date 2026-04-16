interface FailureCardProps {
  outcome: "failed" | "partial" | "blocked";
  stageLabel: string;
  suggestedAction: string;
  technicalDetails: {
    errorCode: string;
    provisioningId: string;
    failedStep: string;
    errorMessage: string;
  };
  onRetry: () => void;
}

export function FailureCard({ outcome, stageLabel, suggestedAction, technicalDetails, onRetry }: FailureCardProps) {
  return (
    <section className="failure-card" role="alert">
      <h2>Provisioning needs attention</h2>
      <p>
        <strong>Setup failed during:</strong> {stageLabel}
      </p>
      <p>
        <strong>Suggested action:</strong> {suggestedAction}
      </p>
      <details>
        <summary>Show technical details</summary>
        <div className="technical-details">
          <p>
            <strong>Error code:</strong> <code>{technicalDetails.errorCode}</code>
          </p>
          <p>
            <strong>Provisioning ID:</strong> <code>{technicalDetails.provisioningId}</code>
          </p>
          <p>
            <strong>Failed step:</strong> <code>{technicalDetails.failedStep}</code>
          </p>
          <p>
            <strong>Message:</strong> {technicalDetails.errorMessage}
          </p>
        </div>
      </details>
      <div className="button-row">
        {(outcome === "failed" || outcome === "blocked") && (
          <button type="button" onClick={onRetry}>
            Retry
          </button>
        )}
        {outcome === "partial" && (
          <a className="button-link" href="mailto:support@foreman.company?subject=Provisioning%20Help">
            Contact support
          </a>
        )}
      </div>
    </section>
  );
}
