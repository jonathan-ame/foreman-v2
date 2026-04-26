import { useState, useRef, useEffect } from "react";
import { trackEmailSubscribed } from "../utils/analytics";

type EmailCaptureSource = "homepage" | "blog" | "contact" | "other";

interface EmailCaptureFormProps {
  source: EmailCaptureSource;
  headline?: string;
  subtext?: string;
  placeholder?: string;
  buttonText?: string;
  variant?: "inline" | "card";
  showSequencePreview?: boolean;
}

export function EmailCaptureForm({
  source,
  headline = "Stay in the loop",
  subtext = "Get early access tips and product updates. No spam, unsubscribe anytime.",
  placeholder = "you@company.com",
  buttonText = "Subscribe",
  variant = "inline",
  showSequencePreview = false,
}: EmailCaptureFormProps) {
  const [email, setEmail] = useState("");
  const [submittedEmail, setSubmittedEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "submitting" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");
  const [unsubscribeToken, setUnsubscribeToken] = useState<string | null>(null);
  const successRef = useRef<HTMLDivElement>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || status === "submitting") return;

    setStatus("submitting");
    setErrorMessage("");

    try {
      const params = new URLSearchParams(window.location.search);
      const response = await fetch("/api/marketing/subscribe", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: email.trim(),
          source,
          utmSource: params.get("utm_source") || undefined,
          utmMedium: params.get("utm_medium") || undefined,
          utmCampaign: params.get("utm_campaign") || undefined,
        }),
      });

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        throw new Error(data.error ?? "Something went wrong");
      }

      setSubmittedEmail(email.trim());
      setStatus("success");
      setEmail("");
      trackEmailSubscribed(source);
      const data = await response.json();
      if (data.unsubscribe_token) {
        setUnsubscribeToken(data.unsubscribe_token);
      }
    } catch (err) {
      setStatus("error");
      setErrorMessage(err instanceof Error ? err.message : "Network error. Please try again.");
    }
  };

  useEffect(() => {
    if (status === "success" && successRef.current) {
      successRef.current.focus();
    }
  }, [status]);

  if (status === "success") {
    const prefsLink = unsubscribeToken && submittedEmail
      ? `/preferences?email=${encodeURIComponent(submittedEmail)}&token=${encodeURIComponent(unsubscribeToken)}`
      : `/preferences?email=${encodeURIComponent(submittedEmail)}`;

    return (
      <div className={`email-capture email-capture--${variant} email-capture--success`} ref={successRef} tabIndex={-1}>
        <div className="email-capture-confirmation">
          <div className="email-capture-confirmation-badge" aria-hidden="true">&#10003;</div>
          <h3 className="email-capture-confirmation-headline">You're on the list!</h3>
          <p className="email-capture-confirmation-detail">
            We'll send you early access updates and launch details at <strong>{submittedEmail}</strong>.
          </p>

          {showSequencePreview && (
            <div className="email-capture-next-steps">
              <h4>What's next</h4>
              <div className="email-capture-next-step-item">
                <span className="email-capture-next-step-icon">&#9993;</span>
                <div className="email-capture-next-step-text">
                  <strong>Pre-launch</strong>
                  <span>Early access tips and countdown</span>
                </div>
              </div>
              <div className="email-capture-next-step-item">
                <span className="email-capture-next-step-icon">&#9993;</span>
                <div className="email-capture-next-step-text">
                  <strong>Launch day</strong>
                  <span>Your exclusive early access link</span>
                </div>
              </div>
              <div className="email-capture-next-step-item">
                <span className="email-capture-next-step-icon">&#9993;</span>
                <div className="email-capture-next-step-text">
                  <strong>Day 1-7</strong>
                  <span>Check-ins, results, and feature deep dives</span>
                </div>
              </div>
            </div>
          )}

          <p className="email-capture-prefs-link">
            <a href={prefsLink}>Manage email preferences</a>
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className={`email-capture email-capture--${variant}`}>
      <h3 className="email-capture-headline">{headline}</h3>
      <p className="email-capture-subtext">{subtext}</p>
      <form onSubmit={handleSubmit} className="email-capture-form">
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder={placeholder}
          required
          className="email-capture-input"
          disabled={status === "submitting"}
          aria-label="Email address"
          autoComplete="email"
        />
        <button
          type="submit"
          className="button-primary email-capture-button"
          disabled={status === "submitting"}
        >
          {status === "submitting" ? "Subscribing..." : buttonText}
        </button>
      </form>
      {status === "error" && <p className="email-capture-error" role="alert">{errorMessage}</p>}
      <p className="email-capture-note">No spam. Unsubscribe anytime.</p>
    </div>
  );
}
