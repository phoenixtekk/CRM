#!/usr/bin/env python3
# synfid_config.py — scaffold/validate a Validation Suite config, draft a Field Manifest, check mapping
#
# PURPOSE: Scope & config helper for the fidelity/validation asset library. Scaffolds a reusable
#          Validation Suite config, drafts a Field Manifest by inferring column types from a
#          synthetic dataset (header + a small sample only), and validates that a manifest maps
#          cleanly to a dataset. Safe by default: writes only with --write (else prints to stdout).
# HOW TO RUN: python synfid_config.py scaffold --out validation_suite.json [--write]
#             python synfid_config.py infer-manifest --data synthetic.csv [--out manifest.json] [--write]
#             python synfid_config.py validate --config validation_suite.json --data synthetic.csv
#             (Python 3.10+, standard library only; see --help)
# EXPECTED RESULTS: A printed (or written) JSON config/manifest, or a PASS/FAIL mapping report with
#                   the exact fields that do not line up. Non-zero exit on validation failure.

import argparse
import csv
import json
import sys
from datetime import datetime, date

TEMPLATE = {
    "asset_name": "Validation Suite - <Use Case> - v1",
    "target_data_model": "FHIR | OMOP | native",
    "field_manifest": "manifest.json",
    "reference_profile": "reference_profile.json",
    "tolerances": {
        "max_distribution_distance": 0.10,   # per numeric field (e.g. normalized Wasserstein/KS)
        "max_category_divergence": 0.10,     # per categorical field (total variation)
        "min_correlation_preservation": 0.85,  # abs correlation delta -> preservation score
        "max_utility_gap": 0.05              # TSTR: real-trained minus synth-trained metric
    },
    "coverage_targets": [
        {"name": "elderly_readmit", "rule": "age>=80 AND readmitted==1", "min_fraction": 0.02}
    ],
    "utility_task": {
        "in_scope": False,
        "target_field": "",
        "task_type": "classification | regression | none"
    },
    "privacy": {
        "quasi_identifiers": [],
        "max_exact_match_fraction": 0.0,
        "min_nearest_neighbor_distance": 0.0
    }
}


def _infer_type(values):
    """Infer a field type from sampled string values. Order matters: int/float, then date, else category."""
    non_null = [v for v in values if v not in ("", None)]
    if not non_null:
        return "unknown"
    is_num = True
    for v in non_null:
        try:
            float(v)
        except (TypeError, ValueError):
            is_num = False
            break
    if is_num:
        # distinguish likely identifier-ints from measures only by cardinality heuristic upstream
        return "numeric"
    is_date = True
    for v in non_null[:50]:
        parsed = False
        for fmt in ("%Y-%m-%d", "%Y-%m-%dT%H:%M:%S", "%m/%d/%Y", "%Y/%m/%d"):
            try:
                datetime.strptime(v, fmt)
                parsed = True
                break
            except ValueError:
                continue
        if not parsed:
            is_date = False
            break
    if is_date:
        return "datetime"
    return "categorical"


def _read_sample(path, sample_rows=500):
    with open(path, newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        header = reader.fieldnames or []
        rows = []
        for i, row in enumerate(reader):
            if i >= sample_rows:
                break
            rows.append(row)
    return header, rows


def cmd_scaffold(args):
    out = json.dumps(TEMPLATE, indent=2)
    if args.write and args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(out + "\n")
        print(f"[written] Validation Suite config -> {args.out}")
    else:
        print("# dry-run: pass --write --out <file> to save. Config preview:")
        print(out)
    return 0


def cmd_infer_manifest(args):
    header, rows = _read_sample(args.data)
    manifest = {"asset_name": "Field Manifest - <Use Case> - v1", "fields": []}
    for col in header:
        col_values = [r.get(col, "") for r in rows]
        distinct = len(set(v for v in col_values if v != ""))
        ftype = _infer_type(col_values)
        lname = col.lower()
        # heuristic role: obvious identifier-ish names or numeric high-cardinality -> identifier
        role = "fidelity"
        if any(k in lname for k in ("id", "mrn", "uuid", "guid", "ssn")):
            role = "identifier"
            ftype = "identifier"
        elif ftype == "categorical" and distinct > max(50, len(rows) // 2):
            role = "free-text"
            ftype = "free-text"
        manifest["fields"].append({
            "name": col,
            "type": ftype,
            "role": role,
            "distinct_sampled": distinct,
        })
    out = json.dumps(manifest, indent=2)
    if args.write and args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(out + "\n")
        print(f"[written] draft Field Manifest -> {args.out}  (REVIEW roles/types before use)")
    else:
        print("# dry-run draft manifest (REVIEW before use; pass --write --out <file> to save):")
        print(out)
    return 0


def cmd_validate(args):
    with open(args.config, encoding="utf-8") as fh:
        config = json.load(fh)
    manifest_path = config.get("field_manifest")
    try:
        with open(manifest_path, encoding="utf-8") as fh:
            manifest = json.load(fh)
    except (OSError, TypeError):
        print(f"[FAIL] cannot open field_manifest '{manifest_path}' referenced by config")
        return 2
    header, _ = _read_sample(args.data, sample_rows=1)
    dataset_cols = set(header)
    problems = []
    for field in manifest.get("fields", []):
        name = field.get("name")
        if name not in dataset_cols:
            problems.append(f"manifest field '{name}' not present in dataset")
    stat_fields = [f["name"] for f in manifest.get("fields", [])
                   if f.get("role") in ("fidelity", "cohort", "key")]
    if not stat_fields:
        problems.append("no in-scope statistical fields (roles fidelity/cohort/key) in manifest")
    if problems:
        print("[FAIL] manifest <-> dataset mapping problems:")
        for p in problems:
            print(f"  - {p}")
        return 1
    print(f"[PASS] manifest maps cleanly to dataset "
          f"({len(manifest.get('fields', []))} fields, {len(stat_fields)} statistical).")
    return 0


def build_parser():
    p = argparse.ArgumentParser(description="Scope & config helper for the fidelity/validation asset library.")
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("scaffold", help="Print/write a Validation Suite config template.")
    s.add_argument("--out", help="Output path (used with --write).")
    s.add_argument("--write", action="store_true", help="Write to --out (default: print only).")
    s.set_defaults(func=cmd_scaffold)

    m = sub.add_parser("infer-manifest", help="Draft a Field Manifest from a dataset's columns.")
    m.add_argument("--data", required=True, help="Synthetic dataset CSV (header + sample read only).")
    m.add_argument("--out", help="Output path (used with --write).")
    m.add_argument("--write", action="store_true", help="Write to --out (default: print only).")
    m.set_defaults(func=cmd_infer_manifest)

    v = sub.add_parser("validate", help="Check a manifest maps cleanly to a dataset.")
    v.add_argument("--config", required=True, help="Validation Suite config JSON.")
    v.add_argument("--data", required=True, help="Synthetic dataset CSV (header read only).")
    v.set_defaults(func=cmd_validate)
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
