# Implementation

Follow these ordered steps to stand up a privacy-conscious test environment on a **pilot** scope,
with explicit pass/fail gates and a documented rollback. The steps follow the house model **Assess →
Design → Generate/Build → Validate → Expand**. Every artifact is **named** with the convention
`<Purpose> – <Scope> – <Stage>`; reuse those exact names in testing, troubleshooting, and scripts.

> **Boundary reminder.** These steps produce **method and evidence**. The **determination** that the
> result is "de-identified" / the residual risk is acceptable belongs to privacy/compliance/legal.
> Do not release on a green metric alone — release on a green metric **plus** the recorded sign-off.

---

## Stage 0 — Preconditions

1. Confirm the six global requirements and the solution-specific prerequisites **S1–S5** in
   `02-requirements.md` are met. Do not start until **Risk Threshold – Pilot – v1** (S2) exists — the
   gate must be defined before you generate.
2. Confirm the **isolated non-production environment** is ready and is **not** connected to production
   PHI stores. This environment receives only synthetic or de-identified output — never the raw
   extract.
3. Confirm the Python environment is available (`python --version` ≥ 3.10). Install `pandas`/`numpy`
   if the scripts will use them (`pip install pandas numpy`).

## Stage 1 — Assess

4. Obtain the governed input: either the **minimized, read-only source extract** (S3, de-ID route,
   staged in the privacy-controlled zone) **or** confirm the **synthesis route** and its target model.
5. Produce a **draft classification**: run
   `python phi_field_scanner.py --input <extract.csv> --out field-classification-draft.json`.
   This *suggests* direct-identifier / quasi-identifier / sensitive / non-identifying per column.
6. Have the **privacy stakeholder review and correct** the draft, especially the quasi-identifier
   list. Save the reviewed result as the artifact **Field Classification – Pilot – v1**
   (`field-classification-pilot-v1.json`).
7. Confirm **Risk Threshold – Pilot – v1** (S2): the minimum **k**, minimum **l**, and/or maximum
   disclosure-risk the dataset must meet to be releasable.

   > **Gate A (scope gate):** every in-scope column is classified and reviewed, and the threshold is
   > recorded. If not, stop here.

## Stage 2 — Design

8. Build the pipeline configuration with the config helper:
   `python deid_config_helper.py --classification field-classification-pilot-v1.json --k 5 --l 2 --out deid-pipeline-pilot-v1.json`.
   This generates a starting **De-Identification Pipeline – Pilot – v1** config: per-field policy —
   **suppress** direct identifiers, **generalize** quasi-identifiers (age→age band, ZIP→3-digit,
   dates→shifted/coarsened), pass through non-identifying fields.
9. Apply the **S4 pseudonymization/key decision** into the config: default direct identifiers to
   `suppress`; only set `pseudonymize` where a governed re-linkage need is documented and the key is
   held outside the test environment.
10. Review the generalization policy for utility: confirm the AI/QA use cases can still be exercised
    after generalization (this is the fidelity-vs-privacy trade-off). Record the reviewed config.

   > **Gate B (design gate):** the pipeline config exists, the direct-identifier handling matches the
   > S4 decision, and no re-identification key is destined for the test environment.

## Stage 3 — Generate / Build

11. Produce the candidate dataset in the isolated environment:
    - **De-ID route:** `python deid_pipeline.py --input <extract.csv> --config deid-pipeline-pilot-v1.json --out deidentified-pilot-v1.csv` (writes only under `--apply`; dry-run by default).
    - **Synthesis route:** generate fully artificial records against the target model (via the
      selected synthesizer at the pattern level — see the vendor's documentation for platform
      specifics), landing `synthetic-pilot-v1.csv`.
12. Name the output **De-Identified Dataset – Pilot – v1** (or **Synthetic Dataset – Pilot – v1**).
    This candidate is **not yet releasable** — it must pass Stage 4 first.

## Stage 4 — Validate (the release gates)

13. Run the re-identification-risk assessment against the threshold:
    `python reid_risk_assessor.py --input deidentified-pilot-v1.csv --classification field-classification-pilot-v1.json --k 5 --l 2 --out reid-risk-pilot-v1.json`.
    It reports **k-anonymity** (smallest equivalence class), **l-diversity**, the **disclosure-risk**
    proportion (share of records in classes smaller than k), and simple **membership/attribute-
    inference** signals, each with a **PASS/FAIL** against **Risk Threshold – Pilot – v1**.
14. Run the fidelity/coverage check (utility must survive de-identification):
    `python fidelity_coverage_report.py --synthetic deidentified-pilot-v1.csv --reference <ref-stats.json> --out fidelity-pilot-v1.json`.
15. Assemble the **Privacy Evidence Record – Pilot – v1**:
    `python deid_config_helper.py --assemble-evidence --classification field-classification-pilot-v1.json --pipeline deid-pipeline-pilot-v1.json --risk reid-risk-pilot-v1.json --fidelity fidelity-pilot-v1.json --out privacy-evidence-pilot-v1.md`.
    Store it at the S5 evidence destination.

   > **Gate C (privacy release gate):** the re-ID assessment is **PASS** against every threshold and
   > the evidence record is captured. If any metric **FAILs**, **roll back** — do **not** release the
   > dataset. Return to Stage 2, tighten the generalization/suppression policy, and re-run Stages 3–4.

16. **Route the evidence to privacy/compliance/legal for the determination and sign-off.** Only after
    the recorded sign-off is the dataset releasable into the shared test environment. (Technical PASS
    ≠ regulatory determination.)

## Stage 5 — Expand

17. With the pilot passed and signed, widen scope one increment at a time (a further domain, service
    line, or larger cohort). For each increment, **re-run Stages 1–4** and capture a new evidence
    record — expansion never inherits the pilot's PASS.
18. Keep the pipeline config, thresholds, and evidence records under version control so every released
    test dataset is traceable to the classification, transformations, and metrics that justified it.

## Rollback

At any gate failure: **do not release** the candidate dataset; retain the failing evidence record
(it documents *why* it was held); tighten the pipeline policy and repeat. Because the isolated
environment only ever receives *released* datasets, a held candidate has zero exposure.
