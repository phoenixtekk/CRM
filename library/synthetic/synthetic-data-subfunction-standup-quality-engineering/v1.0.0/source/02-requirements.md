# Requirements

This solution builds **on** the six category-wide requirements in
`global-requirements-synthetic.md` (Python data environment; target clinical data model; isolated
non-production environment; privacy/governance stakeholders and policy; AI/QA use cases and a pilot
scope; read-only minimized reference data for fidelity). **Verify those six first** — they are not
repeated here.

Below are the **solution-specific** prerequisites for standing up the sub-function as an operating
model. Each is stated as: **Description / Why required / How to verify / How to implement if missing.**

> **Boundary reminder.** Never place real PHI into a shared synthetic harness, twin, or AI test
> environment. Regulatory/legal determinations (de-identification, IRB, disclosure-risk acceptance)
> are deferred to the organization's privacy, compliance, and legal functions.

---

## S1. An executive sponsor and a funded charter

- **Description:** A named **executive sponsor** in (or over) quality engineering who owns the
  sub-function's mandate, funds at least a pilot's worth of capacity, and can arbitrate cross-program
  prioritization.
- **Why required:** A shared service that cannot say "no" or "not yet" to a program will be captured
  by the loudest requester; a standup without funded capacity produces a charter no one honors. The
  sponsor is the escalation point the intake pod needs.
- **How to verify:** Confirm a named sponsor, a funding line for at least the pilot, and written
  authority to prioritize across programs. Recorded in the **Capability Charter – Sub-Function – v1**.
- **How to implement if missing:** Run the maturity self-assessment (Assess stage) and use its output
  to make the sponsorship ask concrete (scope, capacity, first pilot value) before designing pods.

## S2. Defined pod structure and named roles

- **Description:** A documented **pod/squad structure** (Intake, Generation, Validation & Governance,
  Platform/enablement — some may be virtual at low maturity) with **named people or committed FTE
  fractions** and a RACI for the intake-to-release flow.
- **Why required:** Pods and a single intake queue are what make the service repeatable; without named
  ownership, requests route by relationship, not by process, and KPIs cannot be attributed.
- **How to verify:** Confirm each pod has an owner and committed capacity, and that the RACI names who
  triages, who generates, and who holds the release decision. Use `intakequeue.py --capacity` to model
  whether the committed capacity covers the expected intake.
- **How to implement if missing:** Start with a minimum viable structure (one intake owner, one
  generation engineer, one validation owner — the last two may be the same person at pilot) and grow
  as maturity advances.

## S3. An intake and prioritization scheme

- **Description:** A defined **intake form** (fields: requesting program, AI/QA use case, target
  model/domains, data volume, fidelity need, privacy sensitivity, needed-by date) and a
  **prioritization method** (a documented scoring model — value, urgency, effort, risk).
- **Why required:** Intake is the front door of the operating model and the source of every KPI. An
  undefined intake produces unscoped work and meaningless lead-time metrics.
- **How to verify:** Confirm the intake form exists and the scoring weights are agreed with the
  sponsor. Validate a queue export with `intakequeue.py`.
- **How to implement if missing:** Adopt the intake schema this solution's `intakequeue.py` expects as
  a starting point and tune the weights with the sponsor.

## S4. A defined KPI framework with baselines

- **Description:** An agreed set of **delivery-quality** KPIs (e.g. validation pass rate, defect
  escape rate, rework rate, gate cycle time) and **engineering-productivity** KPIs (e.g. request lead
  time, throughput, flow efficiency, WIP), each with a **definition, a target, and a baseline** taken
  at standup.
- **Why required:** "Repeatable, measured service" is the whole point; without agreed definitions and
  a baseline, later numbers cannot show improvement and cannot survive review.
- **How to verify:** Confirm each KPI has an owner, a formula, a target, and a baseline value. Compute
  a rollup with `kpirollup.py`.
- **How to implement if missing:** Adopt the KPI catalog this solution defines (see `03-implementation.md`)
  and take the baseline on the pilot before expanding.

## S5. A reference-architecture definition of record

- **Description:** A written **reference architecture** naming the environment tiers (isolated
  non-prod), the engine interface (so Synthea / commercial platform / AI framework are swappable
  behind it), the storage and access-control model, the validation/gate stage, and the data-flow
  boundaries (what may and may not cross into the harness).
- **Why required:** Engine-agnostic patterns and a fixed gate stage are what let the sub-function scale
  and swap tools without re-architecting; the architecture is also where the **no-real-PHI-in-shared-
  harness** boundary is enforced.
- **How to verify:** Confirm the architecture document exists and lists the required tiers, the engine
  interface, and the isolation boundary. Validate a machine-readable config with
  `kpirollup.py --refarch`.
- **How to implement if missing:** Use the reference-architecture config schema the validator
  (`kpirollup.py --refarch`) expects as the starting template and fill it in with the platform pod.

## S6. A maturity target and cadence

- **Description:** An agreed **maturity model** (levels from ad-hoc to optimized across dimensions:
  operating model, engineering, validation/quality, privacy/governance, and adoption) and a **review
  cadence** at which the sub-function re-assesses and advances.
- **Why required:** Standup is stage one of five (Assess→…→Expand); without a maturity target and
  cadence, the sub-function plateaus at pilot and never becomes a program-wide service.
- **How to verify:** Confirm the current level is baselined and a target level + review date are set.
  Run `maturityassess.py` to capture the baseline.
- **How to implement if missing:** Run the maturity self-assessment at standup to set the baseline and
  the first target.
