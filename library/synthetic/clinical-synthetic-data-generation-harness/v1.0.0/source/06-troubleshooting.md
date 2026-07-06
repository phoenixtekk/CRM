# Troubleshooting

Common failure modes when building and running the harness, and how to resolve them. Artifact names
match the Implementation and Testing guides.

---

## The generator refuses my `--out-dir`

- **Symptom:** `generate_harness.py` exits with `REFUSED: out-dir ... matches PHI/production signal`.
- **Cause:** the path contains a signal like `prod`, `phi`, or `ehr-live` — the safe-by-default guard
  will not write synthetic data into anything that looks like a production/PHI location.
- **Resolution:** point `--out-dir` at the **isolated output directory** from Requirement R3. This
  guard is intentional; do not disable it. Re-run `scope_assessment.py` if unsure the path is safe.

## Generation writes nothing

- **Symptom:** the tool prints a plan and record counts, then "DRY-RUN: nothing written."
- **Cause:** dry-run is the default — writing is opt-in.
- **Resolution:** add `--apply`. Confirm the printed out-dir and record counts first (this is by
  design so you review before writing).

## Scope assessment reports BLOCK issues

- **Symptom:** `scope_assessment.py` exits non-zero with `[BLOCK]` lines.
- **Cause:** a domain has no reference coverage (R2), the target profile does not define a domain
  (R1), or the out-dir matches a PHI signal (R3).
- **Resolution:** resolve each BLOCK — extend the reference stats, complete the target profile, or fix
  the out-dir — before Stage 2 (Design). The **Synthetic EHR – Scope – Pilot** artifact must show 0
  blocking issues.

## `scenario_config.py validate` fails

- **Symptom:** `RESULT: FAIL` with problems listed.
- **Common causes & fixes:**
  - *"requires a condition but 'conditions' domain is not in scope"* — add `conditions` (or `labs`) to
    `--domains`, or remove the requirement from the scenario.
  - *"'patients' domain missing"* — patients are the root entity; add them.
  - *"scenario has non-positive size"* — set a positive `--size`.
  - *"duplicate scenario name"* — rename; scenario names must be unique.

## Plausibility gate FAILs on a distribution

- **Symptom:** `plausibility_report.py` shows `[FAIL]` for a domain (e.g. condition prevalence out of
  tolerance).
- **Cause:** the generation config or the reference distribution for that domain is off, or the pilot
  is too small for a stable estimate.
- **Resolution:** adjust the reference (R2) or the config for that domain and **regenerate** — never
  hand-edit the dataset. If the pilot is small, increase `--patients` so the estimate stabilizes.
  Widening `--tolerance` is a last resort and must be agreed with the consumer (R5).

## Plausibility gate FAILs on an impossible value

- **Symptom:** `[FAIL]` under impossible-value checks (e.g. `diastolic>=systolic`, negative age/lab).
- **Cause:** a clinical invariant was violated by the generator or a bad config edit.
- **Resolution:** these are always failures regardless of the reference. Fix the generator/config so
  the invariant holds and regenerate. The bundled generator enforces `systolic > diastolic` and
  non-negative ages/labs — investigate any custom change that broke it.

## Coverage gate FAILs — a required scenario is under threshold

- **Symptom:** `[FAIL] scenario:<name>: have N ... need M`.
- **Cause:** the scenario's required cohort is rarer than its size threshold at the current
  `--patients`, or the required condition/lab is not being generated.
- **Resolution:** raise `--patients`, increase the scenario weighting via `scenario_config.py`, or
  confirm the required condition code exists in the target profile (R1). Regenerate and re-check.

## Privacy gate FAILs — direct identifier detected

- **Symptom:** `schema_privacy_validator.py` reports identifier hits (SSN/email/phone/MRN pattern) or a
  non-synthetic patient id.
- **Cause:** a real value reached the harness — this should never happen; only aggregate stats belong
  in the reference (R2).
- **Resolution:** **treat as an incident.** Purge the dataset from the isolated out-dir, trace how the
  value entered (usually a real record wrongly placed in the reference file), correct the source, then
  regenerate. Never scrub the output and ship it.

## Privacy gate FAILs — exact reference-record match (leakage)

- **Symptom:** `leakage` hits — a synthetic record exactly matches a reference sample.
- **Cause:** the reference file contains real sample **records** (it should contain only aggregate
  statistics), or the harness over-fit and memorized a sample.
- **Resolution:** remove real records from the reference (keep only aggregates), reduce over-fitting,
  and regenerate. Treat any leakage as a privacy incident for the isolated environment.

## Reproducibility check fails — different manifest hash on re-run

- **Symptom:** re-running the same `--seed` and config yields a different `content_hash` (Testing T4).
- **Cause:** non-determinism — unseeded randomness, an unpinned config value, or environment-dependent
  ordering.
- **Resolution:** ensure every random draw goes through the seeded generator, pin all config values,
  and avoid iteration over unordered structures in generation. Same seed + same config must produce an
  identical dataset (R4). Discard the scratch copy used for the check.

## `pandas`/`numpy` not installed

- **Symptom:** a note on stdout that richer distribution comparisons are unavailable.
- **Cause:** the optional analytics libraries (R6) are absent.
- **Resolution:** `pip install pandas numpy` in the isolated environment. The tools still run without
  them at reduced precision — the note is informational, not a failure.

## FHIR/OMOP conformance disagreements

- **Symptom:** records the validator passes are rejected by your FHIR server or OMOP tooling.
- **Cause:** version-specific terminology bindings, value sets, or concept IDs differ from the profile
  you configured.
- **Resolution:** the harness treats terminology/vocabulary as configuration you **verify against your
  version** (see Overview). Reconcile the target profile (R1) with your FHIR version / OMOP vocabulary
  release and regenerate; consult the vendor's documentation for version-specific internals.
