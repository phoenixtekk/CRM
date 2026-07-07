# Best Practices

Durable practices for deploying and driving adoption of Gemini Enterprise across a large workforce.

## Rollout discipline

- **License assignment is the real switch.** Enabling a feature at the OU level does not grant a paid
  seat; assigning the Gemini/AI license does. Always verify assignment (`License Assignment – Gemini –
  v1`) matches the cohort — under-assignment leaves trained users with no Gemini experience;
  over-assignment wastes seats.
- **Never enable ahead of governance.** Gate G0 (guardrail pre-check) runs before every wave, not just
  the pilot. Speed of rollout must never outrun the security posture owned by the separate governance
  solution.
- **Pilot as a true dress rehearsal.** The pilot cohort exercises every capability, the training
  package, the measurement pipeline, and the rollback — so Wave 1 is a repeat, not a first attempt.
- **One config of record.** `Feature Enablement Matrix – Workforce – v1` is the single source of truth
  for what is enabled where, whether each item is GA or preview, and the exact Admin-console control
  used. Every wave matches the validated pilot configuration; drift is a Gate G1 failure.
- **Snapshot before every wave.** Take a config snapshot before enabling a wave so rollback is
  mechanical and scoped — a regressing wave is reverted without disturbing prior waves.

## Feature-surface caution

- **Treat feature names and toggles as tenant-specific.** Gemini capabilities evolve and some are
  **preview** or edition/region-gated. Record the *actual* control path you used per capability and
  carry a "verify in your tenant" note wherever availability or the label was not certain.
- **Don't enable what you can't govern and verify.** For preview/edition-gated capabilities
  (frequently NotebookLM Enterprise, and evolving controls like Gems), mark them *Deferred* until they
  are clearly available **and** covered by the governance baseline — never enable on assumption.
- **Separate the three concerns.** Governance decides *allowed*, connectors decide *reachable*, this
  deployment rolls out the *allowed + reachable* capability. Keep connector/agent gaps as feedback to
  the connector solution rather than solving them here.

## Adoption

- **Baseline first, then trend.** Capture the pre-rollout adoption baseline before any wave; every
  wave is measured *against* it, so the investment is reported with data, not anecdotes.
- **Train at the moment of enablement.** Deliver the readiness package as the wave goes live — a seat
  assigned without readiness becomes an unused seat.
- **Make adoption the gate.** Gate G3 (adoption threshold) is an objective pass/fail; a wave below
  target is investigated (readiness, connector gaps, feature availability) and remediated before
  expanding — expansion is earned, not scheduled.
- **Role-based use cases beat generic demos.** Package example prompts, starter Gems, and (where
  enabled) NotebookLM use cases per role; concrete "here's how your job gets easier" material drives
  adoption more than feature tours.

## Operations & safety

- **Least-privilege admin.** Run day-to-day rollout with a delegated admin role scoped to licensing +
  Gemini service management, not a full super-admin.
- **Dry-run everything that writes.** The configuration/assignment helper defaults to dry-run; apply
  only after reviewing the printed plan and confirming the control path in the tenant.
- **No secrets in tooling.** Automation uses ADC / `gcloud` auth or an authorized service account from
  the environment; no exported keys, no credentials in code or config committed to the repo.
- **Read-only measurement.** Reporting uses the Reports API with a read-only scope and (for service
  accounts) domain-wide delegation limited to the reports read scope only.
