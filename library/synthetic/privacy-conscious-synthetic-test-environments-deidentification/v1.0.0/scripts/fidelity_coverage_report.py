#!/usr/bin/env python3
# fidelity_coverage_report.py — check that utility survived de-identification vs. an agreed reference
#
# PURPOSE: Fidelity/coverage report. Compares the candidate dataset's per-column MARGINAL distributions
#          and category COVERAGE against an agreed reference-statistics file, reporting per-field
#          divergence and an overall PASS/FAIL within a tolerance — so over-generalization that destroys
#          analytic utility is caught before release. Uses AGGREGATE reference stats, never real records.
# HOW TO RUN: python fidelity_coverage_report.py --synthetic deidentified-pilot-v1.csv --reference ref-stats.json --out fidelity-pilot-v1.json
# EXPECTED RESULTS: JSON + stdout with per-field distances, coverage gaps, and an overall PASS/FAIL vs.
#          --tolerance. FAIL means utility likely collapsed — revisit the privacy/utility trade-off.
#
# Standard-library only. The --reference file holds AGGREGATE stats (category proportions / numeric
# summaries), not real individual records. No network, no secrets, no PHI. Read-only on inputs.
#
# Reference file shape (example):
# { "fields": { "sex": {"type":"categorical","proportions":{"M":0.49,"F":0.51}},
#               "age_band": {"type":"categorical","proportions":{"0-9":0.1,"10-19":0.12, ...}} } }

import argparse
import csv
import json
import sys
from collections import Counter


def _load_json(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def _read(path):
    with open(path, newline="", encoding="utf-8-sig") as fh:
        return list(csv.DictReader(fh))


def _proportions(values):
    total = len(values)
    if total == 0:
        return {}
    return {k: v / total for k, v in Counter(values).items()}


def _tvd(p, q):
    """Total-variation distance between two categorical distributions (0 identical .. 1 disjoint)."""
    keys = set(p) | set(q)
    return 0.5 * sum(abs(p.get(k, 0.0) - q.get(k, 0.0)) for k in keys)


def main(argv=None):
    p = argparse.ArgumentParser(description="Check that utility survived de-identification vs. an agreed aggregate reference.")
    p.add_argument("--synthetic", required=True,
                   help="Candidate de-identified/synthetic CSV (read-only).")
    p.add_argument("--reference", required=True,
                   help="Agreed AGGREGATE reference-statistics JSON (no real records).")
    p.add_argument("--tolerance", type=float, default=0.15,
                   help="Max acceptable total-variation distance per field (default 0.15).")
    p.add_argument("--min-coverage", type=float, default=0.9, dest="min_coverage",
                   help="Min share of reference categories that must appear (default 0.9).")
    p.add_argument("--out", help="Write JSON report here; default stdout.")
    args = p.parse_args(argv)

    rows = _read(args.synthetic)
    ref = _load_json(args.reference).get("fields", {})
    if not rows:
        raise SystemExit("ERROR: synthetic input has no data rows.")

    field_results = {}
    for field, spec in ref.items():
        col = [r.get(field, "") for r in rows if r.get(field, "") != ""]
        ref_props = spec.get("proportions", {})
        cand_props = _proportions(col)
        tvd = round(_tvd(ref_props, cand_props), 4)
        ref_cats = set(ref_props)
        covered = ref_cats & set(cand_props)
        coverage = round(len(covered) / len(ref_cats), 4) if ref_cats else 1.0
        field_results[field] = {
            "tvd": tvd,
            "coverage": coverage,
            "tvd_pass": tvd <= args.tolerance,
            "coverage_pass": coverage >= args.min_coverage,
            "missing_categories": sorted(ref_cats - covered),
        }

    passes = [f for r in field_results.values() for f in (r["tvd_pass"], r["coverage_pass"])]
    overall = all(passes) if field_results else False
    score = round(sum(1 for x in passes if x) / len(passes), 3) if passes else 0.0

    report = {
        "artifact": "Fidelity / Coverage Report – Pilot – v1",
        "synthetic_file": args.synthetic,
        "reference_file": args.reference,
        "tolerance": args.tolerance,
        "min_coverage": args.min_coverage,
        "fields": field_results,
        "overall_score": score,
        "pass": overall,
        "note": "Utility check only. A fidelity FAIL is a privacy/utility trade-off decision, not "
                "necessarily a privacy failure.",
    }

    text = json.dumps(report, indent=2)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(text)
        print(f"[written] {args.out}")

    print(f"Fidelity/coverage vs. reference ({len(field_results)} fields):")
    for field, r in field_results.items():
        flag = "PASS" if (r["tvd_pass"] and r["coverage_pass"]) else "FAIL"
        print(f"  {field:20s} tvd={r['tvd']:<6} coverage={r['coverage']:<6} {flag}")
    print(f"\nOVERALL: {'PASS' if overall else 'FAIL'}  (score {score})")
    return 0 if overall else 1


if __name__ == "__main__":
    sys.exit(main())
