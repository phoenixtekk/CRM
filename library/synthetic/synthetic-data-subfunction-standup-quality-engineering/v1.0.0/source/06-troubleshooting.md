# Troubleshooting

Common failure modes when standing up and operating the synthetic-data sub-function, and how to
resolve them. Grouped by stage. Named artifacts and tools follow `03-implementation.md`.

> Any privacy failure is a **hard block** with rollback — never "troubleshoot around" it by releasing.
> Regulatory/legal determinations stay with privacy/compliance/legal.

## Standup / operating model

**Requests keep arriving outside the intake queue.**
- *Cause:* No enforced single front door; requesters use relationships.
- *Fix:* Route every request — including sponsor "favors" — through `Intake Scheme – Sub-Function – v1`.
  Log expedites as priority overrides so they still appear in `intakequeue.py` and the KPIs. If it is
  not in the queue, it does not get done.

**`intakequeue.py` rejects rows.**
- *Cause:* Missing required fields or out-of-range scores (value/urgency/effort/risk must be 1–5).
- *Fix:* Correct the intake data to match the schema (see `REQUIRED_FIELDS` in the tool). A rejected
  row is unscoped work — do not let it silently proceed.

**A pod shows OVER-COMMITTED (or NO-CAPACITY) in `intakequeue.py --capacity`.**
- *Cause:* Committed FTE cannot cover the demand mix at the utilization ceiling (default 85%).
- *Fix:* Re-staff, re-scope, or defer lower-priority requests before committing the charter. Do not
  commit to demand the capacity model rejects; that is how lead time silently degrades.

**`kpirollup.py --refarch` reports ERROR findings.**
- *Cause:* The reference-architecture config is missing a required element — most often the
  `isolation_boundary` assertion, a defined `engine_interface`, or the `gate_stage`.
- *Fix:* Complete the config. The **no-real-PHI isolation boundary** and a present gate stage are
  hard requirements; Gate B cannot close with any ERROR finding.

**Maturity level looks stuck at 1–2 despite good tooling.**
- *Cause:* `maturityassess.py` caps overall maturity by the weakest of validation/quality and
  privacy/governance — strong engineering cannot compensate for missing gates.
- *Fix:* Raise the gate-critical dimensions (stand up the validation record and privacy screens)
  before expecting the overall level to move.

## Generation / build

**Generated dataset fails structural conformance (B1).**
- *Cause:* Engine output does not match the target model (missing domain, broken
  patient→encounter→observation links).
- *Fix:* Correct the engine mapping/config to the target model; regenerate `Synthetic EHR – Pilot – v1`
  (counts as rework). If the engine is Synthea or a commercial platform, verify the mapping against
  that vendor's documentation for your version.

**Coverage below target (B2).**
- *Cause:* Scenario set or generation parameters do not exercise all required categories/value sets.
- *Fix:* Extend the scenario suite or generation parameters to include the missing categories reported
  by `datasetprofile.py --mode coverage`, then re-run.

**Engine swap broke the pipeline.**
- *Cause:* Vendor-specific behavior leaked outside the engine interface.
- *Fix:* Keep all engine specifics behind the reference-architecture engine interface; the intake,
  validation, and KPI stages must not know which engine ran. Re-validate the architecture with
  `kpirollup.py --refarch` after any engine change.

## Validation / privacy

**`datasetprofile.py` fidelity shows N/A.**
- *Cause:* No `--reference` supplied — expected when no governed reference or agreed distribution
  exists.
- *Fix:* This is **not** a pass and **not** a failure: report distributional fidelity as N/A and make
  no fidelity claim. Coverage and structure still gate. Obtain a governed/minimized reference (or agree
  published distributions) if a fidelity claim is required.

**Fidelity distance is out of tolerance (B3).**
- *Cause:* Synthetic distributions diverge from the reference beyond the agreed tolerance.
- *Fix:* Tune engine parameters (prevalence, age/sex mix) and re-run. Do not loosen the tolerance to
  force a pass without sponsor agreement.

**`privacycheck.py` reports HARD FAIL on identifiers (B4).**
- *Cause:* A direct-identifier field name or a value matching an SSN/email/phone pattern is present.
- *Fix:* **Block release.** Find and remove the leak in the engine/config; direct identifiers must
  never appear in synthetic output. Regenerate and re-screen.

**`privacycheck.py` reports HARD FAIL on copies (B5).**
- *Cause:* Synthetic rows are exact copies of reference rows — the engine is memorizing/leaking real
  data.
- *Fix:* **Block release.** Investigate the engine's use of reference data (it should learn
  distributions, not copy rows). This is a serious safety issue; fix before any further generation.

**`privacycheck.py` reports ESCALATE on uniqueness (B6).**
- *Cause:* Too many records are unique on the quasi-identifier set (below the agreed k).
- *Fix:* Escalate the evidence to the **privacy officer** for the disclosure-risk determination — do
  not self-clear. Mitigations (generalization, suppression, larger cohorts) are applied only with the
  privacy officer's direction.

**Everything passes but the consuming team reports the data is unusable.**
- *Cause:* Coverage/fidelity gates passed but the scenarios do not match the actual AI/QA use case.
- *Fix:* Return to intake — the `use_case` scoping was incomplete. Re-scope with the consuming team;
  this is an intake-quality problem, and it will show up as *defect escape rate* in `kpirollup.py`.

## KPIs / measurement

**KPIs cannot be computed (`kpirollup.py` errors or zeros).**
- *Cause:* Records are missing timestamps or validation outcomes.
- *Fix:* Ensure intake and validation capture the fields the tool expects (accepted/released times,
  first-pass, cycles, gate time, issues). Fix the capture, not the tool.

**KPIs look good but the sponsor doesn't trust them.**
- *Cause:* Side-channel work bypasses intake, so the metrics cover only part of reality.
- *Fix:* Close the side channels (see the first item). A measured service requires that *all* work
  flows through intake; otherwise the numbers are unrepresentative.
