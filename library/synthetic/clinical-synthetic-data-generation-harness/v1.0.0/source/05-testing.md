# Testing & Validation

These procedures verify the harness produces **schema-valid, clinically plausible, reproducible,
privacy-conscious** data. Run them against **Synthetic EHR – Dataset – Pilot – v1** before any
expansion, and against every expanded dataset thereafter. Each test states its **expected pass/fail**.

The two validators — `plausibility_report.py` and `schema_privacy_validator.py` — implement the
Stage 4 gates. A dataset is releasable to an AI/QA consumer **only** when every test below passes
**and** the privacy/compliance function has recorded its sign-off (deferred determination, global §4).

---

## T1. Schema conformance (structural validity)

- **Procedure:** Run `schema_privacy_validator.py` against the dataset with the target profile (R1).
  Inspect the report's `schema` section.
- **Expected PASS:** **100%** of records conform to the target model — every required field present,
  correct type/cardinality, coded fields drawn from the bound value set/vocabulary.
- **Expected FAIL:** any non-conformant record. **Action:** fix the generator/config mapping for that
  domain and regenerate; do not hand-edit the dataset.

## T2. Clinical plausibility (fidelity vs. reference)

- **Procedure:** Run `plausibility_report.py` against the dataset and the reference stats (R2).
  Review each domain's distribution comparison.
- **Expected PASS:** every in-scope domain is within the agreed tolerance of the reference —
  age/sex mix, condition prevalence, medication-to-condition linkage, lab reference-range and
  out-of-range rates, vital-sign ranges. No impossible values (e.g. negative age, systolic below
  diastolic, a pediatric-only value in an adult cohort).
- **Expected FAIL:** any domain out of tolerance, or any impossible/implausible value. **Action:**
  adjust the reference distributions or generation config for that domain and regenerate.

## T3. Coverage (domains & scenarios the consumers need)

- **Procedure:** In the plausibility report, review the `coverage` section against consumer
  acceptance criteria (R5).
- **Expected PASS:** every consumer-required **domain** is present and every required **scenario**
  (e.g. `diabetes-panel`, `sepsis-pathway`) is represented at or above its minimum count/threshold.
- **Expected FAIL:** a required domain absent or a scenario under its threshold. **Action:** add or
  resize the scenario via `scenario_config.py` and regenerate.

## T4. Reproducibility (seed + config determinism)

- **Procedure:** Regenerate the dataset with the **same** `--seed` and the **same** config into a
  scratch location, then compare the two run manifests' content hashes (the manifest records seed,
  config hash, tool version, and per-domain record counts).
- **Expected PASS:** identical content hash — same seed + same config ⇒ identical dataset.
- **Expected FAIL:** differing hashes. **Action:** find the non-determinism (unseeded randomness, an
  unpinned config value, environment-dependent ordering) and fix it; reproducibility is a core
  promise (R4). Discard the scratch copy afterward.

## T5. Privacy — no direct identifiers

- **Procedure:** Review the `identifiers` section of the schema/privacy validator report.
- **Expected PASS:** **0** direct identifiers — no real names, SSNs, MRNs, addresses, or contact
  details; synthetic identifiers are clearly synthetic (e.g. prefixed, from a synthetic namespace).
- **Expected FAIL:** any field matching a direct-identifier or real-PHI pattern. **Action:** stop,
  investigate how it entered (a real value should never reach the harness), purge the dataset from the
  isolated out-dir, and correct the source before regenerating.

## T6. Privacy — no leakage of reference records

- **Procedure:** Review the `leakage` section. The validator checks that no synthetic record is an
  **exact match** to a reference record and that no memorized real value from a reference sample
  appears verbatim.
- **Expected PASS:** **0** exact matches to any reference record.
- **Expected FAIL:** one or more exact matches. **Action:** treat as a privacy incident for the
  isolated environment — purge the dataset, review how reference data was used (only aggregate stats
  should ever be in the reference file, R2), and regenerate.

## T7. Safe-by-default write behavior

- **Procedure:** Run `generate_harness.py` **without** `--apply` (dry-run), then run it with
  `--out-dir` pointed at a non-isolated or PHI-signal path.
- **Expected PASS:** dry-run writes **nothing** and prints the plan; a non-isolated/PHI-signal
  `--out-dir` is **refused** with a clear error before any write.
- **Expected FAIL:** any write during dry-run, or any write to a refused path. **Action:** stop using
  the build until the guard is restored — this guard is what keeps real PHI out of the shared harness.

---

## Release checklist (all must be true)

- [ ] T1 schema conformance = 100%
- [ ] T2 plausibility within tolerance for every domain
- [ ] T3 coverage meets every consumer's acceptance criteria
- [ ] T4 reproducible (identical manifest hash on re-run)
- [ ] T5 zero direct identifiers
- [ ] T6 zero exact reference-record matches
- [ ] T7 safe-by-default writes confirmed
- [ ] Privacy/compliance sign-off recorded (deferred determination — not this tool's call)
