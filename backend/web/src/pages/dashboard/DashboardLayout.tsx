import { useCallback, useEffect, useRef, useState } from "react";
import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { useFocusTrap, FOCUSABLE_SELECTOR, getFocusableElements } from "../../utils/useFocusTrap";

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

function TasksIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
      <rect x="1.5" y="2" width="13" height="12" rx="2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M5 6h6M5 8.5h4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function IntegrationsIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
      <path d="M5.5 3.5h5v2h2v5h-2v2h-5v-2h-2v-5h2v-2z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
      <circle cx="8" cy="8" r="1.5" fill="currentColor" />
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

function HamburgerIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 20 20" fill="none" aria-hidden="true">
      <path d="M3 5h14M3 10h14M3 15h14" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function CloseIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 20 20" fill="none" aria-hidden="true">
      <path d="M5 5l10 10M15 5L5 15" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

interface SidebarNavProps {
  pendingApprovals: number;
  customer: CustomerSession;
  onClose?: () => void;
  className?: string;
  sidebarRef?: React.RefObject<HTMLDivElement | null>;
  isModal?: boolean;
  navId?: string;
}

const FOCUSABLE_SELECTOR =
  'a[href],button:not([disabled]),input:not([disabled]):not([type="hidden"]),select:not([disabled]),textarea:not([disabled]),[tabindex]:not([tabindex="-1"])';

function getFocusableElements(container: HTMLElement): HTMLElement[] {
  return Array.from(container.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR)).filter(
    (el) => el.offsetParent !== null
  );
}

function SidebarNav({ pendingApprovals, customer, onClose, className, sidebarRef, isModal, navId }: SidebarNavProps) {
  const navigate = useNavigate();

  const handleSignOut = async () => {
    await fetch("/api/internal/auth/logout", { method: "POST", credentials: "include" });
    navigate("/app");
  };

  const handleNavClick = () => {
    onClose?.();
  };

  const handleNavKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLElement>) => {
      if (!isModal) return;

      const container = e.currentTarget;
      const focusable = getFocusableElements(container);
      if (focusable.length === 0) return;

      const activeIndex = focusable.indexOf(document.activeElement as HTMLElement);
      if (activeIndex === -1) return;

      let nextIndex = -1;

      switch (e.key) {
        case "ArrowDown":
          e.preventDefault();
          nextIndex = activeIndex + 1 < focusable.length ? activeIndex + 1 : 0;
          break;
        case "ArrowUp":
          e.preventDefault();
          nextIndex = activeIndex - 1 >= 0 ? activeIndex - 1 : focusable.length - 1;
          break;
        case "Home":
          e.preventDefault();
          nextIndex = 0;
          break;
        case "End":
          e.preventDefault();
          nextIndex = focusable.length - 1;
          break;
        default:
          return;
      }

      focusable[nextIndex]?.focus();
    },
    [isModal]
  );

  return (
    <nav
      id={navId}
      ref={sidebarRef}
      className={`dash-sidebar${className ? ` ${className}` : ""}`}
      role={isModal ? "dialog" : undefined}
      aria-modal={isModal ? "true" : undefined}
      aria-label="Main navigation"
      onKeyDown={handleNavKeyDown}
    >
      <div className="dash-sidebar-top">
        <div className="dash-logo">
          <span className="dash-logo-text">Foreman</span>
        </div>

        <ul className="dash-nav-list" role="list">
          <li>
            <NavLink to="/dashboard" end className={({ isActive }) => `dash-nav-item${isActive ? " dash-nav-item--active" : ""}`} onClick={handleNavClick}>
              <HomeIcon />
              <span>Chief of Staff</span>
            </NavLink>
          </li>
          <li>
            <NavLink to="/dashboard/projects" className={({ isActive }) => `dash-nav-item${isActive ? " dash-nav-item--active" : ""}`} onClick={handleNavClick}>
              <ProjectsIcon />
              <span>Projects</span>
            </NavLink>
          </li>
          <li>
            <NavLink to="/dashboard/team" className={({ isActive }) => `dash-nav-item${isActive ? " dash-nav-item--active" : ""}`} onClick={handleNavClick}>
              <TeamIcon />
              <span>Team</span>
            </NavLink>
          </li>
          <li>
            <NavLink to="/dashboard/inbox" className={({ isActive }) => `dash-nav-item${isActive ? " dash-nav-item--active" : ""}`} onClick={handleNavClick}>
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
            <NavLink to="/dashboard/tasks" className={({ isActive }) => `dash-nav-item${isActive ? " dash-nav-item--active" : ""}`} onClick={handleNavClick}>
              <TasksIcon />
              <span>Tasks</span>
            </NavLink>
          </li>
          <li>
            <NavLink to="/dashboard/economics" className={({ isActive }) => `dash-nav-item${isActive ? " dash-nav-item--active" : ""}`} onClick={handleNavClick}>
              <EconomicsIcon />
              <span>Economics</span>
            </NavLink>
          </li>
          <li>
            <NavLink to="/dashboard/integrations" className={({ isActive }) => `dash-nav-item${isActive ? " dash-nav-item--active" : ""}`} onClick={handleNavClick}>
              <IntegrationsIcon />
              <span>Integrations</span>
            </NavLink>
          </li>
        </ul>
      </div>

      <div className="dash-sidebar-bottom">
        <NavLink to="/dashboard/settings" className={({ isActive }) => `dash-nav-item${isActive ? " dash-nav-item--active" : ""}`} onClick={handleNavClick}>
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

      {onClose && (
        <button type="button" className="dash-sidebar-close" onClick={onClose} aria-label="Close navigation">
          <CloseIcon />
        </button>
      )}
    </nav>
  );
}

export function DashboardLayout() {
  const [customer, setCustomer] = useState<CustomerSession | null>(null);
  const [loading, setLoading] = useState(true);
  const [pendingApprovals, setPendingApprovals] = useState(0);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const navigate = useNavigate();
  const hamburgerRef = useRef<HTMLButtonElement>(null);
  const sidebarRef = useFocusTrap(sidebarOpen);

  const sidebarId = "dash-sidebar-nav";

  const closeSidebar = useCallback(() => {
    setSidebarOpen(false);
  }, []);

  useEffect(() => {
    if (!sidebarOpen) return;
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        e.preventDefault();
        closeSidebar();
      }
    };
    document.addEventListener("keydown", handleEscape);
    return () => document.removeEventListener("keydown", handleEscape);
  }, [sidebarOpen, closeSidebar]);

  useEffect(() => {
    if (sidebarOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [sidebarOpen]);

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
      <header className="dash-mobile-header">
        <button type="button" ref={hamburgerRef} className="dash-mobile-hamburger" onClick={() => setSidebarOpen(true)} aria-label="Open navigation menu" aria-expanded={sidebarOpen} aria-controls={sidebarId}>
          <HamburgerIcon />
        </button>
        <span className="dash-mobile-title">Foreman</span>
      </header>

      {sidebarOpen && (
        <div className="dash-overlay dash-overlay--visible" onClick={closeSidebar} role="presentation" />
      )}

      <SidebarNav pendingApprovals={pendingApprovals} customer={customer} onClose={closeSidebar} className={sidebarOpen ? "dash-sidebar--open" : undefined} sidebarRef={sidebarRef} isModal={sidebarOpen} navId={sidebarId} />

      <main className="dash-main">
        <Outlet context={{ customer } satisfies DashboardContext} />
      </main>
    </div>
  );
}
