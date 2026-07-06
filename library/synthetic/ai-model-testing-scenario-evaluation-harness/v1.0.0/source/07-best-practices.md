# Best Practices

Durable practices for running the AI Model Testing & Scenario-Based Evaluation Harness well. They keep
evaluations **safe, repeatable, and comparable** over time.

## Treat scenarios, metrics, and gates as versioned data — not code

Keep the **Evaluation Scenario Suite**, **Metric Definition Set**, and **Evaluation Gate Policy** as
versioned files (`…pilot.v1.json`, `…v2.json`). Bump the version on any change and stamp every Run
Record with the versions it used. This is what makes two runs comparable and a regression check
meaningful.

## Set gate thresholds before you see results

Agree PASS thresholds with the AI/QA and governance owners **before** the first scored run (requirement
**R3**). A threshold chosen after seeing the numbers is not a gate — it is a rationalization. Record the
agreed numbers in the Gate Policy and change them only through a deliberate, versioned decision.

## Keep the model behind the adapter — never leak vendor SDKs into the harness

All model access goes through the single `MUT Adapter` `predict(...)` contract. Never scatter vendor
client calls through the runner, metrics, or gates. This keeps the harness model- and vendor-agnostic,
lets you compare models on identical terms, and makes swapping a model a one-file change. For any
vendor framework, wrap its **documented** client call and **verify the signature against your version**
— do not assume.

## Never write real PHI into the shared harness

Evaluation runs on **synthetic/twin data** in the **isolated environment**. Any reference statistics
used for realism are read-only and minimized under the governing privacy controls. Keep every write
target inside the isolated environment; the privacy gate and test **T4** enforce this. Leave the
**disclosure-risk and de-identification determinations to privacy/compliance/legal** — the harness
supplies the technical evidence, not the legal sign-off.

## Cover the edges and the safety cases, not just the happy path

Coverage is the ceiling on assurance. Deliberately include edge cohorts, malformed/boundary inputs, and
**safety/refusal** scenarios. Grow the suite as new failure modes are discovered — every production
surprise should become a scenario so it can never regress silently.

## Make every run reproducible

Pin the model version, fix seeds, snapshot the data, and record all of it in the Run Record (requirement
**R6**). Reproducibility is the precondition for trusting a regression comparison; without it, diffs are
noise.

## Baseline deliberately, and re-baseline only on an approved improvement

Promote a run to **Evaluation Baseline** only after all gates PASS. Re-baseline when a model or suite
genuinely improves — not to make a red regression go green. The baseline is the contract the next
candidate must beat.

## Keep secrets in the environment, never in assets

Model credentials and endpoints live in environment variables read by the adapter — never in
`config.*.json`, scenarios, or scripts. Config files are versioned artifacts; secrets are not.

## Automate the gate into pre-production

Once stable, run the suite + report + regression check automatically for every candidate model version
before promotion. A harness that only runs when someone remembers is not a gate.

## Retain failed runs

Keep failing Run Records and Gate Reports — they are the diagnosis trail and the raw material for new
scenarios. Do not delete a red run just because the candidate was rejected.
