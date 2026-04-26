import { type FormEvent, useEffect, useState } from "react";
import { useOutletContext } from "react-router-dom";
import type { DashboardContext } from "./DashboardLayout";

const TIER_LABELS: Record<string, string> = {
  trial: "Free trial",
  tier_1: "Starter",
  tier_2: "Growth",
  tier_3: "Scale",
  byok_platform: "BYOK Platform"
};

const TIER_PRICES: Record<string, { label: string; price: string }> = {
  tier_1: { label: "Starter", price: "$49/mo" },
  tier_2: { label: "Growth", price: "$99/mo" },
  tier_3: { label: "Scale", price: "$199/mo" }
};

interface OrgSettings {
  workspace_name: string;
  model_tier: "open" | "frontier" | "hybrid";
  approval_preference: "auto" | "manual";
  api_key_mode: "foreman_managed" | "byok";
  display_name?: string;
  agent_approval_mode?: "auto" | "manual";
}

const MODEL_LABELS: Record<OrgSettings["model_tier"], string> = {
  open: "Essentials — good for simple tasks",
  hybrid: "Recommended — best balance",
  frontier: "Premium — most capable"
};

export function Settings() {
  const { customer } = useOutletContext<DashboardContext>();
  const [settings, setSettings] = useState<OrgSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saveStatus, setSaveStatus] = useState<"idle" | "saved" | "error">("idle");
  const [showApiKeyHelp, setShowApiKeyHelp] = useState(false);
  const [apiKey, setApiKey] = useState("");
  const [validating, setValidating] = useState(false);
  const [apiKeyStatus, setApiKeyStatus] = useState<"idle" | "valid" | "invalid">("idle");
  const [checkoutLoading, setCheckoutLoading] = useState<string | null>(null);
  const [portalLoading, setPortalLoading] = useState(false);

  useEffect(() => {
    const load = async () => {
      try {
        const res = await fetch("/api/internal/settings", { credentials: "include" });
        if (res.ok) {
          const data = (await res.json()) as Record<string, unknown>;
          setSettings({
            workspace_name: (data.display_name as string) ?? "",
            model_tier: ((data.model_tier as string) ?? "hybrid") as OrgSettings["model_tier"],
            approval_preference: ((data.agent_approval_mode as string) ?? "auto") as OrgSettings["approval_preference"],
            api_key_mode: (data.byok_key_set ? "byok" : "foreman_managed") as OrgSettings["api_key_mode"]
          });
        }
      } catch {
        // non-fatal
      } finally {
        setLoading(false);
      }
    };
    void load();
  }, []);

  const validateApiKey = async (key: string) => {
    if (!key.startsWith("sk-or-")) {
      setApiKeyStatus("invalid");
      return;
    }
    setValidating(true);
    try {
      const res = await fetch("/api/internal/openrouter/validate-key", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ api_key: key })
      });
      if (res.ok) {
        const data = (await res.json()) as { valid: boolean };
        setApiKeyStatus(data.valid ? "valid" : "invalid");
      } else {
        setApiKeyStatus("invalid");
      }
    } catch {
      setApiKeyStatus("invalid");
    } finally {
      setValidating(false);
    }
  };

  const handleSave = async (event: FormEvent) => {
    event.preventDefault();
    if (!settings) return;
    setSaving(true);
    setSaveStatus("idle");
    const payload: Record<string, string> = {
      display_name: settings.workspace_name,
      agent_approval_mode: settings.approval_preference,
      model_tier: settings.model_tier
    };
    try {
      const res = await fetch("/api/internal/settings", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify(payload)
      });
      setSaveStatus(res.ok ? "saved" : "error");

      if (res.ok && settings.api_key_mode === "byok" && apiKey.trim()) {
        await fetch("/api/internal/settings/byok-key", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          credentials: "include",
          body: JSON.stringify({ api_key: apiKey.trim() })
        });
      } else if (res.ok && settings.api_key_mode === "foreman_managed") {
        await fetch("/api/internal/settings/byok-key", {
          method: "DELETE",
          headers: { "Content-Type": "application/json" },
          credentials: "include"
        });
      }
    } catch {
      setSaveStatus("error");
    } finally {
      setSaving(false);
      setTimeout(() => setSaveStatus("idle"), 3000);
    }
  };

  const currentMode = settings?.api_key_mode ?? "foreman_managed";

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

          {/* Billing / Plan */}
          <section className="settings-section">
            <h2 className="settings-section-title">Plan & Billing</h2>
            <dl className="settings-dl">
              <dt>Current plan</dt>
              <dd>{TIER_LABELS[customer.current_tier ?? "trial"]}</dd>
            </dl>
            {customer.current_billing_mode === "trial" && (
              <div className="settings-billing-actions">
                <p className="muted" style={{ marginBottom: 12 }}>Upgrade to unlock more agents and capabilities.</p>
                <div className="settings-plan-grid">
                  {Object.entries(TIER_PRICES).map(([tier, info]) => (
                    <button
                      key={tier}
                      type="button"
                      className={`button-primary${checkoutLoading === tier ? " button-loading" : ""}`}
                      disabled={checkoutLoading !== null}
                      onClick={async () => {
                        setCheckoutLoading(tier);
                        try {
                          const res = await fetch("/api/internal/billing/checkout", {
                            method: "POST",
                            headers: { "Content-Type": "application/json" },
                            credentials: "include",
                            body: JSON.stringify({ priceId: "", tier })
                          });
                          if (res.ok) {
                            const data = (await res.json()) as { url: string };
                            window.location.assign(data.url);
                          } else {
                            alert("Unable to start checkout. Please try again.");
                          }
                        } catch {
                          alert("Network error. Please try again.");
                        } finally {
                          setCheckoutLoading(null);
                        }
                      }}
                    >
                      {checkoutLoading === tier ? "Redirecting…" : `${info.label} — ${info.price}`}
                    </button>
                  ))}
                </div>
              </div>
            )}
            {customer.current_billing_mode !== "trial" && (
              <button
                type="button"
                className="button-ghost"
                disabled={portalLoading}
                onClick={async () => {
                  setPortalLoading(true);
                  try {
                    const res = await fetch("/api/internal/billing/portal", { credentials: "include" });
                    if (res.ok) {
                      const data = (await res.json()) as { url: string };
                      window.location.assign(data.url);
                    } else {
                      alert("Unable to open billing portal. Please try again.");
                    }
                  } catch {
                    alert("Network error. Please try again.");
                  } finally {
                    setPortalLoading(false);
                  }
                }}
              >
                {portalLoading ? "Loading…" : "Manage subscription"}
              </button>
            )}
          </section>

          {/* API Keys — available on all plans */}
          {settings && (
            <section className="settings-section">
              <h2 className="settings-section-title">API Keys</h2>
              <p className="muted settings-section-desc">
                Choose how Foreman connects to AI models. You can switch anytime.
              </p>
              <div className="settings-key-mode">
                <label className={`settings-key-option${currentMode === "foreman_managed" ? " settings-key-option--active" : ""}`}>
                  <input
                    type="radio"
                    name="key-mode"
                    checked={currentMode === "foreman_managed"}
                    onChange={() => setSettings({ ...settings, api_key_mode: "foreman_managed" })}
                  />
                  <div className="settings-key-option-content">
                    <span className="settings-key-option-title">Hassle-free setup</span>
                    <span className="settings-key-option-desc">Foreman handles everything. Just start chatting with your agent.</span>
                  </div>
                </label>
                <label className={`settings-key-option${currentMode === "byok" ? " settings-key-option--active" : ""}`}>
                  <input
                    type="radio"
                    name="key-mode"
                    checked={currentMode === "byok"}
                    onChange={() => setSettings({ ...settings, api_key_mode: "byok" })}
                  />
                  <div className="settings-key-option-content">
                    <span className="settings-key-option-title">I have an OpenRouter key</span>
                    <span className="settings-key-option-desc">Lower cost per task. Paste your key from openrouter.ai/keys</span>
                  </div>
                </label>
              </div>

              {currentMode === "byok" && (
                <div className="settings-byok-fields">
                  <label className="field-row">
                    <span className="field-label">OpenRouter API key</span>
                    <input
                      type="password"
                      className="settings-api-input"
                      placeholder="sk-or-..."
                      value={apiKey}
                      onChange={(e) => {
                        setApiKey(e.target.value);
                        setApiKeyStatus("idle");
                      }}
                      onBlur={() => {
                        if (apiKey.trim()) validateApiKey(apiKey.trim());
                      }}
                      autoComplete="off"
                    />
                    {validating && <small className="muted">Checking key…</small>}
                    {apiKeyStatus === "valid" && <small className="success-text">Valid key</small>}
                    {apiKeyStatus === "invalid" && <small className="error-text">Invalid key. Check your key and try again.</small>}
                  </label>
                  <p className="muted" style={{ fontSize: "13px" }}>
                    Find your key at{" "}
                    <a href="https://openrouter.ai/keys" target="_blank" rel="noopener noreferrer">
                      openrouter.ai/keys
                    </a>
                  </p>
                  <button
                    type="button"
                    className="link-button"
                    style={{ fontSize: "13px", marginTop: "-4px" }}
                    onClick={() => setShowApiKeyHelp((v) => !v)}
                  >
                    What&apos;s an API key?
                  </button>
                  {showApiKeyHelp && (
                    <p className="muted" style={{ fontSize: "13px", marginTop: "4px", lineHeight: 1.5 }}>
                      An API key is like a password that lets Foreman talk to AI models on your behalf.
                      If you don&apos;t have one, choose Hassle-free setup — it&apos;s included in your plan.
                    </p>
                  )}
                </div>
              )}
            </section>
          )}

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
                      {MODEL_LABELS[tier]}
                    </label>
                  ))}
                  <p className="muted" style={{ fontSize: "13px", marginTop: "8px" }}>
                    You can change this anytime.
                  </p>
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
