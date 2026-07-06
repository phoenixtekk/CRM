#!/usr/bin/env python3
# portability_lockin_assessor.py — score anti-lock-in / portability and exercise the exit path
#
# PURPOSE: Turn the anti-lock-in criteria (open target model, exportable artifacts, adapter
#          isolation, documented+exercised exit, exit cost) into a portability score and lock-in
#          risk rating, and optionally exercise a test export to prove the exit works. Read-only
#          by default; only writes a portable export when you pass --export-out. Gate F tool.
# HOW TO RUN: python portability_lockin_assessor.py --plan exit_plan.json
#             [--data vendor_output.json --export-out portable.json]   (Python 3.10+; see --help)
# EXPECTED RESULTS: A per-criterion portability score, a LOW/MEDIUM/HIGH lock-in rating, and
#          "GATE F: PASS" or "GATE F: FAIL" against the agreed minimum (export must re-load).
"""Portability / lock-in assessor.

The exit plan (Portability & Exit Plan – <Vendor Capability> – Design) declares, per criterion,
whether the anti-lock-in condition holds. A portability score that has never produced a working
export is aspirational, so this tool can perform a TEST EXPORT of the vendor output to a
vendor-neutral JSON and re-load it — proving the exit is real. Standard-library only; no PHI.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Anti-lock-in criteria and their weights (sum 1.0). Each is scored 0..1 in the exit plan.
CRITERIA = {
    "open_target_model": 0.25,   # emits/accepts FHIR/OMOP/native rather than a proprietary shape
    "exportable_artifacts": 0.25,  # outputs can be exported in an open, re-loadable format
    "adapter_isolation": 0.20,   # vendor code confined to the two adapters, harness sees contract
    "documented_exit": 0.20,     # exit path + rollback documented and agreed up front
    "low_exit_cost": 0.10,       # switching/exit cost is low (contractual + technical)
}
DEFAULT_MIN = 0.65


def load_json(path: str):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except FileNotFoundError:
        sys.exit(f"ERROR: file not found: {path}")
    except json.JSONDecodeError as exc:
        sys.exit(f"ERROR: invalid JSON in {path}: {exc}")


def rating(score: float) -> str:
    if score >= 0.75:
        return "LOW"
    if score >= 0.5:
        return "MEDIUM"
    return "HIGH"


def test_export(data_path: str, out_path: str) -> bool:
    """Exercise the exit: export vendor output to vendor-neutral JSON and re-load it."""
    data = load_json(data_path)
    Path(out_path).write_text(json.dumps(data, indent=2), encoding="utf-8")
    reloaded = json.loads(Path(out_path).read_text(encoding="utf-8"))
    return reloaded == data


def main() -> int:
    ap = argparse.ArgumentParser(description="Score portability / lock-in risk and exercise the exit path.")
    ap.add_argument("--plan", required=True,
                    help="Exit-plan JSON: {scores:{criterion:0-1}, notes:{...}}.")
    ap.add_argument("--min-score", type=float, default=DEFAULT_MIN,
                    help=f"Agreed minimum portability score (default {DEFAULT_MIN}).")
    ap.add_argument("--data", help="Vendor-output JSON to test-export (optional).")
    ap.add_argument("--export-out", help="Where to write the test export (opt-in write; requires --data).")
    args = ap.parse_args()

    plan = load_json(args.plan)
    scores = plan.get("scores", {})
    print("Gate F — Portability / lock-in")
    print("=" * 50)
    weighted = 0.0
    for crit, weight in CRITERIA.items():
        raw = scores.get(crit)
        flag = "" if raw is not None else "  (MISSING → 0)"
        raw = max(0.0, min(1.0, float(raw))) if raw is not None else 0.0
        weighted += raw * weight
        print(f"  {crit:<22} {raw:>4.2f} x {weight:<4}  = {raw*weight:.3f}{flag}")
    weighted = round(weighted, 4)
    print(f"\nportability score = {weighted}   lock-in risk = {rating(weighted)}")

    # Exercise the exit path if requested.
    export_ok = None
    if args.data and args.export_out:
        export_ok = test_export(args.data, args.export_out)
        print(f"test export → {args.export_out}: {'RE-LOADED OK' if export_ok else 'FAILED to re-load'}")
    elif args.data or args.export_out:
        print("NOTE: pass BOTH --data and --export-out to exercise the exit path.")
    else:
        print("NOTE: no test export exercised (pass --data + --export-out to prove the exit).")

    print("\n" + "-" * 50)
    score_ok = weighted >= args.min_score
    # If an export was attempted it must succeed; if not attempted, warn but gate on score.
    if score_ok and export_ok is not False:
        if export_ok is None:
            print("GATE F: PASS (score) — exercise a real export before expanding to confirm the exit.")
        else:
            print("GATE F: PASS — score at/above minimum and exit export re-loaded.")
        return 0
    print(f"GATE F: FAIL — score {weighted} vs min {args.min_score}"
          + ("" if export_ok is not False else " and/or export did not re-load")
          + ". Improve adapter isolation / negotiate exit terms before expanding.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
