# Testing & Validation

These procedures validate the hospital twin and the AI evaluation it produces. Run them against the
named artifacts from `03-implementation.md` (the `– Pilot – v1` set). Each has an explicit
**pass/fail**. The three acceptance gates in `Twin Acceptance Gates – Pilot – v1` are the release
signal for the pilot.

> All validation runs in the **isolated non-production environment**. Privacy-check **acceptance**
> is a privacy-office determination; the tools provide evidence only.

## Test 1 — Twin build integrity (does it stand up?)

- **Procedure:** Run the simulator in dry-run against the config and feed:
  `python scripts/twin_simulator.py --config "Twin Scope Config - Pilot - v1.json" --feed "Synthetic Feed Binding - Pilot - v1" --dry-run`.
- **Expected PASS:** The plan reports the configured population size (±0), all in-scope domains
  present, a valid event plan, and **no real-PHI markers** detected in the feed.
- **FAIL:** Missing domains, zero population, an unparseable feed, or any real-PHI marker. Do not
  proceed — see `06-troubleshooting.md`.

## Test 2 — Scenario executes end-to-end (Gate 2)

- **Procedure:** Run one scenario with the **mock** AI adapter and `--commit`:
  `python scripts/twin_scenario_runner.py --config "Twin Scope Config - Pilot - v1.json" --scenario "Twin Scenario Suite - Pilot - v1/sepsis-alert.json" --ai-adapter mock --commit`.
- **Expected PASS:** The twin advances through every scenario event, the AI plug-in is invoked at
  each plug-in point, outputs are captured, and a non-empty `Twin Evaluation Record – Pilot – v1`
  is written.
- **FAIL:** The run aborts, the plug-in is never invoked, or the record is empty. This is **Gate 2**
  — fix before validation.

## Test 3 — Fidelity & coverage (fidelity gate)

- **Procedure:** `python scripts/twin_fidelity_report.py --config "Twin Scope Config - Pilot - v1.json" --reference "Twin Reference Profile - Pilot - v1.json" --out "Twin Fidelity Report - Pilot - v1.html"`.
- **Expected PASS:** Every in-scope metric's distance to the reference profile is **within** its
  threshold in `Twin Acceptance Gates – Pilot – v1`, and scenario coverage meets the agreed minimum
  (every pilot use case exercised by ≥1 scenario).
- **FAIL:** Any metric exceeds its threshold, or a use case is uncovered. Refine the synthetic feed
  or dynamics and re-run; do not accept an out-of-threshold twin.

## Test 4 — Privacy validation (privacy gate)

- **Procedure:** `python scripts/twin_privacy_validate.py --config "Twin Scope Config - Pilot - v1.json" --dataset "Synthetic Feed Binding - Pilot - v1" --out "Twin Privacy Validation - Pilot - v1.json"`.
- **Expected PASS (technical):** Every check reports PASS — no exact-match records against any
  reference, quasi-identifier k-anonymity ≥ the configured *k*, and the **real-PHI leakage guard**
  finds no real-PHI markers. The report is then handed to the privacy office.
- **FAIL:** Any check FAIL — investigate and remediate the synthetic source before use. **A
  technical PASS is not an acceptance:** residual-disclosure-risk acceptance is the privacy office's
  determination.

## Test 5 — Scenario-based AI evaluation (scenario gate)

- **Procedure:** Run the full suite against the **real** AI adapter:
  `python scripts/twin_scenario_runner.py --config "Twin Scope Config - Pilot - v1.json" --scenario-suite "Twin Scenario Suite - Pilot - v1" --ai-adapter real --commit --out "Twin Evaluation Record - Pilot - v1.json"`.
- **Expected PASS:** The AI produces the expected/acceptable behavior for at least the threshold
  fraction of scenarios in `Twin Acceptance Gates – Pilot – v1`, and produces **no** unacceptable
  behavior on any scenario flagged critical.
- **FAIL:** Pass-rate below threshold, or any critical scenario yields the unacceptable behavior.
  The AI is **not** ready for broader adoption; return findings to the AI team.

## Test 6 — Reproducibility

- **Procedure:** Re-run Test 2 with the **same seed** from `Twin Scope Config – Pilot – v1`.
- **Expected PASS:** Identical population and event sequence, and an identical evaluation record for
  a deterministic AI adapter (mock) — proving the twin is reproducible for regression testing.
- **FAIL:** Divergent results with the same seed — a non-determinism bug; fix before relying on
  regression comparisons.

## Release signal

The pilot is **validated** only when Tests 1–6 PASS **and** all three gates in
`Twin Acceptance Gates – Pilot – v1` are met (fidelity within threshold, every privacy check PASS
with privacy-office acceptance, scenario pass-rate ≥ threshold). Only then proceed to **Expand**.
