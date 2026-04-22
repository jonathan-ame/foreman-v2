import { useState } from "react";
import { trackFeedbackSubmitted } from "../utils/analytics";

type FeedbackCategory = "bug" | "suggestion" | "praise" | "other";

const categories: { value: FeedbackCategory; label: string }[] = [
  { value: "suggestion", label: "Suggestion" },
  { value: "bug", label: "Bug report" },
  { value: "praise", label: "Something I love" },
  { value: "other", label: "Other" },
];

export function FeedbackWidget() {
  const [open, setOpen] = useState(false);
  const [category, setCategory] = useState<FeedbackCategory>("suggestion");
  const [message, setMessage] = useState("");
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "submitting" | "success" | "error">("idle");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!message.trim()) return;

    setStatus("submitting");

    try {
      const response = await fetch("/api/marketing/feedback", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          category,
          message: message.trim(),
          email: email.trim() || undefined,
          page: window.location.pathname,
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to submit feedback");
      }

      trackFeedbackSubmitted(category);
      setStatus("success");
      setMessage("");
      setEmail("");
    } catch {
      setStatus("error");
    }
  };

  if (!open) {
    return (
      <button
        className="feedback-trigger"
        onClick={() => setOpen(true)}
        aria-label="Send feedback"
      >
        Feedback
      </button>
    );
  }

  return (
    <div className="feedback-overlay" onClick={(e) => { if (e.target === e.currentTarget) setOpen(false); }}>
      <div className="feedback-panel" role="dialog" aria-label="Send feedback">
        <div className="feedback-header">
          <h3>Send us feedback</h3>
          <button className="feedback-close" onClick={() => { setOpen(false); setStatus("idle"); }} aria-label="Close feedback">
            &times;
          </button>
        </div>

        {status === "success" ? (
          <div className="feedback-success">
            <p>Thank you for your feedback! We read every message.</p>
            <button className="button-primary" onClick={() => { setOpen(false); setStatus("idle"); }}>
              Close
            </button>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="feedback-form">
            <div className="form-group">
              <label htmlFor="feedback-category">What's this about?</label>
              <select
                id="feedback-category"
                value={category}
                onChange={(e) => setCategory(e.target.value as FeedbackCategory)}
              >
                {categories.map((c) => (
                  <option key={c.value} value={c.value}>{c.label}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label htmlFor="feedback-message">Your feedback *</label>
              <textarea
                id="feedback-message"
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                rows={4}
                required
                placeholder="Tell us what you think..."
              />
            </div>

            <div className="form-group">
              <label htmlFor="feedback-email">Email (optional)</label>
              <input
                type="email"
                id="feedback-email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@company.com"
                autoComplete="email"
              />
            </div>

            {status === "error" && (
              <p className="feedback-error" role="alert">Something went wrong. Please try again.</p>
            )}

            <div className="feedback-actions">
              <button type="button" className="button-ghost" onClick={() => { setOpen(false); setStatus("idle"); }}>
                Cancel
              </button>
              <button type="submit" className="button-primary" disabled={status === "submitting" || !message.trim()}>
                {status === "submitting" ? "Sending..." : "Send feedback"}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
