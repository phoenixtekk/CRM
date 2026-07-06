# Requirements

These are the **solution-specific** prerequisites for extending synthetic generation to multi-modal
clinical data (structured + notes + vitals/time-series). They build **on top of** the six category-wide
requirements in `global-requirements-synthetic.md` — a Python data environment (§1), a target clinical
data model/standard (§2), an isolated non-production test environment (§3), privacy/governance
stakeholders and policy (§4), AI/QA use cases and a pilot scope (§5), and read-only/minimized reference
access for fidelity (§6). **Verify the global six first**; do not duplicate them. The items below are
the additional prerequisites this multi-modal solution needs, each with how to *verify* it and how to
*implement* it if missing.

> **Boundary reminder.** Everything below operates on **synthetic** data in the **isolated
> non-production** environment. Never place real PHI into the shared harness. Regulatory/legal
> determinations are deferred to privacy/compliance/legal.

## R1. A working structured (tabular) synthetic backbone

- **Description:** An existing, validated **structured** synthetic generator/harness producing patients,
  encounters, conditions, medications and labs in the target model — the tabular layer this solution
  extends. (If you do not yet have one, that is a separate structured-generation effort; this solution
  assumes the tabular backbone exists or is stood up first.)
- **Why required:** Notes and vitals are **derived from** the structured record's per-patient clinical
  state. Without a trustworthy structured backbone there is nothing consistent to narrate or to signal.
- **How to verify:** Confirm you can generate a small structured cohort in the target model and that it
  passes its own basic validation (schema-valid, plausible field values).
- **How to implement if missing:** Stand up the structured backbone (in-house generator or a
  Synthea-style/commercial platform integrated at the pattern level — verify version specifics against
  the vendor's documentation) and validate it before adding modalities.

## R2. A per-patient clinical state contract (the shared source of truth)

- **Description:** An agreed, documented **clinical state** object per synthetic patient — the structured
  record plus a small set of derived clinical facts (e.g. `febrile`, `hypotensive_episode`,
  `on_vasopressors`, primary/secondary diagnoses, admission→discharge trajectory) that **both** the note
  synthesizer and the vitals generator read.
- **Why required:** Cross-modal consistency is only achievable if all modalities render from **one**
  shared state. Independently authored notes and vitals will drift and contradict each other.
- **How to verify:** Confirm a written schema for the clinical state and that a sample structured record
  can be mapped to it (each downstream fact has a defined source field/rule).
- **How to implement if missing:** Define the clinical-state schema (with the AI/QA and clinical SMEs)
  and a deterministic mapping from the structured record to the derived facts before generating notes or
  vitals.

## R3. Note types, clinical template/phrase references (NLP-ready, no real PHI)

- **Description:** The **note types** in scope (e.g. admission note, progress note, discharge summary)
  and the **templates / controlled vocabularies / phrase banks** used to synthesize them — authored or
  curated in-house, or drawn from **published, non-PHI** clinical templating references. Templates are
  slot-filling patterns, **not** copies of real patient notes.
- **Why required:** Notes must be realistic and labelable for NLP testing while remaining **synthetic**.
  Copying real notes would reintroduce PHI and defeat the purpose.
- **How to verify:** Confirm the note-type list, that each has a template family with slots keyed to
  clinical-state facts, and that no template contains real patient text.
- **How to implement if missing:** Author the templates and phrase banks (clinical SME review
  recommended) with slots mapped to R2's clinical state; keep them under version control.

## R4. Vitals/time-series channels, sampling and physiologic ranges

- **Description:** The **vitals channels** in scope (e.g. HR, systolic/diastolic BP, respiratory rate,
  temperature, SpO₂), their **sampling cadence** (e.g. hourly), duration (encounter length), and
  **physiologically plausible ranges/trends** per clinical state (baseline, expected events).
- **Why required:** The signal generator needs defined channels, cadence, and plausible ranges to
  produce time-series that (a) are realistic and (b) match the same patient's notes and structured record.
- **How to verify:** Confirm the channel list, cadence, and agreed normal/abnormal ranges (from the
  reference in global §6 or published reference ranges), and that abnormal events map to R2 facts.
- **How to implement if missing:** Define the channels, cadence, and range/trend rules per clinical
  state; document the reference for the ranges before generating.

## R5. Cross-modal consistency rules and pass/fail gates

- **Description:** The explicit **consistency rules** that bind the modalities (e.g. diagnoses stated in
  a note must appear in the structured problem list; a note asserting a vitals event must have a matching
  signal event; units and ranges must be physiologically valid) and the **pass/fail gates** for release
  (modalities present, cross-modally consistent, physiologically plausible, privacy checks clean).
- **Why required:** "Consistent" must be *measurable* to gate a release. Without codified rules the
  validator cannot pass or fail a dataset objectively.
- **How to verify:** Confirm a written rule set and the numeric/boolean thresholds each gate requires.
- **How to implement if missing:** Author the consistency rules and gate thresholds with the AI/QA and
  privacy stakeholders before the Validate stage.

## R6. A synthetic-safety / no-real-PHI control for the multi-modal set

- **Description:** A control ensuring the notes and vitals contain **no real PHI** and that nothing real
  is written to the shared harness — e.g. an allow-list of synthetic identifiers, a scan for real-name /
  MRN / date patterns, and confirmation that any real reference data used for ranges stayed read-only and
  minimized (global §6).
- **Why required:** Notes and free-text especially are a re-identification risk surface; this is the
  operational guardrail that keeps the multi-modal set safe to share in the harness.
- **How to verify:** Confirm the scan/allow-list exists and runs as part of validation, and that
  reference-data handling is documented as read-only/minimized.
- **How to implement if missing:** Implement the synthetic-safety scan and reference-handling record
  before releasing any multi-modal set to AI/QA teams. (Note: this is a **technical guardrail**, not a
  de-identification determination — that remains with privacy/compliance/legal.)
