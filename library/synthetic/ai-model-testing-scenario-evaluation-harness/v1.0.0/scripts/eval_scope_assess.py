#!/usr/bin/env python3
# eval_scope_assess.py — profile readiness/scope for the AI evaluation harness (read-only).
#
# PURPOSE: Assess whether the environment is ready to run scenario-based AI model evaluation on
#          synthetic/twin data — models under test, target data model, isolated environment, use
#          cases, and a results store — and write an "Eval Readiness Report - <scope> - v1". Read-only.
# HOW TO RUN: python eval_scope_assess.py --scope pilot --out reports/   (Python 3.10+; see --help)
# EXPECTED RESULTS: A readiness report (JSON) + a console summary; PASS if no blocking gaps, otherwise
#                   FAIL listing each gap. Exit code 0 = ready, 1 = gaps found. Writes nothing but the
#                   report (never real PHI).

import argparse
import datetime as dt
import json
import os
import sys

# The readiness checklist. Each item maps a solution/global requirement to an evidence key the
# operator supplies via an intake JSON (or answers interactively). Nothing here touches real data.
CHECKS = [
    ("python_env", "Supported Python data/engineering environment available", True),
    ("target_data_model", "Target clinical data model in scope (FHIR / OMOP / native)", True),
    ("isolated_env", "Isolated non-production environment (no real-PHI systems attached)", True),
    ("mut_adapter", "At least one Model Under Test reachable via a predict() adapter (R1)", True),
    ("ground_truth", "Ground truth / expected behavior defined per scenario (R2)", True),
    ("metrics_thresholds", "Evaluation metrics + PASS thresholds agreed up front (R3)", True),
    ("synthetic_data", "Synthetic/twin test data mapped to scenarios, contains NO real PHI (R4)", True),
    ("results_store", "Writable, access-controlled run/baseline store (R5)", True),
    ("reproducibility", "Seeds pinned + model version + data snapshot recorded (R6)", False),
]


def load_intake(path):
    if not path:
        return {}
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def assess(intake):
    results = []
    for key, desc, blocking in CHECKS:
        val = intake.get(key)
        # Truthiness: an intake value that is present and truthy = satisfied.
        satisfied = bool(val)
        results.append(
            {
                "check": key,
                "description": desc,
                "blocking": blocking,
                "satisfied": satisfied,
                "evidence": val if satisfied else None,
            }
        )
    return results


def main(argv=None):
    p = argparse.ArgumentParser(
        description="Profile readiness/scope for scenario-based AI model evaluation (read-only)."
    )
    p.add_argument("--scope", default="pilot", help="Scope label for the report (e.g. pilot).")
    p.add_argument(
        "--intake",
        help="Path to an intake JSON providing evidence per check. If omitted, all checks are "
        "reported as UNKNOWN/unsatisfied (nothing is assumed).",
    )
    p.add_argument("--out", default="reports/", help="Directory to write the readiness report into.")
    p.add_argument(
        "--print-template",
        action="store_true",
        help="Print a blank intake template and exit (no files written).",
    )
    args = p.parse_args(argv)

    if args.print_template:
        template = {key: "" for key, _, _ in CHECKS}
        print(json.dumps(template, indent=2))
        return 0

    intake = load_intake(args.intake)
    results = assess(intake)

    blocking_gaps = [r for r in results if r["blocking"] and not r["satisfied"]]
    advisory_gaps = [r for r in results if not r["blocking"] and not r["satisfied"]]
    ready = not blocking_gaps

    report = {
        "artifact": f"Eval Readiness Report - {args.scope} - v1",
        "generated_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "scope": args.scope,
        "ready": ready,
        "blocking_gap_count": len(blocking_gaps),
        "advisory_gap_count": len(advisory_gaps),
        "checks": results,
        "note": "Read-only assessment. Regulatory/legal determinations are deferred to "
        "privacy/compliance/legal. Never place real PHI in the shared harness.",
    }

    os.makedirs(args.out, exist_ok=True)
    out_path = os.path.join(args.out, f"eval-readiness-{args.scope}.json")
    with open(out_path, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2)

    print(f"Eval Readiness Report - {args.scope} - v1")
    print(f"  written: {out_path}")
    for r in results:
        mark = "OK " if r["satisfied"] else ("XX " if r["blocking"] else ".. ")
        print(f"  [{mark}] {r['check']}: {r['description']}")
    if blocking_gaps:
        print(f"\nFAIL: {len(blocking_gaps)} blocking gap(s) — resolve before evaluating.")
    else:
        print("\nPASS: no blocking gaps.")
        if advisory_gaps:
            print(f"  ({len(advisory_gaps)} advisory item(s) recommended before scoring.)")
    return 0 if ready else 1


if __name__ == "__main__":
    sys.exit(main())
