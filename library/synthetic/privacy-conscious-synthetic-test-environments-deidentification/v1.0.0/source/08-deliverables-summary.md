# Deliverables Summary

What the buyer receives — a complete, self-guided kit to establish a **privacy-conscious test
environment**: de-identification/synthesis pipeline, re-identification-risk assessment against a
threshold, and the privacy evidence governance needs to review and approve.

## Documentation

- **Solution Overview** — the privacy model for test data (synthetic vs. de-identified), disclosure-
  risk concepts (k-anonymity, l-diversity, membership/attribute inference), the safe-by-design
  posture, and the Assess→Design→Generate/Build→Validate→Expand model.
- **Requirements Guide** — the six category-wide prerequisites plus five solution-specific ones (field
  classification, disclosure-risk threshold, governed source extract, pseudonymization/key decision,
  evidence destination), each with how to verify and how to implement.
- **Implementation Guide** — exact ordered steps, pilot-first, with named artifacts and the three
  pass/fail gates (scope, design, privacy release) plus rollback.
- **Testing & Validation** — eight validation procedures (classification, suppression, k-anonymity,
  l-diversity, disclosure-risk/inference, fidelity, evidence completeness, human release decision),
  each with expected PASS/FAIL.
- **Troubleshooting** — common failure modes and resolutions.
- **Best Practices** — durable practices for keeping test data safe and defensible as scope grows.

## The 5 Python tools

1. **`phi_field_scanner.py`** — *Assessment / profiling.* Profiles a tabular extract and **suggests** a
   per-field classification (direct identifier / quasi-identifier / sensitive / non-identifying) using
   name and value-pattern heuristics; also runs an **audit** mode to detect residual direct-identifier
   values in an output. Produces the draft for **Field Classification – Pilot – v1**. Read-only; writes
   only a classification JSON.

2. **`deid_pipeline.py`** — *Transformation / generation.* Applies the de-identification pipeline —
   suppress direct identifiers, generalize quasi-identifiers (age bands, ZIP truncation, date
   shifting/coarsening), pass through non-identifying fields — per the pipeline config. **Dry-run by
   default**; writes the de-identified dataset only with `--apply`.

3. **`fidelity_coverage_report.py`** — *Fidelity / coverage report.* Compares the candidate dataset's
   marginal distributions and category coverage to an agreed reference-statistics file and reports
   whether utility survived de-identification, within a documented tolerance.

4. **`reid_risk_assessor.py`** — *Privacy / validation check.* Computes **k-anonymity**,
   **l-diversity**, the **disclosure-risk proportion**, and simple **membership/attribute-inference**
   signals over the quasi-identifiers/sensitive attributes, and reports **PASS/FAIL** against the
   agreed threshold. The core release-gate tool.

5. **`deid_config_helper.py`** — *Scope / config helper.* Generates and validates a starting
   **De-Identification Pipeline – Pilot – v1** config from a field classification and target k/l, and
   (with `--assemble-evidence`) composes the **Privacy Evidence Record** from the classification,
   pipeline, risk, and fidelity outputs — so the pipeline, assessor, and evidence all read a
   consistent, versioned configuration.

## What it adds up to

Test data that is **safe by design and defensible on review** — de-identified or synthetic, re-ID
risk assessed under an agreed threshold, evidence captured — with the **regulatory determination
cleanly deferred** to the organization's privacy, compliance, and legal functions.
