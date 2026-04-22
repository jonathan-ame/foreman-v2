import { useState, useRef, useEffect } from "react";

type EmailCaptureSource = "homepage" | "blog" | "contact" | "other";

interface EmailCaptureFormProps {
  source: EmailCaptureSource;
  headline?: string;
  subtext?: string;
  placeholder?: string;
  buttonText?: string;
  variant?: "inline" | "card";
}

export function EmailCaptureForm({
  source,
  headline = "Stay in the loop",
  subtext = "Get early access tips and product updates. No spam, unsubscribe anytime.",
  placeholder = "you@company.com",
  buttonText = "Subscribe",
  variant = "inline",
}: EmailCaptureFormProps) {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "submitting" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");
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

      setStatus("success");
      setEmail("");
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
    return (
      <div className={`email-capture email-capture--${variant} email-capture--success`} ref={successRef} tabIndex={-1}>
        <p className="email-capture-success-text">You're in! Check your inbox for a confirmation.</p>
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
