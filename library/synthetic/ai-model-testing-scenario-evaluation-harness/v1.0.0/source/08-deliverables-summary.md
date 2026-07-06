# Deliverables Summary

What the buyer receives — a complete, reusable **AI model testing and scenario-based evaluation
harness** for safe pre-production evaluation of AI/ML models on synthetic/twin data.

## Documentation

- **Solution Overview** — the evaluation model: scenarios, metrics, synthetic/twin test data,
  pass/fail gates, the Model Under Test adapter pattern, and the Assess→Design→Generate/Build→
  Validate→Expand deployment model.
- **Requirements Guide** — the six solution-specific prerequisites (model-under-test contract, ground
  truth, agreed metrics/thresholds, synthetic/twin test data, run/baseline store, reproducibility
  controls), each with how to verify and how to implement — on top of the six category-wide
  requirements.
- **Implementation Guide** — exact, ordered, pilot-first steps to author the scenario suite, metric
  set, and gate policy; wire the model adapter and synthetic/twin data; run evaluations; enforce the
  pass/fail gates; baseline; and expand — with the rollback rule.
- **Testing & Validation** — seven procedures (coverage, metric correctness, gate enforcement,
  privacy/no-PHI, reproducibility, regression, end-to-end pilot), each with an explicit PASS/FAIL.
- **Best Practices** — durable practices for safe, repeatable, comparable evaluation.
- **Troubleshooting** — common failure modes and resolutions.
- **Executive Summary** — the outcome, approach, and why it is safe.

## The 5 Python tools

1. **`eval_scope_assess.py`** — *Assessment / profiling.* Profiles readiness and scope (models under
   test, target data model, isolated environment, use cases, results store) and writes an **Eval
   Readiness Report**, flagging every gap. Read-only.

2. **`scenario_runner.py`** — *Scenario execution.* Loads the Evaluation Scenario Suite and Metric
   Definition Set, calls each model through the abstract **Model Under Test adapter**, computes
   per-scenario metrics, and writes a **Run Record**. **Dry-run by default** (`--commit` to persist).

3. **`metrics_reporter.py`** — *Fidelity/coverage report + gate enforcement.* Aggregates a Run Record
   and applies the **Evaluation Gate Policy** (coverage, quality, and privacy gates), writes the
   **Evaluation Gate Report**, and **exits non-zero on FAIL** so it can gate a pipeline.

4. **`regression_check.py`** — *Privacy/validation & regression check.* Compares a new Run Record to the
   approved **Evaluation Baseline**, flags any metric regression beyond tolerance, and verifies the run
   stayed within the isolated (no-real-PHI) boundary. Exits non-zero on a detected regression.

5. **`harness_config.py`** — *Scope/config helper.* Scaffolds and validates the harness config and the
   three core asset skeletons (scenarios, metrics, gates), and manages the baseline pointer
   (`set-baseline`). Safe: `init`/`validate` don't overwrite without `--force`.

All tools are **Python 3.10+**, standard-library-first, **safe-by-default** (no real PHI written to
shared locations; dry-run/opt-in for anything that writes), and carry no hardcoded secrets. Run any with
`--help`.
