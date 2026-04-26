import { useState, useEffect, useRef, useCallback } from "react";
import { trackFeedbackSubmitted } from "../utils/analytics";
import { useFocusTrap } from "../utils/useFocusTrap";

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
  const triggerRef = useRef<HTMLButtonElement>(null);
  const successRef = useRef<HTMLDivElement>(null);
  const panelRef = useFocusTrap(open);

  const closeModal = useCallback(() => {
    setOpen(false);
    setStatus("idle");
  }, []);

  useEffect(() => {
    if (!open) return;
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        e.preventDefault();
        closeModal();
      }
    };
    document.addEventListener("keydown", handleEscape);
    return () => document.removeEventListener("keydown", handleEscape);
  }, [open, closeModal]);

  useEffect(() => {
    if (!open && triggerRef.current) {
      triggerRef.current.focus();
    }
  }, [open]);

  useEffect(() => {
    if (open) {
      const scrollbarWidth = window.innerWidth - document.documentElement.clientWidth;
      document.body.style.overflow = "hidden";
      document.body.style.paddingRight = `${scrollbarWidth}px`;
      const inertTargets = document.querySelectorAll<HTMLElement>(".marketing > :not(.feedback-overlay)");
      inertTargets.forEach((el) => el.setAttribute("inert", ""));
      return () => {
        document.body.style.overflow = "";
        document.body.style.paddingRight = "";
        inertTargets.forEach((el) => el.removeAttribute("inert"));
      };
    }
  }, [open]);

  useEffect(() => {
    if (status === "success" && successRef.current) {
      const focusable = successRef.current.querySelector<HTMLElement>(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      );
      if (focusable) focusable.focus();
    }
  }, [status]);

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
        ref={triggerRef}
        className="feedback-trigger"
        onClick={() => setOpen(true)}
        aria-label="Send feedback"
      >
        Feedback
      </button>
    );
  }

  return (
    <div className="feedback-overlay" onClick={(e) => { if (e.target === e.currentTarget) closeModal(); }}>
      <div ref={panelRef} className="feedback-panel" role="dialog" aria-modal="true" aria-labelledby="feedback-dialog-title" aria-describedby="feedback-dialog-desc">
        <div className="feedback-header">
          <h3 id="feedback-dialog-title">Send us feedback</h3>
          <p id="feedback-dialog-desc" className="visually-hidden">Share your feedback with our team. All fields marked with an asterisk are required.</p>
          <button className="feedback-close" onClick={closeModal} aria-label="Close feedback">
            &times;
          </button>
        </div>

        <div aria-live="polite" aria-atomic="true" className="visually-hidden">
          {status === "success" && "Your feedback has been submitted. Thank you!"}
          {status === "error" && "Something went wrong submitting your feedback. Please try again."}
        </div>

        {status === "success" ? (
          <div className="feedback-success" ref={successRef}>
            <p>Thank you for your feedback! We read every message.</p>
            <button className="button-primary" onClick={closeModal}>
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
              <p className="feedback-error">Something went wrong. Please try again.</p>
            )}

            <div className="feedback-actions">
              <button type="button" className="button-ghost" onClick={closeModal}>
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
