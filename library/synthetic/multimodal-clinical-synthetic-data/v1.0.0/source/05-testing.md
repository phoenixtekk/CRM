# Testing & Validation

These procedures validate a **Multi-Modal Synthetic Set – Pilot – v1** before it is released to AI/QA
teams. Each test states its purpose, how to run it, and the **expected pass/fail**. Together they
implement **Gate D** from `03-implementation.md` (the release gate). All tests run in the isolated
non-production environment on synthetic data.

Run the fidelity/coverage report and the consistency/safety check on every set; do not release a set
that fails any gate.

---

## T1 — Modality coverage (every modality present per patient)

- **Purpose:** Confirm each in-scope modality (structured, notes, vitals) exists for **every** synthetic
  patient — no patient missing a note or a vitals stream.
- **How to run:**
  ```
  python fidelity_coverage_report.py --set ./harness/pilot --config multimodal-config.json \
      --reference reference-stats.json --report fidelity-coverage.json
  ```
  Inspect the `coverage` section.
- **Expected — PASS:** coverage = 100% for every in-scope modality across the cohort.
- **FAIL:** any patient missing an in-scope modality → regenerate (Stage 3) after fixing the config/state
  mapping.

## T2 — Fidelity vs. reference

- **Purpose:** Confirm structured fields and vitals distributions are realistic **against the reference**
  (global §6) within configured thresholds.
- **How to run:** same command as T1; inspect the `fidelity` section (per-field/channel distances vs.
  thresholds).
- **Expected — PASS:** all fidelity metrics within their configured thresholds.
- **FAIL:** metrics out of threshold → adjust generation parameters/ranges and regenerate. (Fidelity
  claims hold only against the validated reference.)

## T3 — Physiologic plausibility of vitals

- **Purpose:** Confirm vitals time-series stay within physiologically plausible ranges and follow the
  expected trend/events for each patient's clinical state (R4).
- **How to run:**
  ```
  python crossmodal_consistency_check.py --set ./harness/pilot --config multimodal-config.json \
      --report consistency.json
  ```
  Inspect the `plausibility` section.
- **Expected — PASS:** no out-of-range or physiologically implausible values; documented events (e.g. a
  fever) appear in the matching channel.
- **FAIL:** out-of-range values or missing/contradictory events → fix vitals rules and regenerate.

## T4 — Cross-modal consistency (the modalities tell the same story)

- **Purpose:** Confirm the structured record, notes, and vitals **agree** for each patient (R5): note
  diagnoses appear in the structured problem list; a note asserting a vitals event has a matching signal
  event; units and codes align.
- **How to run:** same command as T3; inspect the `consistency` section (defect list per patient).
- **Expected — PASS:** zero unresolved consistency defects across the cohort.
- **FAIL:** any consistency defect (e.g. note says "afebrile" but temperature curve shows a fever) →
  fix the shared-state mapping/templates and regenerate. This is the core multi-modal guarantee.

## T5 — NLP-readiness of notes

- **Purpose:** Confirm synthesized notes are structurally usable for NLP testing — expected sections per
  note type, non-empty required slots, parseable text, and (where configured) that clinical
  entities/labels referenced by the state are actually present in the text.
- **How to run:** inspect the `notes` section of the consistency report (per-note-type structure and
  slot-fill checks).
- **Expected — PASS:** each note has its expected sections/slots filled and the state's key entities are
  findable in text.
- **FAIL:** empty/malformed notes or missing entities → fix templates/phrase banks and regenerate.

## T6 — Synthetic-safety / no-real-PHI scan (release blocker)

- **Purpose:** Confirm the multi-modal set contains **no real PHI** — especially in free-text notes — and
  that any real reference data used stayed read-only/minimized (R6).
- **How to run:** same command as T4; inspect the `safety` section (synthetic-identifier allow-list check
  and real-name/MRN/date pattern scan).
- **Expected — PASS:** zero real-PHI pattern hits; all identifiers on the synthetic allow-list; reference
  handling documented read-only/minimized.
- **FAIL:** **any** hit is a hard block — do **not** release; investigate the template/state source, purge
  the offending set, and regenerate. (This is a technical guardrail; the privacy/de-identification
  *determination* remains with privacy/compliance/legal.)

---

## Release decision

Record the outcomes as **Multi-Modal Validation Report – Pilot – v1**. Release the set to AI/QA only when
**T1–T6 all PASS** (Gate D). Any failure → rollback (discard the synthetic set) and regenerate. Attach
the reports as evidence so every released set is reproducible and auditable.
