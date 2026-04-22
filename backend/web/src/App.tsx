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
import { Home } from "./pages/marketing/Home";
import { HowItWorks } from "./pages/marketing/HowItWorks";
import { Pricing } from "./pages/marketing/Pricing";
import { AuthPage } from "./pages/AuthPage";
import { OnboardingWizard } from "./pages/OnboardingWizard";
import { DashboardLayout } from "./pages/dashboard/DashboardLayout";
import { ChiefOfStaff } from "./pages/dashboard/ChiefOfStaff";
import { EconomicsDashboard } from "./pages/dashboard/EconomicsDashboard";
import { Projects } from "./pages/dashboard/Projects";
import { Team } from "./pages/dashboard/Team";
import { Inbox } from "./pages/dashboard/Inbox";
import { Settings } from "./pages/dashboard/Settings";
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
}

function AppShell() {
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

  return <OnboardingWizard customer={customer} />;
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
          <Route path="inbox" element={<Inbox />} />
          <Route path="settings" element={<Settings />} />
          <Route path="economics" element={<EconomicsDashboard />} />
        </Route>

        {/* Fallback */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
