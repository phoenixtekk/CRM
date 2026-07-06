# Troubleshooting

Common failure modes when building and running the fidelity & validation asset library, with
resolutions. All work happens in the isolated environment; no real PHI is written to a shared
harness.

## The Reference Profile build refuses to emit ("contains row-level data")
- **Cause:** The profile builder's safety check found row-level values in the output — usually a
  field mis-typed so raw values were retained, or a manifest role not set.
- **Resolution:** Correct **Field Manifest – <Use Case> – v1** so identifiers/free-text are flagged
  out of statistical scope, then rebuild. The profile must be aggregate-only before it leaves the
  governed environment.

## Manifest fields not found in the synthetic dataset
- **Cause:** Column names differ (case, prefixes, model mapping) between the reference and the
  synthetic dataset.
- **Resolution:** Run `synfid_config.py validate --config … --data …` to list the exact mismatches;
  align the manifest field names to the dataset columns (or rename dataset columns on export).

## Fidelity passes but the model is worse on synthetic data (utility gap)
- **Cause:** Statistical distances can look fine while the joint structure the model relies on is
  distorted — the classic silent failure.
- **Resolution:** Ensure utility is **in scope** and measured: define **Utility Task – <Use Case> –
  v1**, run TSTR (`--real-test-metric` / `--synth-test-metric`), and gate on `max_utility_gap`. If
  the gap fails, return to generation — do not release on statistical fidelity alone.

## Correlation preservation is low despite good per-field distributions
- **Cause:** The generator reproduced marginals but not joint relationships between numeric fields.
- **Resolution:** This is expected behavior of the metric — it exists to catch exactly this. Report
  the failing pairs to the generation team and regenerate with correlation-aware settings (see the
  generator vendor's documentation); re-run the fidelity suite.

## A coverage rule reports RULE_ERROR
- **Cause:** The rule uses unsupported syntax. The checker supports a small, safe grammar:
  `field<op>value` predicates joined by `AND`, ops `== != >= <= > <` (no `OR`, no functions, no
  `eval`).
- **Resolution:** Rewrite the rule within the grammar (split an `OR` into two coverage targets).
  Quote string values or leave them bare; numerics compare numerically automatically.

## Coverage fails because a required cohort is absent
- **Cause:** The generator under-produced a rare cohort the AI use case needs.
- **Resolution:** Add the cohort — regenerate with the generator's rare-case controls, or use the
  scenario/coverage runner to enumerate the needed slices — then re-check against **Coverage Spec –
  <Use Case> – v1**.

## Privacy check reports a FAIL (exact match or nearest-neighbor)
- **Cause:** Synthetic quasi-identifier tuples too closely reproduce the reference sample.
- **Resolution:** Treat as a **signal**, not a verdict: escalate to the privacy office. Technically,
  regenerate with stronger privacy settings and/or reduce quasi-identifier granularity. **The
  de-identification determination remains with privacy/compliance/legal — the tool never makes it.**

## The runner reports utility "NOT_MEASURED" but you expected it measured
- **Cause:** `utility_task.in_scope` is `true` in the config but no `--real-test-metric` /
  `--synth-test-metric` were supplied.
- **Resolution:** Supply both metrics (or set `in_scope` to `false` if utility genuinely isn't part
  of this suite). The runner deliberately fails rather than silently skip an in-scope gate.

## `synfid_validate.py` cannot import the sibling tools
- **Cause:** The scripts were separated from each other; the runner imports `synfid_fidelity`,
  `synfid_coverage`, and `synfid_privacy`.
- **Resolution:** Keep all five scripts in the same directory (they ship together in
  `SYNFID-Scripts.zip`). The runner adds its own directory to `sys.path`; do not rename the modules.

## Evidence Reports differ run-to-run on the same inputs
- **Cause:** Non-determinism upstream (a re-sampled reference, a changed dataset, or an unpinned
  generator), not the metrics — the metric code is deterministic for fixed inputs.
- **Resolution:** Pin the inputs: use the hashed **Reference Profile**, a fixed synthetic dataset,
  and a versioned config. Same inputs must yield the same verdict; if not, an input changed.
