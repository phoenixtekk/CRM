# Testing & Validation

These procedures verify that the library itself works and that a synthetic dataset meets its
gates. Each has an explicit **expected pass/fail** signal. Run them in the isolated environment;
no real PHI is written there — reference inputs are aggregate-only.

## Test 1 — Reference Profile is aggregate-only and complete

- **Procedure:** Build **Reference Profile – <Use Case> – v1** with `synfid_profile.py`, then
  inspect the output.
- **Expected PASS:** The profile contains per-field statistics (distributions, category
  frequencies, correlations, missingness) for every in-scope field and **no row-level real
  values**. File carries a manifest hash.
- **Expected FAIL:** Any in-scope field missing, or any row-level real data present → do not
  export; fix scope/config and rebuild.

## Test 2 — Field manifest maps cleanly to the dataset

- **Procedure:** Run the config helper's validation on **Field Manifest – <Use Case> – v1**
  against **Synthetic Dataset – <Use Case> – Pilot – v1**.
- **Expected PASS:** Every manifest field exists in the dataset with a compatible type;
  identifiers/free-text flagged out of statistical scope.
- **Expected FAIL:** Unmapped columns or type mismatches → correct the manifest before measuring.

## Test 3 — Statistical fidelity within tolerance

- **Procedure:** Run `synfid_fidelity.py` with the Validation Suite config.
- **Expected PASS:** Per-field distribution distances ≤ the configured max; category-frequency
  divergence ≤ max; correlation-preservation ≥ the configured min — for all gated fields/pairs.
- **Expected FAIL:** Any gated field/pair breaches its tolerance → the dataset fails the fidelity
  gate; return to generation.

## Test 4 — Utility (fit-for-use) within gap tolerance

- **Procedure:** Where utility is in scope, run the TSTR-style utility comparison via
  `synfid_fidelity.py` (or the runner) using **Utility Task – <Use Case> – v1**.
- **Expected PASS:** The utility gap (real-trained vs synthetic-trained performance on the same
  real test measure) ≤ the configured max gap.
- **Expected FAIL:** Utility gap exceeds tolerance even if statistical fidelity passed — a silent
  failure this test exists to catch; the dataset fails the utility gate.

## Test 5 — Coverage & edge cases met

- **Procedure:** Run `synfid_coverage.py` against **Coverage Spec – <Use Case> – v1**.
- **Expected PASS:** Every required cohort/range/combination is present at or above its minimum
  representation.
- **Expected FAIL:** Any required cohort missing or below minimum → coverage gate fails; add the
  missing cohorts (regenerate or run the scenario/coverage runner) and re-check.

## Test 6 — Privacy/disclosure signals reviewed

- **Procedure:** Run `synfid_privacy.py`; route the output to the privacy office.
- **Expected PASS (technical):** Exact-match and nearest-neighbor indicators are within the
  agreed technical threshold **and** the privacy office has reviewed the signals.
- **Expected FAIL:** Indicators exceed the agreed technical threshold → escalate; **the
  determination remains with privacy/compliance/legal**, not the tool.

## Test 7 — Evidence Report renders an objective overall verdict

- **Procedure:** Run `synfid_validate.py` to produce **Evidence Report – <Use Case> – Pilot – v1**.
- **Expected PASS:** The report aggregates Tests 3–6 into an overall **PASS** only when every gate
  passes, and is reproducible (same inputs → same verdict).
- **Expected FAIL:** Any gate FAIL yields overall **FAIL**; the report names the failing gate(s).

## Test 8 — Assets are reusable on a second dataset

- **Procedure:** Point the same Validation Suite at a second synthetic dataset in the same domain
  and run the runner without re-authoring the assets.
- **Expected PASS:** The suite runs end-to-end and emits a new Evidence Report using the reused
  assets.
- **Expected FAIL:** The suite requires re-authoring to run → the assets are not truly reusable;
  parameterize what changed (dataset path, dates) out of the fixed method.
