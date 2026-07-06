# Troubleshooting

Common failure modes when standing up and running the AI Model Testing & Scenario-Based Evaluation
Harness, with resolutions. Artifact names match `03-implementation.md`. All work stays in the isolated
environment on synthetic/twin data — never real PHI in the shared harness.

---

## Scenarios error out or are skipped (coverage gate FAILS)

- **Symptom:** `scenario_runner.py` reports `errored > 0`, or `metrics_reporter.py` fails the coverage
  gate.
- **Likely causes:** a scenario `input` doesn't resolve against the synthetic/twin dataset; the
  adapter raised on a malformed input; the scenario shape doesn't match what the adapter expects.
- **Resolution:** inspect the Run Record's `per_scenario[].error`. Fix the scenario input or the
  adapter's input handling in **Evaluation Scenario Suite – Pilot – v1**; re-run `--dry-run` until
  `errored = 0`. Do not lower `coverage.max_errored` to hide a broken scenario.

## Adapter import/resolve fails

- **Symptom:** `adapter target 'module:callable' is not callable` or an `ImportError`.
- **Likely causes:** the `--adapter module:function` path is wrong, the module isn't on `PYTHONPATH`,
  or the adapter isn't a callable returning the `{output, latency_ms, safety_flags}` contract.
- **Resolution:** confirm the module is importable from the run directory; confirm the target is a
  function or `Class.method`; validate the return shape. Use `--adapter fixture` to prove the harness
  itself works, then point back at the real **MUT Adapter – `<model>` – v1**.

## A metric looks wrong even though the model seems fine

- **Symptom:** `normalized_match` is 0.0 for answers that look correct.
- **Likely causes:** whitespace/case/punctuation differences; `expected` doesn't match the model's
  output format; the wrong metric for the task (exact match where `contains` or a rubric was meant).
- **Resolution:** run test **T2** (fixture) to confirm the metric scores as designed; normalize the
  `expected` values or switch the metric in **Metric Definition Set – Pilot – v1**. Remember metrics
  are only in `PER_SCENARIO_METRICS` if implemented in `scenario_runner.py`.

## Gate reports PASS when it should FAIL (or vice versa)

- **Symptom:** a run that breaches a threshold still shows OVERALL PASS.
- **Likely causes:** wrong `direction` in the Gate Policy (`min` vs `max`), a threshold set too loose,
  or the metric name in `gates.quality[].metric` doesn't match the aggregate key.
- **Resolution:** verify each quality gate's `metric` name matches a key in the run's `aggregates`,
  and that `direction` matches the metric's meaning (`latency_ms_p95` and `safety_flag_rate` are
  `max`; match/score metrics are `min`). Re-run test **T3** with a known-bad run.

## Privacy gate FAILS / boundary not attested

- **Symptom:** `metrics_reporter.py` or `regression_check.py` fails the privacy/boundary check.
- **Likely causes:** the run wasn't produced by this harness on synthetic/twin data, a `real_phi_present`
  flag is set, or a configured path points outside the isolated environment.
- **Resolution:** **stop and investigate** — confirm all scenario inputs trace to the synthetic/twin
  dataset and every write target is inside the isolated environment (test **T4**). Never suppress this
  gate. The disclosure-risk *determination* remains with privacy/compliance/legal; this check only
  enforces the technical control.

## Reproducibility: two runs of the same model disagree

- **Symptom:** identical suite + model version yields different metrics across runs (test **T5** FAILS).
- **Likely causes:** unseeded randomness in the model or sampling, an unpinned model version, or a
  shifting data snapshot.
- **Resolution:** pin the model version in `config.*.json` (`model_version`), set seeds, and snapshot
  the data (requirement **R6**). Record all three in the Run Record. Only trust regression comparisons
  once T5 passes.

## Regression check reports no regression on an obviously worse model

- **Symptom:** a degraded candidate passes `regression_check.py`.
- **Likely causes:** tolerance set too high, wrong `metric_directions`, or the baseline pointer is
  stale/wrong.
- **Resolution:** confirm `regression_tolerance` is tight, verify `metric_directions` (higher-better
  vs lower-better), and confirm `baseline_run` points at the intended **Evaluation Baseline – Pilot –
  v1**. Re-run test **T6** with a deliberately degraded fixture run.

## `harness_config.py validate` reports a secret in the config

- **Symptom:** validation FAILS with "config appears to contain a secret-like key".
- **Likely cause:** credentials or endpoints with tokens were placed in `config.*.json`.
- **Resolution:** remove them. Credentials belong only in environment variables read by the adapter;
  config files are versioned artifacts and must never hold secrets.

## Vendor model framework behaves differently than documented

- **Symptom:** the adapter's wrapped vendor client call returns an unexpected shape or errors.
- **Likely cause:** version drift — the framework's client signature or response changed across versions.
- **Resolution:** this solution integrates model frameworks **at the pattern level** only. Consult the
  vendor's documentation and **verify the client signature/response against your installed version**;
  adjust the adapter accordingly. Do not assume internals — keep the harness depending only on the
  `predict(...)` contract.
