#!/usr/bin/env python3
# regression_check.py — compare a Run Record to the approved baseline and verify the safety boundary.
#
# PURPOSE: Detect quality REGRESSIONS by comparing a new Evaluation Run's aggregated metrics against
#          the approved Evaluation Baseline (within a tolerance), and validate the run stayed inside
#          the isolated, no-real-PHI boundary. Guards against silent degradation from a model, prompt,
#          or data change.
# HOW TO RUN: python regression_check.py --config harness/config.pilot.json --run reports/runs/<id>.json
#             (Python 3.10+; see --help)
# EXPECTED RESULTS: Console PASS/FAIL listing any regressed metric. Exit 0 = no regression + boundary
#                   ok, 1 = regression detected or boundary violated. Reads only artifacts; no real PHI.

import argparse
import datetime as dt
import json
import os
import sys


def load_json(path):
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


# Direction per metric: 'min' => higher is better (a drop is a regression);
#                       'max' => lower is better (a rise is a regression).
DEFAULT_DIRECTIONS = {
    "normalized_match": "min",
    "contains": "min",
    "task_score": "min",
    "latency_ms_p95": "max",
    "safety_flag_rate": "max",
}


def is_regression(name, baseline_val, new_val, tolerance, directions):
    if baseline_val is None or new_val is None:
        return False
    direction = directions.get(name, "min")
    if direction == "min":
        # regression if new is worse (lower) than baseline beyond tolerance
        return new_val < (baseline_val - tolerance)
    # 'max': regression if new is worse (higher) than baseline beyond tolerance
    return new_val > (baseline_val + tolerance)


def main(argv=None):
    p = argparse.ArgumentParser(description="Compare a Run Record to the approved baseline.")
    p.add_argument("--config", required=True, help="Harness config JSON (holds baseline pointer).")
    p.add_argument("--run", required=True, help="New Evaluation Run record JSON to check.")
    p.add_argument("--baseline", help="Override baseline run path (else read from config).")
    p.add_argument(
        "--tolerance",
        type=float,
        default=None,
        help="Absolute tolerance before a delta counts as a regression (else config or 0.0).",
    )
    args = p.parse_args(argv)

    config = load_json(args.config)
    run = load_json(args.run)

    baseline_path = args.baseline or config.get("baseline_run")
    if not baseline_path:
        print("FAIL: no baseline configured. Set one with harness_config.py set-baseline.")
        return 1
    if not os.path.exists(baseline_path):
        print(f"FAIL: baseline run not found: {baseline_path}")
        return 1

    baseline = load_json(baseline_path)
    tolerance = args.tolerance if args.tolerance is not None else float(config.get("regression_tolerance", 0.0))
    directions = {**DEFAULT_DIRECTIONS, **config.get("metric_directions", {})}

    base_aggs = baseline.get("summary", {}).get("aggregates", {})
    new_aggs = run.get("summary", {}).get("aggregates", {})

    regressions = []
    comparisons = []
    for name, base_val in base_aggs.items():
        new_val = new_aggs.get(name)
        reg = is_regression(name, base_val, new_val, tolerance, directions)
        comparisons.append({"metric": name, "baseline": base_val, "new": new_val, "regression": reg})
        if reg:
            regressions.append(name)

    # Safety-boundary check: the run must attest synthetic-only and carry no real-PHI flag.
    note = str(run.get("note", "")).lower()
    boundary_ok = (not bool(run.get("real_phi_present", False))) and (
        "never real phi" in note or "synthetic" in note
    )

    print(f"Regression Check - baseline {baseline.get('run_id')} vs run {run.get('run_id')}")
    print(f"  tolerance: {tolerance}")
    for c in comparisons:
        mark = "REGRESSED" if c["regression"] else "ok"
        print(f"  [{mark}] {c['metric']}: baseline={c['baseline']} new={c['new']}")
    print(f"  [{'ok' if boundary_ok else 'VIOLATED'}] safety boundary (synthetic-only, no real PHI)")

    passed = (not regressions) and boundary_ok
    if passed:
        print(f"\nPASS: no regression against baseline; boundary intact ({dt.date.today()}).")
        return 0
    if regressions:
        print(f"\nFAIL: {len(regressions)} metric(s) regressed: {', '.join(regressions)}")
    if not boundary_ok:
        print("FAIL: safety boundary not attested — STOP; run may have touched real PHI.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
