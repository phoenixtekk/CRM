#!/usr/bin/env python3
# kpi_privacy_check.py — scan a KPI observations/feed file for suspected PHI (the privacy gate)
#
# PURPOSE: Read-only privacy gate for the KPI pipeline. Scans a CSV feed/observations file for
#          patient-level column names and cell patterns (MRN/SSN/email/phone/DOB/free-text) that must
#          NEVER appear in an aggregate KPI feed. It NEVER writes data and NEVER echoes cell contents.
# HOW TO RUN: python kpi_privacy_check.py --input feed.csv [--max-report 20]
#             (Python 3.10+; run --emit-sample-clean / --emit-sample-dirty to see inputs; --help)
# EXPECTED RESULTS: A findings summary (counts by rule, no raw values shown). Exit 0 = PASS (clean);
#                   exit 1 = FAIL (suspected PHI found) — expansion is blocked until remediated.

import argparse
import csv
import io
import re
import sys

SUSPECT_COLUMNS = {
    "patient", "patient_id", "patientid", "mrn", "ssn", "name", "first_name", "last_name",
    "dob", "date_of_birth", "address", "phone", "email", "diagnosis_text", "note",
    "clinical_note", "encounter_note", "member_id", "record_id",
}

# Cell-content signatures. Deliberately conservative; a hit is "suspected", to be reviewed.
CELL_RULES = [
    ("ssn_like", re.compile(r"\b\d{3}-\d{2}-\d{4}\b")),
    ("email_like", re.compile(r"\b[\w.+-]+@[\w-]+\.[\w.-]+\b")),
    ("phone_like", re.compile(r"\b\(?\d{3}\)?[ .-]?\d{3}[ .-]?\d{4}\b")),
    ("dob_like", re.compile(r"\b(19|20)\d{2}[-/](0?[1-9]|1[0-2])[-/](0?[1-9]|[12]\d|3[01])\b")),
    ("mrn_like", re.compile(r"\bMRN[:#]?\s*\w+\b", re.IGNORECASE)),
    ("long_freetext", re.compile(r"^.{120,}$")),  # long prose in a KPI cell is a smell
]


def sample_clean_csv() -> str:
    rows = [
        ["kpi", "period", "value", "n", "aggregation"],
        ["Delivery cycle time", "2026-W24", "5.0", "3", "median"],
        ["Privacy-gate first-pass rate", "2026-W24", "0.97", "4", "mean"],
    ]
    buf = io.StringIO()
    csv.writer(buf).writerows(rows)
    return buf.getvalue()


def sample_dirty_csv() -> str:
    # An example of what the gate must CATCH — synthetic-looking but PHI-shaped fields.
    rows = [
        ["kpi", "period", "value", "patient_id", "note"],
        ["Delivery cycle time", "2026-W24", "5.0", "P-000123",
         "call patient at 555-123-4567 re: 1985-04-02 follow-up"],
    ]
    buf = io.StringIO()
    csv.writer(buf).writerows(rows)
    return buf.getvalue()


def scan(rows):
    """Return (column_hits, cell_rule_counts). Never returns raw cell values."""
    if not rows:
        return [], {}
    header = [c.strip() for c in rows[0].keys()]
    column_hits = [c for c in header if c.strip().lower() in SUSPECT_COLUMNS]

    cell_counts = {label: 0 for label, _ in CELL_RULES}
    for r in rows:
        for _col, raw in r.items():
            if raw is None:
                continue
            text = str(raw)
            for label, rx in CELL_RULES:
                if rx.search(text):
                    cell_counts[label] += 1
    cell_counts = {k: v for k, v in cell_counts.items() if v > 0}
    return column_hits, cell_counts


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description="Privacy gate: scan a KPI file for suspected PHI.")
    p.add_argument("--input", help="Path to CSV feed/observations to scan.")
    p.add_argument("--emit-sample-clean", action="store_true",
                   help="Print a clean sample CSV and exit.")
    p.add_argument("--emit-sample-dirty", action="store_true",
                   help="Print a PHI-shaped sample CSV (what the gate must catch) and exit.")
    args = p.parse_args(argv)

    if args.emit_sample_clean:
        sys.stdout.write(sample_clean_csv())
        return 0
    if args.emit_sample_dirty:
        sys.stdout.write(sample_dirty_csv())
        return 0

    if args.input:
        try:
            with open(args.input, "r", newline="", encoding="utf-8") as fh:
                rows = list(csv.DictReader(fh))
        except OSError as e:
            print(f"ERROR: could not read input: {e}", file=sys.stderr)
            return 2
    else:
        print("NOTE: no --input given; scanning the built-in CLEAN sample.", file=sys.stderr)
        rows = list(csv.DictReader(io.StringIO(sample_clean_csv())))

    if not rows:
        print("ERROR: no rows to scan.", file=sys.stderr)
        return 2

    column_hits, cell_counts = scan(rows)

    print("KPI privacy gate — scan summary (no cell values are shown)")
    print("-" * 60)
    print(f"rows scanned: {len(rows)}")
    if column_hits:
        print(f"SUSPECT COLUMNS: {', '.join(column_hits)}")
    else:
        print("suspect columns: none")
    if cell_counts:
        print("SUSPECT CELL PATTERNS (rule: count):")
        for label, count in sorted(cell_counts.items()):
            print(f"    {label}: {count}")
    else:
        print("suspect cell patterns: none")
    print("-" * 60)

    if column_hits or cell_counts:
        print("RESULT: FAIL — suspected PHI present. A KPI feed must be aggregate and PHI-free.")
        print("Remove the offending column(s)/value(s) at the source and re-run. "
              "Expansion is blocked until this passes.")
        return 1

    print("RESULT: PASS — no suspected PHI found. (Aggregate, PHI-free feed.)")
    print("Note: this is a technical screen, not a compliance determination — that remains "
          "with privacy/compliance/legal.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
