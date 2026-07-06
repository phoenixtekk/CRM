# Requirements

These are the **solution-specific** prerequisites for the AI Model Testing & Scenario-Based Evaluation
Harness. They build on — and do **not** repeat — the six category-wide requirements in
`global-requirements-synthetic.md` (a Python data/engineering environment, a target clinical data
model, an isolated non-production environment, privacy/governance stakeholders and policy, AI/QA use
cases + pilot scope, and read-only minimized reference access). Confirm those six first; the items
below are what this harness additionally needs.

> Reminder of the boundary: evaluation runs on **synthetic/twin data in an isolated environment** with
> **no real PHI** in the shared harness. Vendor model frameworks are integrated at the pattern level;
> regulatory/legal determinations are deferred to privacy/compliance/legal.

---

## R1. A model exposed through a callable "Model Under Test" contract

- **Description:** Each model to be evaluated must be reachable behind a single callable interface — a
  function/class that takes a scenario input and returns the model's output (and, ideally, latency and
  any safety/refusal flags). This is the **Model Under Test adapter** (`MUT Adapter – <model> – v1`).
- **Why required:** The harness stays model- and vendor-agnostic by depending only on this contract,
  never on a vendor SDK's payload shape. Without it, scenarios cannot be run uniformly.
- **How to verify:** Confirm you can call the model once from the isolated environment and get a
  deterministic-enough response for a known input (record the call latency).
- **How to implement if missing:** Write a thin adapter that wraps whatever the model exposes (local
  inference call, hosted endpoint, or a vendor framework's client — **see that vendor's documentation**
  for the exact client call) into the harness's `predict(scenario_input) -> output` shape. Keep any
  credentials in environment variables, never in the adapter code.

## R2. Ground truth / expected behavior for each scenario

- **Description:** For every scenario, a definition of "correct enough" — an expected answer, an
  acceptable-answer set, a reference label, or a rubric/threshold the metric can score against.
- **Why required:** Metrics and gates are meaningless without a reference; a scenario with no expected
  behavior cannot pass or fail.
- **How to verify:** Confirm each scenario in the Evaluation Scenario Suite has an `expected` (or a
  documented metric that needs none, e.g. latency or a safety-flag check).
- **How to implement if missing:** Work with the AI/QA owners of the use case to define expected
  behavior per scenario; where exact answers don't exist, define a scored rubric or a tolerance band.

## R3. Agreed evaluation metrics and pass/fail thresholds

- **Description:** The specific metrics to compute (e.g. normalized match rate, task score, latency
  percentile, refusal/safety-flag rate) and the numeric thresholds that constitute a PASS — captured as
  the **Metric Definition Set** and **Evaluation Gate Policy**.
- **Why required:** The gate decision is only as credible as the agreed thresholds; thresholds set after
  seeing results are not a gate.
- **How to verify:** Confirm each metric has an owner, an aggregation rule, and a threshold agreed with
  the AI/QA and governance stakeholders **before** the first scored run.
- **How to implement if missing:** Facilitate a short threshold-setting session; record the agreed
  numbers in the Gate Policy file and version it.

## R4. Synthetic/twin test data mapped to the scenarios

- **Description:** The synthetic or hospital-twin records that scenario inputs draw from, in the target
  model's shape (FHIR / OMOP / native) and sufficient in volume and variety to cover the use cases.
- **Why required:** Scenarios must run on realistic, safe inputs; thin or unrepresentative test data
  produces a green gate that means nothing.
- **How to verify:** Confirm the synthetic/twin dataset exists in the isolated environment, matches the
  target model, and contains the cohorts/edge cases the scenarios reference. Confirm it holds **no real
  PHI**.
- **How to implement if missing:** Generate/obtain the synthetic/twin data (a separate synthetic-data
  or twin solution) before authoring scenarios that depend on it.

## R5. A run/results store and a baseline location

- **Description:** A location in the isolated environment to write **Run Records** (per-run raw outputs
  + metrics) and to keep the **approved baseline** run for regression comparison — a directory, an
  artifact store, or a small database.
- **Why required:** Comparability and regression protection require durable, versioned run history; the
  gate and the regression check read from it.
- **How to verify:** Confirm a writable results path exists and is access-controlled, and that a
  baseline slot is designated.
- **How to implement if missing:** Create the results directory/store and record its path in the harness
  config (the config helper writes this).

## R6. Determinism / reproducibility controls for the run

- **Description:** The controls needed to make a run **repeatable** — fixed random seeds, a pinned model
  version identifier, a recorded scenario-suite version, and a fixed data snapshot reference.
- **Why required:** "Comparable across models and versions" only holds if a re-run of the same inputs
  yields the same decision; uncontrolled nondeterminism makes regression comparison noise.
- **How to verify:** Run the same suite twice against the same model version and confirm metrics match
  within the tolerance recorded in the Gate Policy.
- **How to implement if missing:** Pin the model version, set and record seeds, snapshot the data, and
  stamp every Run Record with the scenario-suite and metric-set versions.
