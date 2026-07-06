# Executive Summary

## The outcome

Clinical AI runs on more than tables. Document models read **clinical notes**, signal and sequence
models read **vitals and time-series**, and multi-modal pipelines depend on those modalities *agreeing*
with one another. Synthetic data that stops at structured tables can only test a fraction of what real
care actually uses. This solution extends synthetic generation to **multi-modal clinical data** —
structured records **plus** realistic, NLP-ready clinical notes **plus** vitals/time-series — kept
**cross-modally consistent for a single synthetic patient**, so AI teams can test document-, signal-, and
sequence-based models, not just tabular ones.

## The approach

The generator is driven by one **per-patient clinical state** — the structured record plus a small set of
derived clinical facts — that all three modalities render from. A template/pattern **note synthesizer**
produces labelable free-text, a **vitals generator** produces physiologically plausible signals, and both
read the same state, so the note narrative, the structured record, and the vitals streams tell the **same
story**. A **cross-modal consistency validator** then proves it — diagnoses in notes appear in the
structured problem list, asserted vitals events have matching signals, and everything stays in plausible
ranges. Delivery follows a **pilot-first Assess → Design → Generate/Build → Validate → Expand** model with
explicit pass/fail gates and a clean rollback, and ships five safe-by-default **Python** tools that
automate assessment, generation, fidelity/coverage reporting, consistency/safety validation, and config.

## Why it's safe

Every artifact is **synthetic**. Notes are slot-filled from templates and phrase banks — never copied from
real patient text — and **no real PHI is ever written into the shared harness**. All work runs in an
**isolated non-production** environment; any real reference data used for fidelity stays **read-only and
minimized**. A **release-blocking no-real-PHI scan** runs on every set, with free-text notes treated as
the primary risk surface. The solution provides the technical **method and evidence** only —
HIPAA/HITRUST de-identification determinations, IRB/privacy-office sign-off, and disclosure-risk
acceptance are **deferred to the organization's privacy, compliance, and legal functions**. Vendor
synthetic-data and AI frameworks are integrated at the pattern level, with version-specific behavior
verified against the vendor's documentation.

## Bottom line

Synthetic clinical data across modalities — structured, notes, and vitals/time-series, consistent per
patient — so AI teams can test the models real care actually uses, safely, at a fraction of bespoke
consulting cost.
