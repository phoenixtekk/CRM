# Testing & Validation

These procedures validate that the harness itself is correct and that a candidate model's run is
trustworthy. Each has an **expected PASS/FAIL** signal. Run them in the isolated environment on
synthetic/twin data. Artifact names match `03-implementation.md`.

---

## T1. Scenario coverage validation

- **Goal:** Confirm every scenario in **Evaluation Scenario Suite – Pilot – v1** actually ran and
  produced a metric.
- **Procedure:** Run `scenario_runner.py` in `--dry-run` and inspect the summary; then check the Run
  Record's per-scenario status.
- **PASS:** Count of scenarios executed = count in the suite; zero errored/skipped scenarios above the
  Gate Policy tolerance.
- **FAIL:** Any scenario failed to resolve an input, call the adapter, or compute a metric — fix before
  scoring (see `06-troubleshooting.md`).

## T2. Metric correctness (fixture) validation

- **Goal:** Confirm each metric in **Metric Definition Set – Pilot – v1** scores as intended.
- **Procedure:** Run the suite against a **fixture adapter** with known outputs (a stub that returns
  pre-set answers, including deliberate wrong ones), and check the metrics match hand-computed values.
- **PASS:** Every metric equals its expected value on the fixture within tolerance (e.g. a perfect
  fixture → `normalized_match = 1.0`; a half-wrong fixture → `0.5`).
- **FAIL:** Any metric disagrees with the hand-computed value — the metric definition is wrong, not the
  model.

## T3. Gate enforcement validation

- **Goal:** Confirm the **Evaluation Gate Policy – Pilot – v1** turns metrics into the correct PASS/FAIL
  and that a FAIL blocks promotion.
- **Procedure:** Run `metrics_reporter.py` against (a) a Run Record known to clear all thresholds and
  (b) one known to breach a threshold.
- **PASS:** Case (a) exits **0** and reports PASS; case (b) exits **non-zero** and reports FAIL with the
  breaching metric/scenario enumerated.
- **FAIL:** A breaching run reports PASS, or the reporter exits 0 on a FAIL — the gate is not enforcing.

## T4. Privacy / no-PHI validation

- **Goal:** Confirm the run wrote **no real PHI** to shared locations and operated only on
  synthetic/twin data.
- **Procedure:** Run `privacy_check.py`-equivalent step (the privacy gate in `metrics_reporter.py`
  plus a manual review): verify inputs came from the synthetic/twin dataset, outputs were retained only
  in the isolated results store, and no configured path points outside the isolated environment.
- **PASS:** All scenario inputs trace to the synthetic/twin dataset; no output path resolves outside the
  isolated environment; the privacy gate reports PASS.
- **FAIL:** Any input traces to a real-PHI source, or any write target is outside the isolated
  environment — **stop**; this violates the safety boundary. (Note: the *disclosure-risk determination*
  itself is deferred to privacy/compliance/legal — this test checks the technical control, not the
  legal acceptance.)

## T5. Reproducibility validation

- **Goal:** Confirm a re-run of the same suite against the same model version yields the same decision.
- **Procedure:** With seeds fixed and the model version pinned (requirement **R6**), run the suite
  twice and diff the aggregated metrics.
- **PASS:** The two runs' metrics match within the reproducibility tolerance recorded in the Gate
  Policy, and both yield the same PASS/FAIL.
- **FAIL:** Metrics differ beyond tolerance — nondeterminism is uncontrolled; pin/seed before trusting
  regression comparisons.

## T6. Regression comparison validation

- **Goal:** Confirm `regression_check.py` detects a real quality drop against the **Evaluation Baseline
  – Pilot – v1**.
- **Procedure:** Compare (a) the baseline run to itself (expect zero regressions) and (b) a deliberately
  degraded run (e.g. fixture adapter with more wrong answers) to the baseline.
- **PASS:** Case (a) reports no regression and exits 0; case (b) reports the regressed metric(s) and
  exits non-zero.
- **FAIL:** A degraded run reports no regression — the check is not comparing correctly.

## T7. End-to-end pilot validation

- **Goal:** Confirm the full Assess→Validate flow produces a defensible gate decision on the real
  pilot model.
- **Procedure:** Execute steps 9–14 of `03-implementation.md` against the pilot model and dataset.
- **PASS:** A committed **Evaluation Run – Pilot – `<timestamp>`**, an **Evaluation Gate Report – Pilot
  – v1** with an explicit PASS/FAIL, and (on PASS) an established **Evaluation Baseline – Pilot – v1**.
- **FAIL:** Any stage cannot produce its artifact — resolve before declaring the harness ready for
  Expand.
