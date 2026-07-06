# Troubleshooting

Common failure modes when building and running the hospital twin, with resolutions. Artifacts are
referenced by their `<Purpose> – <Scope> – <Stage>` names from `03-implementation.md`.

## Readiness reports a BLOCKER

- **Symptom:** `twin_readiness_assess.py` prints `NOT READY` with one or more `BLOCKER` findings and
  exits non-zero.
- **Cause:** A required input is missing — no synthetic source, no AI plug-in contract, no AI use
  cases, or Python < 3.10.
- **Resolution:** Clear each blocker named in `Twin Readiness – Pilot – v1` (bind the
  `Synthetic Feed Binding – Pilot – v1`, author the `Twin AI Plug-In Contract – Pilot – v1`, declare
  use cases, or upgrade Python). Re-run until `READY`. Do not proceed to Design with blockers.

## Scope config fails validation

- **Symptom:** `twin_readiness_assess.py --validate-config` prints `FAIL` with a list of errors.
- **Cause:** A missing key, a non-positive `population`, a non-integer `seed`, an unsupported
  `target_model`, or empty `in_scope_domains`.
- **Resolution:** Fix the listed fields in `Twin Scope Config – Pilot – v1.json`. Regenerate a clean
  starter with `--init-config` if the file drifted, then re-validate. Every later tool reads this
  file, so it must pass first.

## Simulator ABORTS on a real-PHI marker

- **Symptom:** `twin_simulator.py` prints `ABORT: real-PHI markers detected in the feed` and exits
  code 3.
- **Cause:** The `Synthetic Feed Binding – Pilot – v1` contains real-PHI markers (e.g. `ssn`,
  `mrn_real`) — real data leaked into a feed that must be synthetic-only.
- **Resolution:** **Stop.** Do not force the run. Remove the real data from the source; regenerate
  the feed from the synthetic generator or a governed synthetic dataset only. Never load real PHI
  into the twin. Re-run the simulator and confirm `real-PHI guard: PASS`.

## Simulator reports zero population or missing domains

- **Symptom:** Dry-run plan shows population 0 or absent in-scope domains.
- **Cause:** The feed did not load, or the config's `population`/`in_scope_domains` don't match the
  feed.
- **Resolution:** Confirm `Synthetic Feed Binding – Pilot – v1` path is correct and parses into the
  target model; reconcile `population` and `in_scope_domains` in `Twin Scope Config – Pilot – v1`.
  Re-run the dry-run (Test 1) before committing.

## Scenario runner: AI plug-in never invoked / empty evaluation record (Gate 2 fail)

- **Symptom:** `twin_scenario_runner.py` runs but `points_matched` is 0 for all scenarios, or the
  record is empty.
- **Cause:** The scenario has no `plugin_points`, or (real adapter) `--adapter-spec` is wrong so the
  AI is never actually called.
- **Resolution:** First prove wiring with `--ai-adapter mock` (it echoes the scenario's `expected`
  label, so a correctly authored scenario passes). If mock passes but real fails, fix the
  `module.path:function` in `--adapter-spec` and confirm the adapter runs **inside the isolated
  environment** against synthetic data only. A non-empty `Twin Evaluation Record – Pilot – v1` is
  Gate 2.

## Real adapter import error

- **Symptom:** `ERROR loading real adapter: ...` (bad module/function, or the callable raises).
- **Cause:** `--adapter-spec` not in `module.path:function` form, module not on `PYTHONPATH`, or the
  AI callable errors on the twin's input shape.
- **Resolution:** Verify the adapter contract matches `Twin AI Plug-In Contract – Pilot – v1` (input
  and output shapes). Ensure the module is importable from the run directory. Keep the AI behind a
  thin adapter so twin↔AI shape mismatches are fixed in one place.

## Fidelity gate NOT MET

- **Symptom:** `twin_fidelity_report.py` marks one or more metrics `FAIL` (distance over threshold),
  or reports uncovered use cases.
- **Cause:** The synthetic population/events diverge from the `Twin Reference Profile – Pilot – v1`
  beyond the agreed threshold, or a pilot use case has no scenario.
- **Resolution:** Tune the synthetic feed or event dynamics toward the reference and re-run; or, if
  the threshold is genuinely too tight, re-agree it with the metric owner in
  `Twin Acceptance Gates – Pilot – v1`. Author a scenario for any uncovered use case. Never accept an
  out-of-threshold twin silently.

## "Observed value not found" in the fidelity report

- **Symptom:** A metric row shows `observed: None` / `observed value not found`.
- **Cause:** The reference profile's `observed_key` path doesn't exist in the run log, or no
  `--run-log` was supplied.
- **Resolution:** Pass the committed `Twin Simulation Run – Pilot – v1.json` via `--run-log`, and
  align each metric's `observed_key` to a real path in that run log (e.g. `event_counts.admit`).

## Privacy check FAIL

- **Symptom:** `twin_privacy_validate.py` reports a `FAIL` on the leakage guard, exact-match, or
  k-anonymity check.
- **Cause:** Real-PHI markers present; a synthetic record exactly copies a reference record; or a
  quasi-identifier combination occurs fewer than *k* times.
- **Resolution:** Remediate the synthetic source (remove markers; increase generation diversity;
  generalize/suppress rare quasi-identifiers or raise the population). Re-run until every check
  PASSes, then hand `Twin Privacy Validation – Pilot – v1` to the privacy office — **the technical
  PASS is evidence, not acceptance**; residual-risk acceptance is their determination.

## Non-reproducible results with the same seed

- **Symptom:** Re-running with the same `seed` yields a different population or event stream (Test 6
  fail).
- **Cause:** A non-seeded source of randomness, or the config's `seed` changed between runs.
- **Resolution:** Confirm `seed` in `Twin Scope Config – Pilot – v1` is fixed and that any custom
  adapter is deterministic for the mock path. Reproducibility is what makes the twin a regression
  harness — fix it before comparing AI versions.

## Gate passed but production use is being assumed

- **Symptom:** Stakeholders read a passing `Twin Evaluation Record – Pilot – v1` as authorization to
  deploy the AI to production.
- **Cause:** Misreading twin evidence as a production sign-off.
- **Resolution:** Restate the boundary: passing the twin is **necessary but not sufficient** and
  **informs** — does not replace — the human decision to authorize production. Production trust also
  requires the accountable owners' sign-off and post-rollout monitoring.
