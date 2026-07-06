#!/usr/bin/env python3
# vendor_evaluation_scorecard.py — score & rank candidate digital-twin / synthetic-data vendors
#
# PURPOSE: Score candidate vendors against agreed weighted criteria (fidelity, privacy,
#          interoperability, portability, support, cost) and rank them, flagging missing
#          evidence. Read-only by default; only writes a scorecard when you pass --out.
# HOW TO RUN: python vendor_evaluation_scorecard.py --candidates candidates.json
#             [--criteria criteria.json] [--out scorecard.json]   (Python 3.10+; see --help)
# EXPECTED RESULTS: A ranked table on stdout with each vendor's weighted score, per-criterion
#          breakdown, missing-evidence flags, and PASS/BELOW-THRESHOLD against the agreed
#          minimum. No files are written unless --out is given.
"""Vendor evaluation scorecard.

Inputs are plain JSON so the tool is standard-library-only. All scoring is transparent and
deterministic; it produces evidence for a human selection decision, not a decision itself.
Vendor capabilities are treated at the pattern level — this tool scores what you can observe
(sample output, docs, export terms), it does not probe vendor internals.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Default criteria + weights (must sum to 1.0). Override with --criteria to match the weights
# your technical + governance stakeholders agreed BEFORE scoring (see Requirements §4).
DEFAULT_CRITERIA = {
    "fidelity": 0.20,
    "privacy_posture": 0.20,
    "interoperability": 0.20,
    "portability": 0.20,
    "support": 0.10,
    "cost": 0.10,
}
DEFAULT_MIN_SCORE = 0.60  # agreed minimum weighted score to clear Gate A selection.
SCORE_MIN, SCORE_MAX = 0.0, 1.0


def load_json(path: str):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except FileNotFoundError:
        sys.exit(f"ERROR: file not found: {path}")
    except json.JSONDecodeError as exc:
        sys.exit(f"ERROR: invalid JSON in {path}: {exc}")


def normalize_weights(criteria: dict) -> dict:
    total = sum(criteria.values())
    if total <= 0:
        sys.exit("ERROR: criteria weights must sum to a positive number.")
    if abs(total - 1.0) > 1e-6:
        print(f"NOTE: weights sum to {total:.3f}; normalizing to 1.0.", file=sys.stderr)
        criteria = {k: v / total for k, v in criteria.items()}
    return criteria


def score_vendor(vendor: dict, criteria: dict) -> dict:
    scores = vendor.get("scores", {})
    weighted = 0.0
    missing = []
    per_criterion = {}
    for crit, weight in criteria.items():
        raw = scores.get(crit)
        if raw is None:
            # Missing evidence is a signal, not a neutral gap: treat as 0 and flag it.
            missing.append(crit)
            raw = 0.0
        raw = max(SCORE_MIN, min(SCORE_MAX, float(raw)))
        per_criterion[crit] = round(raw, 3)
        weighted += raw * weight
    return {
        "vendor": vendor.get("name", "<unnamed>"),
        "weighted_score": round(weighted, 4),
        "per_criterion": per_criterion,
        "missing_evidence": missing,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Score & rank candidate synthetic-data / digital-twin vendors.")
    ap.add_argument("--candidates", required=True,
                    help="JSON: list of {name, scores:{criterion:0-1}} objects.")
    ap.add_argument("--criteria", help="JSON: {criterion: weight}. Defaults to the house weights.")
    ap.add_argument("--min-score", type=float, default=DEFAULT_MIN_SCORE,
                    help=f"Agreed minimum weighted score (default {DEFAULT_MIN_SCORE}).")
    ap.add_argument("--out", help="Optional path to write the ranked scorecard JSON (opt-in write).")
    args = ap.parse_args()

    criteria = normalize_weights(load_json(args.criteria) if args.criteria else dict(DEFAULT_CRITERIA))
    candidates = load_json(args.candidates)
    if not isinstance(candidates, list) or not candidates:
        sys.exit("ERROR: --candidates must be a non-empty JSON list.")

    results = [score_vendor(v, criteria) for v in candidates]
    results.sort(key=lambda r: r["weighted_score"], reverse=True)

    print("Vendor Evaluation – Candidate Set – Assess")
    print("=" * 60)
    print(f"Criteria weights: {json.dumps(criteria)}")
    print(f"Minimum score for selection (Gate A): {args.min_score}\n")
    print(f"{'rank':<5}{'vendor':<26}{'score':<9}{'result':<16}missing")
    print("-" * 72)
    for i, r in enumerate(results, 1):
        verdict = "PASS" if r["weighted_score"] >= args.min_score else "BELOW-THRESHOLD"
        miss = ",".join(r["missing_evidence"]) or "-"
        print(f"{i:<5}{r['vendor'][:25]:<26}{r['weighted_score']:<9.3f}{verdict:<16}{miss}")

    passing = [r for r in results if r["weighted_score"] >= args.min_score]
    print(f"\n{len(passing)} of {len(results)} candidate(s) clear the agreed minimum.")
    if not passing:
        print("Gate A: NO candidate clears the threshold — revisit the candidate set.")

    if args.out:
        payload = {
            "artifact": "Vendor Evaluation – Candidate Set – Assess",
            "criteria": criteria,
            "min_score": args.min_score,
            "ranked": results,
        }
        Path(args.out).write_text(json.dumps(payload, indent=2), encoding="utf-8")
        print(f"\nWrote scorecard to {args.out}")
    else:
        print("\n(read-only run — pass --out to persist the scorecard)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
