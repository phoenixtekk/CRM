# Requirements

This framework builds on the **six category-wide requirements** in
`global-requirements-synthetic.md` (a Python data/engineering environment, a target clinical data
model, an isolated non-production test environment, privacy/governance stakeholders and policy,
AI/QA use cases with a pilot scope, and read-only/minimized reference-data access for fidelity).
Confirm those first — in particular that **no real PHI ever enters a shared harness, twin, or AI
test environment**, and that regulatory/de-identification determinations remain with the
organization's privacy, compliance, and legal functions.

The prerequisites below are **specific to this operating-model/measurement solution**. Each is
listed with its Description, Why required, How to verify, and How to implement if missing.

## S1. One or more AI-delivery teams (or the mandate to form them)

- **Description:** At least one team that delivers AI on synthetic data / in isolated test
  environments — the people who will be organized into the pod/squad topology and whose work the
  KPIs measure. For a greenfield program, the executive **mandate** to form such teams.
- **Why required:** The framework structures and measures delivery teams; there must be delivery to
  structure and measure.
- **How to verify:** Confirm with the sponsor which team(s) or program(s) are in scope for the
  pilot, and roughly how many people and roles exist today.
- **How to implement if missing:** If no team exists yet, agree the pilot squad's staffing and
  charter with the sponsor before designing the topology.

## S2. Executive sponsorship for structure and measurement

- **Description:** A named executive sponsor who owns the operating-model change and will act on KPI
  outcomes (re-prioritize, staff, or unblock) rather than treat the dashboard as reporting theater.
- **Why required:** Structure changes (who owns what) and measurement changes (which KPIs are
  "official") are organizational decisions; without a sponsor the cadence produces reports no one
  acts on, and the metrics decay into vanity numbers.
- **How to verify:** Confirm the sponsor by name and that they will chair or attend the improvement
  cadence.
- **How to implement if missing:** Secure sponsorship before publishing the KPI catalog; an
  un-sponsored catalog should not be declared "official".

## S3. Access to delivery telemetry (issue tracker, CI/CD, code review)

- **Description:** Read access to the operational data sources the productivity and quality KPIs are
  computed from — the issue/work tracker, the CI/CD pipeline history, and the code-review system —
  exported as data (CSV/JSON) or via their APIs.
- **Why required:** KPIs such as cycle time, throughput, defect escape, and rework are computed from
  this telemetry. Without it the framework cannot instrument the catalog.
- **How to verify:** Confirm you can export, for the pilot squad, a work-item history (with created/
  closed timestamps and type), a build/deploy history (with pass/fail), and a review history.
- **How to implement if missing:** Arrange read-only exports or API access with the tool owners
  before the Generate/Build stage. Reference each tool's documentation for export specifics; do not
  assume console internals — verify against your version.

## S4. Access to the fidelity/privacy validation evidence

- **Description:** The **validation reports** the synthetic solutions already produce — fidelity/
  coverage results and privacy-gate outcomes — as the source for the quality KPIs' safety dimension.
- **Why required:** The framework treats "did the release pass its privacy gate" and "did synthetic
  output meet its fidelity threshold" as first-class quality signals, so speed is never rewarded over
  safety. These come from the validation evidence, not from operational telemetry.
- **How to verify:** Confirm you can obtain, per release/dataset, a pass/fail fidelity result and a
  pass/fail privacy-gate result. **These are aggregate pass/fail signals — never the underlying
  records, and never real PHI.**
- **How to implement if missing:** Agree with the validation owners a standard, PHI-free
  pass/fail export before defining the quality KPIs.

## S5. An agreed, small candidate KPI set (and the discipline to keep it small)

- **Description:** A shortlist of candidate KPIs covering both productivity (flow/throughput) and
  quality (defect/rework/validation/privacy), with an explicit agreement to keep the official set
  small (roughly 6–10) and to **exclude vanity metrics** (raw output counts, individual utilization,
  lines of code, story-point velocity used as a productivity target).
- **Why required:** Metric sprawl and vanity metrics are the primary failure mode of KPI programs;
  the framework's value depends on a curated, outcome-tied set.
- **How to verify:** Confirm stakeholders agree to the small-set principle and the vanity-metric
  exclusion list before the catalog is authored.
- **How to implement if missing:** Facilitate a short definition workshop; use the KPI-definition
  validator tool (see deliverables) to screen candidates against the vanity-metric guard.

## S6. A dashboard / BI surface (or the agreement to use the portable feed)

- **Description:** A place to render the KPIs — an existing BI/dashboard tool, or agreement to
  consume the framework's portable `KPI Dashboard Feed – Program – v1` (CSV/JSON) directly.
- **Why required:** The improvement cadence needs the KPIs visible against targets; the framework
  produces a tool-agnostic feed rather than binding to one BI product.
- **How to verify:** Confirm which surface the pilot squad will use and that it can ingest CSV/JSON.
- **How to implement if missing:** If no BI tool is available, the cadence can run directly off the
  generated feed files and the variance report until a dashboard is provisioned.
