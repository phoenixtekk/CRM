#!/usr/bin/env python3
# datasetprofile.py — fidelity/coverage report for a synthetic dataset (structure/coverage/fidelity)
#
# PURPOSE: Profile a SYNTHETIC dataset for structural conformance to the target model, in-scope
#          coverage of required categories, and — only when a reference-statistics file is supplied —
#          distributional fidelity. Produces the fidelity/coverage section of the validation record.
#          Read-only: reports to stdout; writes a JSON report only with --out. Operates on synthetic
#          data in the isolated environment; never writes real values.
# HOW TO RUN: python datasetprofile.py --dataset data.csv --spec spec.json
#             [--reference refstats.json] [--mode structure|coverage|fidelity|all] [--out report.json]
#             (Python 3.10+; standard library only; see --help). With no args it runs a built-in demo.
# EXPECTED RESULTS: PASS/FAIL per check. Fidelity is reported "N/A (no reference)" when --reference is
#                   absent -- it is NOT counted as a pass, so no unfounded fidelity claim is made.

import argparse
import csv
import io
import json
import sys
from collections import Counter
from datetime import datetime, timezone

# spec: required domains->fields, required categorical coverage, and the fidelity fields/tolerance.
EXAMPLE_SPEC = {
    "target_model": "FHIR",
    "required_fields": ["patient_id", "encounter_id", "condition_code", "age_band", "sex"],
    "coverage": {
        "condition_code": ["I10", "E11", "J45", "N18"],
        "age_band": ["0-17", "18-39", "40-64", "65+"],
    },
    "coverage_target": 0.90,
    "fidelity_fields": ["age_band", "sex"],
    "fidelity_tolerance": 0.10,
}

EXAMPLE_DATA = """patient_id,encounter_id,condition_code,age_band,sex
P1,E1,I10,40-64,F
P2,E2,E11,65+,M
P3,E3,J45,18-39,F
P4,E4,I10,0-17,M
P5,E5,N18,65+,F
P6,E6,E11,40-64,M
"""

EXAMPLE_REF = {  # reference distributions (fractions) — governed/minimized or agreed published stats
    "age_band": {"0-17": 0.15, "18-39": 0.25, "40-64": 0.35, "65+": 0.25},
    "sex": {"F": 0.51, "M": 0.49},
}


def load_rows(text):
    return list(csv.DictReader(io.StringIO(text)))


def check_structure(rows, spec):
    findings = []
    ok = True
    if not rows:
        return False, ["no rows in dataset"]
    cols = set(rows[0].keys())
    for f in spec["required_fields"]:
        if f not in cols:
            findings.append(f"missing required field: {f}")
            ok = False
    # simple referential check: encounter rows should reference a patient
    if "patient_id" in cols:
        empties = sum(1 for r in rows if not (r.get("patient_id") or "").strip())
        if empties:
            findings.append(f"{empties} rows with empty patient_id")
            ok = False
    findings.append(f"rows={len(rows)} fields={len(cols)}")
    return ok, findings


def check_coverage(rows, spec):
    target = spec.get("coverage_target", 0.90)
    findings = []
    ok = True
    for field, required in spec.get("coverage", {}).items():
        present = set(r.get(field) for r in rows)
        covered = [c for c in required if c in present]
        frac = len(covered) / len(required) if required else 1.0
        status = "ok" if frac >= target else "LOW"
        if frac < target:
            ok = False
        missing = sorted(set(required) - present)
        findings.append(f"{field}: {frac:.0%} covered ({status})"
                        + (f"; missing {missing}" if missing else ""))
    return ok, findings, target


def _dist(rows, field):
    c = Counter(r.get(field) for r in rows if r.get(field))
    total = sum(c.values())
    return {k: v / total for k, v in c.items()} if total else {}


def check_fidelity(rows, spec, reference):
    if reference is None:
        return None, ["N/A (no reference supplied) — no distributional-fidelity claim made"], None
    tol = spec.get("fidelity_tolerance", 0.10)
    findings = []
    ok = True
    for field in spec.get("fidelity_fields", []):
        ref = reference.get(field)
        if not ref:
            findings.append(f"{field}: N/A (no reference distribution)")
            continue
        syn = _dist(rows, field)
        cats = set(ref) | set(syn)
        # normalized L1 distance / 2 -> total variation distance in [0,1]
        tvd = sum(abs(syn.get(c, 0) - ref.get(c, 0)) for c in cats) / 2
        status = "ok" if tvd <= tol else "OUT-OF-TOL"
        if tvd > tol:
            ok = False
        findings.append(f"{field}: distance={tvd:.3f} (tol {tol:.2f}) {status}")
    return ok, findings, tol


def main(argv=None):
    p = argparse.ArgumentParser(description="Fidelity/coverage report for a synthetic dataset.")
    p.add_argument("--dataset", help="CSV synthetic dataset. Omit for a built-in demo.")
    p.add_argument("--spec", help="JSON profiling spec (required fields, coverage, fidelity).")
    p.add_argument("--reference", help="JSON reference distributions (enables fidelity mode).")
    p.add_argument("--mode", choices=["structure", "coverage", "fidelity", "all"], default="all")
    p.add_argument("--out", help="Optional path to WRITE the JSON report (safe default: no write).")
    args = p.parse_args(argv)

    if args.dataset:
        with open(args.dataset, "r", encoding="utf-8") as fh:
            rows = load_rows(fh.read())
    else:
        print("[info] no --dataset; using built-in demo dataset.", file=sys.stderr)
        rows = load_rows(EXAMPLE_DATA)

    spec = EXAMPLE_SPEC
    if args.spec:
        with open(args.spec, "r", encoding="utf-8") as fh:
            spec = json.load(fh)

    reference = None
    if args.reference:
        with open(args.reference, "r", encoding="utf-8") as fh:
            reference = json.load(fh)
    elif not args.dataset:
        reference = EXAMPLE_REF  # demo convenience only

    report = {"artifact": "Validation Record (fidelity/coverage section)",
              "generated_utc": datetime.now(timezone.utc).isoformat(),
              "target_model": spec.get("target_model"), "checks": {}}
    overall_pass = True

    print("\n=== datasetprofile: fidelity/coverage report ===")
    if args.mode in ("structure", "all"):
        ok, f = check_structure(rows, spec)
        report["checks"]["structure"] = {"pass": ok, "findings": f}
        overall_pass = overall_pass and ok
        print(f"\n[structure] {'PASS' if ok else 'FAIL'}")
        for line in f:
            print(f"  - {line}")

    if args.mode in ("coverage", "all"):
        ok, f, target = check_coverage(rows, spec)
        report["checks"]["coverage"] = {"pass": ok, "target": target, "findings": f}
        overall_pass = overall_pass and ok
        print(f"\n[coverage] {'PASS' if ok else 'FAIL'} (target {target:.0%})")
        for line in f:
            print(f"  - {line}")

    if args.mode in ("fidelity", "all"):
        ok, f, tol = check_fidelity(rows, spec, reference)
        report["checks"]["fidelity"] = {"pass": ok, "tolerance": tol, "findings": f}
        # None means N/A -> does not fail the gate, but is not a pass either
        if ok is False:
            overall_pass = False
        label = "N/A" if ok is None else ("PASS" if ok else "FAIL")
        print(f"\n[fidelity] {label}")
        for line in f:
            print(f"  - {line}")

    signal = "PASS" if overall_pass else "FAIL"
    report["signal"] = signal
    print(f"\nOverall fidelity/coverage signal: {signal}")

    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        print(f"[written] report saved to {args.out}")
    else:
        print("[dry-run] no file written (pass --out to save the report).")

    return 0 if overall_pass else 1


if __name__ == "__main__":
    sys.exit(main())
