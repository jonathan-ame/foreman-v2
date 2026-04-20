import { useState } from "react";

export interface PlanApproval {
  id: string;
  agent_name: string;
  agent_role: string;
  plan_title: string;
  summary: string;
  task_count: number;
  estimated_cost_mo: number | null;
  requested_at: string;
  status: "pending" | "approved" | "changes_requested";
}

interface PlanCardProps {
  plan: PlanApproval;
  onApprove: (id: string) => void;
  onRequestChanges: (id: string, note: string) => void;
  compact?: boolean;
}

export function PlanCard({ plan, onApprove, onRequestChanges, compact = false }: PlanCardProps) {
  const [expanded, setExpanded] = useState(!compact);
  const [requestingChanges, setRequestingChanges] = useState(false);
  const [changesNote, setChangesNote] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const relativeTime = (iso: string) => {
    const diff = Date.now() - new Date(iso).getTime();
    const mins = Math.floor(diff / 60_000);
    if (mins < 1) return "just now";
    if (mins < 60) return `${mins}m ago`;
    const hours = Math.floor(mins / 60);
    if (hours < 24) return `${hours}h ago`;
    return `${Math.floor(hours / 24)}d ago`;
  };

  const handleApprove = async () => {
    setSubmitting(true);
    try {
      onApprove(plan.id);
    } finally {
      setSubmitting(false);
    }
  };

  const handleSubmitChanges = async () => {
    if (!changesNote.trim()) return;
    setSubmitting(true);
    try {
      onRequestChanges(plan.id, changesNote.trim());
      setRequestingChanges(false);
      setChangesNote("");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className={`plan-card${plan.status !== "pending" ? " plan-card--resolved" : ""}`}>
      <div className="plan-card-header" onClick={() => setExpanded((v) => !v)} role="button" tabIndex={0} onKeyDown={(e) => e.key === "Enter" && setExpanded((v) => !v)} aria-expanded={expanded}>
        <div className="plan-card-meta">
          <div className="plan-card-agent">
            <span className="plan-card-agent-avatar">{plan.agent_role.charAt(0).toUpperCase()}</span>
            <span className="plan-card-agent-name">{plan.agent_name}</span>
            <span className="plan-card-agent-role muted">{plan.agent_role}</span>
          </div>
          <div className="plan-card-status-row">
            {plan.status === "pending" && <span className="plan-card-badge plan-card-badge--pending">Needs review</span>}
            {plan.status === "approved" && <span className="plan-card-badge plan-card-badge--approved">Approved</span>}
            {plan.status === "changes_requested" && <span className="plan-card-badge plan-card-badge--changes">Changes requested</span>}
            <span className="plan-card-time muted">{relativeTime(plan.requested_at)}</span>
          </div>
        </div>
        <h3 className="plan-card-title">{plan.plan_title}</h3>
        {!expanded && <p className="plan-card-summary-preview muted">{plan.summary.slice(0, 120)}{plan.summary.length > 120 ? "…" : ""}</p>}
      </div>

      {expanded && (
        <div className="plan-card-body">
          <p className="plan-card-summary">{plan.summary}</p>
          <div className="plan-card-stats">
            <span className="plan-card-stat">
              <strong>{plan.task_count}</strong> tasks
            </span>
            {plan.estimated_cost_mo != null && (
              <span className="plan-card-stat">
                ~<strong>${plan.estimated_cost_mo}</strong>/mo est.
              </span>
            )}
          </div>

          {plan.status === "pending" && !requestingChanges && (
            <div className="plan-card-actions">
              <button type="button" className="button-primary plan-card-btn" onClick={handleApprove} disabled={submitting}>
                {submitting ? "Approving…" : "Approve"}
              </button>
              <button type="button" className="button-ghost plan-card-btn" onClick={() => setRequestingChanges(true)} disabled={submitting}>
                Request changes
              </button>
            </div>
          )}

          {requestingChanges && (
            <div className="plan-card-changes-form">
              <label className="field-label" htmlFor={`changes-note-${plan.id}`}>
                What needs to change?
              </label>
              <textarea
                id={`changes-note-${plan.id}`}
                className="plan-card-textarea"
                value={changesNote}
                onChange={(e) => setChangesNote(e.target.value)}
                placeholder="Describe the changes you'd like to see…"
                rows={3}
              />
              <div className="plan-card-actions">
                <button type="button" className="button-primary plan-card-btn" onClick={handleSubmitChanges} disabled={submitting || !changesNote.trim()}>
                  {submitting ? "Sending…" : "Send feedback"}
                </button>
                <button type="button" className="button-ghost plan-card-btn" onClick={() => { setRequestingChanges(false); setChangesNote(""); }} disabled={submitting}>
                  Cancel
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
