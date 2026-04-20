import { type FormEvent, useState } from "react";

type AuthMode = "login" | "signup";

interface CustomerSession {
  customer_id: string;
  email: string;
  display_name: string;
  current_tier: string | null;
  current_billing_mode: string;
}

interface AuthPageProps {
  onAuthenticated: (customer: CustomerSession) => void;
}

function GoogleIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" aria-hidden="true">
      <path
        d="M17.64 9.2c0-.637-.057-1.251-.164-1.84H9v3.481h4.844a4.14 4.14 0 0 1-1.796 2.716v2.259h2.908c1.702-1.567 2.684-3.875 2.684-6.615z"
        fill="#4285F4"
      />
      <path
        d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332A8.997 8.997 0 0 0 9 18z"
        fill="#34A853"
      />
      <path
        d="M3.964 10.71A5.41 5.41 0 0 1 3.682 9c0-.593.102-1.17.282-1.71V4.958H.957A8.996 8.996 0 0 0 0 9c0 1.452.348 2.827.957 4.042l3.007-2.332z"
        fill="#FBBC05"
      />
      <path
        d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0A8.997 8.997 0 0 0 .957 4.958L3.964 6.29C4.672 4.163 6.656 3.58 9 3.58z"
        fill="#EA4335"
      />
    </svg>
  );
}

function LinkedInIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true" fill="#0A66C2">
      <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 0 1-2.063-2.065 2.064 2.064 0 1 1 2.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z" />
    </svg>
  );
}

function OAuthButtons() {
  const handleGoogle = () => {
    window.location.assign("/api/auth/google");
  };

  const handleLinkedIn = () => {
    window.location.assign("/api/auth/linkedin");
  };

  return (
    <div className="oauth-stack">
      <button type="button" className="oauth-button" onClick={handleGoogle}>
        <GoogleIcon />
        Continue with Google
      </button>
      <button type="button" className="oauth-button" onClick={handleLinkedIn}>
        <LinkedInIcon />
        Continue with LinkedIn
      </button>
    </div>
  );
}

function Divider() {
  return (
    <div className="divider">
      <span>or continue with email</span>
    </div>
  );
}

interface LoginFormProps {
  onAuthenticated: (customer: CustomerSession) => void;
  onSwitchMode: () => void;
}

function LoginForm({ onAuthenticated, onSwitchMode }: LoginFormProps) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      const response = await fetch("/api/internal/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ email: email.trim(), password })
      });

      if (response.ok) {
        const data = (await response.json()) as { customer: CustomerSession };
        onAuthenticated(data.customer);
        return;
      }

      if (response.status === 401) {
        setError("Incorrect email or password.");
      } else if (response.status === 404) {
        setError("No account found for that email.");
      } else {
        setError("Sign in failed. Please try again.");
      }
    } catch {
      setError("Network error. Please check your connection.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
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
        />
      </label>

      <label>
        <span className="field-label">Password</span>
        <div className="password-wrapper">
          <input
            type={showPassword ? "text" : "password"}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            autoComplete="current-password"
            required
          />
          <button
            type="button"
            className="password-toggle"
            onClick={() => setShowPassword((v) => !v)}
            aria-label={showPassword ? "Hide password" : "Show password"}
          >
            {showPassword ? "Hide" : "Show"}
          </button>
        </div>
      </label>

      <div className="forgot-row">
        <a href="/forgot-password" className="forgot-link">
          Forgot password?
        </a>
      </div>

      {error && (
        <p className="auth-error" role="alert">
          {error}
        </p>
      )}

      <button type="submit" disabled={isSubmitting || !email || !password}>
        {isSubmitting ? "Signing in..." : "Sign in"}
      </button>

      <p className="auth-switch">
        Don&apos;t have an account?{" "}
        <button type="button" className="link-button" onClick={onSwitchMode}>
          Create one
        </button>
      </p>
    </form>
  );
}

interface SignupFormProps {
  onAuthenticated: (customer: CustomerSession) => void;
  onSwitchMode: () => void;
}

function SignupForm({ onAuthenticated, onSwitchMode }: SignupFormProps) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const passwordMismatch = confirmPassword.length > 0 && password !== confirmPassword;

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (passwordMismatch) return;

    if (password.length < 8) {
      setError("Password must be at least 8 characters.");
      return;
    }

    setError(null);
    setIsSubmitting(true);

    try {
      const response = await fetch("/api/internal/auth/signup", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ email: email.trim(), password })
      });

      if (response.ok) {
        const data = (await response.json()) as { customer: CustomerSession };
        onAuthenticated(data.customer);
        return;
      }

      if (response.status === 409) {
        setError("An account already exists for that email. Try signing in.");
      } else if (response.status === 422) {
        const data = (await response.json()) as { error?: string };
        setError(data.error ?? "Invalid email or password format.");
      } else {
        setError("Account creation failed. Please try again.");
      }
    } catch {
      setError("Network error. Please check your connection.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
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
        />
      </label>

      <label>
        <span className="field-label">Password</span>
        <div className="password-wrapper">
          <input
            type={showPassword ? "text" : "password"}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Min. 8 characters"
            autoComplete="new-password"
            required
          />
          <button
            type="button"
            className="password-toggle"
            onClick={() => setShowPassword((v) => !v)}
            aria-label={showPassword ? "Hide password" : "Show password"}
          >
            {showPassword ? "Hide" : "Show"}
          </button>
        </div>
      </label>

      <label>
        <span className="field-label">Confirm password</span>
        <input
          type={showPassword ? "text" : "password"}
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
        disabled={isSubmitting || !email || !password || !confirmPassword || passwordMismatch}
      >
        {isSubmitting ? "Creating account..." : "Create account"}
      </button>

      <p className="auth-switch">
        Already have an account?{" "}
        <button type="button" className="link-button" onClick={onSwitchMode}>
          Sign in
        </button>
      </p>
    </form>
  );
}

export function AuthPage({ onAuthenticated }: AuthPageProps) {
  const [mode, setMode] = useState<AuthMode>("login");

  return (
    <main className="app-shell">
      <section className="panel auth-panel">
        <div className="auth-logo">
          <span className="auth-logo-text">Foreman</span>
        </div>

        <div className="auth-tabs" role="tablist">
          <button
            role="tab"
            aria-selected={mode === "login"}
            className={`auth-tab${mode === "login" ? " auth-tab--active" : ""}`}
            onClick={() => setMode("login")}
          >
            Sign in
          </button>
          <button
            role="tab"
            aria-selected={mode === "signup"}
            className={`auth-tab${mode === "signup" ? " auth-tab--active" : ""}`}
            onClick={() => setMode("signup")}
          >
            Create account
          </button>
        </div>

        <OAuthButtons />
        <Divider />

        {mode === "login" ? (
          <LoginForm onAuthenticated={onAuthenticated} onSwitchMode={() => setMode("signup")} />
        ) : (
          <SignupForm onAuthenticated={onAuthenticated} onSwitchMode={() => setMode("login")} />
        )}
      </section>
    </main>
  );
}
