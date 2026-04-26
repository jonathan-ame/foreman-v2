import { useEffect, useState } from "react";
import { useOutletContext } from "react-router-dom";
import type { DashboardContext } from "./DashboardLayout";

interface Connection {
  id: string;
  connected_account_id: string;
  toolkit_slug: string;
  toolkit_name: string | null;
  status: string;
  created_at: string;
}

interface Toolkit {
  slug: string;
  name: string;
  logo?: string;
  categories?: string[];
}

export function Integrations() {
  useOutletContext<DashboardContext>();
  const [connections, setConnections] = useState<Connection[]>([]);
  const [toolkits, setToolkits] = useState<Toolkit[]>([]);
  const [loading, setLoading] = useState(true);
  const [connecting, setConnecting] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const loadConnections = async () => {
    try {
      const res = await fetch("/api/internal/composio/connections", { credentials: "include" });
      if (res.ok) {
        const data = (await res.json()) as { connections: Connection[] };
        setConnections(data.connections);
      }
    } catch {
      // non-fatal
    }
  };

  const loadToolkits = async () => {
    try {
      const res = await fetch("/api/internal/composio/toolkits", { credentials: "include" });
      if (res.ok) {
        const data = (await res.json()) as { toolkits: Toolkit[] };
        setToolkits(data.toolkits);
      }
    } catch {
      // non-fatal — Composio may not be configured
    }
  };

  useEffect(() => {
    const load = async () => {
      await Promise.all([loadConnections(), loadToolkits()]);
      setLoading(false);
    };
    void load();
  }, []);

  const handleConnect = async (toolkitSlug: string) => {
    setConnecting(toolkitSlug);
    setError(null);
    try {
      const res = await fetch("/api/internal/composio/connections/authorize", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          toolkit: toolkitSlug,
          redirect_url: `${window.location.origin}/dashboard/integrations`
        })
      });

      if (!res.ok) {
        const data = (await res.json()) as { error: string };
        setError(data.error === "composio_not_configured" ? "Integrations are not yet configured for this workspace." : "Failed to connect. Please try again.");
        return;
      }

      const data = (await res.json()) as { connect_url: string };
      window.open(data.connect_url, "_blank", "width=600,height=700");

      setTimeout(() => void loadConnections(), 5000);
    } catch {
      setError("Connection failed. Please try again.");
    } finally {
      setConnecting(null);
    }
  };

  const handleDisconnect = async (connectedAccountId: string, toolkitSlug: string) => {
    if (!confirm(`Disconnect ${toolkitSlug}? Your agents will lose access to this integration.`)) return;
    try {
      const res = await fetch("/api/internal/composio/connections", {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ connected_account_id: connectedAccountId })
      });
      if (res.ok) {
        await loadConnections();
      }
    } catch {
      // non-fatal
    }
  };

  const connectedSlugs = new Set(connections.map((c) => c.toolkit_slug));

  const popularToolkits = [
    { slug: "github", name: "GitHub", description: "Issues, PRs, code management" },
    { slug: "slack", name: "Slack", description: "Messages, channels, workflows" },
    { slug: "gmail", name: "Gmail", description: "Email reading and sending" },
    { slug: "linear", name: "Linear", description: "Issues, projects, cycles" },
    { slug: "notion", name: "Notion", description: "Pages, databases, wikis" },
    { slug: "jira", name: "Jira", description: "Issues, boards, sprints" },
    { slug: "hubspot", name: "HubSpot", description: "CRM, contacts, deals" },
    { slug: "figma", name: "Figma", description: "Design files, comments" }
  ];

  return (
    <div className="dash-content-shell">
      <header className="dash-content-header">
        <h1 className="dash-content-title">Integrations</h1>
        <p className="muted">Connect external tools so your agents can take action on your behalf.</p>
      </header>

      {error && <div className="error-banner">{error}</div>}

      {loading && <p className="muted">Loading integrations...</p>}

      {!loading && (
        <div className="settings-sections">
          {/* Connected integrations */}
          {connections.length > 0 && (
            <section className="settings-section">
              <h2 className="settings-section-title">Connected</h2>
              <div className="integrations-grid">
                {connections.map((conn) => (
                  <div key={conn.id} className="integration-card integration-card--connected">
                    <div className="integration-card-info">
                      <span className="integration-card-name">
                        {conn.toolkit_name ?? conn.toolkit_slug}
                      </span>
                      <span className="integration-card-slug">{conn.toolkit_slug}</span>
                    </div>
                    <button
                      type="button"
                      className="button-danger button-sm"
                      onClick={() => handleDisconnect(conn.connected_account_id, conn.toolkit_slug)}
                    >
                      Disconnect
                    </button>
                  </div>
                ))}
              </div>
            </section>
          )}

          {/* Popular toolkits */}
          <section className="settings-section">
            <h2 className="settings-section-title">Available integrations</h2>
            <div className="integrations-grid">
              {popularToolkits.map((toolkit) => {
                const isConnected = connectedSlugs.has(toolkit.slug);
                return (
                  <div key={toolkit.slug} className={`integration-card${isConnected ? " integration-card--connected" : ""}`}>
                    <div className="integration-card-info">
                      <span className="integration-card-name">{toolkit.name}</span>
                      <span className="integration-card-desc">{toolkit.description}</span>
                    </div>
                    {isConnected ? (
                      <span className="success-text">Connected</span>
                    ) : (
                      <button
                        type="button"
                        className="button-primary button-sm"
                        disabled={connecting !== null}
                        onClick={() => handleConnect(toolkit.slug)}
                      >
                        {connecting === toolkit.slug ? "Connecting..." : "Connect"}
                      </button>
                    )}
                  </div>
                );
              })}
            </div>
          </section>

          {/* Browse all toolkits */}
          {toolkits.length > 0 && (
            <section className="settings-section">
              <h2 className="settings-section-title">Browse all toolkits</h2>
              <p className="muted">
                {toolkits.length} toolkits available via Composio — your agents can discover and use any of them at runtime.
              </p>
            </section>
          )}

          {/* Info box */}
          <section className="settings-section">
            <h2 className="settings-section-title">How it works</h2>
            <div className="info-box">
              <p>When you connect a tool, your Foreman agents gain access to it through Composio.</p>
              <ul>
                <li>Agents discover relevant tools at runtime using natural language</li>
                <li>OAuth connections are managed securely — tokens are refreshed automatically</li>
                <li>Each agent role has recommended integrations based on its responsibilities</li>
                <li>You can disconnect any integration at any time</li>
              </ul>
            </div>
          </section>
        </div>
      )}
    </div>
  );
}
