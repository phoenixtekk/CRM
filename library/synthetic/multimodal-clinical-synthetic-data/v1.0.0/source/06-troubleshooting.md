# Troubleshooting

Common failure modes when extending synthetic generation to multi-modal clinical data, and how to
resolve them. All fixes stay inside the isolated non-production environment on synthetic data; rollback
is always "discard the synthetic set and regenerate" because nothing production or real-PHI is touched.

---

## The note and the vitals contradict each other (T4 consistency FAIL)

- **Symptom:** `crossmodal_consistency_check.py` reports defects such as a note stating "afebrile" while
  the temperature channel shows a fever, or an asserted vitals event with no matching signal.
- **Cause:** The note and the vitals were **not** rendered from the same clinical state — the shared-state
  contract (R2) is incomplete, or a template/vitals rule reads a different fact than the one generated.
- **Resolution:** Confirm both the note synthesizer and the vitals generator read the **same**
  `clinical_state_facts`. Fix the template slot or the `channel_target` mapping so both key off the same
  fact, then regenerate. Never edit one modality's output by hand — always regenerate from state.

## A note states a diagnosis that isn't in the structured problem list (T4 consistency FAIL)

- **Symptom:** Defect `note_diagnoses_in_structured_problem_list`.
- **Cause:** The note template injected a diagnosis code not present in `structured.problem_list`, or the
  structured record was generated separately from the note.
- **Resolution:** Ensure the note's `stated_diagnoses` are derived from the structured record's problem
  list (single source of truth), then regenerate. Add the diagnosis to the structured record *or* remove
  it from the note — do not leave them disagreeing.

## Vitals out of physiologic range (T3 plausibility FAIL)

- **Symptom:** `plausibility.violations` lists values outside a channel's `plausible` band.
- **Cause:** A channel's target range (baseline or event) exceeds the configured plausible band, or the
  config's `normal`/`plausible` ranges are inconsistent (`normal` not inside `plausible`).
- **Resolution:** Run `scope_config_helper.py validate` — it flags ranges where `normal` isn't inside
  `plausible`. Correct the ranges/event targets in the config, then regenerate.

## `scope_config_helper.py validate` reports FAIL

- **Symptom:** Missing sections, empty `note_types`/`consistency_rules`, or bad ranges.
- **Cause:** Config was hand-edited into an invalid state, or a required gate threshold was removed.
- **Resolution:** Re-run `init` to get a known-good skeleton, port your tuned values in, and re-validate.
  Keep the config in version control so you can diff against the last valid one.

## A modality is missing for some patients (T1 coverage FAIL)

- **Symptom:** `fidelity_coverage_report.py` coverage < 100%; `missing` lists patients/modalities.
- **Cause:** The modality isn't in the config's `modalities`, or generation skipped it (e.g. no
  `note_types` defined but `notes` in scope).
- **Resolution:** Ensure every in-scope modality has its inputs (note types for notes, channels for
  vitals) and is listed in `modalities`, then regenerate the full cohort.

## Fidelity shows "NOT-SCORED"

- **Symptom:** `fidelity_coverage_report.py` prints `fidelity=NOT-SCORED`.
- **Cause:** No `--reference` was supplied, so there is nothing to measure realism against (global
  requirement #6). This is **not** a pass — it means fidelity is unproven.
- **Resolution:** Provide read-only, minimized reference statistics (or agreed published reference
  distributions) via `--reference` and re-run. Realism claims are only valid against a stated reference.

## Fidelity FAIL (distance over threshold)

- **Symptom:** A channel's normalized distance exceeds `fidelity_max_distance`.
- **Cause:** Generation parameters/ranges don't match the reference distribution, or the scenario mix
  skews a channel's mean.
- **Resolution:** Tune the channel's baseline/event ranges (or scenario weights) toward the reference,
  or, if the threshold is unrealistic for a synthetic pilot, agree a defensible threshold with the AI/QA
  and privacy stakeholders and record it. Re-validate.

## Synthetic-safety scan hit — a real-PHI pattern (T6 FAIL — hard block)

- **Symptom:** `safety.hits` is non-empty (e.g. an SSN/MRN/date/email pattern, or a
  non-allow-listed identifier).
- **Cause:** A template or phrase bank contained real patient text, real data leaked into a slot value,
  or a patient used a non-synthetic identifier.
- **Resolution:** **Do not release.** Purge the offending set, trace the source (template, phrase bank,
  or state field) and remove the real content, then regenerate and re-scan until clean. Keep the
  synthetic-identifier allow-list (`SYN-#####`) current. This is a **technical guardrail** — the
  de-identification/disclosure-risk *determination* remains with privacy/compliance/legal.

## Notes are empty or malformed (T5 NLP-readiness FAIL)

- **Symptom:** `notes.issues` lists empty required sections.
- **Cause:** A template slot mapped to a fact the state didn't set, so the section rendered blank.
- **Resolution:** Ensure every note-type section has a template phrase and a state fact to fill it;
  regenerate. Empty notes are unusable for NLP testing and must be fixed before release.

## Vendor synthetic-data / AI framework behaves differently than documented here

- **Symptom:** A Synthea-style generator or commercial platform produces output that doesn't match the
  structure these tools expect.
- **Cause:** Vendor console internals and versions vary; this solution integrates at the pattern level.
- **Resolution:** **Verify version-specific behavior against the vendor's documentation** and adapt the
  mapping into the shared clinical state. Do not assume vendor internals — the shared-state contract is
  the integration boundary.
