#!/usr/bin/env python3
# phi_field_scanner.py — profile a tabular extract and suggest a per-field privacy classification
#
# PURPOSE: Read-only scanner that PROFILES a CSV and SUGGESTS a per-field classification
#          (direct-identifier / quasi-identifier / sensitive / non-identifying) from column-name
#          and value-pattern heuristics; an "audit" mode instead flags residual direct-identifier
#          VALUES left in an output. It suggests; a privacy stakeholder decides. Writes only a
#          classification/report JSON — never the input data.
# HOW TO RUN: python phi_field_scanner.py --input extract.csv --out field-classification-draft.json
#             python phi_field_scanner.py --input deidentified.csv --mode audit   (Python 3.10+; see --help)
# EXPECTED RESULTS: A draft classification JSON (classify mode) you hand to privacy for review, or an
#          audit report listing any columns/rows with residual direct-identifier patterns (audit mode).
#
# Standard-library only. This is a SUGGESTION tool: heuristics are conservative but not authoritative.
# No network calls, no secrets, no real PHI written anywhere. Input is read-only.

import argparse
import csv
import json
import re
import sys
from collections import defaultdict

# --- Heuristic vocabularies -------------------------------------------------

DIRECT_NAME_HINTS = (
    "name", "firstname", "lastname", "surname", "fullname", "ssn", "socialsecurity",
    "mrn", "medicalrecord", "email", "e-mail", "phone", "fax", "mobile", "telephone",
    "address", "street", "account", "license", "passport", "url", "ip", "device",
    "beneficiary", "certificate", "vehicle", "biometric",
)
QUASI_NAME_HINTS = (
    "dob", "birth", "date", "dt", "admit", "admission", "discharge", "zip", "postal",
    "postcode", "geo", "city", "county", "state", "age", "sex", "gender", "race",
    "ethnicity", "language", "maritalstatus", "occupation", "employer",
)
SENSITIVE_NAME_HINTS = (
    "diagnosis", "dx", "icd", "condition", "procedure", "cpt", "medication", "drug",
    "rx", "lab", "result", "hiv", "mental", "substance", "genetic", "note", "problem",
)

# Value-pattern signatures (compiled once).
PATTERNS = {
    "ssn": re.compile(r"^\d{3}-?\d{2}-?\d{4}$"),
    "email": re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$"),
    "phone": re.compile(r"^\+?\d[\d\s().-]{7,}\d$"),
    "zip5": re.compile(r"^\d{5}(-\d{4})?$"),
    "iso_date": re.compile(r"^\d{4}-\d{2}-\d{2}"),
    "us_date": re.compile(r"^\d{1,2}/\d{1,2}/\d{2,4}$"),
    "mrn_like": re.compile(r"^[A-Z]{0,3}\d{6,12}$"),
}


def _norm(name):
    return re.sub(r"[^a-z0-9]", "", name.lower())


def _read_columns(path, sample):
    """Return (headers, {col: [sample values]}) reading at most `sample` rows. Read-only."""
    with open(path, newline="", encoding="utf-8-sig") as fh:
        reader = csv.reader(fh)
        try:
            headers = next(reader)
        except StopIteration:
            return [], {}
        cols = {h: [] for h in headers}
        for i, row in enumerate(reader):
            if i >= sample:
                break
            for h, v in zip(headers, row):
                if v.strip():
                    cols[h].append(v.strip())
    return headers, cols


def _pattern_hits(values):
    hits = defaultdict(int)
    for v in values:
        for label, pat in PATTERNS.items():
            if pat.match(v):
                hits[label] += 1
    n = max(len(values), 1)
    return {k: round(c / n, 3) for k, c in hits.items()}


def _classify_column(name, values):
    """Return (classification, reason). Name hints take priority; values corroborate."""
    key = _norm(name)
    hits = _pattern_hits(values)
    strong = {k: r for k, r in hits.items() if r >= 0.5}

    # Value evidence for direct identifiers is decisive.
    for label in ("ssn", "email", "phone", "mrn_like"):
        if label in strong:
            return "direct_identifier", f"value pattern '{label}' in >=50% of samples"

    if any(h in key for h in DIRECT_NAME_HINTS):
        return "direct_identifier", "column name matches a direct-identifier hint"
    if any(h in key for h in SENSITIVE_NAME_HINTS):
        return "sensitive_attribute", "column name matches a sensitive-attribute hint"
    if any(h in key for h in QUASI_NAME_HINTS) or "zip5" in strong or "iso_date" in strong or "us_date" in strong:
        return "quasi_identifier", "name/value indicates a quasi-identifier (date/geo/demographic)"

    # Low-cardinality free categories default to quasi (cautious); otherwise non-identifying.
    distinct = len(set(values))
    if 0 < distinct <= max(2, len(values) // 4):
        return "quasi_identifier", "low-cardinality category — review as possible quasi-identifier"
    return "non_identifying", "no identifier signal detected"


def cmd_classify(args):
    headers, cols = _read_columns(args.input, args.sample)
    if not headers:
        print("ERROR: input has no header row.", file=sys.stderr)
        return 2
    classification = {}
    for h in headers:
        cls, reason = _classify_column(h, cols[h])
        classification[h] = {"classification": cls, "reason": reason,
                             "samples_seen": len(cols[h])}
    out = {
        "artifact": "Field Classification – Pilot – v1 (DRAFT)",
        "input_file": args.input,
        "note": "SUGGESTED classification. A privacy stakeholder MUST review, especially "
                "quasi-identifiers, before this becomes the reviewed artifact.",
        "fields": classification,
    }
    _emit(out, args.out)
    counts = defaultdict(int)
    for v in classification.values():
        counts[v["classification"]] += 1
    print("Draft classification (SUGGESTED — needs privacy review):")
    for cls in ("direct_identifier", "quasi_identifier", "sensitive_attribute", "non_identifying"):
        print(f"  {cls:20s}: {counts[cls]}")
    return 0


def cmd_audit(args):
    """Flag residual direct-identifier VALUES left in an output (post de-identification)."""
    headers, cols = _read_columns(args.input, args.sample)
    findings = []
    for h in headers:
        hits = _pattern_hits(cols[h])
        for label in ("ssn", "email", "phone", "mrn_like"):
            if hits.get(label, 0) > 0:
                findings.append({"column": h, "pattern": label, "rate": hits[label]})
    result = {
        "artifact": "Direct-Identifier Audit",
        "input_file": args.input,
        "pass": len(findings) == 0,
        "findings": findings,
    }
    _emit(result, args.out)
    if findings:
        print(f"FAIL: {len(findings)} residual direct-identifier signal(s) found:")
        for f in findings:
            print(f"  column '{f['column']}': pattern '{f['pattern']}' in {f['rate']*100:.0f}% of samples")
        return 1
    print("PASS: no residual direct-identifier patterns detected in sampled rows.")
    return 0


def _emit(obj, out_path):
    text = json.dumps(obj, indent=2)
    if out_path:
        with open(out_path, "w", encoding="utf-8") as fh:
            fh.write(text)
        print(f"[written] {out_path}")
    else:
        print(text)


def main(argv=None):
    p = argparse.ArgumentParser(description="Profile a CSV and suggest a per-field privacy classification (or audit for residual direct IDs).")
    p.add_argument("--input", required=True, help="Path to the CSV extract (read-only).")
    p.add_argument("--mode", choices=["classify", "audit"], default="classify",
                   help="classify: suggest per-field classification; audit: flag residual direct IDs.")
    p.add_argument("--sample", type=int, default=1000, help="Max rows to sample (default 1000).")
    p.add_argument("--out", help="Write JSON here; default prints to stdout.")
    args = p.parse_args(argv)
    return cmd_audit(args) if args.mode == "audit" else cmd_classify(args)


if __name__ == "__main__":
    sys.exit(main())
