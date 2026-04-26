import { type FormEvent, useState } from "react";

export function ForgotPassword() {
  const [email, setEmail] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      const response = await fetch("/api/internal/auth/forgot-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ email: email.trim() })
      });

      if (response.ok) {
        setSent(true);
        return;
      }

      setError("Something went wrong. Please try again.");
    } catch {
      setError("Network error. Please check your connection.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <main className="app-shell">
      <section className="panel auth-panel">
        <div className="auth-logo">
          <span className="auth-logo-text">Foreman</span>
        </div>

        {sent ? (
          <>
            <h1 style={{ fontSize: "1.25rem", fontWeight: 600, margin: "0 0 8px" }}>
              Check your email
            </h1>
            <p className="muted">
              If an account exists for {email}, you&apos;ll receive a password reset link shortly.
            </p>
            <a href="/app" className="link-button" style={{ display: "inline-block", marginTop: 16 }}>
              Back to sign in
            </a>
          </>
        ) : (
          <>
            <h1 style={{ fontSize: "1.25rem", fontWeight: 600, margin: "0 0 8px" }}>
              Reset your password
            </h1>
            <p className="muted">
              Enter your email and we&apos;ll send you a link to reset your password.
            </p>
            <form className="stack" onSubmit={handleSubmit} noValidate>
              <label>
                <span className="field-label">Email</span>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@example.com"
                  autoComplete="email"
                  required
                  autoFocus
                />
              </label>

              {error && (
                <p className="auth-error" role="alert">
                  {error}
                </p>
              )}

              <button type="submit" disabled={isSubmitting || !email}>
                {isSubmitting ? "Sending..." : "Send reset link"}
              </button>
            </form>
            <p className="auth-switch" style={{ marginTop: 16 }}>
              <a href="/app" className="link-button">Back to sign in</a>
            </p>
          </>
        )}
      </section>
    </main>
  );
}