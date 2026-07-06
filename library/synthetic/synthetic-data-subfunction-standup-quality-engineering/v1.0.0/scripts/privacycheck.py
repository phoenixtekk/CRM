#!/usr/bin/env python3
# privacycheck.py — privacy/validation screen for a synthetic dataset (identifiers/copies/uniqueness)
#
# PURPOSE: Screen a SYNTHETIC dataset for (a) direct-identifier leakage, (b) exact/near-exact copies of
#          reference rows (memorization), and (c) quasi-identifier uniqueness risk (k-anonymity signal).
#          Produces TECHNICAL EVIDENCE and a pass/fail signal only; the disclosure-risk DETERMINATION is
#          deferred to the privacy officer. Read-only: prints evidence; writes a report only with --out;
#          NEVER emits real data values (only counts, hashes, and category names).
# HOW TO RUN: python privacycheck.py --dataset data.csv [--reference ref.csv]
#             [--check identifiers|copies|uniqueness|all] [--quasi age_band,sex,zip3] [--k 5]
#             [--out report.json]   (Python 3.10+; standard library only; see --help). No args = demo.
# EXPECTED RESULTS: PASS/FAIL per check. Any direct identifier or exact reference copy is a HARD FAIL
#                   (block release). Uniqueness above the k threshold ESCALATES to the privacy officer.

import argparse
import csv
import hashlib
import io
import json
import re
import sys
from collections import Counter
from datetime import datetime, timezone

# Field-name patterns that should NOT appear as identifying fields in synthetic output.
DIRECT_ID_NAME_PATTERNS = [
    r"\b(ssn|social)\b", r"\bmrn\b", r"medical_record", r"\bfirst_?name\b", r"\blast_?name\b",
    r"\bfull_?name\b", r"\bemail\b", r"\bphone\b", r"\baddress\b", r"\bdob\b", r"date_of_birth",
]
# Value patterns that look like real direct identifiers (screened per cell).
DIRECT_ID_VALUE_PATTERNS = {
    "ssn_like": re.compile(r"^\d{3}-?\d{2}-?\d{4}$"),
    "email_like": re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$"),
    "phone_like": re.compile(r"^\+?\d[\d\-\(\) ]{8,}\d$"),
}

EXAMPLE_DATA = """patient_id,age_band,sex,zip3,condition_code
SYN-1,40-64,F,021,I10
SYN-2,65+,M,021,E11
SYN-3,18-39,F,940,J45
SYN-4,40-64,F,021,I10
SYN-5,0-17,M,606,N18
"""

EXAMPLE_REF = """patient_id,age_band,sex,zip3,condition_code
REAL-1,40-64,F,021,I10
REAL-9,65+,M,300,E11
"""


def load_rows(text):
    return list(csv.DictReader(io.StringIO(text)))


def _row_hash(row, fields):
    key = "|".join(str(row.get(f, "")) for f in fields)
    return hashlib.sha256(key.encode("utf-8")).hexdigest()


def check_identifiers(rows):
    findings = []
    ok = True
    if not rows:
        return True, ["no rows"]
    cols = list(rows[0].keys())
    for col in cols:
        for pat in DIRECT_ID_NAME_PATTERNS:
            if re.search(pat, col, re.IGNORECASE):
                findings.append(f"field name looks like a direct identifier: '{col}'")
                ok = False
                break
    # value-level screen (report counts only, never the values themselves)
    hits = Counter()
    for r in rows:
        for col, val in r.items():
            v = (val or "").strip()
            for label, pat in DIRECT_ID_VALUE_PATTERNS.items():
                if v and pat.match(v):
                    hits[(col, label)] += 1
    for (col, label), n in hits.items():
        findings.append(f"{n} value(s) in '{col}' match {label} pattern")
        ok = False
    if ok:
        findings.append("no direct-identifier field names or value patterns detected")
    return ok, findings


def check_copies(rows, ref_rows):
    if ref_rows is None:
        return None, ["N/A (no --reference supplied) — memorization screen skipped"]
    fields = [f for f in rows[0].keys()] if rows else []
    common = [f for f in fields if f != "patient_id" and (not ref_rows or f in ref_rows[0])]
    ref_hashes = {_row_hash(r, common) for r in ref_rows}
    copies = sum(1 for r in rows if _row_hash(r, common) in ref_hashes)
    ok = copies == 0
    findings = [f"compared on fields {common}",
                f"exact reference-row copies found: {copies}"]
    if not ok:
        findings.append("HARD FAIL: synthetic rows exactly match reference rows (memorization leak)")
    return ok, findings


def check_uniqueness(rows, quasi, k):
    if not rows:
        return True, ["no rows"], 0.0
    missing = [q for q in quasi if q not in rows[0]]
    if missing:
        return False, [f"quasi-identifier fields not in dataset: {missing}"], 1.0
    groups = Counter(_row_hash(r, quasi) for r in rows)
    unique_below_k = sum(cnt for cnt in groups.values() if cnt < k)
    frac = unique_below_k / len(rows)
    ok = frac == 0.0
    findings = [f"quasi-identifiers: {quasi}, k={k}",
                f"records in groups smaller than k: {unique_below_k}/{len(rows)} ({frac:.0%})"]
    if not ok:
        findings.append("ESCALATE: quasi-identifier uniqueness above threshold — refer evidence "
                        "to the privacy officer for the disclosure-risk determination")
    return ok, findings, frac


def main(argv=None):
    p = argparse.ArgumentParser(description="Privacy/validation screen for a synthetic dataset.")
    p.add_argument("--dataset", help="CSV synthetic dataset. Omit for a built-in demo.")
    p.add_argument("--reference", help="CSV reference dataset (enables the memorization/copy screen).")
    p.add_argument("--check", choices=["identifiers", "copies", "uniqueness", "all"], default="all")
    p.add_argument("--quasi", default="age_band,sex,zip3",
                   help="Comma-separated quasi-identifier fields for the uniqueness check.")
    p.add_argument("--k", type=int, default=5, help="k-anonymity threshold (default 5).")
    p.add_argument("--out", help="Optional path to WRITE the JSON evidence report (safe default: none).")
    args = p.parse_args(argv)

    demo = not args.dataset
    rows = load_rows(open(args.dataset, encoding="utf-8").read()) if args.dataset \
        else load_rows(EXAMPLE_DATA)
    if args.reference:
        ref_rows = load_rows(open(args.reference, encoding="utf-8").read())
    elif demo:
        ref_rows = load_rows(EXAMPLE_REF)
    else:
        ref_rows = None
    if demo:
        print("[info] no --dataset; using built-in demo dataset + reference.", file=sys.stderr)

    quasi = [q.strip() for q in args.quasi.split(",") if q.strip()]
    report = {"artifact": "Validation Record (privacy section)",
              "generated_utc": datetime.now(timezone.utc).isoformat(),
              "note": "technical evidence only; disclosure-risk determination deferred to privacy officer",
              "checks": {}}
    hard_fail = False
    escalate = False

    print("\n=== privacycheck: privacy/validation screen ===")

    if args.check in ("identifiers", "all"):
        ok, f = check_identifiers(rows)
        report["checks"]["identifiers"] = {"pass": ok, "findings": f}
        hard_fail = hard_fail or not ok
        print(f"\n[identifiers] {'PASS' if ok else 'HARD FAIL'}")
        for line in f:
            print(f"  - {line}")

    if args.check in ("copies", "all"):
        ok, f = check_copies(rows, ref_rows)
        report["checks"]["copies"] = {"pass": ok, "findings": f}
        if ok is False:
            hard_fail = True
        label = "N/A" if ok is None else ("PASS" if ok else "HARD FAIL")
        print(f"\n[copies] {label}")
        for line in f:
            print(f"  - {line}")

    if args.check in ("uniqueness", "all"):
        ok, f, frac = check_uniqueness(rows, quasi, args.k)
        report["checks"]["uniqueness"] = {"pass": ok, "fraction_below_k": frac, "findings": f}
        if not ok:
            escalate = True
        print(f"\n[uniqueness] {'PASS' if ok else 'ESCALATE'}")
        for line in f:
            print(f"  - {line}")

    if hard_fail:
        signal = "FAIL-BLOCK-RELEASE"
    elif escalate:
        signal = "ESCALATE-TO-PRIVACY-OFFICER"
    else:
        signal = "PASS"
    report["signal"] = signal
    print(f"\nPrivacy signal: {signal}")
    print("Reminder: this is technical evidence; the disclosure-risk DETERMINATION is the privacy "
          "officer's, not this tool's.")

    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        print(f"[written] evidence report saved to {args.out}")
    else:
        print("[dry-run] no file written (pass --out to save the evidence report).")

    return 0 if signal == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
