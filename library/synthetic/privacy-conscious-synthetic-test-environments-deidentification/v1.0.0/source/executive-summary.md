# Executive Summary

AI and QA teams need realistic clinical test data — but test environments built from clinical data
must be **privacy-safe**, and the organization must be able to *prove* it on review. Assertions are
not enough; governance needs evidence.

**Outcome.** This solution establishes **privacy-conscious test environments** where the data is
**safe by design and defensible on review** — either de-identified from a governed source or fully
synthetic, with **re-identification risk assessed under an agreed threshold** and the supporting
**privacy evidence captured**. AI teams evaluate models and QA exercises systems **without carrying
real-PHI exposure into a shared environment**.

**Approach.** A pilot-first method — **Assess → Design → Generate/Build → Validate → Expand** — with
explicit pass/fail gates. It classifies every field (direct identifier / quasi-identifier / sensitive
/ non-identifying), applies a configurable de-identification or synthesis pipeline, and then measures
re-identification risk with **k-anonymity, l-diversity, disclosure-risk, and membership/attribute-
inference** signals against a threshold agreed with privacy. The result is packaged into a structured
**evidence record** — classification → transformation → metric → threshold → result — the artifact
governance signs against. Five Python tools automate the work: a PHI-field scanner, a de-identification
pipeline, a fidelity/coverage report, a re-ID-risk assessor, and a config/evidence helper — all
**safe by default** (no real PHI written to shared locations; dry-run where they write).

**Why it is safe.** Real source data stays read-only and minimized in the privacy-controlled zone;
only *released* datasets enter the isolated test environment; any re-identification key is held
outside it. Disclosure risk is **measured, not assumed**, and a candidate that fails a gate is rolled
back, not released. Critically, the solution keeps a clean separation of duties: engineering produces
the **method and evidence**, while the **regulatory determination** — HIPAA Safe Harbor / Expert
Determination, IRB/privacy sign-off, residual-risk acceptance — is **deferred to the organization's
privacy, compliance, and legal functions**. A technical PASS is a signal for that decision, not a
substitute for it.

**Bottom line.** Test data that is safe by design and defensible on review — de-identified or
synthetic, re-ID risk assessed under threshold, evidence captured — so AI teams can evaluate without
privacy exposure, and governance can approve with confidence.
