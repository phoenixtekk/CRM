# Deliverables Summary

What the buyer gets: a complete, self-guided package to stand up a **synthetic data sub-function**
inside quality engineering as a repeatable, measured service — the operating-model documentation plus
five working Python tools.

## Documentation

- **Solution Overview** — the sub-function's mission, scope, target model (FHIR/OMOP/native), how it
  serves AI/QA, the operating model, benefits, and limitations.
- **Requirements Guide** — the six category-wide requirements plus six solution-specific prerequisites
  (sponsor/charter, pod structure, intake scheme, KPI framework, reference architecture, maturity
  target), each with how to *verify* and *implement if missing*.
- **Implementation / Operating Model & Roadmap** — the ordered standup following
  Assess → Design → Generate/Build → Validate → Expand: pod/squad design, intake and prioritization,
  reference architecture, the KPI catalog, and explicit pass/fail gates with rollback. Every artifact
  is named (`Capability Charter – Sub-Function – v1`, `Synthetic EHR – Pilot – v1`, etc.).
- **Testing & Validation** — operating-model tests and per-dataset fidelity/coverage/privacy gates,
  each with an expected pass/fail signal.
- **Troubleshooting** — common standup and dataset failure modes and their resolutions.
- **Best Practices** — durable practices for operating and scaling the sub-function.
- **Capability document template** — the charter/operating-model structure embedded in the
  implementation guide, ready to fill in.

## The 5 Python tools (`SYNFUNC-Scripts.zip`)

All tools are Python 3.10+, standard-library-first, and **safe by default** (dry-run for anything that
writes; never write synthetic output to shared locations; never emit real data values).

1. **`maturityassess.py`** — Capability & maturity self-assessment. Scores the sub-function across
   dimensions (operating model, engineering, validation/quality, privacy/governance, adoption),
   computes an overall maturity level, and emits `Maturity Baseline – Sub-Function – v1`.

2. **`intakequeue.py`** — Intake-queue analyzer & pod-capacity helper. Ingests a request queue,
   validates the intake schema, applies the value/urgency/effort/risk prioritization scoring model,
   ranks the queue, and models demand against pod FTE (per-pod utilization vs. a ceiling) to flag
   over-commitment for the charter and expansion waves.

3. **`datasetprofile.py`** — Fidelity/coverage report. Profiles a synthetic dataset for structural
   conformance, in-scope coverage, and (when a reference is supplied) distributional fidelity, with an
   explicit N/A when no reference exists. Produces the fidelity/coverage section of the validation
   record.

4. **`privacycheck.py`** — Privacy/validation check. Screens a synthetic dataset for direct-identifier
   leakage, exact reference-row copies (memorization), and quasi-identifier/uniqueness risk
   (k-anonymity signal). Produces technical evidence and a pass/fail signal; defers the disclosure-risk
   determination to the privacy officer.

5. **`kpirollup.py`** — KPI computation & rollup + reference-architecture config validator. Computes
   the delivery-quality and productivity KPIs from intake + validation records, and (in `--refarch`
   mode) validates the reference-architecture config for the required tiers, engine interface, gate
   stage, and the no-real-PHI isolation boundary.
