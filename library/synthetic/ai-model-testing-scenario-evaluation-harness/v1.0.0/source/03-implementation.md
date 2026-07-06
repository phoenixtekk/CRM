# Implementation

Follow these steps in order. They implement the house model — **Assess → Design → Generate/Build →
Validate → Expand** — **pilot-first**, with explicit **pass/fail gates** and a **rollback** rule. Every
artifact is named with the `<Purpose> – <Scope> – <Stage>` convention and that exact name is reused in
Testing, Troubleshooting, and the scripts. All work happens in the **isolated non-production
environment** on **synthetic/twin data** — never real PHI in the shared harness.

The five Python tools referenced below live in `scripts/`:

- `eval_scope_assess.py` — assessment/profiling of readiness and scope.
- `scenario_runner.py` — loads scenarios + metrics, runs the model adapter, writes a Run Record.
- `metrics_reporter.py` — aggregates a Run Record and enforces the Gate Policy (PASS/FAIL).
- `regression_check.py` — compares a Run Record to the approved baseline.
- `harness_config.py` — scaffolds/validates the harness config and asset skeletons.

All scripts are **safe-by-default** (dry-run where they would write; no real PHI to shared locations).
Run any with `--help`.

---

## Stage 1 — Assess

1. **Confirm the six global requirements** (`global-requirements-synthetic.md`) and the six
   solution-specific requirements (`02-requirements.md`) are met. Do not proceed with an unmet
   environment-isolation or privacy requirement.

2. **Profile readiness.** Run the assessment tool to produce the **Eval Readiness Report – Pilot – v1**:

   ```
   python scripts/eval_scope_assess.py --scope pilot --out reports/
   ```

   It records the model(s) under test, the target data model (FHIR/OMOP/native), the isolated
   environment, the AI use cases, and the results-store path, and flags any gap. **Resolve every
   flagged gap before Stage 2.**

3. **Fix the pilot scope.** With the AI/QA owners, name **one** pilot use case and the model version to
   evaluate. Record it as the pilot scope in the readiness report.

## Stage 2 — Design

4. **Scaffold the harness assets.** Create the config and empty asset skeletons:

   ```
   python scripts/harness_config.py init --scope pilot --out harness/
   ```

   This writes `harness/config.pilot.json` (results path, baseline slot, seeds, versions) and skeletons
   for the three core assets. **Never** put credentials in the config — the model adapter reads those
   from environment variables.

5. **Author the Evaluation Scenario Suite – Pilot – v1.** For each scenario, define: an `id`, the
   scenario `input` (drawn from the synthetic/twin data in the target model's shape), the `expected`
   behavior/answer (per requirement **R2**), and the metric group it belongs to. Cover the happy path,
   known edge cases, and at least one safety/refusal scenario. Save as
   `harness/scenarios.pilot.v1.json`.

6. **Author the Metric Definition Set – Pilot – v1.** Define each metric (name, how it scores one
   scenario, how it aggregates across the suite) — e.g. `normalized_match`, `task_score`,
   `latency_ms_p95`, `safety_flag_rate`. Save as `harness/metrics.pilot.v1.json`.

7. **Author the Evaluation Gate Policy – Pilot – v1.** For each metric (and the overall run), set the
   **PASS threshold** agreed under requirement **R3**, the per-metric direction (higher/lower is
   better), and the **rollback rule** (any hard-gate failure → candidate not promoted). Save as
   `harness/gates.pilot.v1.json`.

8. **Define the Model Under Test adapter (`MUT Adapter – <model> – v1`).** Implement the single
   `predict(scenario_input) -> {output, latency_ms, safety_flags}` contract (requirement **R1**),
   wrapping whatever the model exposes. For a vendor model framework, wrap that vendor's documented
   client call — **see the vendor's documentation; verify the client signature against your version.**
   Keep secrets in env vars.

## Stage 3 — Generate/Build

9. **Wire the data and adapter, then dry-run.** Point the config at the synthetic/twin dataset and the
   adapter, and produce a Run Record without gating:

   ```
   python scripts/scenario_runner.py \
     --config harness/config.pilot.json \
     --scenarios harness/scenarios.pilot.v1.json \
     --metrics harness/metrics.pilot.v1.json \
     --adapter mut_adapter:predict \
     --dry-run
   ```

   `--dry-run` (default) executes the scenarios and prints a run summary **without** writing the Run
   Record. Confirm every scenario resolves an input, calls the adapter, and computes its metrics.

10. **Produce the first Run Record.** Re-run with `--commit` to write **Evaluation Run – Pilot –
    `<timestamp>`** into the results store:

    ```
    python scripts/scenario_runner.py --config harness/config.pilot.json \
      --scenarios harness/scenarios.pilot.v1.json --metrics harness/metrics.pilot.v1.json \
      --adapter mut_adapter:predict --commit
    ```

## Stage 4 — Validate (gates)

11. **Enforce the gates.** Aggregate the Run Record and apply the Gate Policy:

    ```
    python scripts/metrics_reporter.py \
      --run reports/runs/<run-id>.json \
      --gates harness/gates.pilot.v1.json \
      --out reports/
    ```

    This writes the **Evaluation Gate Report – Pilot – v1** and exits **non-zero on FAIL**.

    - **Scenario/coverage gate (PASS/FAIL):** every scenario in the suite ran and produced a metric —
      no errored or skipped scenarios above the tolerance in the Gate Policy.
    - **Quality gate (PASS/FAIL):** each metric meets its PASS threshold (e.g. `normalized_match ≥`
      threshold, `latency_ms_p95 ≤` threshold, `safety_flag_rate ≤` threshold).
    - **Privacy gate (PASS/FAIL):** the run wrote **no real PHI** to shared locations — the harness
      operated only on synthetic/twin inputs and the outputs were retained under the isolated
      environment's controls. (Any disclosure-risk *determination* is deferred to privacy/compliance.)

12. **Gate decision & rollback.** If **all gates PASS**, approve the run as the **Evaluation Baseline –
    Pilot – v1** (next step). If **any gate FAILS**, **do not promote the candidate** — retain the Run
    Record and Gate Report for diagnosis (see `06-troubleshooting.md`), fix the model/scenario/data, and
    re-run from step 10. A failed gate is the rollback trigger.

13. **Establish the baseline.** Store the approved run as the baseline the regression check compares to:

    ```
    python scripts/harness_config.py set-baseline \
      --config harness/config.pilot.json --run reports/runs/<run-id>.json
    ```

14. **Confirm regression protection works.** Run the regression check against the same run (expect zero
    regressions) to prove the wiring:

    ```
    python scripts/regression_check.py \
      --config harness/config.pilot.json --run reports/runs/<run-id>.json
    ```

## Stage 5 — Expand

15. **Broaden coverage.** Add scenarios for more cohorts, edge cases, and safety conditions; bump the
    suite to `Evaluation Scenario Suite – Pilot – v2` and re-baseline once it passes.

16. **Onboard more models/use cases.** Register additional models behind their own
    `MUT Adapter – <model> – v1` and run them through the **same** scenarios, metrics, and gates for an
    apples-to-apples comparison.

17. **Make it a repeatable gate.** Schedule the run + report + regression check to execute for every
    candidate model version before promotion, and keep the assets versioned so results stay comparable
    over time.
