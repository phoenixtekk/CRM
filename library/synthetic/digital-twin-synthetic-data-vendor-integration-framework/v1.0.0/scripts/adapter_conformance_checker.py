#!/usr/bin/env python3
# adapter_conformance_checker.py — check data-in/data-out adapter round-trip & native-shape leaks
#
# PURPOSE: Verify the vendor adapters are lossless for in-scope fields and that no vendor-native
#          keys leak past the adapter boundary into the harness-facing output. Read-only: it
#          compares fixtures and reports; it writes nothing. This is the Gate C tool.
# HOW TO RUN: python adapter_conformance_checker.py --fixtures fixtures.json   (Python 3.10+; see --help)
# EXPECTED RESULTS: A per-fixture round-trip report of lost/added/drifted fields plus any leaked
#          vendor-native keys, ending in "GATE C: PASS" or "GATE C: FAIL".
"""Adapter conformance checker.

A fixture pairs an EXPECTED target-model record with the ACTUAL record your data-out adapter
produced from the vendor output (and, for data-in, what the vendor was fed). This tool never
calls the vendor and needs no PHI — run it with synthetic fixtures. Keeping vendor-native keys
out of the harness-facing record is the core anti-lock-in check.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def load_json(path: str):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except FileNotFoundError:
        sys.exit(f"ERROR: file not found: {path}")
    except json.JSONDecodeError as exc:
        sys.exit(f"ERROR: invalid JSON in {path}: {exc}")


def check_record(expected: dict, actual: dict, in_scope: list[str],
                 native_prefixes: list[str]) -> dict:
    lost, drifted = [], []
    for f in in_scope:
        if f not in actual or actual[f] in (None, ""):
            lost.append(f)
        elif expected.get(f) != actual.get(f):
            drifted.append((f, expected.get(f), actual.get(f)))
    # native-shape leak: keys that look like the vendor's own naming reaching the harness
    leaked = [k for k in actual
              if any(k.startswith(p) for p in native_prefixes) or k.startswith("_vendor")]
    return {"lost": lost, "drifted": drifted, "leaked": leaked}


def main() -> int:
    ap = argparse.ArgumentParser(description="Check adapter round-trip fidelity and native-shape leaks.")
    ap.add_argument("--fixtures", required=True,
                    help="JSON: {in_scope:[...], native_prefixes:[...], cases:[{name,expected,actual}]}")
    ap.add_argument("--direction", choices=["in", "out", "both"], default="both",
                    help="Which adapter direction the fixtures represent (reporting label only).")
    args = ap.parse_args()

    spec = load_json(args.fixtures)
    in_scope = spec.get("in_scope")
    cases = spec.get("cases")
    if not in_scope or not cases:
        sys.exit("ERROR: fixtures must define 'in_scope' fields and non-empty 'cases'.")
    native_prefixes = spec.get("native_prefixes", [])

    print(f"Gate C — Adapter conformance ({args.direction})")
    print("=" * 50)
    total_problems = 0
    for case in cases:
        name = case.get("name", "<case>")
        res = check_record(case.get("expected", {}), case.get("actual", {}),
                           in_scope, native_prefixes)
        problems = len(res["lost"]) + len(res["drifted"]) + len(res["leaked"])
        total_problems += problems
        status = "OK" if problems == 0 else "PROBLEM"
        print(f"\n[{status}] {name}")
        if res["lost"]:
            print(f"    lost in-scope fields : {res['lost']}")
        for f, e, a in res["drifted"]:
            print(f"    drifted '{f}': expected {e!r} got {a!r}")
        if res["leaked"]:
            print(f"    vendor-native leak   : {res['leaked']}")

    print("\n" + "-" * 50)
    if total_problems == 0:
        print("round-trip lossless for in-scope fields; no native-shape leaks")
        print("GATE C: PASS")
        return 0
    print(f"{total_problems} problem(s) across {len(cases)} case(s)")
    print("GATE C: FAIL — fix the adapter(s); keep vendor-native keys out of the harness.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
