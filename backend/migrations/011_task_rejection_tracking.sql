CREATE TABLE task_escalation_state (
  issue_id TEXT PRIMARY KEY,
  workspace_slug TEXT NOT NULL,
  agent_id UUID NOT NULL REFERENCES agents(agent_id),
  rejection_count INTEGER NOT NULL DEFAULT 0,
  escalated_to_frontier BOOLEAN NOT NULL DEFAULT FALSE,
  escalated_at TIMESTAMPTZ,
  frontier_model TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_task_escalation_workspace ON task_escalation_state(workspace_slug);
CREATE INDEX idx_task_escalation_agent ON task_escalation_state(agent_id);

CREATE TRIGGER task_escalation_state_updated_at
  BEFORE UPDATE ON task_escalation_state
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
