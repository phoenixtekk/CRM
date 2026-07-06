# Best Practices

Durable practices for producing and maintaining multi-modal clinical synthetic data (structured + notes
+ vitals/time-series) that stays consistent, realistic, and safe.

## Generate from one shared state — never author modalities independently
Cross-modal consistency is only achievable when the structured record, notes, and vitals all render from
a **single per-patient clinical state** (the **Clinical State Contract – Pilot – v1**). The moment a note
is written independently of the vitals, they drift and contradict. Treat the clinical state as the sole
source of truth and derive every modality from it deterministically.

## Make "consistent" measurable, and gate on it
Codify the consistency rules (note diagnoses ↔ structured problem list; asserted vitals events ↔ signal
events; valid units/ranges) and the pass/fail thresholds **before** generating, and enforce them as a
release gate (Gate D). A dataset that isn't gated on consistency will quietly teach multi-modal models
the wrong correlations.

## Keep templates synthetic and version-controlled
Note templates are **slot-filling patterns with phrase banks**, never copies of real notes. Keep them in
version control, review them with a clinical SME for plausibility, and label each slot with the clinical
fact it renders. This keeps notes NLP-ready *and* free of real PHI.

## Anchor vitals to physiology and to the note narrative
Define channel ranges, cadence, baselines, and event shapes from a documented reference. When a note
asserts an event ("febrile to 39.2°C at hour 14"), the temperature channel must show it. Physiologic
plausibility and note-alignment are both required — one without the other is a defect.

## Validate against a reference, and state the reference
Fidelity claims are only as strong as the reference they're measured against (global §6). Always record
which reference statistics or published distributions a set was validated against, so realism claims are
defensible and reproducible.

## Run the no-real-PHI scan on every set — free-text is the biggest risk surface
Notes are where real PHI is most likely to leak in. Make the synthetic-safety scan a **mandatory,
release-blocking** step (T6), keep the synthetic-identifier allow-list current, and confirm any real
reference data stayed read-only and minimized.

## Pilot-first, expand only after the gate passes
Prove the full pipeline on a small cohort and pass every gate before widening the cohort or adding note
types/vitals channels. Re-validate at each expansion step — new modalities and cohorts introduce new
consistency and plausibility risks.

## Keep the config the single driver; keep everything reproducible
Drive generation and validation from one validated **Multi-Modal Config – Pilot – v1**. Version the
config, the templates, and the reports together so any released set can be regenerated and its gates
re-audited. Reproducibility is what makes a synthetic set trustworthy to AI/QA teams.

## Stay inside the boundary
Everything runs in the isolated non-production environment on synthetic data. The solution provides the
technical **method and evidence**; HIPAA/HITRUST de-identification determinations, IRB/privacy-office
sign-off, and disclosure-risk acceptance are **deferred to privacy/compliance/legal**. For vendor tools,
integrate at the pattern level and verify version-specific behavior against the vendor's documentation.
