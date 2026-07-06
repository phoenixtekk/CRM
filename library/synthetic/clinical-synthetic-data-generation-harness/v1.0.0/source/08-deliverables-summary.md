# Deliverables Summary

Everything the buyer receives with the **Clinical Synthetic Data Generation Harness** — one page.

## Documentation

- **Solution Overview** — what the harness is, how it works, the target-model options
  (FHIR / OMOP / native), benefits, limitations, and the Assess → Design → Generate → Validate →
  Expand model.
- **Requirements Guide** — the six category-wide requirements plus six solution-specific prerequisites
  (target profile, reference distributions, isolated output directory, reproducibility policy, named
  consumers, optional analytics libraries), each with how to verify and how to implement.
- **Implementation Guide** — exact, ordered, pilot-first steps through all five stages, every artifact
  named, with the explicit pass/fail gates and rollback.
- **Testing & Validation** — seven procedures (schema, plausibility, coverage, reproducibility, two
  privacy checks, safe-write behavior) each with expected pass/fail, plus a release checklist.
- **Troubleshooting** — common failure modes and resolutions.
- **Best Practices** — durable practices for privacy, reproducibility, fidelity, maintainability, and
  governance.
- **Executive Summary** — the outcome, approach, and why it is safe, for decision-makers.

## The 5 Python tools (`scripts/`)

All are Python 3.10+, standard-library-first, run with `--help`, and are **safe by default**
(dry-run / opt-in for anything that writes; generation writes only to the isolated output directory;
no real PHI).

1. **`scope_assessment.py`** — *Assessment / profiling.* Profiles the target model, in-scope domains,
   reference coverage, and the isolated out-dir; reports blocking issues before generation. Produces
   **Synthetic EHR – Scope – Pilot**.
2. **`generate_harness.py`** — *Generation harness.* The seeded, reproducible generator that emits
   synthetic patients, encounters, conditions, medications, labs, and vitals in the target model's
   shape — dry-run by default, `--apply` to write, only ever under `--out-dir`. Emits a run manifest.
   Produces **Synthetic EHR – Dataset – Pilot – v1**.
3. **`plausibility_report.py`** — *Fidelity & coverage report.* Grades the generated dataset against
   the agreed reference distributions and consumer coverage criteria; implements the plausibility
   gate. Produces **Synthetic EHR – Plausibility Report – Pilot**.
4. **`schema_privacy_validator.py`** — *Schema & privacy validator.* Confirms 100% schema conformance
   and checks for direct identifiers, real-PHI patterns, and exact reference-record leakage; implements
   the privacy/schema gate (evidence only — determination deferred). Produces
   **Synthetic EHR – Privacy Validation – Pilot**.
5. **`scenario_config.py`** — *Scope / config helper.* Scaffolds, edits, and validates the harness
   configuration and scenario suite that drive reproducible runs. Produces the config inside
   **Synthetic EHR – Harness Design – Pilot**.
