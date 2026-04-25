import { useCallback, useEffect, useRef, useState } from "react";
import { Outlet, useNavigate, useParams } from "react-router-dom";
import { useFocusTrap } from "../../utils/useFocusTrap";

interface TaskSummary {
  id: string;
  identifier?: string;
  title: string;
  status: "backlog" | "todo" | "in_progress" | "in_review" | "done" | "blocked" | "cancelled";
  priority: "critical" | "high" | "medium" | "low";
  assigneeAgentId?: string;
  assigneeAgentName?: string;
  updatedAt: string;
}

const STATUS_LABEL: Record<TaskSummary["status"], string> = {
  backlog: "Backlog",
  todo: "To Do",
  in_progress: "In Progress",
  in_review: "In Review",
  done: "Done",
  blocked: "Blocked",
  cancelled: "Cancelled"
};

const STATUS_ICON: Record<TaskSummary["status"], string> = {
  backlog: "○",
  todo: "◻",
  in_progress: "◐",
  in_review: "◎",
  done: "●",
  blocked: "⊘",
  cancelled: "✕"
};

const PRIORITY_DOT: Record<TaskSummary["priority"], string> = {
  critical: "task-priority-critical",
  high: "task-priority-high",
  medium: "task-priority-medium",
  low: "task-priority-low"
};

const STATUS_COLORS: Record<TaskSummary["status"], string> = {
  backlog: "task-status task-status--backlog",
  todo: "task-status task-status--todo",
  in_progress: "task-status task-status--in-progress",
  in_review: "task-status task-status--in-review",
  done: "task-status task-status--done",
  blocked: "task-status task-status--blocked",
  cancelled: "task-status task-status--cancelled"
};

function relativeTime(iso: string) {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60_000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d ago`;
  return new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

export function Tasks() {
  const [tasks, setTasks] = useState<TaskSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<string>("all");
  const [showCreate, setShowCreate] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    const load = async () => {
      try {
        const params = new URLSearchParams();
        if (filter !== "all") params.set("status", filter);
        const res = await fetch(`/api/internal/tasks?${params}`, { credentials: "include" });
        if (res.ok) {
          const data = (await res.json()) as { tasks: TaskSummary[] };
          setTasks(data.tasks ?? []);
        }
      } catch {
        // non-fatal
      } finally {
        setLoading(false);
      }
    };
    void load();
  }, [filter]);

  const handleCreate = async (title: string, description: string, priority: string, assigneeId?: string) => {
    try {
      const res = await fetch("/api/internal/tasks", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          title,
          description,
          priority,
          assigneeAgentId: assigneeId || undefined
        })
      });
      if (res.ok) {
        const data = (await res.json()) as { task: TaskSummary };
        setTasks((prev) => [data.task, ...prev]);
        setShowCreate(false);
        navigate(`/dashboard/tasks/${data.task.id}`);
      }
    } catch {
      // non-fatal
    }
  };

  const filtered = filter === "all" ? tasks : tasks.filter((t) => t.status === filter);

  return (
    <div className="dash-content-shell">
      <header className="dash-content-header">
        <h1 className="dash-content-title">Tasks</h1>
        <div className="task-header-actions">
          <div className="task-filters">
            {["all", "todo", "in_progress", "in_review", "blocked", "done"].map((s) => (
              <button
                key={s}
                type="button"
                className={`task-filter-btn${filter === s ? " task-filter-btn--active" : ""}`}
                onClick={() => setFilter(s)}
              >
                {s === "all" ? "All" : STATUS_LABEL[s as TaskSummary["status"]] ?? s}
              </button>
            ))}
          </div>
          <button type="button" className="button-primary" onClick={() => setShowCreate(true)}>
            + New Task
          </button>
        </div>
      </header>

      {loading && <p className="muted">Loading tasks…</p>}

      {!loading && filtered.length === 0 && (
        <div className="dash-empty">
          <p className="dash-empty-text">
            {filter === "all"
              ? "No tasks yet. Create your first task to get started."
              : `No ${STATUS_LABEL[filter as TaskSummary["status"]] ?? ""} tasks.`}
          </p>
        </div>
      )}

      {!loading && filtered.length > 0 && (
        <ul className="task-list" role="list">
          {filtered.map((task) => (
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
              <span className={STATUS_COLORS[task.status]} aria-label={task.status}>
                {STATUS_ICON[task.status]}
              </span>
              <div className="task-row-body">
                <p className="task-row-title">
                  {task.identifier && <span className="task-identifier">{task.identifier}</span>}
                  {task.title}
                </p>
                <div className="task-row-meta">
                  <span className={PRIORITY_DOT[task.priority]} />
                  {task.assigneeAgentName && <span className="task-assignee">{task.assigneeAgentName}</span>}
                  <span className="muted">{relativeTime(task.updatedAt)}</span>
                </div>
              </div>
            </li>
          ))}
        </ul>
      )}

      {showCreate && (
        <CreateTaskModal
          onConfirm={handleCreate}
          onCancel={() => setShowCreate(false)}
        />
      )}

      <Outlet />
    </div>
  );
}

function CreateTaskModal({
  onConfirm,
  onCancel
}: {
  onConfirm: (title: string, description: string, priority: string, assigneeId?: string) => void;
  onCancel: () => void;
}) {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [priority, setPriority] = useState("medium");
  const [agents, setAgents] = useState<{ id: string; name: string }[]>([]);
  const [assigneeId, setAssigneeId] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const trapRef = useFocusTrap(true);
  const previousFocusRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    previousFocusRef.current = document.activeElement as HTMLElement;
    const firstInput = trapRef.current?.querySelector<HTMLElement>(
      'input:not([type="hidden"]),textarea,select'
    );
    if (firstInput) firstInput.focus();
    return () => {
      previousFocusRef.current?.focus();
    };
  }, [trapRef]);

  useEffect(() => {
    const load = async () => {
      try {
        const res = await fetch("/api/internal/agents", { credentials: "include" });
        if (res.ok) {
          const data = (await res.json()) as { agents: { id: string; name: string }[] };
          setAgents(data.agents ?? []);
        }
      } catch {
        // non-fatal
      }
    };
    void load();
  }, []);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === "Escape") {
        e.preventDefault();
        onCancel();
      }
    },
    [onCancel]
  );

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || submitting) return;
    setSubmitting(true);
    onConfirm(title.trim(), description.trim(), priority, assigneeId || undefined);
  };

  return (
    <div className="modal-overlay" onClick={onCancel} onKeyDown={handleKeyDown} role="presentation">
      <div
        ref={trapRef}
        className="modal-panel"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="create-task-title"
      >
        <h2 id="create-task-title" className="modal-title">Create Task</h2>
        <form onSubmit={handleSubmit}>
          <label className="form-label">
            Title
            <input
              className="form-input"
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="What needs to be done?"
            />
          </label>
          <label className="form-label">
            Description
            <textarea
              className="form-textarea"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Add details, context, or requirements…"
              rows={4}
            />
          </label>
          <div className="form-row">
            <label className="form-label">
              Priority
              <select className="form-select" value={priority} onChange={(e) => setPriority(e.target.value)}>
                <option value="critical">Critical</option>
                <option value="high">High</option>
                <option value="medium">Medium</option>
                <option value="low">Low</option>
              </select>
            </label>
            {agents.length > 0 && (
              <label className="form-label">
                Assign to
                <select className="form-select" value={assigneeId} onChange={(e) => setAssigneeId(e.target.value)}>
                  <option value="">Unassigned</option>
                  {agents.map((a) => (
                    <option key={a.id} value={a.id}>{a.name}</option>
                  ))}
                </select>
              </label>
            )}
          </div>
          <div className="modal-actions">
            <button type="button" className="button-secondary" onClick={onCancel}>Cancel</button>
            <button type="submit" className="button-primary" disabled={!title.trim() || submitting}>
              {submitting ? "Creating…" : "Create Task"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

interface Comment {
  id: string;
  authorAgentId?: string;
  authorAgentName?: string;
  body: string;
  createdAt: string;
}

interface TaskDetail {
  id: string;
  identifier?: string;
  title: string;
  description?: string;
  status: TaskSummary["status"];
  priority: TaskSummary["priority"];
  assigneeAgentId?: string;
  assigneeAgentName?: string;
  parentId?: string;
  createdAt: string;
  updatedAt: string;
}

const VALID_TRANSITIONS: Record<TaskSummary["status"], TaskSummary["status"][]> = {
  backlog: ["todo", "cancelled"],
  todo: ["in_progress", "backlog", "cancelled"],
  in_progress: ["in_review", "blocked", "todo", "cancelled"],
  in_review: ["done", "in_progress", "cancelled"],
  blocked: ["in_progress", "todo", "cancelled"],
  done: ["todo"],
  cancelled: ["todo"]
};

export function TaskDetail() {
  const { taskId } = useParams();
  const navigate = useNavigate();
  const [task, setTask] = useState<TaskDetail | null>(null);
  const [comments, setComments] = useState<Comment[]>([]);
  const [commentInput, setCommentInput] = useState("");
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!taskId) return;
    const load = async () => {
      try {
        const [taskRes, commentsRes] = await Promise.all([
          fetch(`/api/internal/tasks/${taskId}`, { credentials: "include" }),
          fetch(`/api/internal/tasks/${taskId}/comments`, { credentials: "include" })
        ]);
        if (taskRes.ok) {
          const data = (await taskRes.json()) as { task: TaskDetail };
          setTask(data.task);
        }
        if (commentsRes.ok) {
          const data = (await commentsRes.json()) as { comments: Comment[] };
          setComments(data.comments ?? []);
        }
      } catch {
        // non-fatal
      } finally {
        setLoading(false);
      }
    };
    void load();
  }, [taskId]);

  const updateStatus = async (newStatus: TaskSummary["status"]) => {
    if (!taskId || !task) return;
    try {
      const res = await fetch(`/api/internal/tasks/${taskId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ status: newStatus, comment: `Status changed to ${STATUS_LABEL[newStatus]}` })
      });
      if (res.ok) {
        setTask((prev) => prev ? { ...prev, status: newStatus } : prev);
      }
    } catch {
      // non-fatal
    }
  };

  const addComment = async () => {
    if (!taskId || !commentInput.trim()) return;
    setSubmitting(true);
    try {
      const res = await fetch(`/api/internal/tasks/${taskId}/comments`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ body: commentInput.trim() })
      });
      if (res.ok) {
        const data = (await res.json()) as { comment: Comment };
        setComments((prev) => [...prev, data.comment]);
        setCommentInput("");
      }
    } catch {
      // non-fatal
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return <div className="dash-loading"><p>Loading task…</p></div>;
  if (!task) return <div className="dash-empty"><p className="dash-empty-text">Task not found.</p></div>;

  const transitions = VALID_TRANSITIONS[task.status] ?? [];

  return (
    <div className="task-detail-shell">
      <button type="button" className="task-back-btn" onClick={() => navigate("/dashboard/tasks")}>
        ← Back to Tasks
      </button>
      <div className="task-detail-header">
        <div className="task-detail-title-row">
          {task.identifier && <span className="task-identifier task-identifier--large">{task.identifier}</span>}
          <h1 className="task-detail-title">{task.title}</h1>
        </div>
        <div className="task-detail-meta">
          <span className={STATUS_COLORS[task.status]}>{STATUS_ICON[task.status]} {STATUS_LABEL[task.status]}</span>
          <span className={PRIORITY_DOT[task.priority]} /> {task.priority}
          {task.assigneeAgentName && <span className="task-assignee">{task.assigneeAgentName}</span>}
        </div>
      </div>

      {transitions.length > 0 && (
        <div className="task-status-actions">
          {transitions.map((s) => (
            <button
              key={s}
              type="button"
              className={`task-transition-btn task-transition-btn--${s}`}
              onClick={() => updateStatus(s)}
            >
              {STATUS_LABEL[s]}
            </button>
          ))}
        </div>
      )}

      {task.description && (
        <section className="task-detail-description">
          <p>{task.description}</p>
        </section>
      )}

      <section className="task-comments-section">
        <h2 className="task-comments-heading">Comments</h2>
        {comments.length === 0 && <p className="muted">No comments yet.</p>}
        <ul className="task-comments-list" role="list">
          {comments.map((c) => (
            <li key={c.id} className="task-comment">
              <div className="task-comment-header">
                <span className="task-comment-author">{c.authorAgentName ?? "You"}</span>
                <span className="muted">{relativeTime(c.createdAt)}</span>
              </div>
              <p className="task-comment-body">{c.body}</p>
            </li>
          ))}
        </ul>
        <form
          className="task-comment-form"
          onSubmit={(e) => {
            e.preventDefault();
            void addComment();
          }}
        >
          <textarea
            className="form-textarea"
            value={commentInput}
            onChange={(e) => setCommentInput(e.target.value)}
            placeholder="Add a comment…"
            rows={2}
          />
          <button type="submit" className="button-primary" disabled={!commentInput.trim() || submitting}>
            {submitting ? "Sending…" : "Comment"}
          </button>
        </form>
      </section>
    </div>
  );
}