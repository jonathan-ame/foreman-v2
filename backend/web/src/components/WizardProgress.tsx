interface WizardProgressProps {
  steps: string[];
  currentIndex: number;
}

export function WizardProgress({ steps, currentIndex }: WizardProgressProps) {
  return (
    <nav className="wizard-progress" aria-label="Onboarding progress">
      <ol className="wizard-progress-list" role="list">
        {steps.map((label, i) => {
          const completed = i < currentIndex;
          const current = i === currentIndex;
          return (
            <li
              key={label}
              className={`wizard-progress-step${completed ? " wizard-progress-step--done" : current ? " wizard-progress-step--current" : ""}`}
              aria-current={current ? "step" : undefined}
            >
              <span className="wizard-progress-dot" aria-hidden="true">
                {completed ? "✓" : ""}
              </span>
              <span className="wizard-progress-label">{label}</span>
            </li>
          );
        })}
      </ol>
    </nav>
  );
}
