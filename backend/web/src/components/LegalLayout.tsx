import { Link } from "react-router-dom";

interface LegalLayoutProps {
  title: string;
  lastUpdated: string;
  children: React.ReactNode;
}

export function LegalLayout({ title, lastUpdated, children }: LegalLayoutProps) {
  return (
    <div className="legal-page">
      <div className="legal-page-inner">
        <Link to="/" className="legal-back">
          ← Back to foreman.company
        </Link>
        <h1>{title}</h1>
        <p className="legal-updated">Last updated: {lastUpdated}</p>
        <div className="legal-body">{children}</div>
        <div className="legal-footer">
          <p>
            Questions? Email us at{" "}
            <a href="mailto:legal@foreman.company">legal@foreman.company</a>
          </p>
        </div>
      </div>
    </div>
  );
}
