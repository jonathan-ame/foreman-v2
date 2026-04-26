import { type FormEvent, useEffect, useState } from "react";

export function ResetPassword() {
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [token, setToken] = useState<string | null>(null);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const t = params.get("token");
    if (t) {
      setToken(t);
    } else {
      setError("Invalid or missing reset link. Please request a new password reset email.");
    }
  }, []);

  const passwordMismatch = confirmPassword.length > 0 && password !== confirmPassword;

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!token) return;
    if (passwordMismatch) return;
    if (password.length < 8) {
      setError("Password must be at least 8 characters.");
      return;
    }

    setError(null);
    setIsSubmitting(true);

    try {
      const response = await fetch("/api/internal/auth/reset-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ token, password })
      });

      if (response.ok) {
        setSuccess(true);
        return;
      }

      const data = (await response.json().catch(() => ({}))) as { error?: string };
      if (response.status === 401 || response.status === 400) {
        setError(data.error ?? "This reset link has expired. Please request a new one.");
      } else {
        setError("Something went wrong. Please try again.");
      }
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

        {success ? (
          <>
            <h1 style={{ fontSize: "1.25rem", fontWeight: 600, margin: "0 0 8px" }}>
              Password updated
            </h1>
            <p className="muted">
              Your password has been reset. You can now sign in with your new password.
            </p>
            <a href="/app" className="link-button" style={{ display: "inline-block", marginTop: 16 }}>
              Sign in
            </a>
          </>
        ) : (
          <>
            <h1 style={{ fontSize: "1.25rem", fontWeight: 600, margin: "0 0 8px" }}>
              Set new password
            </h1>
            {!token ? (
              <p className="auth-error" role="alert">{error}</p>
            ) : (
              <form className="stack" onSubmit={handleSubmit} noValidate>
                <label>
                  <span className="field-label">New password</span>
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Min. 8 characters"
                    autoComplete="new-password"
                    required
                    autoFocus
                  />
                  <div className="password-strength">
                    {password.length > 0 && password.length < 8 && (
                      <small className="error-text">{8 - password.length} more characters needed</small>
                    )}
                    {password.length >= 8 && <small className="success-text">Password meets requirements</small>}
                  </div>
                </label>

                <label>
                  <span className="field-label">Confirm new password</span>
                  <input
                    type="password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    placeholder="••••••••"
                    autoComplete="new-password"
                    required
                    aria-invalid={passwordMismatch}
                  />
                  {passwordMismatch && (
                    <span className="field-hint error-text" role="alert">
                      Passwords do not match.
                    </span>
                  )}
                </label>

                {error && (
                  <p className="auth-error" role="alert">
                    {error}
                  </p>
                )}

                <button
                  type="submit"
                  disabled={isSubmitting || !password || !confirmPassword || passwordMismatch || password.length < 8}
                >
                  {isSubmitting ? "Resetting..." : "Reset password"}
                </button>
              </form>
            )}
            <p className="auth-switch" style={{ marginTop: 16 }}>
              <a href="/app" className="link-button">Back to sign in</a>
            </p>
          </>
        )}
      </section>
    </main>
  );
}