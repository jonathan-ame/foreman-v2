import { type FormEvent, useEffect, useState } from "react";
import { useOutletContext } from "react-router-dom";
import type { DashboardContext } from "./DashboardLayout";

interface OrgSettings {
  workspace_name: string;
  model_tier: "open" | "frontier" | "hybrid";
  approval_preference: "auto" | "manual";
  api_key_mode: "foreman_managed" | "byok";
}

export function Settings() {
  const { customer } = useOutletContext<DashboardContext>();
  const [settings, setSettings] = useState<OrgSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saveStatus, setSaveStatus] = useState<"idle" | "saved" | "error">("idle");

  useEffect(() => {
    const load = async () => {
      try {
        const res = await fetch("/api/internal/settings", { credentials: "include" });
        if (res.ok) {
          const data = (await res.json()) as { settings: OrgSettings };
          setSettings(data.settings);
        }
      } catch {
        // non-fatal
      } finally {
        setLoading(false);
      }
    };
    void load();
  }, []);

  const handleSave = async (event: FormEvent) => {
    event.preventDefault();
    if (!settings) return;
    setSaving(true);
    setSaveStatus("idle");
    try {
      const res = await fetch("/api/internal/settings", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify(settings)
      });
      setSaveStatus(res.ok ? "saved" : "error");
    } catch {
      setSaveStatus("error");
    } finally {
      setSaving(false);
      setTimeout(() => setSaveStatus("idle"), 3000);
    }
  };

  return (
    <div className="dash-content-shell">
      <header className="dash-content-header">
        <h1 className="dash-content-title">Settings</h1>
      </header>

      {loading && <p className="muted">Loading settings…</p>}

      {!loading && (
        <div className="settings-sections">
          {/* Account info (read-only) */}
          <section className="settings-section">
            <h2 className="settings-section-title">Account</h2>
            <dl className="settings-dl">
              <dt>Email</dt>
              <dd>{customer.email}</dd>
              <dt>Plan</dt>
              <dd>{customer.current_tier ?? "Free"}</dd>
              <dt>Billing</dt>
              <dd className="capitalize">{customer.current_billing_mode.replace("_", " ")}</dd>
            </dl>
          </section>

          {/* Org settings (editable) */}
          {settings && (
            <section className="settings-section">
              <h2 className="settings-section-title">Workspace</h2>
              <form className="settings-form stack" onSubmit={handleSave}>
                <label className="field-row">
                  <span className="field-label">Workspace name</span>
                  <input
                    type="text"
                    value={settings.workspace_name}
                    onChange={(e) => setSettings({ ...settings, workspace_name: e.target.value })}
                  />
                </label>

                <fieldset className="field settings-fieldset">
                  <legend className="field-label">Model tier</legend>
                  {(["open", "hybrid", "frontier"] as const).map((tier) => (
                    <label key={tier} className="settings-radio-label">
                      <input
                        type="radio"
                        name="model-tier"
                        value={tier}
                        checked={settings.model_tier === tier}
                        onChange={() => setSettings({ ...settings, model_tier: tier })}
                      />
                      {tier === "open" ? "Open models — most affordable" : tier === "hybrid" ? "Hybrid (recommended)" : "Frontier models — most capable"}
                    </label>
                  ))}
                </fieldset>

                <fieldset className="field settings-fieldset">
                  <legend className="field-label">Hire approval</legend>
                  <label className="settings-radio-label">
                    <input
                      type="radio"
                      name="approval"
                      value="auto"
                      checked={settings.approval_preference === "auto"}
                      onChange={() => setSettings({ ...settings, approval_preference: "auto" })}
                    />
                    Let my CEO hire as needed
                  </label>
                  <label className="settings-radio-label">
                    <input
                      type="radio"
                      name="approval"
                      value="manual"
                      checked={settings.approval_preference === "manual"}
                      onChange={() => setSettings({ ...settings, approval_preference: "manual" })}
                    />
                    Notify me to approve each new hire
                  </label>
                </fieldset>

                <div className="settings-save-row">
                  <button type="submit" className="button-primary" disabled={saving}>
                    {saving ? "Saving…" : "Save changes"}
                  </button>
                  {saveStatus === "saved" && <span className="success-text">Saved.</span>}
                  {saveStatus === "error" && <span className="error-text">Save failed. Try again.</span>}
                </div>
              </form>
            </section>
          )}

          {/* Danger zone */}
          <section className="settings-section settings-section--danger">
            <h2 className="settings-section-title">Danger zone</h2>
            <p className="muted">Deleting your workspace permanently removes all agents, projects, and data.</p>
            <button type="button" className="button-danger" disabled>Delete workspace (contact support)</button>
          </section>
        </div>
      )}
    </div>
  );
}
