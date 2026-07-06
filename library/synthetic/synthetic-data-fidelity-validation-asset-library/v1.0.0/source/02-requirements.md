# Requirements

These are the **solution-specific** prerequisites for the Synthetic Data Fidelity & Validation
Asset Library. They build on — and do **not** repeat — the six category-wide requirements in
`global-requirements-synthetic.md` (Python environment, a target clinical data model, an isolated
non-production environment, privacy/governance stakeholders and policy, AI/QA use cases + pilot
scope, and read-only minimized reference/real-data access). Confirm those six first; the items
below are what *this* solution additionally needs.

> **Boundary reminder.** No real PHI is written to a shared harness, twin, or AI test environment.
> Reference access is read-only and minimized. Privacy/de-identification determinations are
> deferred to the organization's privacy, compliance, and legal functions.

## 1. A synthetic dataset under test

- **Description:** The synthetic dataset(s) to be validated, in a tabular form (CSV/Parquet) or an
  export from the org's synthetic-data platform, matching the in-scope fields of the target data
  model.
- **Why required:** The library *validates* synthetic data; generation is done by the org's tool.
  Without a dataset to score, there is nothing to measure.
- **How to verify:** Confirm the dataset exists in the isolated environment, is readable, and its
  columns map to the field manifest (below).
- **How to implement if missing:** Generate or export the synthetic dataset from the org's
  synthetic-data tool (e.g. Synthea or a commercial platform — see the vendor's documentation)
  into the isolated environment, then name it `Synthetic Dataset – <Use Case> – Pilot – v1`.

## 2. A governed Reference Profile source (aggregate-only)

- **Description:** Read-only, minimized access to **reference statistics** — either a governed
  real dataset (under the §4/§6 privacy controls) or agreed published reference distributions —
  from which an **aggregate-only** Reference Profile can be built. Row-level real data is never
  copied into the harness.
- **Why required:** Statistical fidelity and utility are measured against this reference; without
  it, fidelity claims are unfounded.
- **How to verify:** Confirm the reference source, its access terms, and that only aggregate
  statistics (not rows) will leave the governed environment.
- **How to implement if missing:** Agree the reference approach with the privacy office; build the
  **Reference Profile – <Use Case> – v1** in-place inside the governed environment and export only
  the aggregate profile.

## 3. A field manifest (schema typing) for the in-scope fields

- **Description:** A per-field declaration of **type** (numeric / categorical / datetime /
  identifier / free-text) and **role** (in scope for fidelity, key for correlation, cohort key for
  coverage, quasi-identifier for privacy signals), for the in-scope fields of the target model.
- **Why required:** Every metric is type-aware — distribution distance for numerics, frequency
  divergence for categoricals, correlation preservation across numeric pairs. Identifiers and
  free-text are excluded from statistical metrics. The manifest is what makes the assets reusable.
- **How to verify:** Confirm each in-scope field has a type and role; confirm identifiers/free-text
  are flagged out of statistical scope.
- **How to implement if missing:** Author the manifest with the AI/QA and data teams and store it
  as **Field Manifest – <Use Case> – v1** (the config helper tool scaffolds this).

## 4. Fidelity/utility tolerances and coverage targets (the pass/fail gates)

- **Description:** The agreed numeric **tolerances** (e.g. maximum acceptable distribution
  distance, minimum correlation-preservation, maximum utility gap) and **coverage targets** (which
  cohorts/ranges/combinations must be present and at what minimum representation) for this AI use
  case.
- **Why required:** "Faithful enough" is use-case-specific. Without agreed thresholds, the
  Evidence Report cannot render an objective pass/fail and the Validate gate is subjective.
- **How to verify:** Confirm the thresholds are documented and signed off by the AI/QA owners.
- **How to implement if missing:** Elicit thresholds with the AI/QA owners; record them in the
  Validation Suite config as **Validation Suite – <Use Case> – v1**.

## 5. A utility evaluation task (TSTR-style), where utility is in scope

- **Description:** A concrete, runnable **downstream task** representative of the AI use case (a
  classification/regression target, or an analytic query) used for **Train-on-Synthetic,
  Test-on-Real (TSTR)** — or, where real data cannot leave the governed environment, an equivalent
  utility comparison run inside it.
- **Why required:** Utility ("fit-for-use") cannot be inferred from statistical fidelity alone; it
  must be measured on a task that mirrors how the AI use case will consume the data.
- **How to verify:** Confirm a representative task, target variable/metric, and evaluation split
  are defined.
- **How to implement if missing:** Define the smallest representative task with the AI/QA team and
  record it as **Utility Task – <Use Case> – v1**.

## 6. A version-controlled asset store

- **Description:** A location (a repo or governed artifact store in the isolated environment) to
  hold the reusable assets — Field Manifest, Reference Profile (aggregate-only), Fidelity Metric
  Suite config, Coverage Specification, Validation Suite config, and Evidence Reports — under
  version control.
- **Why required:** Reuse and auditability depend on the assets being versioned and discoverable;
  this is what lets the library *grow* rather than be rebuilt per dataset.
- **How to verify:** Confirm the store exists, is access-controlled, and holds no row-level real
  data.
- **How to implement if missing:** Provision the store and commit the pilot assets as the first
  entries.
