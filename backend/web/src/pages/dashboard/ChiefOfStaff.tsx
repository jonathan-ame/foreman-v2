import { type FormEvent, useEffect, useRef, useState } from "react";
import { useOutletContext } from "react-router-dom";
import { PlanCard, type PlanApproval } from "../../components/PlanCard";
import type { DashboardContext } from "./DashboardLayout";

interface ChatMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
  created_at: string;
}

function SendIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
      <path d="M14 8L2 2l2.5 6L2 14l12-6z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
    </svg>
  );
}

function EmptyChat({ customerName, onSuggestionClick }: { customerName: string; onSuggestionClick: (text: string) => void }) {
  const suggestions = [
    "What should I focus on this week?",
    "Review our team's priorities",
    "Help me create a project plan"
  ];

  return (
    <div className="cos-empty">
      <div className="cos-empty-icon" aria-hidden="true">✦</div>
      <h2 className="cos-empty-heading">Good to see you, {customerName.split(" ")[0]}.</h2>
      <p className="cos-empty-sub">
        Your Chief of Staff is ready. Ask anything — kick off a project, check on the team, or review a plan.
      </p>
      <div className="cos-suggestions">
        {suggestions.map((s) => (
          <button
            key={s}
            type="button"
            className="cos-suggestion-chip"
            onClick={() => onSuggestionClick(s)}
          >
            {s}
          </button>
        ))}
      </div>
    </div>
  );
}

interface ChatBubbleProps {
  message: ChatMessage;
}

function ChatBubble({ message }: ChatBubbleProps) {
  const isUser = message.role === "user";
  return (
    <div className={`cos-bubble-row${isUser ? " cos-bubble-row--user" : ""}`}>
      {!isUser && <div className="cos-bubble-avatar" aria-hidden="true">F</div>}
      <div className={`cos-bubble${isUser ? " cos-bubble--user" : " cos-bubble--assistant"}`}>
        <p className="cos-bubble-text">{message.content}</p>
      </div>
    </div>
  );
}

export function ChiefOfStaff() {
  const { customer } = useOutletContext<DashboardContext>();
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [pendingPlans, setPendingPlans] = useState<PlanApproval[]>([]);
  const [input, setInput] = useState("");
  const [sending, setSending] = useState(false);
  const [loadingHistory, setLoadingHistory] = useState(true);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const load = async () => {
      try {
        const [histRes, plansRes] = await Promise.all([
          fetch("/api/internal/chat/history", { credentials: "include" }),
          fetch("/api/internal/approvals/pending", { credentials: "include" })
        ]);
        if (histRes.ok) {
          const data = (await histRes.json()) as { messages: ChatMessage[] };
          setMessages(data.messages ?? []);
        }
        if (plansRes.ok) {
          const data = (await plansRes.json()) as { approvals: PlanApproval[] };
          setPendingPlans(data.approvals ?? []);
        }
      } catch {
        // non-fatal: show empty state
      } finally {
        setLoadingHistory(false);
      }
    };
    void load();
  }, []);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const sendMessage = async (event: FormEvent) => {
    event.preventDefault();
    const text = input.trim();
    if (!text || sending) return;

    const optimistic: ChatMessage = {
      id: crypto.randomUUID(),
      role: "user",
      content: text,
      created_at: new Date().toISOString()
    };
    setMessages((prev) => [...prev, optimistic]);
    setInput("");
    setSending(true);

    try {
      const res = await fetch("/api/internal/chat/send", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ message: text })
      });
      if (res.ok) {
        const data = (await res.json()) as { reply: ChatMessage };
        setMessages((prev) => [...prev, data.reply]);
      }
    } catch {
      // non-fatal: optimistic message stays, reply missing
    } finally {
      setSending(false);
    }
  };

  const handleApprove = async (id: string) => {
    try {
      await fetch(`/api/internal/approvals/${id}/approve`, {
        method: "POST",
        credentials: "include"
      });
      setPendingPlans((prev) => prev.map((p) => p.id === id ? { ...p, status: "approved" as const } : p));
    } catch {
      // non-fatal
    }
  };

  const handleRequestChanges = async (id: string, note: string) => {
    try {
      await fetch(`/api/internal/approvals/${id}/request-changes`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ note })
      });
      setPendingPlans((prev) => prev.map((p) => p.id === id ? { ...p, status: "changes_requested" as const } : p));
    } catch {
      // non-fatal
    }
  };

  const activePending = pendingPlans.filter((p) => p.status === "pending");

  return (
    <div className="cos-shell">
      <header className="dash-content-header">
        <h1 className="dash-content-title">Chief of Staff</h1>
        {activePending.length > 0 && (
          <span className="cos-approval-pill">
            {activePending.length} plan{activePending.length > 1 ? "s" : ""} awaiting review
          </span>
        )}
      </header>

      <div className="cos-body">
        {/* Plan approval cards — inline at top of feed */}
        {pendingPlans.length > 0 && (
          <section className="cos-plans-section" aria-label="Pending plan approvals">
            <p className="cos-plans-label">Plans for review</p>
            <div className="cos-plans-list">
              {pendingPlans.map((plan) => (
                <PlanCard
                  key={plan.id}
                  plan={plan}
                  onApprove={handleApprove}
                  onRequestChanges={handleRequestChanges}
                  compact
                />
              ))}
            </div>
          </section>
        )}

        {/* Chat thread */}
        <div className="cos-thread" aria-live="polite" aria-label="Conversation">
          {!loadingHistory && messages.length === 0 && pendingPlans.length === 0 && (
            <EmptyChat customerName={customer.display_name} onSuggestionClick={(text) => { setInput(text); }} />
          )}
          {messages.map((msg) => (
            <ChatBubble key={msg.id} message={msg} />
          ))}
          {sending && (
            <div className="cos-bubble-row">
              <div className="cos-bubble-avatar" aria-hidden="true">F</div>
              <div className="cos-bubble cos-bubble--assistant cos-bubble--thinking">
                <span className="cos-thinking-dot" />
                <span className="cos-thinking-dot" />
                <span className="cos-thinking-dot" />
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>
      </div>

      {/* Input bar */}
      <form className="cos-input-bar" onSubmit={sendMessage}>
        <input
          className="cos-input"
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Ask your Chief of Staff anything…"
          disabled={sending}
          autoComplete="off"
        />
        <button type="submit" className="cos-send-btn" disabled={!input.trim() || sending} aria-label="Send message">
          <SendIcon />
        </button>
      </form>
    </div>
  );
}
