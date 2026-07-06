#!/usr/bin/env python3
# twin_privacy_validate.py — privacy/disclosure-risk validation for the twin's synthetic feed.
#
# PURPOSE: Runs technical disclosure-risk checks on the synthetic dataset feeding the twin — a
#          real-PHI leakage guard, exact-match/uniqueness against an optional reference, and
#          quasi-identifier k-anonymity — reporting PASS/FAIL per check. The tool provides EVIDENCE;
#          acceptance of residual disclosure risk is deferred to the privacy office.
# HOW TO RUN: python twin_privacy_validate.py --config "Twin Scope Config - Pilot - v1.json" \
#             --dataset synthetic.csv [--reference real_stats.csv] --k 5 \
#             --out "Twin Privacy Validation - Pilot - v1.json"       (Python 3.10+; see --help)
# EXPECTED RESULTS: Per-check PASS/FAIL and an overall technical verdict. Any FAIL => remediate the
#                   synthetic source. A technical PASS is NOT an acceptance (privacy-office decision).
#
# Safe by default: reads a synthetic dataset (CSV/JSONL) read-only; if a reference is supplied it is
# treated read-only and never copied. No real PHI is written anywhere. No network calls.

import argparse
import csv
import json
import os
import sys
from collections import Counter
from datetime import datetime, timezone

REAL_PHI_MARKERS = ("mrn_real", "ssn", "real_patient", "prod_pii", "live_phi")
# Default quasi-identifiers used for k-anonymity when present in the dataset header.
DEFAULT_QIDS = ("age", "sex", "zip", "zip3", "race", "admit_date")


def _now():
    return datetime.now(timezone.utc).isoformat()


def read_rows(path):
    """Read CSV or JSONL into a list of dicts (synthetic data only)."""
    if not os.path.exists(path):
        return None, f"dataset not found: {path}"
    rows = []
    if path.lower().endswith((".jsonl", ".ndjson")):
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if line:
                    rows.append(json.loads(line))
    else:  # default CSV
        with open(path, newline="", encoding="utf-8") as fh:
            rows = list(csv.DictReader(fh))
    return rows, None


def check_real_phi_markers(rows):
    """FAIL if any column name or value token matches a known real-PHI marker."""
    hits = set()
    for row in rows[:5000]:  # bounded scan
        for k, v in row.items():
            kl = str(k).lower()
            vl = str(v).lower()
            for marker in REAL_PHI_MARKERS:
                if marker in kl or marker in vl:
                    hits.add(marker)
    return {"check": "real_phi_leakage_guard", "pass": not hits,
            "detail": f"markers found: {sorted(hits)}" if hits else "no real-PHI markers"}


def check_exact_match(rows, ref_rows):
    """FAIL if any synthetic record exactly equals a reference record (copy leakage)."""
    if not ref_rows:
        return {"check": "exact_match_vs_reference", "pass": True,
                "detail": "no reference supplied; check skipped (informational)"}
    ref_set = {json.dumps(r, sort_keys=True) for r in ref_rows}
    dupes = sum(1 for r in rows if json.dumps(r, sort_keys=True) in ref_set)
    return {"check": "exact_match_vs_reference", "pass": dupes == 0,
            "detail": f"{dupes} synthetic record(s) exactly match a reference record"}


def check_k_anonymity(rows, k, qids):
    """FAIL if any quasi-identifier combination appears fewer than k times."""
    present_qids = [q for q in qids if rows and q in rows[0]]
    if not present_qids:
        return {"check": "quasi_identifier_k_anonymity", "pass": True,
                "detail": "no configured quasi-identifiers present; check skipped"}
    combos = Counter(tuple(str(r.get(q, "")) for q in present_qids) for r in rows)
    violating = sum(1 for c in combos.values() if c < k)
    min_group = min(combos.values()) if combos else 0
    return {"check": "quasi_identifier_k_anonymity", "pass": violating == 0,
            "detail": f"qids={present_qids} k={k} smallest_group={min_group} "
                      f"violating_groups={violating}"}


def main(argv=None):
    p = argparse.ArgumentParser(
        description="Privacy/disclosure-risk validation for the twin's synthetic feed (evidence only).")
    p.add_argument("--config", required=True, help="Twin Scope Config JSON path")
    p.add_argument("--dataset", required=True, help="synthetic dataset (CSV or JSONL) — read-only")
    p.add_argument("--reference", help="optional read-only reference dataset for exact-match check")
    p.add_argument("--k", type=int, default=5, help="k-anonymity threshold (default 5)")
    p.add_argument("--qids", help="comma-separated quasi-identifier columns "
                                  f"(default: {','.join(DEFAULT_QIDS)})")
    p.add_argument("--out", default="Twin Privacy Validation - Pilot - v1.json",
                   help="validation report output path")
    args = p.parse_args(argv)

    if not os.path.exists(args.config):
        print(f"ERROR: config not found: {args.config}", file=sys.stderr)
        return 2

    rows, err = read_rows(args.dataset)
    if err:
        print(f"ERROR: {err}", file=sys.stderr)
        return 2

    ref_rows = None
    if args.reference:
        ref_rows, ref_err = read_rows(args.reference)
        if ref_err:
            print(f"WARN: {ref_err}; exact-match check will be skipped.", file=sys.stderr)
            ref_rows = None

    qids = tuple((args.qids or ",".join(DEFAULT_QIDS)).split(","))

    checks = [
        check_real_phi_markers(rows),
        check_exact_match(rows, ref_rows),
        check_k_anonymity(rows, args.k, qids),
    ]
    all_pass = all(c["pass"] for c in checks)
    verdict = "PASS (technical)" if all_pass else "FAIL"

    print(f"Twin privacy validation: {verdict}  ({len(rows)} synthetic records)")
    for c in checks:
        print(f"  [{'PASS' if c['pass'] else 'FAIL'}] {c['check']}: {c['detail']}")
    print("  NOTE: a technical PASS is evidence, not acceptance. Residual disclosure-risk acceptance"
          " and de-identification determinations are deferred to the privacy/compliance office.")

    report = {
        "artifact_name": "Twin Privacy Validation - Pilot - v1",
        "generated_at": _now(),
        "config": args.config,
        "dataset": args.dataset,
        "record_count": len(rows),
        "k": args.k,
        "checks": checks,
        "technical_verdict": verdict,
        "acceptance": "DEFERRED to privacy/compliance office (not determined by this tool)",
    }
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2)
    print(f"Wrote privacy validation report -> {args.out}")
    return 0 if all_pass else 1


if __name__ == "__main__":
    sys.exit(main())
