import { type FormEvent, useEffect, useMemo, useState } from "react";
import { FailureCard } from "../components/FailureCard";

interface CustomerSession {
  customer_id: string;
  email: string;
  display_name: string;
  current_tier: string | null;
  current_billing_mode: string;
}

interface ProvisionFailureResponse {
  outcome: "failed" | "blocked" | "partial";
  provisioning_id: string;
  failed_step: string;
  error_code: string;
  error_message: string;
  customer_message: string;
}

const PROGRESS_STAGES = [
  "Setting up your CEO...",
  "Connecting to your model provider...",
  "Configuring agent permissions...",
  "Almost ready..."
];

const stageLabelFromFailureStep = (failedStep: string): string => {
  const map: Record<string, string> = {
    "step-0-payment-gate": "payment checks",
    "step-1-paperclip-company": "creating your workspace in Paperclip",
    "step-2-hire-ceo": "hiring your CEO in Paperclip",
    "step-3-openclaw-secret-reload": "connecting to model provider",
    "step-4-openclaw-add": "configuring model access",
    "step-5-openclaw-verify": "verifying agent launch",
    "step-6-supabase-write": "saving your agent record"
  };
  return map[failedStep] ?? failedStep;
};

interface CreateCEOProps {
  customer: CustomerSession;
}

export function CreateCEO({ customer }: CreateCEOProps) {
  const [displayName, setDisplayName] = useState("CEO");
  const [modelTier, setModelTier] = useState<"open" | "frontier" | "hybrid">("hybrid");
  const [apiKeyMode, setApiKeyMode] = useState<"foreman_managed" | "byok">("foreman_managed");
  const [approvalPreference, setApprovalPreference] = useState<"auto" | "manual">("auto");
  const [openRouterKey, setOpenRouterKey] = useState("");
  const [keyValidationStatus, setKeyValidationStatus] = useState<"idle" | "validating" | "valid" | "invalid">("idle");
  const [keyValidationMessage, setKeyValidationMessage] = useState<string | null>(null);
  const [currentProgressIndex, setCurrentProgressIndex] = useState(0);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [failure, setFailure] = useState<ProvisionFailureResponse | null>(null);

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
          headers: {
            "Content-Type": "application/json"
          },
          credentials: "include",
          body: JSON.stringify({
            api_key: trimmed
          })
        });

        if (!response.ok) {
          setKeyValidationStatus("invalid");
          setKeyValidationMessage("Unable to validate key right now.");
          return;
        }

        const data = (await response.json()) as { valid: boolean; reason?: string };
        if (data.valid) {
          setKeyValidationStatus("valid");
          setKeyValidationMessage("OpenRouter key is valid.");
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

  useEffect(() => {
    if (!isSubmitting) {
      return;
    }
    const intervalId = window.setInterval(() => {
      setCurrentProgressIndex((previous) => (previous + 1 >= PROGRESS_STAGES.length ? previous : previous + 1));
    }, 1_200);
    return () => window.clearInterval(intervalId);
  }, [isSubmitting]);

  const canSubmit = useMemo(() => {
    if (isSubmitting) {
      return false;
    }
    if (displayName.trim().length === 0) {
      return false;
    }
    if (apiKeyMode === "byok" && keyValidationStatus !== "valid") {
      return false;
    }
    return true;
  }, [apiKeyMode, displayName, isSubmitting, keyValidationStatus]);

  const submitProvisioning = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setFailure(null);
    setCurrentProgressIndex(0);
    setIsSubmitting(true);

    try {
      const response = await fetch("/api/internal/agents/provision", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        credentials: "include",
        body: JSON.stringify({
          customer_id: customer.customer_id,
          agent_name: displayName.trim(),
          role: "ceo",
          model_tier: modelTier,
          idempotency_key: crypto.randomUUID(),
          api_key_mode: apiKeyMode,
          approval_preference: approvalPreference,
          byok_key: apiKeyMode === "byok" ? openRouterKey.trim() : undefined
        })
      });

      if (response.ok) {
        window.location.assign("/dashboard");
        return;
      }

      if (response.status === 422) {
        const data = (await response.json()) as ProvisionFailureResponse;
        setFailure(data);
        return;
      }

      setFailure({
        outcome: "failed",
        provisioning_id: "unknown",
        failed_step: "unknown",
        error_code: "ONBOARDING_SUBMIT_FAILED",
        error_message: "Unexpected backend response",
        customer_message: "We could not create your CEO right now. Please retry."
      });
    } catch {
      setFailure({
        outcome: "failed",
        provisioning_id: "unknown",
        failed_step: "network",
        error_code: "NETWORK_ERROR",
        error_message: "Unable to reach backend",
        customer_message: "Network error while creating your CEO. Please retry."
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <main className="app-shell">
      <section className="panel">
        <h1>Create your CEO</h1>
        <p className="muted">
          Logged in as <strong>{customer.email}</strong>.
        </p>

        <form className="stack" onSubmit={submitProvisioning}>
          <label className="field">
            <span>Display name</span>
            <input value={displayName} onChange={(event) => setDisplayName(event.target.value)} />
          </label>

          <fieldset className="field">
            <legend>Model tier</legend>
            <label>
              <input
                type="radio"
                name="model-tier"
                value="open"
                checked={modelTier === "open"}
                onChange={() => setModelTier("open")}
              />
              Open models - most affordable
            </label>
            <label>
              <input
                type="radio"
                name="model-tier"
                value="frontier"
                checked={modelTier === "frontier"}
                onChange={() => setModelTier("frontier")}
              />
              Frontier models - most capable
            </label>
            <label>
              <input
                type="radio"
                name="model-tier"
                value="hybrid"
                checked={modelTier === "hybrid"}
                onChange={() => setModelTier("hybrid")}
              />
              Hybrid (recommended) - open by default, frontier when needed
            </label>
          </fieldset>

          <fieldset className="field">
            <legend>API key mode</legend>
            <label>
              <input
                type="radio"
                name="api-key-mode"
                value="foreman_managed"
                checked={apiKeyMode === "foreman_managed"}
                onChange={() => setApiKeyMode("foreman_managed")}
              />
              Use Foreman's key - easier setup, includes a usage surcharge
            </label>
            <label>
              <input
                type="radio"
                name="api-key-mode"
                value="byok"
                checked={apiKeyMode === "byok"}
                onChange={() => setApiKeyMode("byok")}
              />
              Bring my own OpenRouter key - more control, lower cost
            </label>
          </fieldset>

          {apiKeyMode === "byok" && (
            <label className="field">
              <span>OpenRouter API key</span>
              <input
                type="password"
                value={openRouterKey}
                onChange={(event) => setOpenRouterKey(event.target.value)}
                placeholder="sk-or-v1-..."
              />
              {keyValidationStatus !== "idle" && (
                <small className={keyValidationStatus === "valid" ? "success-text" : "error-text"}>
                  {keyValidationStatus === "validating" ? "Validating key..." : keyValidationMessage}
                </small>
              )}
            </label>
          )}

          <fieldset className="field">
            <legend>Approval preference</legend>
            <label>
              <input
                type="radio"
                name="approval-preference"
                value="auto"
                checked={approvalPreference === "auto"}
                onChange={() => setApprovalPreference("auto")}
              />
              Let my CEO hire as needed (recommended)
            </label>
            <label title="Coming soon">
              <input type="radio" name="approval-preference" value="manual" disabled />
              Notify me to approve each new hire (Coming soon)
            </label>
          </fieldset>

          <button type="submit" disabled={!canSubmit}>
            {isSubmitting ? "Creating your CEO..." : "Create CEO"}
          </button>
        </form>

        {isSubmitting && (
          <section className="progress-card">
            <h2>Provisioning progress</h2>
            <p>{PROGRESS_STAGES[currentProgressIndex]}</p>
          </section>
        )}

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
            onRetry={() => setFailure(null)}
          />
        )}
      </section>
    </main>
  );
}
