# Testing & Validation

These validation procedures gate the release of a candidate dataset into the isolated test
environment. Each has an explicit **expected result** and a **PASS/FAIL** meaning. The candidate is
**not releasable** until the privacy gates pass **and** privacy/compliance/legal records a sign-off
(technical PASS ≠ regulatory determination).

Run these against the named artifacts from `03-implementation.md`: **De-Identified Dataset – Pilot –
v1** (or **Synthetic Dataset – Pilot – v1**), **Field Classification – Pilot – v1**, and **Risk
Threshold – Pilot – v1**.

---

## T1. Field classification completeness

- **Procedure:** Confirm every in-scope column in the candidate has exactly one classification in
  **Field Classification – Pilot – v1**, and that direct identifiers listed there are **absent or
  transformed** in the output.
- **Expected / PASS:** No unclassified columns; no direct-identifier column survives in identifiable
  form.
- **FAIL:** Any unclassified column, or any direct identifier present in cleartext — stop, fix the
  classification/pipeline, do not proceed.

## T2. Direct-identifier suppression check

- **Procedure:** Scan the candidate output with `phi_field_scanner.py` (`--mode audit`) to confirm no
  values matching direct-identifier patterns (SSN, MRN, email, phone) remain.
- **Expected / PASS:** Zero direct-identifier matches in the released columns.
- **FAIL:** Any match → a suppression rule was missed; roll back to Stage 2.

## T3. k-anonymity gate

- **Procedure:** `python reid_risk_assessor.py --input <candidate.csv> --classification field-classification-pilot-v1.json --k <threshold-k>`.
  It computes the smallest equivalence class over the quasi-identifiers.
- **Expected / PASS:** Smallest equivalence-class size **≥ k** from **Risk Threshold – Pilot – v1**
  (i.e. every record is indistinguishable from at least k−1 others on the quasi-identifiers).
- **FAIL:** Any class smaller than k → generalize/suppress further; do not release.

## T4. l-diversity gate (sensitive-attribute protection)

- **Procedure:** Same tool, `--l <threshold-l>`; checks each equivalence class contains at least **l**
  distinct sensitive-attribute values.
- **Expected / PASS:** Every class has **≥ l** distinct sensitive values (attribute disclosure is
  bounded).
- **FAIL:** Any class below l → the class leaks the sensitive attribute; tighten and re-run.

## T5. Disclosure-risk / inference gate

- **Procedure:** Same tool reports the **disclosure-risk proportion** (share of records in classes
  below k) and simple **membership/attribute-inference** signals (e.g. unique-record share, exact
  quasi-identifier matches to the reference).
- **Expected / PASS:** Disclosure-risk proportion **≤** the maximum in **Risk Threshold – Pilot – v1**;
  inference signals within tolerance.
- **FAIL:** Over threshold → roll back. (For the **synthesis route**, a high membership-inference
  signal indicates the synthesizer memorized real records — regenerate.)

## T6. Fidelity / coverage (utility survived de-identification)

- **Procedure:** `python fidelity_coverage_report.py --synthetic <candidate.csv> --reference <ref-stats.json>`.
  Compares marginal distributions and category coverage of the candidate to the agreed reference.
- **Expected / PASS:** Distributions and coverage within the documented fidelity tolerance — the AI/QA
  use cases can still be exercised.
- **FAIL:** Utility collapsed (over-generalized) → find a better point on the privacy/utility curve;
  this is a design decision, not necessarily a privacy failure.

## T7. Evidence-record completeness

- **Procedure:** Confirm `privacy_evidence_report.py` produced **Privacy Evidence Record – Pilot – v1**
  containing: the field classification, the transformations applied, the k/l/disclosure-risk metrics,
  the thresholds they were measured against, PASS/FAIL per gate, and the fidelity result.
- **Expected / PASS:** All sections present and stored at the S5 evidence destination.
- **FAIL:** Any missing section → regenerate; governance cannot review an incomplete record.

## T8. Release-decision gate (human)

- **Procedure:** Route the evidence record to privacy/compliance/legal; confirm a **recorded sign-off**
  exists before releasing to the shared environment.
- **Expected / PASS:** Signed determination on file → dataset may be released.
- **FAIL / absent:** No sign-off → **not releasable**, regardless of green metrics. The determination
  is theirs, not the pipeline's.
