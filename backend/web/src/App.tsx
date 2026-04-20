import { useEffect, useState } from "react";
import { CreateCEO } from "./pages/CreateCEO";
import { AuthPage } from "./pages/AuthPage";

interface CustomerSession {
  customer_id: string;
  email: string;
  display_name: string;
  current_tier: string | null;
  current_billing_mode: string;
}


export function App() {
  const [customer, setCustomer] = useState<CustomerSession | null>(null);
  const [loadingSession, setLoadingSession] = useState(true);

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
    return <AuthPage onAuthenticated={setCustomer} />;
  }

  return <CreateCEO customer={customer} />;
}
