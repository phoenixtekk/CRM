# Solution Overview

## What this is

Most synthetic clinical data stops at **tables** — patients, encounters, conditions, medications,
labs. But real clinical AI runs on more than tables. Document models read **clinical notes**, signal
and sequence models read **vitals and time-series**, and the interesting failure modes live in how
those modalities *relate* to one another. A discharge summary that says "afebrile, hemodynamically
stable" is wrong if the paired vitals stream shows a fever spike and a crashing blood pressure. A
tabular record that codes sepsis but a note that never mentions it teaches an NLP model the wrong
thing.

This solution extends synthetic generation **beyond structured tables to multi-modal clinical data**:

- **Structured records** — the tabular backbone (demographics, encounters, conditions, medications,
  labs) generated against a target model.
- **Clinical notes** — realistic, NLP-ready free-text (admission notes, progress notes, discharge
  summaries) produced **template- and pattern-driven** from the structured record, so the narrative
  is *derived from* the same synthetic patient, not written independently.
- **Vitals / time-series** — heart rate, blood pressure, respiratory rate, temperature, SpO₂ and
  similar signals as time-ordered series whose shape reflects the patient's synthetic condition and
  trajectory.

The defining property is **cross-modal consistency**: for a single synthetic patient, the structured
record, the notes, and the vitals **tell the same clinical story**. Every artifact is **synthetic** —
no real Protected Health Information (PHI) is used to author the notes or signals, and nothing real is
written into the shared harness.

## How it works

The generator is driven by a **per-patient clinical state** (the target model record plus a small set
of derived clinical facts — e.g. "febrile", "hypotensive episode at hour 14", "on vasopressors").
That single state is the shared source of truth that all three modalities render from:

1. **Structured** — the tabular record in the target model (see below).
2. **Notes** — a template/pattern note synthesizer fills clinically-worded templates from the state's
   facts. Templates are pattern-based (slot-filling with controlled vocabularies and phrase banks),
   **not** copied from real notes and **not** free-form generation of unverifiable text.
3. **Vitals** — a signal generator produces time-series whose baselines, trends, and events are keyed
   to the same facts (a documented fever produces a matching temperature curve).

Because all three read the **same** state, a **cross-modal consistency validator** can then check that
they agree (the note's stated diagnoses appear in the structured problem list; a note that asserts a
vitals event has a matching signal; units and ranges are physiologically plausible). Disagreements are
reported as consistency defects to fix before the dataset is released to AI/QA teams.

### Target model (structured backbone)

Generate the structured layer against a defined **clinical data model / interoperability standard** —
typically **FHIR** (resources: `Patient`, `Encounter`, `Condition`, `MedicationRequest`,
`Observation`) or **OMOP CDM** (person, visit_occurrence, condition_occurrence, drug_exposure,
measurement) — or the source system's own schema. **Notes** attach as document/`DocumentReference`-style
records and **vitals** as time-stamped `Observation`/measurement rows, so the multi-modal output stays
inside the same target model rather than becoming three disconnected exports. Confirm the exact target
model and in-scope domains with the AI/QA teams before generating (see `02-requirements.md`).

## The deployment model — Assess → Design → Generate/Build → Validate → Expand

Every solution in this category follows the same **pilot-first** model with explicit pass/fail gates
and a documented rollback:

- **Assess** — profile which modalities the AI/QA use cases actually need (notes? vitals? both?),
  confirm the target model, the isolated environment, and the governing privacy policy. Produce the
  **Modality Scope – Pilot – v1** record.
- **Design** — decide the per-patient clinical state model, the note types and template families, the
  vitals channels and sampling, and the consistency rules. Produce the **Multi-Modal Design – Pilot – v1**.
- **Generate/Build** — generate the structured record, synthesize notes, generate vitals for a **pilot
  cohort**, all from the shared state. Produce the **Multi-Modal Synthetic Set – Pilot – v1**.
- **Validate** — run the fidelity/coverage report and the cross-modal consistency validator against
  pass/fail **gates** (modalities present, cross-modally consistent, physiologically plausible,
  privacy checks clean). Produce the **Multi-Modal Validation Report – Pilot – v1**.
- **Expand** — only after the pilot passes, widen the cohort, add note types / vitals channels, and
  scale — re-validating at each step. Rollback = discard the failing synthetic set (it is synthetic and
  isolated) and regenerate; nothing production or real-PHI is touched.

## Benefits

- **Test the models real care uses** — document, signal, and sequence models, not just tabular ones.
- **Cross-modally consistent** — a single synthetic patient's records, notes, and vitals agree, so
  multi-modal pipelines (e.g. note + vitals fusion) can be exercised end to end.
- **NLP-ready notes without real PHI** — template/pattern-driven text that is labelable and safe to
  share in the harness.
- **Safe by construction** — synthetic-only, isolated non-production, safe-by-default tooling.

## Limitations (read these)

- **Synthetic, not real.** Template/pattern notes and modeled vitals approximate clinical language and
  physiology; they are for **testing and development**, not clinical inference or evidence.
- **Fidelity is bounded by the reference.** Realism claims hold only against the reference statistics
  or distributions you validate against (global requirement §6).
- **Not a de-identification method.** This generates synthetic data; it does **not** de-identify real
  data, and it makes **no** HIPAA/HITRUST determination. Those determinations, IRB/privacy sign-off,
  and disclosure-risk acceptance are **deferred to the organization's privacy, compliance, and legal
  functions**.
- **Vendor tools at the pattern level.** Where a synthetic-data platform or AI framework is used
  (e.g. Synthea-style generators, commercial platforms), integrate at the capability/pattern level and
  **verify version-specific behavior against the vendor's documentation** — this solution does not
  reproduce vendor console internals.
