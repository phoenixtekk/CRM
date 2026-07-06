#!/usr/bin/env python3
# synfid_coverage.py — check a synthetic dataset against a coverage / edge-case specification
#
# PURPOSE: Coverage / edge-case checker & scenario enumerator. Evaluates a synthetic dataset against
#          a Coverage Specification (required cohorts / value ranges / combinations, each with a
#          minimum representation) and reports which are met and which are gaps. Can also enumerate
#          the scenario slices a dataset must exercise. Read-only: reports only, writes nothing.
# HOW TO RUN: python synfid_coverage.py check --data synth.csv --config validation_suite.json
#             python synfid_coverage.py enumerate --config validation_suite.json
#             (Python 3.10+, standard library only; see --help)
# EXPECTED RESULTS: A per-target coverage report with observed fraction vs minimum and PASS/FAIL,
#                   plus an overall coverage verdict. Non-zero exit when any required cohort is unmet.

import argparse
import csv
import json
import re
import sys

# Supported rule grammar: space/AND-separated predicates, each  <field><op><value>
# ops: ==, !=, >=, <=, >, <   joined by 'AND'. Deliberately small + safe (no eval).
PRED_RE = re.compile(r"^\s*([A-Za-z0-9_.]+)\s*(==|!=|>=|<=|>|<)\s*(.+?)\s*$")


def load_json(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def read_rows(path):
    with open(path, newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def _coerce(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return v


def _cmp(a, op, b):
    # numeric compare when both numeric, else string equality ops only
    an, bn = _coerce(a), _coerce(b)
    both_num = isinstance(an, float) and isinstance(bn, float)
    if op == "==":
        return (an == bn) if both_num else (str(a) == str(b))
    if op == "!=":
        return (an != bn) if both_num else (str(a) != str(b))
    if not both_num:
        return False
    return {">=": an >= bn, "<=": an <= bn, ">": an > bn, "<": an < bn}[op]


def parse_rule(rule):
    preds = [p for p in re.split(r"\bAND\b", rule) if p.strip()]
    parsed = []
    for p in preds:
        m = PRED_RE.match(p)
        if not m:
            raise ValueError(f"unparseable predicate: '{p.strip()}'")
        field, op, val = m.group(1), m.group(2), m.group(3).strip().strip("'\"")
        parsed.append((field, op, val))
    return parsed


def row_matches(row, preds):
    for field, op, val in preds:
        if field not in row:
            return False
        if not _cmp(row.get(field, ""), op, val):
            return False
    return True


def cmd_check(args):
    config = load_json(args.config)
    targets = config.get("coverage_targets", [])
    if not targets:
        print("[WARN] no coverage_targets in config; nothing to check.")
        return 0
    rows = read_rows(args.data)
    n = len(rows) or 1
    report = {"n_rows": len(rows), "targets": [], "verdict": "PASS"}
    failures = []
    for t in targets:
        try:
            preds = parse_rule(t["rule"])
        except ValueError as e:
            report["targets"].append({"name": t.get("name"), "status": "RULE_ERROR", "error": str(e)})
            failures.append(f"{t.get('name')}: {e}")
            continue
        matched = sum(1 for r in rows if row_matches(r, preds))
        frac = round(matched / n, 6)
        min_frac = t.get("min_fraction", 0.0)
        ok = frac >= min_frac
        report["targets"].append({
            "name": t.get("name"), "rule": t["rule"], "matched": matched,
            "observed_fraction": frac, "min_fraction": min_frac,
            "status": "PASS" if ok else "FAIL"})
        if not ok:
            failures.append(f"{t.get('name')}: observed {frac} < required {min_frac}")
    if failures:
        report["verdict"] = "FAIL"
        report["gaps"] = failures
    print(json.dumps(report, indent=2))
    return 0 if report["verdict"] == "PASS" else 1


def cmd_enumerate(args):
    config = load_json(args.config)
    targets = config.get("coverage_targets", [])
    out = {"scenario_slices": [{"name": t.get("name"), "rule": t.get("rule"),
                                "min_fraction": t.get("min_fraction", 0.0)} for t in targets]}
    print(json.dumps(out, indent=2))
    return 0


def build_parser():
    p = argparse.ArgumentParser(description="Coverage / edge-case checker & scenario enumerator.")
    sub = p.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("check", help="Check a dataset against the coverage spec.")
    c.add_argument("--data", required=True, help="Synthetic dataset CSV.")
    c.add_argument("--config", required=True, help="Validation Suite config JSON.")
    c.set_defaults(func=cmd_check)
    e = sub.add_parser("enumerate", help="List the scenario slices the dataset must exercise.")
    e.add_argument("--config", required=True, help="Validation Suite config JSON.")
    e.set_defaults(func=cmd_enumerate)
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
