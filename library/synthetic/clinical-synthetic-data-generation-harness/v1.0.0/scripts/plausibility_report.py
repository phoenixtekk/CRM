#!/usr/bin/env python3
# plausibility_report.py — grade a synthetic dataset for clinical plausibility and coverage
#
# PURPOSE: Compare a generated synthetic-EHR dataset against agreed reference distributions (fidelity)
#          and consumer coverage criteria, and flag impossible clinical values. Implements the Stage-4
#          PLAUSIBILITY GATE. Read-only; writes only an optional report JSON.
# HOW TO RUN: python plausibility_report.py --dataset /isolated/synthetic-ehr/synthetic-ehr-pilot-v1 \
#             --reference reference-stats.json --config harness-config.json [--report plaus.json]
#             [--tolerance 0.15]   (Python 3.10+; see --help)
# EXPECTED RESULTS: PASS when every in-scope domain is within tolerance of the reference and every required
#                   scenario/domain is covered, with no impossible values. Exit 0 = PASS, 1 = FAIL.

import argparse
import json
import os
import statistics
import sys


def load_json(path):
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def load_dataset(ds_dir):
    rp = os.path.join(ds_dir, "records.json")
    if not os.path.isfile(rp):
        raise SystemExit(f"no records.json under {ds_dir} — generate first with generate_harness.py")
    return load_json(rp)["records"]


def pct(part, whole):
    return (part / whole) if whole else 0.0


def check_distributions(records, reference, tol):
    """Compare simple summary stats to the reference; return list of (domain, PASS/FAIL, detail)."""
    results = []
    ref_domains = reference.get("domains", {}) if reference else {}
    n = len(records)

    if "patients" in ref_domains and n:
        ref = ref_domains["patients"]
        female = pct(sum(1 for r in records if r["patient"]["sex"] == "female"), n)
        ref_female = ref.get("female_fraction")
        if ref_female is not None:
            ok = abs(female - ref_female) <= tol
            results.append(("patients:sex_mix", ok,
                            f"female={female:.2f} vs ref={ref_female:.2f} (tol {tol})"))
        ages = [r["patient"]["age"] for r in records]
        ref_mean = ref.get("mean_age")
        if ref_mean is not None and ages:
            got = statistics.mean(ages)
            ok = abs(got - ref_mean) <= max(5.0, ref_mean * tol)
            results.append(("patients:mean_age", ok, f"mean_age={got:.1f} vs ref={ref_mean:.1f}"))

    if "conditions" in ref_domains and n:
        ref_prev = ref_domains["conditions"].get("prevalence", {})
        counts = {}
        for r in records:
            for c in r.get("conditions", []):
                counts[c["code"]] = counts.get(c["code"], 0) + 1
        for code, ref_p in ref_prev.items():
            got_p = pct(counts.get(code, 0), n)
            ok = abs(got_p - ref_p) <= tol
            results.append((f"conditions:{code}", ok, f"prevalence={got_p:.2f} vs ref={ref_p:.2f}"))

    return results


def check_impossible(records):
    """Clinical invariants — impossible values are always a FAIL regardless of the reference."""
    problems = []
    for r in records:
        p = r["patient"]
        if p["age"] < 0:
            problems.append(f"{p['id']}: negative age {p['age']}")
        v = r.get("vitals")
        if v and v.get("diastolic_mmHg", 0) >= v.get("systolic_mmHg", 0):
            problems.append(f"{p['id']}: diastolic>=systolic ({v['diastolic_mmHg']}/{v['systolic_mmHg']})")
        for lab in r.get("labs", []):
            if lab.get("value", 0) < 0:
                problems.append(f"{p['id']}: negative lab {lab['name']}={lab['value']}")
    return problems


def check_coverage(records, config):
    """Every consumer-required scenario present at/above its size threshold."""
    results = []
    scenarios = (config or {}).get("scenarios", [])
    for sc in scenarios:
        req_code = sc.get("require_condition")
        want = sc.get("size", 0)
        if req_code:
            have = sum(1 for r in records if any(c["code"] == req_code for c in r.get("conditions", [])))
            ok = have >= want
            results.append((f"scenario:{sc.get('name')}", ok, f"have {have} with {req_code}, need {want}"))
    return results


def main():
    ap = argparse.ArgumentParser(description="Grade synthetic-EHR plausibility & coverage (Stage-4 gate).")
    ap.add_argument("--dataset", required=True, help="dataset directory (contains records.json)")
    ap.add_argument("--reference", required=True, help="reference-stats JSON (Requirement R2)")
    ap.add_argument("--config", help="harness config JSON (for scenario coverage)")
    ap.add_argument("--tolerance", type=float, default=0.15, help="fractional tolerance vs reference (default 0.15)")
    ap.add_argument("--report", help="optional path to write the plausibility report JSON")
    args = ap.parse_args()

    records = load_dataset(args.dataset)
    reference = load_json(args.reference)
    config = load_json(args.config) if args.config and os.path.isfile(args.config) else {}

    dist = check_distributions(records, reference, args.tolerance)
    impossible = check_impossible(records)
    coverage = check_coverage(records, config)

    print("=== Synthetic EHR – Plausibility Report – Pilot ===")
    print(f"  records: {len(records)}\n")
    print("  distribution checks:")
    for name, ok, detail in dist:
        print(f"    [{'PASS' if ok else 'FAIL'}] {name}: {detail}")
    print("\n  coverage checks:")
    for name, ok, detail in coverage:
        print(f"    [{'PASS' if ok else 'FAIL'}] {name}: {detail}")
    print("\n  impossible-value checks:")
    if impossible:
        for msg in impossible[:20]:
            print(f"    [FAIL] {msg}")
        if len(impossible) > 20:
            print(f"    ... and {len(impossible) - 20} more")
    else:
        print("    [PASS] no impossible values found")

    dist_ok = all(ok for _, ok, _ in dist)
    cov_ok = all(ok for _, ok, _ in coverage)
    imp_ok = not impossible
    gate = dist_ok and cov_ok and imp_ok

    print("\n--- plausibility gate ---")
    print(f"  distributions : {'PASS' if dist_ok else 'FAIL'}")
    print(f"  coverage      : {'PASS' if cov_ok else 'FAIL'}")
    print(f"  impossible    : {'PASS' if imp_ok else 'FAIL'}")
    print(f"  GATE          : {'PASS' if gate else 'FAIL — do not expand; rollback and fix'}")

    if args.report:
        report = {
            "artifact": "Synthetic EHR – Plausibility Report – Pilot",
            "records": len(records),
            "distributions": [{"name": n, "pass": ok, "detail": d} for n, ok, d in dist],
            "coverage": [{"name": n, "pass": ok, "detail": d} for n, ok, d in coverage],
            "impossible_values": impossible,
            "gate_pass": gate,
        }
        with open(args.report, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        print(f"  report written: {args.report}")

    return 0 if gate else 1


if __name__ == "__main__":
    sys.exit(main())
