# Solution Overview

## What this is

The **Synthetic Data Fidelity & Validation Asset Library** turns "we think our synthetic data
is good enough" into **evidence you can show, defend, and reuse**. It gives a data/platform
engineering team a repeatable way to (1) **measure how faithfully** a synthetic dataset
reproduces the statistical shape and analytic behavior of governed real reference data, (2)
**check that coverage and edge cases** the AI use case depends on are actually present, and (3)
**package the metrics, thresholds, and checks as reusable validation assets and test suites** —
so every synthetic dataset that ships carries an **evidence report of quality**, and teams stop
re-inventing validation for each new dataset.

Fidelity is treated as three distinct questions that must not be collapsed into one:

- **Statistical fidelity** — do the synthetic distributions, correlations, and category
  frequencies match the reference within an agreed tolerance?
- **Utility (fit-for-use)** — does a model or analysis behave equivalently on synthetic data as
  on real data for the target AI use case? (Fidelity without utility is a nice-looking dataset
  that trains a worse model.)
- **Coverage / edge cases** — are the rare-but-critical cohorts, value ranges, and combinations
  the AI use case must handle actually represented?

Privacy/disclosure risk is a **separate axis** that this library reports on technically but does
**not** adjudicate — see Limitations.

## How it works

The library is organized around a small set of **named, reusable assets** that you build once
and reuse across datasets:

- **Reference Profile** — a governed, aggregate-only statistical fingerprint of the real data
  (per-field distributions, correlations, category frequencies, missingness), built from
  read-only, minimized reference access. It contains **no row-level real data**.
- **Fidelity Metric Suite** — a configured set of distribution-distance and
  correlation-preservation metrics with pass/fail tolerances.
- **Coverage Specification** — the cohorts, value ranges, and combinations the AI use case
  requires, expressed as checkable rules.
- **Validation Suite** — the metric suite + coverage spec + tolerances bound together as one
  runnable test suite that emits an **Evidence Report**.

Five Python tools operationalize these assets (all safe-by-default, `--dry-run` where they
write, standard-library-first). They are named and described in `08-deliverables-summary.md`.

## Target data model

The library is **schema-driven and model-agnostic**: it works against whatever clinical data
model the organization has standardized on — **FHIR**, **OMOP CDM**, or a source system's native
schema (see global requirement §2). You supply a **field manifest** (which fields are numeric /
categorical / datetime / identifier, and which are in scope) and the tools compute metrics per
field and per relationship. This is why the assets are reusable: the *method* is fixed, the
*field manifest and reference profile* change per dataset.

## Benefits

- **Ship evidence, not assertions** — each synthetic dataset ships with a machine-generated
  Evidence Report tying it to explicit pass/fail gates.
- **Stop re-inventing validation** — the metric suite, coverage spec, and thresholds are reused;
  new datasets inherit a proven Validation Suite.
- **Catch the two silent failures** — a dataset that looks statistically fine but is useless for
  the model (utility gap), or one that omits the rare cohort the model most needs (coverage gap).
- **Make trade-offs visible** — fidelity, utility, and privacy pull against each other; the
  reports surface all three so decisions are informed, not accidental.

## Limitations

- **Not a privacy/legal determination.** The library reports technical disclosure-risk signals
  (e.g. exact-match / nearest-neighbor indicators). **HIPAA/HITRUST de-identification
  determinations, IRB/privacy-office sign-off, and disclosure-risk acceptance are deferred to the
  organization's privacy, compliance, and legal functions.**
- **Only as good as the reference.** Fidelity is measured against the Reference Profile; if the
  reference statistics are unrepresentative, the metrics are too. The reference must be governed
  and agreed (global requirement §6).
- **No real PHI in a shared harness.** Reference access is read-only and minimized; the Reference
  Profile is aggregate-only. No real PHI is written to a shared harness, twin, or AI test
  environment.
- **Vendor-neutral at the pattern level.** Where a synthetic-data platform (e.g. Synthea, a
  commercial generator) or an AI/model framework is involved, it is referenced by capability;
  verify version-specific behavior against that vendor's documentation.

## Deployment model — Assess → Design → Generate/Build → Validate → Expand

Every Synthetic solution follows the same pilot-first model with explicit pass/fail gates and a
documented rollback:

1. **Assess** — confirm the AI use case, the target data model, the governed reference source,
   and the isolated environment. Decide which fidelity, utility, coverage, and privacy signals
   matter for *this* use case.
2. **Design** — author the **Reference Profile**, the **Fidelity Metric Suite** (with
   tolerances), and the **Coverage Specification** as the reusable assets. Define the pass/fail
   gates.
3. **Generate/Build** — obtain or generate the synthetic dataset under test (generation itself is
   handled by the org's synthetic-data tool; this library validates it).
4. **Validate** — run the **Validation Suite** on the pilot dataset; produce the **Evidence
   Report**; apply the pass/fail gates. Fail → rollback (do not release the dataset) and iterate.
5. **Expand** — once the pilot passes, promote the Validation Suite as a **reusable asset** and
   run it against subsequent datasets, growing the library.
