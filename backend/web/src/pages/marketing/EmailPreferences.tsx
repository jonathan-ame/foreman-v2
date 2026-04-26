import { useState, useEffect } from "react";
import { useSearchParams } from "react-router-dom";

type PreferenceCategory = "launch_updates" | "product_news" | "tips_resources" | "community";

const PREFERENCE_LABELS: Record<PreferenceCategory, string> = {
  launch_updates: "Launch announcements & early access",
  product_news: "Product updates & new features",
  tips_resources: "Tips, guides & resources",
  community: "Community highlights & case studies",
};

const DEFAULT_PREFERENCES: Record<PreferenceCategory, boolean> = {
  launch_updates: true,
  product_news: true,
  tips_resources: true,
  community: true,
};

export function EmailPreferences() {
  const [searchParams] = useSearchParams();
  const [email, setEmail] = useState(searchParams.get("email") ?? "");
  const [token] = useState(searchParams.get("token") ?? "");
  const [preferences, setPreferences] = useState<Record<PreferenceCategory, boolean>>(DEFAULT_PREFERENCES);
  const [status, setStatus] = useState<"idle" | "loading" | "loaded" | "saving" | "unsubscribed" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");
  const [isUnsubscribeAll, setIsUnsubscribeAll] = useState(false);
  const [busy, setBusy] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);

  useEffect(() => {
    if (token && email) {
      loadPreferences();
    } else if (email) {
      setStatus("loaded");
    } else {
      setStatus("idle");
    }
  }, []);

  const loadPreferences = async () => {
    setStatus("loading");
    try {
      const params = new URLSearchParams({ email: email, token: token });
      const response = await fetch(`/api/marketing/preferences?${params.toString()}`);
      if (!response.ok) {
        throw new Error("Failed to load preferences");
      }
      const data = await response.json();
      if (data.unsubscribed_at) {
        setStatus("unsubscribed");
        return;
      }
      if (data.preferences) {
        setPreferences({ ...DEFAULT_PREFERENCES, ...data.preferences });
      }
      setStatus("loaded");
    } catch {
      setErrorMessage("Could not load your preferences. Please try again later.");
      setStatus("error");
    }
  };

  const togglePreference = (key: PreferenceCategory) => {
    setPreferences((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const handleUnsubscribeAll = async () => {
    setBusy(true);
    try {
      const response = await fetch("/api/marketing/unsubscribe", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, token }),
      });
      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        throw new Error(data.error ?? "Failed to unsubscribe");
      }
      setStatus("unsubscribed");
      setIsUnsubscribeAll(true);
      setPreferences({
        launch_updates: false,
        product_news: false,
        tips_resources: false,
        community: false,
      });
    } catch (err) {
      setErrorMessage(err instanceof Error ? err.message : "Something went wrong");
      setStatus("error");
    } finally {
      setBusy(false);
    }
  };

  const handleSavePreferences = async () => {
    setBusy(true);
    try {
      const response = await fetch("/api/marketing/preferences", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, token, preferences }),
      });
      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        throw new Error(data.error ?? "Failed to save preferences");
      }
      setSaveSuccess(true);
      setStatus("loaded");
      setTimeout(() => setSaveSuccess(false), 5000);
    } catch (err) {
      setErrorMessage(err instanceof Error ? err.message : "Something went wrong");
      setStatus("error");
    } finally {
      setBusy(false);
    }
  };

  const handleResubscribe = async () => {
    setBusy(true);
    try {
      const response = await fetch("/api/marketing/resubscribe", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, token }),
      });
      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        throw new Error(data.error ?? "Failed to resubscribe");
      }
      setPreferences(DEFAULT_PREFERENCES);
      setIsUnsubscribeAll(false);
      setStatus("loaded");
    } catch (err) {
      setErrorMessage(err instanceof Error ? err.message : "Something went wrong");
      setStatus("error");
    } finally {
      setBusy(false);
    }
  };

  if (status === "loading") {
    return (
      <section className="email-pref-page">
        <div className="content-inner text-center">
          <p>Loading your preferences…</p>
        </div>
      </section>
    );
  }

  if (status === "error") {
    return (
      <section className="email-pref-page">
        <div className="content-inner">
          <h1>Something went wrong</h1>
          <p className="email-pref-error">{errorMessage}</p>
          <p>
            Try again or <a href={`mailto:support@foreman.company?subject=Email preferences for ${encodeURIComponent(email)}`}>contact support</a>.
          </p>
        </div>
      </section>
    );
  }

  if (status === "unsubscribed") {
    return (
      <section className="email-pref-page">
        <div className="content-inner text-center">
          <h1>You're unsubscribed</h1>
          <p className="email-pref-subtitle">
            {isUnsubscribeAll
              ? "You've been unsubscribed from all Foreman emails."
              : "You were previously unsubscribed from Foreman emails."}
          </p>

          <div className="email-pref-card">
            <h3>Changed your mind?</h3>
            <p>Resubscribe to get launch updates, product news, and early access tips.</p>
            <button
              className="button-primary"
              onClick={handleResubscribe}
              disabled={busy}
            >
              {busy ? "Resubscribing…" : "Resubscribe to all emails"}
            </button>
          </div>

          <p className="email-pref-note">
            Unsubscribing does not delete your account. You can manage your data in your account settings.
          </p>
        </div>
      </section>
    );
  }

  if (!email && status === "idle") {
    return (
      <section className="email-pref-page">
        <div className="email-pref-card">
          <h1>Email preferences</h1>
          <p className="email-pref-subtitle">
            Manage which emails you receive from Foreman.
          </p>

          <form
            className="email-pref-form"
            onSubmit={(e) => {
              e.preventDefault();
              if (email.trim()) {
                window.location.href = `/unsubscribe?email=${encodeURIComponent(email.trim())}`;
              }
            }}
          >
            <label htmlFor="pref-email">Your email address</label>
            <input
              id="pref-email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@company.com"
              required
            />
            <button type="submit" className="button-primary">
              Find my preferences
            </button>
          </form>
        </div>
      </section>
    );
  }

  return (
    <section className="email-pref-page">
      <div className="content-inner">
        <h1>{token ? "Your email preferences" : "Manage your email settings"}</h1>
        <p className="email-pref-subtitle">
          Choose which emails you want to receive at <strong>{email}</strong>.
        </p>

        <div className="email-pref-card">
          {(Object.keys(PREFERENCE_LABELS) as PreferenceCategory[]).map((key) => (
            <label key={key} className="email-pref-toggle">
              <input
                type="checkbox"
                checked={preferences[key]}
                onChange={() => togglePreference(key)}
                disabled={busy}
              />
              <span>{PREFERENCE_LABELS[key]}</span>
            </label>
          ))}
        </div>

        <div className="email-pref-actions">
          <button
            className="button-primary"
            onClick={handleSavePreferences}
            disabled={busy}
          >
            {busy ? "Saving…" : "Save preferences"}
          </button>
          <button
            className="button-ghost"
            onClick={handleUnsubscribeAll}
            disabled={busy}
          >
            Unsubscribe from all
          </button>
        </div>

        <p className="email-pref-note">
          You can also reply to any Foreman email to update your preferences, or{" "}
          <a href={`mailto:support@foreman.company?subject=Email preferences for ${encodeURIComponent(email)}`}>
            contact support
          </a>.
        </p>

        {saveSuccess && (
          <div className="email-pref-save-toast" role="status">
            Preferences saved — your updates will take effect on the next email.
          </div>
        )}

        <div className="email-pref-sequence-preview">
          <h3>What you'll receive</h3>
          <div className="email-pref-timeline">
            <div className={`email-pref-timeline-item ${!preferences.launch_updates ? "email-pref-timeline-item--inactive" : ""}`}>
              <span className="email-pref-timeline-badge launch">Pre-launch</span>
              <p><strong>Launch countdown & early access</strong> — Teaser and last-chance reminders before we go live.</p>
            </div>
            <div className={`email-pref-timeline-item ${!preferences.launch_updates ? "email-pref-timeline-item--inactive" : ""}`}>
              <span className="email-pref-timeline-badge launch">Launch day</span>
              <p><strong>Early access link + case study</strong> — Be first to try Foreman v2.</p>
            </div>
            <div className={`email-pref-timeline-item ${!preferences.product_news ? "email-pref-timeline-item--inactive" : ""}`}>
              <span className="email-pref-timeline-badge followup">Day 1-3</span>
              <p><strong>Check-in & results</strong> — First-week results, social proof, and discount reminders.</p>
            </div>
            <div className={`email-pref-timeline-item ${!preferences.tips_resources ? "email-pref-timeline-item--inactive" : ""}`}>
              <span className="email-pref-timeline-badge followup">Day 5-7</span>
              <p><strong>Feature deep dives</strong> — Agent coordination, workflows, and advanced use cases.</p>
            </div>
            <div className={`email-pref-timeline-item ${!preferences.community ? "email-pref-timeline-item--inactive" : ""}`}>
              <span className="email-pref-timeline-badge followup">Day 10-14</span>
              <p><strong>Last call & re-engagement</strong> — Final discount reminders and value summaries.</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}