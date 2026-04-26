import { useEffect, useRef, useState } from "react";
import { FailureCard } from "../components/FailureCard";
import { WizardProgress } from "../components/WizardProgress";

interface CustomerSession {
  customer_id: string;
  email: string;
  display_name: string;
  current_tier: string | null;
  current_billing_mode: string;
  onboarding_progress: Record<string, string>;
  onboarding_complete: boolean;
}

interface ProvisionFailureResponse {
  outcome: "failed" | "blocked" | "partial";
  provisioning_id: string;
  failed_step: string;
  error_code: string;
  error_message: string;
  customer_message: string;
}

type WizardStep =
  | "welcome"
  | "name"
  | "role"
  | "model"
  | "api-key"
  | "byok-key"
  | "review"
  | "launching"
  | "success"
  | "error";

type ModelTier = "open" | "hybrid" | "frontier";
type ApiKeyMode = "foreman_managed" | "byok";
type ValidationStatus = "idle" | "validating" | "valid" | "invalid";
type AgentRole =
  | "company_leadership"
  | "project_management"
  | "writing_content"
  | "engineering_support"
  | "general_assistant";

const ROLE_OPTIONS: { key: AgentRole; label: string; description: string }[] = [
  { key: "company_leadership", label: "Company leadership", description: "Strategy, hiring, and high-level decisions" },
  { key: "project_management", label: "Project management", description: "Tracking tasks, timelines, and deliverables" },
  { key: "writing_content", label: "Writing & content", description: "Drafting, editing, and content strategy" },
  { key: "engineering_support", label: "Engineering support", description: "Code reviews, architecture, and tech decisions" },
  { key: "general_assistant", label: "General assistant", description: "Flexible help across any area" }
];

const ROLE_TO_BACKEND_ROLE: Record<AgentRole, string> = {
  company_leadership: "ceo",
  project_management: "engineer",
  writing_content: "marketing_analyst",
  engineering_support: "engineer",
  general_assistant: "ceo"
};

const LAUNCH_STAGES = [
  "Setting up your workspace…",
  "Configuring model access…",
  "Running your agent for the first time…",
  "Almost ready…"
];

const STEP_LABELS = ["Name", "Role", "Model", "Key", "Review"];

const ROLE_SUGGESTIONS: Record<AgentRole, string[]> = {
  company_leadership: [
    "Review our current strategy and suggest priorities for this quarter",
    "Help me organize my team's goals and deliverables",
    "Create a hiring plan for the next 90 days"
  ],
  project_management: [
    "Create a project plan for our next product launch",
    "Track and prioritize our current tasks and deadlines",
    "Summarize what the team accomplished this week"
  ],
  writing_content: [
    "Draft a blog post about our product for our target audience",
    "Write email copy for our next campaign",
    "Create a content calendar for the next month"
  ],
  engineering_support: [
    "Review our codebase and identify the top 3 areas for improvement",
    "Write a technical specification for our next feature",
    "Summarize recent code changes and flag potential issues"
  ],
  general_assistant: [
    "Help me organize my tasks for this week",
    "Research competitors in our industry and summarize findings",
    "Draft a summary of our latest meeting notes"
  ]
};

const STEP_TO_INDEX: Partial<Record<WizardStep, number>> = {
  name: 0,
  role: 1,
  model: 2,
  "api-key": 3,
  "byok-key": 3,
  review: 4
};

const stageLabelFromFailureStep = (failedStep: string): string => {
  const map: Record<string, string> = {
    "step-0-payment-gate": "payment checks",
    "step-1-paperclip-company": "creating your workspace",
    "step-2-hire-ceo": "hiring your agent",
    "step-3-openclaw-secret-reload": "connecting to model provider",
    "step-4-openclaw-add": "configuring model access",
    "step-5-openclaw-verify": "verifying agent launch",
    "step-6-supabase-write": "saving your agent record"
  };
  return map[failedStep] ?? failedStep;
};

interface OnboardingWizardProps {
  customer: CustomerSession;
  onComplete?: () => void;
}

export function OnboardingWizard({ customer, onComplete }: OnboardingWizardProps) {
  const storageKey = `foreman:wizard:${customer.customer_id}`;
  const savedStep = (() => { try { const s = localStorage.getItem(storageKey); if (s === "welcome" || s === "name" || s === "role" || s === "model" || s === "api-key" || s === "byok-key" || s === "review") return s; } catch { /* */ } return null; })();
  const [step, setStep] = useState<WizardStep>(savedStep ?? "welcome");
  const [agentName, setAgentName] = useState("CEO");
  const [nameError, setNameError] = useState<string | null>(null);
  const [roleKey, setRoleKey] = useState<AgentRole>("company_leadership");
  const [modelTier, setModelTier] = useState<ModelTier>("hybrid");
  const [apiKeyMode, setApiKeyMode] = useState<ApiKeyMode>("foreman_managed");
  const [openRouterKey, setOpenRouterKey] = useState("");
  const [keyValidationStatus, setKeyValidationStatus] = useState<ValidationStatus>("idle");
  const [keyValidationMessage, setKeyValidationMessage] = useState<string | null>(null);
  const [launchStageIndex, setLaunchStageIndex] = useState(0);
  const [failure, setFailure] = useState<ProvisionFailureResponse | null>(null);
  const [firstTask, setFirstTask] = useState("");
  const [sendingFirstTask, setSendingFirstTask] = useState(false);

  const h1Ref = useRef<HTMLHeadingElement>(null);

  useEffect(() => {
    h1Ref.current?.focus();
  }, [step]);

  // BYOK key validation — 450 ms debounce (reuses existing logic from CreateCEO)
  useEffect(() => {
    if (apiKeyMode !== "byok") {
      setKeyValidationStatus("idle");
      setKeyValidationMessage(null);
      return;
    }

    const trimmed = openRouterKey.trim();
    if (trimmed.length < 20) {
      setKeyValidationStatus("invalid");
      setKeyValidationMessage("Enter a full OpenRouter key to validate.");
      return;
    }

    const timeoutId = window.setTimeout(async () => {
      setKeyValidationStatus("validating");
      try {
        const response = await fetch("/api/internal/openrouter/validate-key", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          credentials: "include",
          body: JSON.stringify({ api_key: trimmed })
        });

        if (!response.ok) {
          setKeyValidationStatus("invalid");
          setKeyValidationMessage("Unable to validate key right now.");
          return;
        }

        const data = (await response.json()) as { valid: boolean; reason?: string };
        if (data.valid) {
          setKeyValidationStatus("valid");
          setKeyValidationMessage("Valid OpenRouter key.");
        } else {
          setKeyValidationStatus("invalid");
          setKeyValidationMessage(data.reason ?? "OpenRouter rejected this key.");
        }
      } catch {
        setKeyValidationStatus("invalid");
        setKeyValidationMessage("Network error while validating key.");
      }
    }, 450);

    return () => window.clearTimeout(timeoutId);
  }, [apiKeyMode, openRouterKey]);

  // Cycle launch stage messages while provisioning
  useEffect(() => {
    if (step !== "launching") return;
    const id = window.setInterval(() => {
      setLaunchStageIndex((prev) => (prev + 1 >= LAUNCH_STAGES.length ? prev : prev + 1));
    }, 1_200);
    return () => window.clearInterval(id);
  }, [step]);

  const STEP_MAP: Record<string, string> = {
    name: "profile",
    model: "plan",
    "api-key": "model",
    review: "agent"
  };

  const markOnboardingStep = (wizardStep: string) => {
    const serverStep = STEP_MAP[wizardStep];
    if (serverStep) {
      fetch("/api/internal/onboarding/complete-step", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ step: serverStep }),
        credentials: "include"
      }).catch(() => { /* non-blocking */ });
    }
  };

  const goTo = (target: WizardStep) => {
    setStep(target);
    try { localStorage.setItem(storageKey, target); } catch { /* ignore */ }
    markOnboardingStep(target);
  };

  const handleNameContinue = () => {
    if (agentName.trim().length === 0) {
      setNameError("Give your agent a name to continue.");
      return;
    }
    setNameError(null);
    goTo("role");
  };

  const handleProvision = async () => {
    setFailure(null);
    setLaunchStageIndex(0);
    goTo("launching");

    try {
      const response = await fetch("/api/internal/agents/provision", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          customer_id: customer.customer_id,
          agent_name: agentName.trim(),
          role: ROLE_TO_BACKEND_ROLE[roleKey],
          model_tier: modelTier,
          idempotency_key: crypto.randomUUID(),
          api_key_mode: apiKeyMode,
          approval_preference: "auto",
          byok_key: apiKeyMode === "byok" ? openRouterKey.trim() : undefined
        })
      });

      if (response.ok) {
        goTo("success");
        return;
      }

      if (response.status === 422) {
        const data = (await response.json()) as ProvisionFailureResponse;
        setFailure(data);
        goTo("error");
        return;
      }

      setFailure({
        outcome: "failed",
        provisioning_id: "unknown",
        failed_step: "unknown",
        error_code: "ONBOARDING_SUBMIT_FAILED",
        error_message: "Unexpected backend response",
        customer_message: "We could not create your agent right now. Please retry."
      });
      goTo("error");
    } catch {
      setFailure({
        outcome: "failed",
        provisioning_id: "unknown",
        failed_step: "network",
        error_code: "NETWORK_ERROR",
        error_message: "Unable to reach backend",
        customer_message: "Network error while creating your agent. Please retry."
      });
      goTo("error");
    }
  };

  const handleSendFirstTask = async () => {
    if (!firstTask.trim()) {
      onComplete?.();
      window.location.assign("/dashboard");
      return;
    }
    setSendingFirstTask(true);
    try {
      await fetch("/api/internal/chat/send", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ message: firstTask.trim() })
      });
    } catch {
      // best-effort — navigate regardless
    }
    onComplete?.();
    window.location.assign("/dashboard");
  };

  const roleLabel = ROLE_OPTIONS.find((r) => r.key === roleKey)?.label ?? roleKey;
  const modelLabel: Record<ModelTier, string> = { open: "Essentials", hybrid: "Recommended", frontier: "Premium" };
  const apiKeyLabel = apiKeyMode === "foreman_managed" ? "Hassle-free setup" : "Your OpenRouter key";

  // ── Envelope screens (no step indicator) ────────────────────────────────────

  if (step === "welcome") {
    return (
      <main className="app-shell">
        <section className="panel wizard-panel">
          <p className="wizard-wordmark">foreman</p>
          <h1 ref={h1Ref} tabIndex={-1} className="wizard-headline">
            Let's build your first agent.
          </h1>
          <p className="wizard-sub">
            You'll be up and running in about 2 minutes. We'll ask you five quick questions,
            then your agent will be live and ready for tasks.
          </p>
          <button type="button" className="wizard-btn-primary wizard-cta" onClick={() => goTo("name")}>
            Get started →
          </button>
          <p className="wizard-skip-row">
            <button
              type="button"
              className="link-button"
              onClick={() => { onComplete?.(); window.location.assign("/dashboard"); }}
            >
              I already have an agent — skip
            </button>
          </p>
        </section>
      </main>
    );
  }

  if (step === "launching") {
    return (
      <main className="app-shell">
        <section className="panel wizard-panel wizard-launching">
          <div className="wizard-spinner" aria-hidden="true" />
          <h1 ref={h1Ref} tabIndex={-1} className="wizard-headline">
            Launching your agent…
          </h1>
          <p className="wizard-launch-status">{LAUNCH_STAGES[launchStageIndex]}</p>
        </section>
      </main>
    );
  }

  if (step === "success") {
    const suggestions = ROLE_SUGGESTIONS[roleKey] ?? ROLE_SUGGESTIONS.general_assistant;
    return (
      <main className="app-shell">
        <section className="panel wizard-panel wizard-success">
          <div className="wizard-check" aria-hidden="true" />
          <h1 ref={h1Ref} tabIndex={-1} className="wizard-headline">
            Your agent is live!
          </h1>
          <p className="wizard-sub">{agentName} is running and ready for its first task.</p>
          <label className="wizard-first-task-label">
            <textarea
              className="cos-input wizard-first-task"
              placeholder={`What should ${agentName} work on first?`}
              value={firstTask}
              onChange={(e) => setFirstTask(e.target.value)}
              rows={3}
            />
          </label>
          <div className="wizard-suggestion-chips">
            {suggestions.map((s) => (
              <button
                key={s}
                type="button"
                className={`wizard-chip${firstTask === s ? " wizard-chip--active" : ""}`}
                onClick={() => setFirstTask(s)}
              >
                {s}
              </button>
            ))}
          </div>
          <div className="wizard-nav">
            <button
              type="button"
              className="wizard-btn-primary"
              onClick={handleSendFirstTask}
              disabled={sendingFirstTask}
            >
              {firstTask.trim()
                ? sendingFirstTask
                  ? "Sending…"
                  : "Send first task →"
                : "Go to dashboard"}
            </button>
          </div>
        </section>
      </main>
    );
  }

  if (step === "error") {
    return (
      <main className="app-shell">
        <section className="panel wizard-panel">
          <h1 ref={h1Ref} tabIndex={-1} className="wizard-question">
            Something went wrong
          </h1>
          {failure && (
            <FailureCard
              outcome={failure.outcome}
              stageLabel={stageLabelFromFailureStep(failure.failed_step)}
              suggestedAction={failure.customer_message}
              technicalDetails={{
                errorCode: failure.error_code,
                provisioningId: failure.provisioning_id,
                failedStep: failure.failed_step,
                errorMessage: failure.error_message
              }}
              onRetry={() => {
                setFailure(null);
                goTo("review");
              }}
            />
          )}
        </section>
      </main>
    );
  }

  // ── Steps 1–5 (with progress indicator) ─────────────────────────────────────

  const currentIndex = STEP_TO_INDEX[step] ?? 0;

  return (
    <main className="app-shell">
      <section className="panel wizard-panel">
        <WizardProgress steps={STEP_LABELS} currentIndex={currentIndex} />

        {step === "name" && (
          <>
            <h1 ref={h1Ref} tabIndex={-1} className="wizard-question">
              What should we call your agent?
            </h1>
            <p className="muted">This is just a display name. You can change it later.</p>
            <div className="wizard-chip-row">
              {["CEO", "Chief of Staff", "EA"].map((chip) => (
                <button
                  key={chip}
                  type="button"
                  className={`wizard-chip${agentName === chip ? " wizard-chip--active" : ""}`}
                  onClick={() => {
                    setAgentName(chip);
                    setNameError(null);
                  }}
                >
                  {chip}
                </button>
              ))}
              <button
                type="button"
                className="wizard-chip"
                onClick={() => {
                  setAgentName("");
                  setNameError(null);
                }}
              >
                Custom…
              </button>
            </div>
            <div className="wizard-input-wrap">
              <input
                value={agentName}
                onChange={(e) => {
                  setAgentName(e.target.value.slice(0, 40));
                  setNameError(null);
                }}
                placeholder="e.g. CEO, Chief of Staff, Assistant"
                autoFocus
              />
              {agentName.length >= 30 && (
                <small className="muted wizard-char-count">{agentName.length}/40</small>
              )}
              {nameError && (
                <small className="error-text" role="alert">
                  {nameError}
                </small>
              )}
            </div>
            <div className="wizard-nav">
              <button type="button" className="wizard-btn-ghost" onClick={() => goTo("welcome")}>
                Back
              </button>
              <button type="button" className="wizard-btn-primary" onClick={handleNameContinue}>
                Continue →
              </button>
            </div>
          </>
        )}

        {step === "role" && (
          <>
            <h1 ref={h1Ref} tabIndex={-1} className="wizard-question">
              What will your agent focus on?
            </h1>
            <p className="muted">This helps Foreman configure the right defaults.</p>
            <div className="wizard-role-grid" role="radiogroup" aria-label="Agent focus area">
              {ROLE_OPTIONS.map((option) => (
                <button
                  key={option.key}
                  type="button"
                  role="radio"
                  aria-checked={roleKey === option.key}
                  className={`wizard-role-card${roleKey === option.key ? " wizard-role-card--selected" : ""}`}
                  onClick={() => setRoleKey(option.key)}
                >
                  <span className="wizard-role-label">{option.label}</span>
                  <span className="wizard-role-desc">{option.description}</span>
                  {roleKey === option.key && (
                    <span className="wizard-role-check" aria-hidden="true">
                      ✓
                    </span>
                  )}
                </button>
              ))}
            </div>
            <div className="wizard-nav">
              <button type="button" className="wizard-btn-ghost" onClick={() => goTo("name")}>
                Back
              </button>
              <button type="button" className="wizard-btn-primary" onClick={() => goTo("model")}>
                Continue →
              </button>
            </div>
          </>
        )}

        {step === "model" && (
          <>
            <h1 ref={h1Ref} tabIndex={-1} className="wizard-question">
              Choose your agent's capability level
            </h1>
            <p className="muted">Don't worry — you can change this anytime from settings.</p>
            <div className="wizard-option-stack" role="radiogroup" aria-label="Model tier">
              {(["open", "hybrid", "frontier"] as ModelTier[]).map((tier) => (
                <button
                  key={tier}
                  type="button"
                  role="radio"
                  aria-checked={modelTier === tier}
                  className={`wizard-option${modelTier === tier ? " wizard-option--selected" : ""}`}
                  onClick={() => setModelTier(tier)}
                >
                  <span className="wizard-option-title">
                    {tier === "open" && "Essentials"}
                    {tier === "hybrid" && (
                      <>
                        Recommended <span className="wizard-badge">Best for most</span>
                      </>
                    )}
                    {tier === "frontier" && "Premium"}
                  </span>
                  <span className="wizard-option-desc">
                    {tier === "open" && "Good for simple tasks, lowest cost"}
                    {tier === "hybrid" && "Best balance of speed and smarts, small usage surcharge"}
                    {tier === "frontier" && "Best reasoning for complex work, higher cost"}
                  </span>
                </button>
              ))}
            </div>
            <div className="wizard-nav">
              <button type="button" className="wizard-btn-ghost" onClick={() => goTo("role")}>
                Back
              </button>
              <button type="button" className="wizard-btn-primary" onClick={() => goTo("api-key")}>
                Continue →
              </button>
            </div>
          </>
        )}

        {step === "api-key" && (
          <>
            <h1 ref={h1Ref} tabIndex={-1} className="wizard-question">
              How would you like to connect?
            </h1>
            <div className="wizard-option-stack" role="radiogroup" aria-label="API key mode">
              <button
                type="button"
                role="radio"
                aria-checked={apiKeyMode === "foreman_managed"}
                className={`wizard-option${apiKeyMode === "foreman_managed" ? " wizard-option--selected" : ""}`}
                onClick={() => setApiKeyMode("foreman_managed")}
              >
                <span className="wizard-option-title">Hassle-free setup <span className="wizard-badge">Recommended</span></span>
                <span className="wizard-option-desc">Foreman handles everything. Just start chatting with your agent.</span>
              </button>
              <button
                type="button"
                role="radio"
                aria-checked={apiKeyMode === "byok"}
                className={`wizard-option${apiKeyMode === "byok" ? " wizard-option--selected" : ""}`}
                onClick={() => setApiKeyMode("byok")}
              >
                <span className="wizard-option-title">I have an OpenRouter key</span>
                <span className="wizard-option-desc">Lower cost per task. Paste your key from openrouter.ai/keys</span>
              </button>
            </div>
            {apiKeyMode === "byok" && (
              <div className="wizard-byok-info">
                <p className="muted wizard-hint">
                  This option is for users who already have an OpenRouter API key. If you're not sure, choose Hassle-free setup — you can always switch later in Settings.
                </p>
                <details className="wizard-details">
                  <summary className="wizard-details-summary">What's an API key?</summary>
                  <p className="wizard-details-body">
                    An API key is like a password that lets Foreman talk to AI models on your behalf. 
                    If you don't have one, choose Hassle-free setup — it's included in your plan. 
                    You can get a key at <a href="https://openrouter.ai/keys" target="_blank" rel="noopener noreferrer">openrouter.ai/keys</a>.
                  </p>
                </details>
              </div>
            )}
            <div className="wizard-nav">
              <button type="button" className="wizard-btn-ghost" onClick={() => goTo("model")}>
                Back
              </button>
              <button
                type="button"
                className="wizard-btn-primary"
                onClick={() => goTo(apiKeyMode === "byok" ? "byok-key" : "review")}
              >
                Continue →
              </button>
            </div>
          </>
        )}

        {step === "byok-key" && (
          <>
            <h1 ref={h1Ref} tabIndex={-1} className="wizard-question">
              Enter your OpenRouter API key
            </h1>
            <p className="muted">Find your key at <a href="https://openrouter.ai/keys" target="_blank" rel="noopener noreferrer">openrouter.ai/keys</a>. Your key is stored encrypted and never shared.</p>
            <div className="wizard-input-wrap">
              <input
                type="password"
                value={openRouterKey}
                onChange={(e) => setOpenRouterKey(e.target.value)}
                placeholder="sk-or-v1-..."
                autoFocus
                className={
                  keyValidationStatus === "valid"
                    ? "input-valid"
                    : keyValidationStatus === "invalid"
                      ? "input-invalid"
                      : ""
                }
              />
              {keyValidationStatus !== "idle" && (
                <small
                  className={
                    keyValidationStatus === "valid"
                      ? "success-text"
                      : keyValidationStatus === "validating"
                        ? "muted"
                        : "error-text"
                  }
                  role={keyValidationStatus === "invalid" ? "alert" : undefined}
                >
                  {keyValidationStatus === "validating" ? "Checking key…" : keyValidationMessage}
                </small>
              )}
            </div>
            <div className="wizard-nav">
              <button type="button" className="wizard-btn-ghost" onClick={() => goTo("api-key")}>
                Back
              </button>
              <button
                type="button"
                className="wizard-btn-primary"
                disabled={keyValidationStatus !== "valid"}
                onClick={() => goTo("review")}
              >
                Continue →
              </button>
            </div>
          </>
        )}

        {step === "review" && (
          <>
            <h1 ref={h1Ref} tabIndex={-1} className="wizard-question">
              Ready to launch?
            </h1>
            <div className="wizard-whats-next">
              <p className="wizard-whats-next-title">What happens next:</p>
              <ol className="wizard-whats-next-list">
                <li>Your agent is created and starts running immediately</li>
                <li>You can chat with it from your dashboard</li>
                <li>Give it any task — it works on it and asks for your approval on important decisions</li>
              </ol>
            </div>
            <div className="wizard-summary">
              {(
                [
                  { label: "Name", value: agentName, target: "name" as WizardStep },
                  { label: "Role", value: roleLabel, target: "role" as WizardStep },
                  { label: "Model", value: modelLabel[modelTier], target: "model" as WizardStep },
                  { label: "API key", value: apiKeyLabel, target: "api-key" as WizardStep }
                ] as { label: string; value: string; target: WizardStep }[]
              ).map(({ label, value, target }) => (
                <div key={label} className="wizard-summary-row">
                  <span className="wizard-summary-label">{label}</span>
                  <span className="wizard-summary-value">{value}</span>
                  <button
                    type="button"
                    className="link-button wizard-edit-btn"
                    onClick={() => goTo(target)}
                  >
                    Edit
                  </button>
                </div>
              ))}
            </div>
            <div className="wizard-nav">
              <button
                type="button"
                className="wizard-btn-ghost"
                onClick={() => goTo(apiKeyMode === "byok" ? "byok-key" : "api-key")}
              >
                Back
              </button>
              <button type="button" className="wizard-btn-primary" onClick={handleProvision}>
                Launch my agent →
              </button>
            </div>
          </>
        )}
      </section>
    </main>
  );
}
