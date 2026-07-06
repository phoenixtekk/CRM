# Troubleshooting

Common failure modes when standing up a privacy-conscious test environment, and how to resolve them.
Symptoms reference the named artifacts and tools from `03-implementation.md` and `05-testing.md`.

---

## The re-ID risk assessment FAILs on k-anonymity (smallest class < k)

- **Cause:** Quasi-identifiers are too granular — a rare combination (e.g. exact date + 5-digit ZIP +
  age) isolates individuals.
- **Resolve:** In **De-Identification Pipeline – Pilot – v1**, strengthen generalization on the
  offending quasi-identifiers (wider age bands, ZIP truncation to 3 digits, coarser dates), re-run
  `deid_pipeline.py`, then `reid_risk_assessor.py`. Do **not** release until k ≥ threshold.

## l-diversity FAILs even though k passes

- **Cause:** An equivalence class is large enough (k) but everyone in it shares the same sensitive
  value — the attribute leaks despite anonymity.
- **Resolve:** Coarsen the quasi-identifiers so classes merge and gain sensitive-value diversity, or
  reconsider whether that attribute should be released at this granularity. Re-run the assessor.

## Disclosure-risk proportion is over threshold but k looks fine

- **Cause:** Many *small* classes just above the FAIL line still push the share of at-risk records
  over `max_disclosure_risk`. k is the minimum; disclosure-risk is a distribution.
- **Resolve:** Generalize the long tail of small classes; re-check both `k_anonymity` and
  `disclosure_risk` in the report.

## High `unique_record_share` on the synthesis route

- **Cause:** The synthesizer memorized real records — a membership-inference signal, not just low
  utility.
- **Resolve:** Regenerate with the synthesizer's privacy/regularization controls (see the vendor's
  documentation for version-specific options). Treat this as a **privacy** failure, not a fidelity
  one.

## `phi_field_scanner.py` audit finds residual SSN/email/phone in the output

- **Cause:** A direct-identifier column was misclassified as non-identifying, so the pipeline kept it.
- **Resolve:** Correct **Field Classification – Pilot – v1**, regenerate the pipeline config with
  `deid_config_helper.py`, re-run `deid_pipeline.py`, and re-audit. This is a **Gate A** classification
  miss — fix upstream, not by patching the output.

## `deid_pipeline.py` refuses to run ("key inside the test environment")

- **Cause:** The config sets a field to `pseudonymize` with `key_location` inside the test environment
  — an S4 violation the pipeline blocks by design.
- **Resolve:** Move the re-identification key to the privacy-controlled zone (outside the test
  environment) and record its custody, or change the field to `suppress`. Then re-run.

## Fidelity/coverage FAILs — distributions collapsed

- **Cause:** Over-generalization to pass the privacy gate destroyed analytic utility (the AI/QA use
  cases can no longer be exercised).
- **Resolve:** This is a **trade-off decision**, not automatically a privacy failure. Find a milder
  generalization that still passes `reid_risk_assessor.py`, or revise the reference tolerance with the
  stakeholders. Record the chosen point on the privacy/utility curve.

## `reid_risk_assessor.py` errors: "classification lists no quasi-identifiers"

- **Cause:** The classification has no fields marked `quasi_identifier`, so k-anonymity is undefined.
- **Resolve:** Re-check **Field Classification – Pilot – v1** — dates, geography, and demographics are
  almost always quasi-identifiers. Have the privacy stakeholder confirm the list.

## The metrics all PASS — is the data releasable?

- **Cause:** A green report is a **technical** signal only.
- **Resolve:** Route the **Privacy Evidence Record** to privacy/compliance/legal and obtain the
  recorded determination/sign-off (Testing **T8**). Release only after that. A technical PASS is never
  the regulatory determination.

## Expansion dataset behaves differently from the pilot

- **Cause:** New scope has different cardinality/rarity, so the pilot's PASS does not carry over.
- **Resolve:** Re-run Stages 1–4 for the new increment and capture a fresh evidence record — expansion
  never inherits the pilot's result.
