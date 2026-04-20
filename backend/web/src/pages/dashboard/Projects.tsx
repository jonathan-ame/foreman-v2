import { useEffect, useState } from "react";

interface Project {
  id: string;
  name: string;
  status: "active" | "planned" | "paused" | "done";
  owner_name: string;
  open_tasks: number;
  updated_at: string;
}

const STATUS_LABEL: Record<Project["status"], string> = {
  active: "Active",
  planned: "Planned",
  paused: "Paused",
  done: "Done"
};

function statusClass(status: Project["status"]) {
  return `proj-status proj-status--${status}`;
}

function relativeDate(iso: string) {
  const diff = Date.now() - new Date(iso).getTime();
  const days = Math.floor(diff / 86_400_000);
  if (days === 0) return "today";
  if (days === 1) return "yesterday";
  if (days < 7) return `${days}d ago`;
  return new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

export function Projects() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      try {
        const res = await fetch("/api/internal/projects", { credentials: "include" });
        if (res.ok) {
          const data = (await res.json()) as { projects: Project[] };
          setProjects(data.projects ?? []);
        }
      } catch {
        // non-fatal
      } finally {
        setLoading(false);
      }
    };
    void load();
  }, []);

  return (
    <div className="dash-content-shell">
      <header className="dash-content-header">
        <h1 className="dash-content-title">Projects</h1>
      </header>

      {loading && <p className="muted">Loading projects…</p>}

      {!loading && projects.length === 0 && (
        <div className="dash-empty">
          <p className="dash-empty-text">No projects yet. Your CEO will create projects as work gets organized.</p>
        </div>
      )}

      {!loading && projects.length > 0 && (
        <div className="proj-table-wrap">
          <table className="proj-table">
            <thead>
              <tr>
                <th>Project</th>
                <th>Status</th>
                <th>Owner</th>
                <th>Open tasks</th>
                <th>Updated</th>
              </tr>
            </thead>
            <tbody>
              {projects.map((p) => (
                <tr key={p.id} className="proj-row">
                  <td className="proj-name">{p.name}</td>
                  <td><span className={statusClass(p.status)}>{STATUS_LABEL[p.status]}</span></td>
                  <td className="muted">{p.owner_name}</td>
                  <td>{p.open_tasks > 0 ? <span className="proj-task-count">{p.open_tasks}</span> : <span className="muted">—</span>}</td>
                  <td className="muted">{relativeDate(p.updated_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
