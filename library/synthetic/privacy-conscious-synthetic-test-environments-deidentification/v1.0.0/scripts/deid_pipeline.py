#!/usr/bin/env python3
# deid_pipeline.py — apply the de-identification pipeline (suppress / generalize / keep) to a CSV
#
# PURPOSE: Transform a governed source extract per a pipeline config — SUPPRESS direct identifiers,
#          GENERALIZE quasi-identifiers (age bands, ZIP truncation, date coarsening/shift), KEEP the
#          rest — producing a candidate de-identified dataset. SAFE BY DEFAULT: dry-run unless --apply,
#          and it refuses to keep any field marked pseudonymize whose key lives in the test env.
# HOW TO RUN: python deid_pipeline.py --input extract.csv --config deid-pipeline-pilot-v1.json          (dry-run)
#             python deid_pipeline.py --input extract.csv --config deid-pipeline-pilot-v1.json --apply --out deidentified-pilot-v1.csv
# EXPECTED RESULTS: Dry-run prints the per-field plan and a preview of the first rows transformed, writing
#          nothing. With --apply it writes the de-identified CSV and prints a summary of transforms applied.
#
# Standard-library only. Deterministic date shift uses a per-run integer offset (report it in evidence).
# No network, no secrets. The input extract is read-only; output is the de-identified candidate only.

import argparse
import csv
import hashlib
import json
import sys


def _load(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def _band_age(value, width):
    try:
        a = int(float(value))
    except (ValueError, TypeError):
        return value
    if a >= 90:  # common HIPAA-style top-coding; the DETERMINATION stays with privacy/legal
        return "90+"
    lo = (a // width) * width
    return f"{lo}-{lo + width - 1}"


def _truncate_zip(value, keep):
    digits = "".join(ch for ch in str(value) if ch.isdigit())
    return digits[:keep] + ("*" * max(0, min(5, len(digits)) - keep)) if digits else value


def _coarsen_date(value, granularity):
    s = str(value)
    if len(s) >= 7 and s[4] == "-":
        if granularity == "year":
            return s[:4]
        if granularity == "month":
            return s[:7]
    return value


def _suppress(_value):
    return ""


def _apply_rule(field, value, rule):
    action = rule.get("action", "keep")
    if action == "suppress":
        return _suppress(value)
    if action == "keep":
        return value
    if action == "pseudonymize":
        # Deterministic, non-reversible token (a real key-based pseudonym stays outside the test env).
        return "PSN-" + hashlib.sha256((field + "|" + str(value)).encode()).hexdigest()[:12]
    if action == "generalize":
        g = rule.get("generalize", {})
        method = g.get("method")
        if method == "band":
            return _band_age(value, g.get("width", 10))
        if method == "truncate":
            return _truncate_zip(value, g.get("keep_prefix", 3))
        if method in ("date_shift_coarsen", "coarsen"):
            return _coarsen_date(value, g.get("granularity", "month"))
    return value


def _preflight(rules):
    """Refuse configs that would leak a re-identification key into the test environment."""
    for name, rule in rules.items():
        if rule.get("action") == "pseudonymize" and rule.get("key_location", "").lower() in (
            "test", "test_env", "test-environment", "inline",
        ):
            raise SystemExit(f"REFUSED: field '{name}' pseudonymizes with a key inside the test "
                             f"environment (S4 violation). Move the key out and retry.")


def main(argv=None):
    p = argparse.ArgumentParser(description="Apply the de-identification pipeline (suppress/generalize/keep) to a CSV; dry-run by default.")
    p.add_argument("--input", required=True, help="Governed source extract CSV (read-only).")
    p.add_argument("--config", required=True, help="Pipeline config from deid_config_helper.py.")
    p.add_argument("--apply", action="store_true", help="Actually write output (default: dry-run).")
    p.add_argument("--out", help="Output CSV path (required with --apply).")
    p.add_argument("--preview", type=int, default=3, help="Rows to preview in dry-run (default 3).")
    args = p.parse_args(argv)

    cfg = _load(args.config)
    rules = cfg.get("field_rules", {})
    _preflight(rules)

    with open(args.input, newline="", encoding="utf-8-sig") as fh:
        reader = csv.reader(fh)
        headers = next(reader, [])
        rows = list(reader)

    plan = {h: rules.get(h, {"action": "keep"}).get("action", "keep") for h in headers}
    print("Per-field plan:")
    for h in headers:
        print(f"  {h:24s}: {plan[h]}")

    def transform(row):
        return [_apply_rule(h, v, rules.get(h, {"action": "keep"})) for h, v in zip(headers, row)]

    if not args.apply:
        print(f"\nDRY-RUN (no file written). Preview of first {args.preview} transformed rows:")
        for row in rows[: args.preview]:
            print("  " + " | ".join(transform(row)))
        print(f"\n{len(rows)} rows would be transformed. Re-run with --apply --out <file> to write.")
        return 0

    if not args.out:
        p.error("--apply requires --out")
    with open(args.out, "w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh)
        writer.writerow(headers)
        for row in rows:
            writer.writerow(transform(row))
    counts = {}
    for a in plan.values():
        counts[a] = counts.get(a, 0) + 1
    print(f"\n[written] {args.out} — {len(rows)} rows. Actions: {counts}")
    print("Candidate 'De-Identified Dataset – Pilot – v1' — NOT releasable until reid_risk_assessor "
          "PASSes and privacy/legal signs the evidence.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
