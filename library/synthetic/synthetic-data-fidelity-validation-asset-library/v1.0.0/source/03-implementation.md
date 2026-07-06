# Implementation Guide

Follow these ordered steps to stand up the fidelity & validation asset library on a **pilot** AI
use case, then promote the assets for reuse. The five Python tools referenced here are described
in `08-deliverables-summary.md`; run each with `--help` first. Every step that produces an
artifact **names** it with the `<Purpose> – <Scope> – <Stage>` convention and reuses that exact
name later.

> **Safety gates are load-bearing.** Do not release a synthetic dataset that fails the Validate
> gates. No real PHI is written to a shared harness/twin/AI test environment; reference access is
> read-only and minimized; the Reference Profile exported from the governed environment is
> **aggregate-only**.

---

## Stage 1 — Assess

1. **Confirm the six global requirements** (`global-requirements-synthetic.md`) and the six
   solution-specific requirements (`02-requirements.md`) are met for the pilot use case.
2. **Fix the pilot scope.** With the AI/QA owners, name the pilot: e.g.
   **Fidelity Pilot – Readmission Model – v1**. Record the AI use case, target data model
   (FHIR / OMOP / native), and the in-scope domains.
3. **Decide which signals matter** for this use case: which fields need statistical fidelity,
   which correlations must be preserved, whether utility (TSTR) is in scope, which cohorts drive
   coverage, and which privacy signals to report. Record these as the scope for the Validation
   Suite.

## Stage 2 — Design (author the reusable assets)

4. **Scaffold the config** with the config helper tool (`synfid_config.py`). Produce
   **Validation Suite – Readmission Model – v1** (a JSON config) that references the field
   manifest, reference profile, metric tolerances, coverage targets, and (if in scope) the utility
   task. Start from the template and edit values.
5. **Author the Field Manifest.** Populate **Field Manifest – Readmission Model – v1** — type and
   role for every in-scope field; flag identifiers/free-text out of statistical scope. The config
   helper can infer a first draft from the synthetic dataset's columns for you to correct.
6. **Build the Reference Profile (aggregate-only).** Inside the governed environment, run the
   reference-profile builder (`synfid_profile.py`) against the read-only, minimized reference to
   produce **Reference Profile – Readmission Model – v1** — per-field distributions, category
   frequencies, correlations, and missingness. **Export only this aggregate profile** from the
   governed environment; no rows leave.
7. **Author the Coverage Specification.** In the Validation Suite config, express the required
   cohorts, value ranges, and combinations as checkable rules with minimum representation, e.g.
   `age>=80 AND readmitted=1` must be present at ≥ target. Name it **Coverage Spec – Readmission
   Model – v1**.
8. **Set the pass/fail gates.** Record the agreed tolerances in the config: max distribution
   distance, min correlation-preservation, max utility gap, and coverage completeness. These are
   the objective gates the Validate stage enforces.

## Stage 3 — Generate/Build (obtain the dataset under test)

9. **Obtain the synthetic dataset** from the org's synthetic-data tool into the isolated
   environment and name it **Synthetic Dataset – Readmission Model – Pilot – v1**. (Generation is
   the org's tool; this library validates the output. Where a scenario/perturbation run is needed
   to exercise coverage, use the scenario/coverage runner — see step 12.)
10. **Sanity-check the dataset** loads and its columns map to **Field Manifest – Readmission
    Model – v1** (the config helper validates this mapping).

## Stage 4 — Validate (measure, gate, report)

11. **Measure statistical fidelity & utility.** Run the fidelity/utility metric suite
    (`synfid_fidelity.py`) with the Validation Suite config against **Synthetic Dataset –
    Readmission Model – Pilot – v1** and **Reference Profile – Readmission Model – v1**. It
    computes per-field distribution distances, correlation-preservation, category-frequency
    divergence, and (if in scope) the TSTR utility gap.
12. **Check coverage & edge cases.** Run the coverage/edge-case checker
    (`synfid_coverage.py`) against the dataset and **Coverage Spec – Readmission Model – v1**;
    it reports which required cohorts/ranges/combinations are present and at what representation.
13. **Run privacy/validation signals.** Run the privacy/validation check
    (`synfid_privacy.py`) to report technical disclosure-risk signals (exact-match /
    nearest-neighbor indicators) against the reference profile. **These are signals for the
    privacy office, not a determination.**
14. **Produce the Evidence Report.** Run the validation-suite runner (`synfid_validate.py`) — it
    orchestrates steps 11–13 under the Validation Suite config and emits **Evidence Report –
    Readmission Model – Pilot – v1** (machine-readable JSON + a human-readable summary) with an
    overall **PASS/FAIL** against every gate.
15. **Apply the gates (pass/fail).**
    - **PASS** (all gates met) → the dataset is cleared for the pilot AI use case; attach the
      Evidence Report to the dataset.
    - **FAIL** (any gate breached) → **rollback**: do **not** release the dataset. Record the
      failing gate(s), return to the org's generator to adjust generation (or to the coverage
      runner to add missing cohorts), and re-run Validate. Iterate until PASS.

## Stage 5 — Expand (grow the library)

16. **Promote the assets.** Commit **Field Manifest / Reference Profile / Validation Suite –
    Readmission Model – v1** to the version-controlled asset store as **reusable assets**.
17. **Reuse on the next dataset.** For a new synthetic dataset in the same domain, reuse the same
    Validation Suite (adjusting only what genuinely differs) and run steps 9–15 — new datasets now
    inherit a proven validation path and ship with their own Evidence Report.
18. **Track the library.** Maintain an index of assets and Evidence Reports so every shipped
    synthetic dataset is traceable to the gates it passed.
