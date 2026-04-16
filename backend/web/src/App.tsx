import { type FormEvent, useEffect, useState } from "react";
import { CreateCEO } from "./pages/CreateCEO";

interface CustomerSession {
  customer_id: string;
  email: string;
  display_name: string;
  current_tier: string | null;
  current_billing_mode: string;
}

interface LoginState {
  email: string;
  isSubmitting: boolean;
  error: string | null;
}

export function App() {
  const [customer, setCustomer] = useState<CustomerSession | null>(null);
  const [loadingSession, setLoadingSession] = useState(true);
  const [loginState, setLoginState] = useState<LoginState>({
    email: "",
    isSubmitting: false,
    error: null
  });

  useEffect(() => {
    const fetchSession = async () => {
      try {
        const response = await fetch("/api/internal/auth/me", {
          credentials: "include"
        });
        if (!response.ok) {
          setLoadingSession(false);
          return;
        }
        const data = (await response.json()) as { customer: CustomerSession };
        setCustomer(data.customer);
      } catch {
        setCustomer(null);
      } finally {
        setLoadingSession(false);
      }
    };

    void fetchSession();
  }, []);

  const submitDevLogin = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setLoginState((previous) => ({
      ...previous,
      isSubmitting: true,
      error: null
    }));

    try {
      const response = await fetch("/api/internal/auth/dev-login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        credentials: "include",
        body: JSON.stringify({
          email: loginState.email.trim()
        })
      });
      if (!response.ok) {
        setLoginState((previous) => ({
          ...previous,
          isSubmitting: false,
          error: response.status === 404 ? "No customer was found for that email." : "Unable to sign in."
        }));
        return;
      }

      const data = (await response.json()) as { customer: CustomerSession };
      setCustomer(data.customer);
      setLoginState((previous) => ({
        ...previous,
        isSubmitting: false,
        error: null
      }));
    } catch {
      setLoginState((previous) => ({
        ...previous,
        isSubmitting: false,
        error: "Login request failed. Try again."
      }));
    }
  };

  if (loadingSession) {
    return (
      <main className="app-shell">
        <section className="panel">
          <p>Checking session...</p>
        </section>
      </main>
    );
  }

  if (!customer) {
    return (
      <main className="app-shell">
        <section className="panel">
          <h1>Create your CEO</h1>
          <p className="muted">Dev login is enabled in non-production environments.</p>
          <form className="stack" onSubmit={submitDevLogin}>
            <label className="field">
              <span>Customer email</span>
              <input
                type="email"
                value={loginState.email}
                onChange={(event) =>
                  setLoginState((previous) => ({
                    ...previous,
                    email: event.target.value
                  }))
                }
                required
              />
            </label>
            {loginState.error ? <p className="error-text">{loginState.error}</p> : null}
            <button type="submit" disabled={loginState.isSubmitting}>
              {loginState.isSubmitting ? "Signing in..." : "Sign in (dev)"}
            </button>
          </form>
        </section>
      </main>
    );
  }

  return <CreateCEO customer={customer} />;
}
