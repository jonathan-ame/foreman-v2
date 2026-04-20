import { useEffect, useState } from "react";
import { NavLink, Outlet, useNavigate } from "react-router-dom";

interface CustomerSession {
  customer_id: string;
  email: string;
  display_name: string;
  current_tier: string | null;
  current_billing_mode: string;
}

export interface DashboardContext {
  customer: CustomerSession;
}

function HomeIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
      <path d="M8 1.5L1.5 7v7h4v-4h5v4h4V7L8 1.5z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
    </svg>
  );
}

function ProjectsIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
      <rect x="1.5" y="1.5" width="5" height="5" rx="1" stroke="currentColor" strokeWidth="1.5" />
      <rect x="9.5" y="1.5" width="5" height="5" rx="1" stroke="currentColor" strokeWidth="1.5" />
      <rect x="1.5" y="9.5" width="5" height="5" rx="1" stroke="currentColor" strokeWidth="1.5" />
      <rect x="9.5" y="9.5" width="5" height="5" rx="1" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

function TeamIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
      <circle cx="6" cy="5" r="2.5" stroke="currentColor" strokeWidth="1.5" />
      <path d="M1.5 13.5c0-2.485 2.015-4.5 4.5-4.5s4.5 2.015 4.5 4.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
      <circle cx="11.5" cy="5" r="2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M14.5 13c0-1.933-1.343-3.5-3-3.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function InboxIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
      <path
        d="M1.5 10.5h3l1.5 2h4l1.5-2h3v3a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-3z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
      <path d="M1.5 10.5l2-7.5h9l2 7.5" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
    </svg>
  );
}

function SettingsIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
      <circle cx="8" cy="8" r="2.5" stroke="currentColor" strokeWidth="1.5" />
      <path
        d="M8 1v1.5M8 13.5V15M15 8h-1.5M2.5 8H1M12.364 3.636l-1.06 1.06M4.696 11.304l-1.06 1.06M12.364 12.364l-1.06-1.06M4.696 4.696l-1.06-1.06"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
      />
    </svg>
  );
}

function EconomicsIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
      <path d="M1.5 12l3.5-4 3 2.5 3-5 3 3" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M1.5 14.5h13" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

interface SidebarNavProps {
  pendingApprovals: number;
  customer: CustomerSession;
}

function SidebarNav({ pendingApprovals, customer }: SidebarNavProps) {
  const navigate = useNavigate();

  const handleSignOut = async () => {
    await fetch("/api/internal/auth/logout", { method: "POST", credentials: "include" });
    navigate("/app");
  };

  return (
    <nav className="dash-sidebar" aria-label="Main navigation">
      <div className="dash-sidebar-top">
        <div className="dash-logo">
          <span className="dash-logo-text">Foreman</span>
        </div>

        <ul className="dash-nav-list" role="list">
          <li>
            <NavLink to="/dashboard" end className={({ isActive }) => `dash-nav-item${isActive ? " dash-nav-item--active" : ""}`}>
              <HomeIcon />
              <span>Chief of Staff</span>
            </NavLink>
          </li>
          <li>
            <NavLink to="/dashboard/projects" className={({ isActive }) => `dash-nav-item${isActive ? " dash-nav-item--active" : ""}`}>
              <ProjectsIcon />
              <span>Projects</span>
            </NavLink>
          </li>
          <li>
            <NavLink to="/dashboard/team" className={({ isActive }) => `dash-nav-item${isActive ? " dash-nav-item--active" : ""}`}>
              <TeamIcon />
              <span>Team</span>
            </NavLink>
          </li>
          <li>
            <NavLink to="/dashboard/inbox" className={({ isActive }) => `dash-nav-item${isActive ? " dash-nav-item--active" : ""}`}>
              <InboxIcon />
              <span>Inbox</span>
              {pendingApprovals > 0 && (
                <span className="dash-badge" aria-label={`${pendingApprovals} pending`}>
                  {pendingApprovals}
                </span>
              )}
            </NavLink>
          </li>
          <li>
            <NavLink to="/dashboard/economics" className={({ isActive }) => `dash-nav-item${isActive ? " dash-nav-item--active" : ""}`}>
              <EconomicsIcon />
              <span>Economics</span>
            </NavLink>
          </li>
        </ul>
      </div>

      <div className="dash-sidebar-bottom">
        <NavLink to="/dashboard/settings" className={({ isActive }) => `dash-nav-item${isActive ? " dash-nav-item--active" : ""}`}>
          <SettingsIcon />
          <span>Settings</span>
        </NavLink>
        <button type="button" className="dash-user-row" onClick={handleSignOut} title="Sign out">
          <div className="dash-user-avatar" aria-hidden="true">
            {customer.display_name.charAt(0).toUpperCase()}
          </div>
          <div className="dash-user-info">
            <span className="dash-user-name">{customer.display_name}</span>
            <span className="dash-user-email">{customer.email}</span>
          </div>
        </button>
      </div>
    </nav>
  );
}

export function DashboardLayout() {
  const [customer, setCustomer] = useState<CustomerSession | null>(null);
  const [loading, setLoading] = useState(true);
  const [pendingApprovals, setPendingApprovals] = useState(0);
  const navigate = useNavigate();

  useEffect(() => {
    const check = async () => {
      try {
        const res = await fetch("/api/internal/auth/me", { credentials: "include" });
        if (!res.ok) {
          navigate("/app");
          return;
        }
        const data = (await res.json()) as { customer: CustomerSession };
        setCustomer(data.customer);
      } catch {
        navigate("/app");
      } finally {
        setLoading(false);
      }
    };
    void check();
  }, [navigate]);

  useEffect(() => {
    if (!customer) return;
    const load = async () => {
      try {
        const res = await fetch("/api/internal/approvals/pending", { credentials: "include" });
        if (res.ok) {
          const data = (await res.json()) as { count: number };
          setPendingApprovals(data.count ?? 0);
        }
      } catch {
        // non-fatal: badge stays at 0
      }
    };
    void load();
  }, [customer]);

  if (loading) {
    return (
      <div className="dash-loading">
        <p>Loading...</p>
      </div>
    );
  }

  if (!customer) return null;

  return (
    <div className="dash-shell">
      <SidebarNav pendingApprovals={pendingApprovals} customer={customer} />
      <main className="dash-main">
        <Outlet context={{ customer } satisfies DashboardContext} />
      </main>
    </div>
  );
}
