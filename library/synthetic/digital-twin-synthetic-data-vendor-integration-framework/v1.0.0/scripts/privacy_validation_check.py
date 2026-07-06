#!/usr/bin/env python3
# privacy_validation_check.py — disclosure-risk check on vendor-produced synthetic output
#
# PURPOSE: Check that vendor-produced SYNTHETIC output does not reproduce real records and that
#          uniqueness / k-anonymity signals on the agreed quasi-identifiers stay within the
#          agreed threshold. Read-only evidence — it never writes data and the acceptance
#          decision is deferred to privacy/compliance. This is the Gate E tool.
# HOW TO RUN: python privacy_validation_check.py --data synth.csv --quasi-identifiers age,sex,zip3
#             [--reference ref.csv] [--k 5]   (Python 3.10+; see --help)
# EXPECTED RESULTS: Counts of exact real-record matches and below-k records, ending in
#          "GATE E: PASS" or "GATE E: FAIL". A PASS is evidence, NOT a compliance determination.
"""Privacy / disclosure-risk validation check.

Compares synthetic vendor output to a READ-ONLY, minimized reference (never load real PHI into
the shared harness — point --reference at a governed read-only copy under your privacy
controls, or omit it to run uniqueness-only). Standard-library CSV only. This tool produces
EVIDENCE; the regulatory de-identification / disclosure-risk ACCEPTANCE is deferred to the
organization's privacy, compliance, and legal functions.
"""
from __future__ import annotations

import argparse
import csv
import sys
from collections import Counter
from pathlib import Path


def read_csv(path: str) -> list[dict]:
    try:
        with open(path, newline="", encoding="utf-8") as fh:
            return list(csv.DictReader(fh))
    except FileNotFoundError:
        sys.exit(f"ERROR: file not found: {path}")


def qi_key(row: dict, qis: list[str]) -> tuple:
    return tuple((row.get(q) or "").strip() for q in qis)


def main() -> int:
    ap = argparse.ArgumentParser(description="Disclosure-risk check on synthetic vendor output (evidence only).")
    ap.add_argument("--data", required=True, help="Synthetic vendor-output CSV.")
    ap.add_argument("--quasi-identifiers", required=True,
                    help="Comma-separated quasi-identifier columns agreed with privacy/governance.")
    ap.add_argument("--reference", help="READ-ONLY minimized reference CSV (governed). Omit for uniqueness-only.")
    ap.add_argument("--k", type=int, default=5, help="Agreed minimum k for k-anonymity (default 5).")
    args = ap.parse_args()

    qis = [c.strip() for c in args.quasi_identifiers.split(",") if c.strip()]
    if not qis:
        sys.exit("ERROR: at least one quasi-identifier is required.")
    data = read_csv(args.data)
    if not data:
        sys.exit("ERROR: --data is empty.")
    missing = [q for q in qis if q not in data[0]]
    if missing:
        sys.exit(f"ERROR: quasi-identifier column(s) not in data: {missing}")

    print("Gate E — Privacy / disclosure-risk validation")
    print("=" * 50)
    print(f"records={len(data)}  quasi-identifiers={qis}  k={args.k}")

    # 1) k-anonymity / uniqueness on the QI combination
    groups = Counter(qi_key(r, qis) for r in data)
    below_k = {key: n for key, n in groups.items() if n < args.k}
    uniques = sum(1 for n in groups.values() if n == 1)
    print(f"\nuniqueness: {uniques} unique QI-combination record(s)")
    print(f"k-anonymity: {len(below_k)} QI group(s) below k={args.k}")

    # 2) exact-match against the read-only reference (memorization / leakage check)
    exact_matches = 0
    if args.reference:
        ref = read_csv(args.reference)
        ref_keys = Counter(qi_key(r, qis) for r in ref)
        for key, n in groups.items():
            if key in ref_keys:
                exact_matches += n
        print(f"exact QI-match against reference: {exact_matches} synthetic record(s)")
    else:
        print("exact-match: skipped (no --reference; uniqueness-only run)")

    fail = (exact_matches > 0) or (len(below_k) > 0)
    print("\n" + "-" * 50)
    if fail:
        print("GATE E: FAIL — quarantine the output; escalate to privacy/governance.")
        print("(Threshold breach is evidence to review; acceptance is a privacy/legal decision.)")
        return 1
    print("no exact real-record matches; all QI groups at/above k")
    print("GATE E: PASS  (evidence only — final acceptance deferred to privacy/compliance/legal)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
