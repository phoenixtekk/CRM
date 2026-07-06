#!/usr/bin/env python3
# metrics_reporter.py — aggregate a Run Record and enforce the Evaluation Gate Policy (PASS/FAIL).
#
# PURPOSE: Read an Evaluation Run record, apply the Evaluation Gate Policy (coverage, quality, and
#          privacy gates), and write an "Evaluation Gate Report". The gate decision is the pass/fail
#          signal a release hangs on; the process EXITS NON-ZERO on FAIL so it can gate a pipeline.
# HOW TO RUN: python metrics_reporter.py --run reports/runs/<id>.json --gates gates.json --out reports/
#             (Python 3.10+; see --help)
# EXPECTED RESULTS: A gate report (JSON) + console PASS/FAIL with breaching metrics listed.
#                   Exit 0 = PASS, 1 = FAIL. Reads only run/gate artifacts; writes no real PHI.

import argparse
import datetime as dt
import json
import os
import sys


def load_json(path):
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def check_threshold(value, threshold, direction):
    """direction: 'min' => value must be >= threshold; 'max' => value must be <= threshold."""
    if value is None:
        return False
    if direction == "min":
        return value >= threshold
    if direction == "max":
        return value <= threshold
    raise ValueError(f"unknown direction '{direction}'")


def evaluate_gates(run, gates):
    summary = run.get("summary", {})
    aggregates = summary.get("aggregates", {})
    results = []

    # --- Coverage gate: every scenario must have executed (within tolerance) ---
    scenario_count = summary.get("scenario_count", 0)
    errored = summary.get("errored", 0)
    max_errored = gates.get("coverage", {}).get("max_errored", 0)
    coverage_pass = errored <= max_errored
    results.append(
        {
            "gate": "coverage",
            "detail": f"errored {errored} of {scenario_count} (allowed {max_errored})",
            "pass": coverage_pass,
        }
    )

    # --- Quality gates: each configured metric vs its threshold ---
    for m in gates.get("quality", []):
        name = m["metric"]
        val = aggregates.get(name)
        ok = check_threshold(val, m["threshold"], m["direction"])
        results.append(
            {
                "gate": f"quality:{name}",
                "detail": f"value={val} {m['direction']} threshold={m['threshold']}",
                "pass": ok,
            }
        )

    # --- Privacy gate: run must declare it operated only on synthetic/twin data ---
    # The technical control: the run record carries the synthetic-only note and no real-PHI flag.
    # (Disclosure-risk DETERMINATION is deferred to privacy/compliance/legal — not decided here.)
    privacy_required = gates.get("privacy", {}).get("require_synthetic_only", True)
    note = str(run.get("note", "")).lower()
    real_phi_flag = bool(run.get("real_phi_present", False))
    privacy_pass = (not real_phi_flag) and ("never real phi" in note or "synthetic" in note) if privacy_required else True
    results.append(
        {
            "gate": "privacy",
            "detail": "run declares synthetic/twin-only and no real-PHI flag"
            if privacy_pass
            else "run does NOT attest synthetic-only / real-PHI flag set — STOP",
            "pass": privacy_pass,
        }
    )

    overall = all(r["pass"] for r in results)
    return overall, results


def main(argv=None):
    p = argparse.ArgumentParser(description="Aggregate a Run Record and enforce the Gate Policy.")
    p.add_argument("--run", required=True, help="Evaluation Run record JSON.")
    p.add_argument("--gates", required=True, help="Evaluation Gate Policy JSON.")
    p.add_argument("--out", default="reports/", help="Directory to write the gate report into.")
    args = p.parse_args(argv)

    run = load_json(args.run)
    gates = load_json(args.gates)

    overall, results = evaluate_gates(run, gates)

    report = {
        "artifact": f"Evaluation Gate Report - {run.get('scope', 'pilot')} - v1",
        "generated_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "run_id": run.get("run_id"),
        "scenario_suite_version": run.get("scenario_suite_version"),
        "metric_set_version": run.get("metric_set_version"),
        "model_version": run.get("model_version"),
        "overall": "PASS" if overall else "FAIL",
        "gates": results,
        "rollback_rule": gates.get(
            "rollback_rule",
            "Any hard-gate FAIL blocks promotion; retain the run + report for diagnosis.",
        ),
    }

    os.makedirs(args.out, exist_ok=True)
    out_path = os.path.join(args.out, f"gate-report-{run.get('run_id', 'run')}.json")
    with open(out_path, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2)

    print(report["artifact"])
    print(f"  run: {run.get('run_id')}  written: {out_path}")
    for r in results:
        print(f"  [{'PASS' if r['pass'] else 'FAIL'}] {r['gate']}: {r['detail']}")
    print(f"\nOVERALL: {report['overall']}")
    if not overall:
        print("  Rollback: " + report["rollback_rule"])
    return 0 if overall else 1


if __name__ == "__main__":
    sys.exit(main())
