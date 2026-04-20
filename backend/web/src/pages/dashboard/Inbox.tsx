import { useEffect, useState } from "react";
import { PlanCard, type PlanApproval } from "../../components/PlanCard";

interface InboxItem {
  id: string;
  kind: "plan_approval" | "agent_update" | "task_complete" | "alert";
  title: string;
  body: string;
  read: boolean;
  created_at: string;
  plan?: PlanApproval;
}

function relativeTime(iso: string) {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60_000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  return new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

function kindIcon(kind: InboxItem["kind"]) {
  switch (kind) {
    case "plan_approval": return "📋";
    case "agent_update": return "🤖";
    case "task_complete": return "✓";
    case "alert": return "⚠";
  }
}

export function Inbox() {
  const [items, setItems] = useState<InboxItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      try {
        const res = await fetch("/api/internal/inbox", { credentials: "include" });
        if (res.ok) {
          const data = (await res.json()) as { items: InboxItem[] };
          setItems(data.items ?? []);
        }
      } catch {
        // non-fatal
      } finally {
        setLoading(false);
      }
    };
    void load();
  }, []);

  const markRead = async (id: string) => {
    setItems((prev) => prev.map((i) => i.id === id ? { ...i, read: true } : i));
    try {
      await fetch(`/api/internal/inbox/${id}/read`, { method: "POST", credentials: "include" });
    } catch {
      // non-fatal
    }
  };

  const handleApprove = async (planId: string) => {
    try {
      await fetch(`/api/internal/approvals/${planId}/approve`, { method: "POST", credentials: "include" });
      setItems((prev) =>
        prev.map((item) =>
          item.plan?.id === planId
            ? { ...item, plan: { ...item.plan!, status: "approved" as const } }
            : item
        )
      );
    } catch {
      // non-fatal
    }
  };

  const handleRequestChanges = async (planId: string, note: string) => {
    try {
      await fetch(`/api/internal/approvals/${planId}/request-changes`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ note })
      });
      setItems((prev) =>
        prev.map((item) =>
          item.plan?.id === planId
            ? { ...item, plan: { ...item.plan!, status: "changes_requested" as const } }
            : item
        )
      );
    } catch {
      // non-fatal
    }
  };

  const unreadCount = items.filter((i) => !i.read).length;

  return (
    <div className="dash-content-shell">
      <header className="dash-content-header">
        <h1 className="dash-content-title">Inbox</h1>
        {unreadCount > 0 && (
          <span className="dash-badge">{unreadCount} unread</span>
        )}
      </header>

      {loading && <p className="muted">Loading inbox…</p>}

      {!loading && items.length === 0 && (
        <div className="dash-empty">
          <p className="dash-empty-text">All caught up. Updates from your team will appear here.</p>
        </div>
      )}

      {!loading && items.length > 0 && (
        <ul className="inbox-list" role="list">
          {items.map((item) => (
            <li key={item.id} className={`inbox-item${item.read ? "" : " inbox-item--unread"}`} onClick={() => !item.read && markRead(item.id)}>
              {item.kind === "plan_approval" && item.plan ? (
                <PlanCard plan={item.plan} onApprove={handleApprove} onRequestChanges={handleRequestChanges} />
              ) : (
                <div className="inbox-row">
                  <span className="inbox-kind-icon" aria-hidden="true">{kindIcon(item.kind)}</span>
                  <div className="inbox-row-body">
                    <p className="inbox-row-title">{item.title}</p>
                    <p className="inbox-row-text muted">{item.body}</p>
                  </div>
                  <span className="inbox-row-time muted">{relativeTime(item.created_at)}</span>
                </div>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
