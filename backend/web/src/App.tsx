import { useEffect, useState } from "react";
import { BrowserRouter, Navigate, Route, Routes, useLocation } from "react-router-dom";
import { MarketingLayout } from "./components/MarketingLayout";
import { AcceptableUse } from "./pages/legal/AcceptableUse";
import { Cookies } from "./pages/legal/Cookies";
import { DPA } from "./pages/legal/DPA";
import { Privacy } from "./pages/legal/Privacy";
import { Security } from "./pages/legal/Security";
import { Terms } from "./pages/legal/Terms";
import { About } from "./pages/marketing/About";
import { Blog } from "./pages/marketing/Blog";
import { BlogPost } from "./pages/marketing/BlogPost";
import { Contact } from "./pages/marketing/Contact";
import { EmailPreferences } from "./pages/marketing/EmailPreferences";
import { Home } from "./pages/marketing/Home";
import { HowItWorks } from "./pages/marketing/HowItWorks";
import { Pricing } from "./pages/marketing/Pricing";
import { AuthPage } from "./pages/AuthPage";
import { ForgotPassword } from "./pages/ForgotPassword";
import { ResetPassword } from "./pages/ResetPassword";
import { OnboardingWizard } from "./pages/OnboardingWizard";
import { DashboardLayout } from "./pages/dashboard/DashboardLayout";
import { ChiefOfStaff } from "./pages/dashboard/ChiefOfStaff";
import { EconomicsDashboard } from "./pages/dashboard/EconomicsDashboard";
import { Projects } from "./pages/dashboard/Projects";
import { Team } from "./pages/dashboard/Team";
import { Inbox } from "./pages/dashboard/Inbox";
import { Settings } from "./pages/dashboard/Settings";
import { Integrations } from "./pages/dashboard/Integrations";
import { Tasks, TaskDetail } from "./pages/dashboard/Tasks";
import { AgentDetail } from "./pages/dashboard/AgentDetail";
import { trackPageView } from "./utils/analytics";

function AnalyticsListener() {
  const { pathname } = useLocation();

  useEffect(() => {
    trackPageView(pathname);
  }, [pathname]);

  return null;
}

interface CustomerSession {
  customer_id: string;
  email: string;
  display_name: string;
  current_tier: string | null;
  current_billing_mode: string;
  onboarding_progress: Record<string, string>;
  onboarding_complete: boolean;
}

type AppPhase = "loading" | "auth" | "checking-team" | "onboarding" | "dashboard";

function AppShell() {
  const [customer, setCustomer] = useState<CustomerSession | null>(null);
  const [phase, setPhase] = useState<AppPhase>("loading");

  useEffect(() => {
    const init = async () => {
      try {
        const response = await fetch("/api/internal/auth/me", {
          credentials: "include"
        });
        if (!response.ok) {
          setPhase("auth");
          return;
        }
        const data = (await response.json()) as { customer: CustomerSession };
        setCustomer(data.customer);
        setPhase("checking-team");
      } catch {
        setPhase("auth");
      }
    };

    void init();
  }, []);

  useEffect(() => {
    if (phase !== "checking-team" || !customer) return;

    if (customer.onboarding_complete) {
      setPhase("dashboard");
      return;
    }

    const checkTeam = async () => {
      try {
        const res = await fetch("/api/internal/team", { credentials: "include" });
        if (res.ok) {
          const team = (await res.json()) as { agents: unknown[] };
          if (team.agents.length > 0) {
            await fetch("/api/internal/onboarding/complete-step", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({ step: "complete" }),
              credentials: "include"
            });
            setPhase("dashboard");
            return;
          }
        }
      } catch {
        // fall through to onboarding
      }
      setPhase("onboarding");
    };

    void checkTeam();
  }, [phase, customer]);

  if (phase === "loading" || phase === "checking-team") {
    return (
      <main className="app-shell">
        <section className="panel">
          <p>Checking session…</p>
        </section>
      </main>
    );
  }

  if (phase === "auth" || !customer) {
    return <AuthPage onAuthenticated={setCustomer} />;
  }

  if (phase === "onboarding") {
    return (
      <OnboardingWizard
        customer={customer}
        onComplete={async () => {
          await fetch("/api/internal/onboarding/complete-step", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ step: "complete" }),
            credentials: "include"
          });
          setPhase("dashboard");
        }}
      />
    );
  }

  return <DashboardLayout />;
}

export function App() {
  return (
    <BrowserRouter>
      <AnalyticsListener />
      <Routes>
        {/* Marketing site with shared nav/footer */}
        <Route element={<MarketingLayout />}>
          <Route path="/" element={<Home />} />
          <Route path="/pricing" element={<Pricing />} />
          <Route path="/how-it-works" element={<HowItWorks />} />
          <Route path="/about" element={<About />} />
          <Route path="/contact" element={<Contact />} />
          <Route path="/unsubscribe" element={<EmailPreferences />} />
          <Route path="/preferences" element={<EmailPreferences />} />
          <Route path="/blog" element={<Blog />} />
          <Route path="/blog/:slug" element={<BlogPost />} />
        </Route>

        {/* Legal pages (self-contained layout) */}
        <Route path="/privacy" element={<Privacy />} />
        <Route path="/terms" element={<Terms />} />
        <Route path="/cookies" element={<Cookies />} />
        <Route path="/dpa" element={<DPA />} />
        <Route path="/acceptable-use" element={<AcceptableUse />} />
        <Route path="/security" element={<Security />} />

        {/* Auth routes */}
        <Route path="/forgot-password" element={<ForgotPassword />} />
        <Route path="/reset-password" element={<ResetPassword />} />

        {/* Legacy redirects — old static pages now handled by SPA */}
        <Route path="/login" element={<Navigate to="/app" replace />} />
        <Route path="/landing" element={<Navigate to="/" replace />} />
        <Route path="/signup" element={<Navigate to="/app" replace />} />

        {/* Authenticated app shell (CEO onboarding) */}
        <Route path="/app" element={<AppShell />} />
        <Route path="/app/*" element={<AppShell />} />

        {/* Dashboard — main app after CEO is provisioned */}
        <Route path="/dashboard" element={<DashboardLayout />}>
          <Route index element={<ChiefOfStaff />} />
          <Route path="projects" element={<Projects />} />
          <Route path="team" element={<Team />} />
          <Route path="team/:agentId" element={<AgentDetail />} />
          <Route path="inbox" element={<Inbox />} />
          <Route path="tasks" element={<Tasks />}>
            <Route path=":taskId" element={<TaskDetail />} />
          </Route>
          <Route path="tasks/:taskId" element={<TaskDetail />} />
          <Route path="settings" element={<Settings />} />
          <Route path="integrations" element={<Integrations />} />
          <Route path="economics" element={<EconomicsDashboard />} />
        </Route>

        {/* Fallback */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
