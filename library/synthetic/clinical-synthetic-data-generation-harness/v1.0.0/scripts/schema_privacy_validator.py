#!/usr/bin/env python3
# schema_privacy_validator.py — validate schema conformance and privacy of a synthetic-EHR dataset
#
# PURPOSE: Confirm every synthetic record conforms to the target profile (required fields/types) and that
#          NO direct identifiers, real-PHI patterns, or exact reference-record matches leaked in. Implements
#          the Stage-4 PRIVACY/SCHEMA GATE. Produces technical EVIDENCE only — the de-identification /
#          disclosure-risk DETERMINATION is deferred to privacy/compliance/legal (global §4). Read-only.
# HOW TO RUN: python schema_privacy_validator.py --dataset /isolated/synthetic-ehr/synthetic-ehr-pilot-v1 \
#             --profile target-profile.json [--reference reference-stats.json] [--report privacy.json]
#             (Python 3.10+; see --help)
# EXPECTED RESULTS: PASS = 100% schema conformance, 0 direct identifiers, 0 exact reference matches.
#                   Exit 0 = PASS (evidence for sign-off), 1 = FAIL (rollback). Determination stays human.

import argparse
import json
import os
import re
import sys

# Direct-identifier / real-PHI patterns (heuristic; a real value should never reach a synthetic harness).
IDENTIFIER_PATTERNS = {
    "ssn": re.compile(r"\b\d{3}-\d{2}-\d{4}\b"),
    "email": re.compile(r"\b[\w.+-]+@[\w-]+\.[\w.-]+\b"),
    "phone": re.compile(r"\b\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b"),
    "mrn_realish": re.compile(r"\bMRN[-:\s]?\d{6,}\b", re.IGNORECASE),
}
# Synthetic identifiers must come from the synthetic namespace (e.g. "SYN-0000001"): this is allowed.
SYNTHETIC_ID = re.compile(r"^SYN-\d+$")


def load_json(path):
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def load_records(ds_dir):
    rp = os.path.join(ds_dir, "records.json")
    if not os.path.isfile(rp):
        raise SystemExit(f"no records.json under {ds_dir} — generate first with generate_harness.py")
    return load_json(rp)["records"]


def iter_strings(obj):
    if isinstance(obj, str):
        yield obj
    elif isinstance(obj, dict):
        for v in obj.values():
            yield from iter_strings(v)
    elif isinstance(obj, list):
        for v in obj:
            yield from iter_strings(v)


def check_schema(records, profile):
    """Required fields present per domain profile. Returns (nonconforming_count, examples)."""
    prof_domains = (profile or {}).get("domains", {})
    nonconforming = 0
    examples = []
    for r in records:
        pid = r.get("patient", {}).get("id", "?")
        # patient required fields
        req_patient = prof_domains.get("patients", {}).get("required", ["id", "sex", "birth_date"])
        for f in req_patient:
            if f not in r.get("patient", {}):
                nonconforming += 1
                if len(examples) < 20:
                    examples.append(f"{pid}: patient missing required field '{f}'")
        # other domains: if profile marks required, the record must carry a non-empty list/obj
        for dom, spec in prof_domains.items():
            if dom == "patients":
                continue
            if spec.get("required_present") and not r.get(dom):
                nonconforming += 1
                if len(examples) < 20:
                    examples.append(f"{pid}: required domain '{dom}' absent/empty")
    return nonconforming, examples


def check_identifiers(records):
    hits = []
    for r in records:
        pid = r.get("patient", {}).get("id", "?")
        # the synthetic id itself is allowed only if it is from the synthetic namespace
        if not SYNTHETIC_ID.match(str(pid)):
            hits.append(f"{pid}: patient id is not a synthetic namespace id (SYN-*)")
        for s in iter_strings(r):
            if SYNTHETIC_ID.match(s):
                continue
            for name, pat in IDENTIFIER_PATTERNS.items():
                if pat.search(s):
                    hits.append(f"{pid}: value matches direct-identifier pattern '{name}': {s!r}")
    return hits


def check_leakage(records, reference):
    """No synthetic record may be an exact match to a reference sample record (memorization/leakage)."""
    if not reference:
        return []
    ref_samples = reference.get("sample_records", [])
    if not ref_samples:
        return []
    ref_set = {json.dumps(s, sort_keys=True) for s in ref_samples}
    hits = []
    for r in records:
        if json.dumps(r, sort_keys=True) in ref_set:
            hits.append(f"{r.get('patient', {}).get('id', '?')}: EXACT match to a reference record")
    return hits


def main():
    ap = argparse.ArgumentParser(description="Validate schema conformance & privacy (Stage-4 gate; evidence only).")
    ap.add_argument("--dataset", required=True, help="dataset directory (contains records.json)")
    ap.add_argument("--profile", required=True, help="target-profile JSON (Requirement R1)")
    ap.add_argument("--reference", help="reference-stats JSON — checked for exact-match leakage (optional)")
    ap.add_argument("--report", help="optional path to write the privacy/schema report JSON")
    args = ap.parse_args()

    records = load_records(args.dataset)
    profile = load_json(args.profile)
    reference = load_json(args.reference) if args.reference and os.path.isfile(args.reference) else None

    nonconform, schema_examples = check_schema(records, profile)
    identifiers = check_identifiers(records)
    leakage = check_leakage(records, reference)

    n = len(records)
    conform_pct = 100.0 * (1 - nonconform / max(1, n))

    print("=== Synthetic EHR – Privacy Validation – Pilot ===")
    print(f"  records: {n}\n")
    print(f"  schema:")
    print(f"    conformance: {conform_pct:.1f}%  ({nonconform} nonconforming issue(s))")
    for e in schema_examples[:10]:
        print(f"      - {e}")
    print(f"\n  identifiers: {len(identifiers)} hit(s)")
    for e in identifiers[:10]:
        print(f"      - {e}")
    print(f"\n  leakage (exact reference matches): {len(leakage)} hit(s)")
    for e in leakage[:10]:
        print(f"      - {e}")

    schema_ok = nonconform == 0
    ident_ok = len(identifiers) == 0
    leak_ok = len(leakage) == 0
    gate = schema_ok and ident_ok and leak_ok

    print("\n--- privacy/schema gate (EVIDENCE — determination deferred to privacy/compliance/legal) ---")
    print(f"  schema 100%   : {'PASS' if schema_ok else 'FAIL'}")
    print(f"  no identifiers: {'PASS' if ident_ok else 'FAIL'}")
    print(f"  no leakage    : {'PASS' if leak_ok else 'FAIL'}")
    print(f"  GATE          : {'PASS' if gate else 'FAIL — treat as an incident; purge and rollback'}")
    print("  NOTE: this is technical evidence only; disclosure-risk acceptance and any de-identification/")
    print("        IRB sign-off remain the privacy/compliance/legal functions' decision.")

    if args.report:
        report = {
            "artifact": "Synthetic EHR – Privacy Validation – Pilot",
            "records": n,
            "schema_conformance_pct": round(conform_pct, 1),
            "schema_issues": schema_examples,
            "identifier_hits": identifiers,
            "leakage_hits": leakage,
            "gate_pass": gate,
            "determination": "deferred to privacy/compliance/legal (global §4)",
        }
        with open(args.report, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        print(f"  report written: {args.report}")

    return 0 if gate else 1


if __name__ == "__main__":
    sys.exit(main())
