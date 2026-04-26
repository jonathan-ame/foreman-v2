import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";

interface AgentNode {
  id: string;
  name: string;
  role: string;
  status: "active" | "idle" | "offline" | "running" | "paused";
  current_task: string | null;
  reports_to_id: string | null;
  adapterType?: string;
  capabilities?: string;
}

const STATUS_DOT: Record<string, string> = {
  active: "team-dot team-dot--active",
  running: "team-dot team-dot--active",
  idle: "team-dot team-dot--idle",
  paused: "team-dot team-dot--idle",
  offline: "team-dot team-dot--offline"
};

function AgentCard({ agent }: { agent: AgentNode }) {
  const navigate = useNavigate();
  return (
    <button
      type="button"
      className="team-card team-card--clickable"
      onClick={() => navigate(`/dashboard/team/${agent.id}`)}
      aria-label={`View agent ${agent.name}`}
    >
      <div className="team-card-header">
        <div className="team-card-avatar" aria-hidden="true">
          {agent.role.charAt(0).toUpperCase()}
        </div>
        <div className="team-card-identity">
          <span className="team-card-name">{agent.name}</span>
          <span className="team-card-role muted">{agent.role}</span>
        </div>
        <span className={STATUS_DOT[agent.status] ?? "team-dot team-dot--offline"} aria-label={agent.status} />
      </div>
      {agent.current_task && (
        <p className="team-card-task muted">{agent.current_task}</p>
      )}
    </button>
  );
}

function buildTree(agents: AgentNode[]): { roots: AgentNode[]; children: Map<string, AgentNode[]> } {
  const children = new Map<string, AgentNode[]>();
  const roots: AgentNode[] = [];
  for (const a of agents) {
    if (!a.reports_to_id) {
      roots.push(a);
    } else {
      const list = children.get(a.reports_to_id) ?? [];
      list.push(a);
      children.set(a.reports_to_id, list);
    }
  }
  return { roots, children };
}

function OrgNode({ agent, children }: { agent: AgentNode; children: AgentNode[] }) {
  return (
    <li className="org-node">
      <AgentCard agent={agent} />
      {children.length > 0 && (
        <ul className="org-children" role="list">
          {children.map((child) => (
            <OrgNode key={child.id} agent={child} children={[]} />
          ))}
        </ul>
      )}
    </li>
  );
}

export function Team() {
  const [agents, setAgents] = useState<AgentNode[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      try {
        const res = await fetch("/api/internal/team", { credentials: "include" });
        if (res.ok) {
          const data = (await res.json()) as { agents: AgentNode[] };
          setAgents(data.agents ?? []);
        }
      } catch {
        // non-fatal
      } finally {
        setLoading(false);
      }
    };
    void load();
  }, []);

  const { roots, children } = buildTree(agents);

  return (
    <div className="dash-content-shell">
      <header className="dash-content-header">
        <h1 className="dash-content-title">Team</h1>
        {agents.length > 0 && (
          <span className="dash-content-meta muted">{agents.length} agent{agents.length !== 1 ? "s" : ""}</span>
        )}
      </header>

      {loading && <p className="muted">Loading team…</p>}

      {!loading && agents.length === 0 && (
        <div className="dash-empty">
          <p className="dash-empty-text">Grow your team — ask your Chief of Staff to hire agents for specific roles like marketing, engineering, or design.</p>
          <a href="/dashboard" className="button-primary" style={{ display: "inline-block", marginTop: 12, textDecoration: "none", fontSize: 14, padding: "8px 20px" }}>
            Suggest a hire
          </a>
        </div>
      )}

      {!loading && agents.length > 0 && (
        <ul className="org-tree" role="list" aria-label="Org chart">
          {roots.map((root) => (
            <OrgNode key={root.id} agent={root} children={children.get(root.id) ?? []} />
          ))}
        </ul>
      )}
    </div>
  );
}
