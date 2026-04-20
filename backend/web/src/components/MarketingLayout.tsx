import { Link, NavLink, Outlet } from "react-router-dom";

export function MarketingLayout() {
  return (
    <div className="marketing">
      <header className="marketing-nav">
        <div className="marketing-nav-inner">
          <Link to="/" className="marketing-logo">
            Foreman
          </Link>
          <nav className="marketing-links">
            <NavLink to="/how-it-works">How it works</NavLink>
            <NavLink to="/pricing">Pricing</NavLink>
            <NavLink to="/blog">Blog</NavLink>
            <NavLink to="/about">About</NavLink>
          </nav>
          <div className="marketing-nav-cta">
            <Link to="/contact" className="nav-link-text">
              Contact
            </Link>
            <a href="/app" className="button-primary">
              Get started
            </a>
          </div>
        </div>
      </header>

      <main>
        <Outlet />
      </main>

      <footer className="marketing-footer">
        <div className="marketing-footer-inner">
          <div className="footer-brand">
            <span className="marketing-logo">Foreman</span>
            <p>AI agents for the rest of us.</p>
          </div>
          <div className="footer-links">
            <div className="footer-col">
              <h4>Product</h4>
              <Link to="/how-it-works">How it works</Link>
              <Link to="/pricing">Pricing</Link>
              <Link to="/blog">Blog</Link>
            </div>
            <div className="footer-col">
              <h4>Company</h4>
              <Link to="/about">About</Link>
              <Link to="/contact">Contact</Link>
            </div>
            <div className="footer-col">
              <h4>Legal</h4>
              <Link to="/privacy">Privacy Policy</Link>
              <Link to="/terms">Terms of Service</Link>
              <Link to="/cookies">Cookie Policy</Link>
              <Link to="/dpa">Data Processing Agreement</Link>
              <Link to="/acceptable-use">Acceptable Use</Link>
              <Link to="/security">Security</Link>
            </div>
          </div>
        </div>
        <div className="footer-bottom">
          <p>© {new Date().getFullYear()} Foreman. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
}
