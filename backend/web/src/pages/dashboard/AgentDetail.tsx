import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";

interface AgentInfo {
  id: string;
  name: string;
  role: string;
  status: string;
  adapterType: string;
  capabilities?: string;
  lastHeartbeatAt?: string;
}

interface TaskSummary {
  id: string;
  identifier?: string;
  title: string;
  status: string;
  priority: string;
  updatedAt: string;
}

function relativeTime(iso: string) {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60_000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

const STATUS_DOT: Record<string, string> = {
  running: "agent-status-dot agent-status-dot--running",
  idle: "agent-status-dot agent-status-dot--idle",
  offline: "agent-status-dot agent-status-dot--offline",
  paused: "agent-status-dot agent-status-dot--idle"
};

const STATUS_LABEL: Record<string, string> = {
  running: "Running",
  idle: "Idle",
  offline: "Offline",
  paused: "Paused",
  active: "Active"
};

export function AgentDetail() {
  const { agentId } = useParams();
  const navigate = useNavigate();
  const [agent, setAgent] = useState<AgentInfo | null>(null);
  const [tasks, setTasks] = useState<TaskSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [triggeringHeartbeat, setTriggeringHeartbeat] = useState(false);

  useEffect(() => {
    if (!agentId) return;
    const load = async () => {
      try {
        const [agentRes, inboxRes] = await Promise.all([
          fetch(`/api/internal/agents/${agentId}`, { credentials: "include" }),
          fetch(`/api/internal/agents/${agentId}/inbox`, { credentials: "include" })
        ]);
        if (agentRes.ok) {
          const data = (await agentRes.json()) as { agent: AgentInfo };
          setAgent(data.agent);
        }
        if (inboxRes.ok) {
          const data = (await inboxRes.json()) as { inbox: TaskSummary[] };
          setTasks(data.inbox ?? []);
        }
      } catch {
        // non-fatal
      } finally {
        setLoading(false);
      }
    };
    void load();
  }, [agentId]);

  const triggerHeartbeat = async () => {
    if (!agentId || triggeringHeartbeat) return;
    setTriggeringHeartbeat(true);
    try {
      await fetch(`/api/internal/agents/${agentId}/heartbeat`, {
        method: "POST",
        credentials: "include"
      });
    } catch {
      // non-fatal
    } finally {
      setTriggeringHeartbeat(false);
    }
  };

  if (loading) return <div className="dash-loading"><p>Loading agent…</p></div>;
  if (!agent) return <div className="dash-empty"><p className="dash-empty-text">Agent not found.</p></div>;

  const statusClass = STATUS_DOT[agent.status] ?? STATUS_DOT.offline;
  const statusLabel = STATUS_LABEL[agent.status] ?? agent.status;

  return (
    <div className="agent-detail-shell">
      <button type="button" className="task-back-btn" onClick={() => navigate("/dashboard/team")}>
        ← Back to Team
      </button>

      <div className="agent-detail-header">
        <div className="agent-detail-avatar">{agent.name.charAt(0).toUpperCase()}</div>
        <div className="agent-detail-identity">
          <h1 className="agent-detail-name">{agent.name}</h1>
          <div className="agent-detail-meta">
            <span className={statusClass} /> {statusLabel}
            <span className="muted">·</span>
            <span className="muted">{agent.role}</span>
            <span className="muted">·</span>
            <span className="muted">{agent.adapterType}</span>
          </div>
        </div>
        <button
          type="button"
          className="button-secondary"
          onClick={() => void triggerHeartbeat()}
          disabled={triggeringHeartbeat}
        >
          {triggeringHeartbeat ? "Triggering…" : "Trigger Heartbeat"}
        </button>
      </div>

      {agent.capabilities && (
        <section className="agent-detail-section">
          <h2 className="agent-detail-section-title">Capabilities</h2>
          <p className="agent-detail-capabilities">{agent.capabilities}</p>
        </section>
      )}

      <section className="agent-detail-section">
        <h2 className="agent-detail-section-title">Active Tasks ({tasks.length})</h2>
        {tasks.length === 0 && (
          <p className="muted">No active tasks assigned to this agent.</p>
        )}
        {tasks.length > 0 && (
          <ul className="task-list" role="list">
            {tasks.map((task) => (
              <li
                key={task.id}
                className="task-row"
                role="button"
                tabIndex={0}
                onClick={() => navigate(`/dashboard/tasks/${task.id}`)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    navigate(`/dashboard/tasks/${task.id}`);
                  }
                }}
                aria-label={`View task ${task.title}`}
              >
                <div className="task-row-body">
                  <p className="task-row-title">
                    {task.identifier && <span className="task-identifier">{task.identifier}</span>}
                    {task.title}
                  </p>
                  <div className="task-row-meta">
                    <span className="muted">{task.status}</span>
                    <span className="muted">{relativeTime(task.updatedAt)}</span>
                  </div>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}