#!/usr/bin/env python3
# kpi_definition_validator.py — validate a KPI catalog and guard against vanity metrics
#
# PURPOSE: Reads a KPI catalog (each KPI: name, definition, data_source, target, owner, direction)
#          and checks each is well-formed AND is not a vanity metric (raw output counts, individual
#          utilization, lines of code, velocity-as-target). Read-only; writes only with --out.
# HOW TO RUN: python kpi_definition_validator.py --catalog kpi_catalog.json [--out report.json]
#             (Python 3.10+; run with --emit-sample to see the expected shape; see --help)
# EXPECTED RESULTS: A per-KPI PASS/FAIL table on stdout. Exit 0 = every KPI complete and zero vanity
#                   flags; exit 1 = one or more KPIs incomplete or flagged as vanity (the fail signal).

import argparse
import json
import re
import sys

REQUIRED_FIELDS = ("name", "definition", "data_source", "target", "owner", "direction")
VALID_DIRECTIONS = ("higher_is_better", "lower_is_better")

# Vanity-metric signatures. Each is (label, regex over the name+definition, why).
VANITY_PATTERNS = [
    ("raw_output_count",
     r"\b(number of (commits|lines|tickets|tasks|features) (produced|written)|"
     r"total (commits|features|tickets) shipped)\b",
     "raw output counts reward volume, not outcome"),
    ("lines_of_code",
     r"\b(lines of code|loc\b|sloc\b|kloc\b)",
     "lines of code measure typing, not value"),
    ("individual_utilization",
     r"\b(individual|per[- ]?person|per[- ]?developer|per[- ]?engineer)\b.*\b(utili[sz]ation|busy|hours)"
     r"|\butili[sz]ation (rate|%|percent)\b",
     "individual utilization drives local optimization and erodes trust"),
    ("velocity_as_target",
     r"\b(story[- ]?points?|velocity)\b.*\b(target|goal|increase|maximi[sz]e)\b"
     r"|\b(target|maximi[sz]e|increase) .*\bvelocity\b",
     "velocity is an estimation aid, not a productivity target"),
]


def sample_catalog() -> dict:
    return {
        "program": "Program",
        "kpis": [
            {"name": "Delivery cycle time", "definition": "Median calendar time from work item "
             "started to delivered, per period.", "data_source": "issue tracker",
             "target": 5.0, "owner": "pod_lead", "direction": "lower_is_better", "unit": "days"},
            {"name": "Defect escape rate", "definition": "Share of defects found after release vs "
             "total defects, per period.", "data_source": "issue tracker + CI/CD",
             "target": 0.05, "owner": "qa_validation", "direction": "lower_is_better", "unit": "ratio"},
            {"name": "Privacy-gate first-pass rate", "definition": "Share of releases that passed the "
             "privacy gate on first attempt (aggregate PHI-free pass/fail).",
             "data_source": "validation reports", "target": 0.95, "owner": "privacy_liaison",
             "direction": "higher_is_better", "unit": "ratio"},
            # An intentionally bad KPI to demonstrate the guard:
            {"name": "Lines of code per sprint", "definition": "Total lines of code written by the "
             "team each sprint.", "data_source": "code review", "target": 5000,
             "owner": "pod_lead", "direction": "higher_is_better", "unit": "count"},
        ],
    }


def validate_kpi(kpi: dict) -> dict:
    name = kpi.get("name", "<unnamed>")
    missing = [f for f in REQUIRED_FIELDS if kpi.get(f) in (None, "", [])]
    direction = kpi.get("direction")
    bad_direction = direction is not None and direction not in VALID_DIRECTIONS

    haystack = f"{name} {kpi.get('definition', '')}".lower()
    vanity = []
    for label, pattern, why in VANITY_PATTERNS:
        if re.search(pattern, haystack):
            vanity.append({"flag": label, "why": why})

    ok = not missing and not bad_direction and not vanity
    return {
        "name": name,
        "missing_fields": missing,
        "bad_direction": bad_direction,
        "vanity_flags": vanity,
        "ok": ok,
    }


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description="Validate a KPI catalog; guard against vanity metrics.")
    p.add_argument("--catalog", help="Path to KPI catalog JSON. If omitted, a sample is used.")
    p.add_argument("--out", help="Optional JSON path to write the full report (opt-in write).")
    p.add_argument("--emit-sample", action="store_true",
                   help="Print a sample catalog JSON to stdout and exit.")
    args = p.parse_args(argv)

    if args.emit_sample:
        print(json.dumps(sample_catalog(), indent=2))
        return 0

    if args.catalog:
        try:
            with open(args.catalog, "r", encoding="utf-8") as fh:
                cat = json.load(fh)
        except (OSError, json.JSONDecodeError) as e:
            print(f"ERROR: could not read catalog: {e}", file=sys.stderr)
            return 2
    else:
        print("NOTE: no --catalog given; using built-in sample (includes a deliberate vanity "
              "metric to demonstrate the guard).", file=sys.stderr)
        cat = sample_catalog()

    kpis = cat.get("kpis", [])
    if not kpis:
        print("ERROR: catalog has no kpis.", file=sys.stderr)
        return 2

    results = [validate_kpi(k) for k in kpis]
    print(f"KPI catalog validation — program '{cat.get('program', 'Program')}' "
          f"({len(kpis)} KPIs)")
    print("-" * 72)
    n_ok = 0
    for r in results:
        if r["ok"]:
            n_ok += 1
            print(f"[PASS] {r['name']}")
            continue
        print(f"[FAIL] {r['name']}")
        if r["missing_fields"]:
            print(f"    missing fields: {', '.join(r['missing_fields'])}")
        if r["bad_direction"]:
            print(f"    direction must be one of {VALID_DIRECTIONS}")
        for v in r["vanity_flags"]:
            print(f"    VANITY: {v['flag']} — {v['why']}")

    # Catalog-size hygiene note (small-set principle).
    if len(kpis) > 10:
        print(f"\nNOTE: {len(kpis)} KPIs exceeds the recommended 6-10; consider pruning.")

    if args.out:
        try:
            with open(args.out, "w", encoding="utf-8") as fh:
                json.dump({"program": cat.get("program"), "results": results}, fh, indent=2)
            print(f"\nWrote validation report to {args.out}")
        except OSError as e:
            print(f"ERROR: could not write --out: {e}", file=sys.stderr)
            return 2

    print("-" * 72)
    if n_ok == len(kpis):
        print(f"RESULT: PASS — all {n_ok} KPIs are well-formed and non-vanity.")
        return 0
    print(f"RESULT: FAIL — {len(kpis) - n_ok} of {len(kpis)} KPIs need attention.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
