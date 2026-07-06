# Requirements

Before building the hospital twin, satisfy the **six category-wide requirements** in
`global-requirements-synthetic.md` (a Python data/engineering environment; a target clinical data
model/standard; an isolated non-production test environment; privacy/governance/compliance
stakeholders and policy; AI/QA use cases and a pilot scope; and read-only, minimized
reference/real-data access for fidelity). Those are assumed here and are **not** repeated.

The following prerequisites are **specific to the hospital twin**. Each names *what* it is, *why*
it is required, *how to verify* it, and *how to implement* it if missing. Confirm all of them
before starting the Build Guide (`03-implementation.md`).

## 1. A defined AI-under-test integration contract

- **Description:** A documented contract for how the AI solution under test is invoked from the
  twin — the **plug-in point**: input shape (e.g. a FHIR Bundle, an OMOP record set, or a
  feature vector), output shape (e.g. a risk score, an alert, a recommendation), and the invocation
  mechanism (a local Python callable/adapter, or an **isolated** test endpoint). Recorded as the
  `Twin AI Plug-In Contract – Pilot – v1`.
- **Why required:** Scenarios and the plug-in harness are built against this contract; without it
  the twin cannot call the AI or capture its outputs for scoring.
- **How to verify:** Confirm the AI team can supply (a) an input schema, (b) an output schema, and
  (c) a callable/endpoint that runs **inside the isolated environment** with no production or
  real-PHI dependency.
- **How to implement if missing:** Work with the AI team to wrap the model behind a thin adapter
  that accepts the twin's normalized input and returns a structured output; document the two
  schemas before building scenarios.

## 2. A synthetic data source bound to the target model

- **Description:** A working **synthetic data source** — a generator (Synthea-style or a commercial
  platform, at the pattern level) or a previously generated governed synthetic dataset — that
  produces records in, or mappable to, the chosen target model (FHIR/OMOP/native). Recorded as the
  `Synthetic Feed Binding – Pilot – v1`.
- **Why required:** The twin's population and records come from this feed; it is what lets the twin
  be populated and clinically plausible with **no real PHI**.
- **How to verify:** Generate (or load) a small sample and confirm it parses into the twin's target
  model and that the in-scope domains (patients, encounters, conditions, meds, labs/vitals) are
  present.
- **How to implement if missing:** Stand up the generator or obtain the governed synthetic dataset;
  write/confirm the mapping from its output to the target model.

## 3. Scenario definitions for the pilot AI use cases

- **Description:** For each pilot AI use case, at least one **scenario**: a named starting state,
  an ordered event sequence, and the **expected/acceptable AI behavior** (including the failure
  behavior that must be caught). Recorded collectively as the `Twin Scenario Suite – Pilot – v1`.
- **Why required:** A scenario is the unit of evaluation; without expected behavior there is no
  pass/fail signal for the AI.
- **How to verify:** Confirm each pilot use case has ≥1 scenario with an explicit expected outcome
  and an explicit unacceptable outcome.
- **How to implement if missing:** Run a scenario-design working session with the AI/QA and clinical
  SME stakeholders; capture each scenario in the twin's scenario format (see `03-implementation.md`).

## 4. A reference profile for fidelity gates

- **Description:** The agreed **reference distributions/statistics** the twin's synthetic output is
  measured against (from the read-only, minimized reference of global requirement #6, or agreed
  published reference distributions). Recorded as `Twin Reference Profile – Pilot – v1`.
- **Why required:** Fidelity/coverage gates compare the twin's population and events to reality;
  without a reference, "realistic" is unfalsifiable.
- **How to verify:** Confirm the reference source, the specific metrics in scope (e.g. age/sex
  distribution, condition prevalence, encounter length-of-stay, event timing), and the acceptance
  thresholds.
- **How to implement if missing:** Agree the reference approach (governed real stats vs. published
  reference distributions) and record the metrics + thresholds before validating.

## 5. Explicit pass/fail gates (fidelity, privacy, scenario)

- **Description:** Written, numeric **acceptance gates** for the pilot: a **fidelity** gate (how
  close to the reference profile is acceptable), a **privacy** gate (the disclosure-risk checks the
  synthetic data must pass), and a **scenario** gate (what fraction of scenarios the AI must handle
  acceptably). Recorded as `Twin Acceptance Gates – Pilot – v1`.
- **Why required:** The deployment model requires explicit pass/fail gates and a documented
  rollback; the tools emit signals that only mean something against agreed thresholds.
- **How to verify:** Confirm each gate has a metric, a threshold, and a named owner who accepts it.
- **How to implement if missing:** Define the three gates with the AI/QA and privacy stakeholders
  before the pilot evaluation; the privacy gate's *acceptance* is deferred to the privacy office.

## 6. Twin scope & configuration record

- **Description:** A single **scope/config record** for the pilot twin — target model, in-scope
  domains, service line(s), population size, simulation clock settings, the AI plug-in contract
  reference, and the seed for reproducibility. Recorded as `Twin Scope Config – Pilot – v1`
  (produced/validated by the config helper tool).
- **Why required:** Every tool and step reads this one record; it is the reproducibility and
  traceability anchor for the whole twin.
- **How to verify:** Confirm the config validates against the config helper
  (`twin_readiness_assess.py --validate-config`) with no errors.
- **How to implement if missing:** Generate a starter config with the config helper
  (`twin_readiness_assess.py --init-config`), fill it in, and validate.
