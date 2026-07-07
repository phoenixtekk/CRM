#!/usr/bin/env python3
# gwmme_config_helper.py — mapping/config validator, wave-subset builder, and throttle-budget check
#
# PURPOSE: Scope/config helper for GWMME. Validates the master mapping CSV (1:1 source->target, no
#          duplicates, well-formed), derives a per-wave mapping subset GWMME can consume, and computes
#          a throttle-budget summary (concurrency and estimated run time per wave) so batches respect
#          source/destination limits. Read-only / generate-only: writes CSV artifacts, never migrates.
# HOW TO RUN: python gwmme_config_helper.py --mapping planned-mapping.csv --validate
#             python gwmme_config_helper.py --mapping planned-mapping.csv --wave Pilot-01 \
#                 --out Wave-Pilot-01.csv
#             python gwmme_config_helper.py --mapping planned-mapping.csv --throttle-check \
#                 --concurrency 4 --mb-per-min 300
#             (Python 3.10+; standard library only. --help for all modes.)
# EXPECTED RESULTS: --validate prints PASS/FAIL on mapping integrity; --wave writes the wave's subset
#                   CSV; --throttle-check prints per-wave concurrency and estimated run-time headroom.

import argparse
import csv
import sys

REQUIRED = ["source_smtp", "target_google_email"]


def load(path):
    with open(path, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        fields = list(reader.fieldnames or [])
        rows = list(reader)
    have = {c.lower().strip() for c in fields}
    missing = [c for c in REQUIRED if c not in have]
    if missing:
        sys.exit(f"ERROR: mapping missing required columns: {', '.join(missing)}")
    return rows, fields


def validate(rows):
    seen_src, seen_tgt, problems = set(), set(), []
    for i, r in enumerate(rows, start=2):
        src = (r.get("source_smtp") or "").strip().lower()
        tgt = (r.get("target_google_email") or "").strip().lower()
        if not src or not tgt:
            problems.append(f"row {i}: blank source/target")
            continue
        if "@" not in tgt:
            problems.append(f"row {i}: target '{tgt}' is not an email")
        if src in seen_src:
            problems.append(f"row {i}: duplicate source {src}")
        if tgt in seen_tgt:
            problems.append(f"row {i}: duplicate target {tgt}")
        seen_src.add(src)
        seen_tgt.add(tgt)
    return problems


def write_subset(rows, fields, wave, out):
    subset = [r for r in rows if (r.get("wave") or "").strip() == wave]
    if not subset:
        sys.exit(f"ERROR: no rows for wave '{wave}'. Assign waves first (gwmme_batch_planner.py).")
    write_fields = [c for c in fields if not c.startswith("_")]
    with open(out, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=write_fields, extrasaction="ignore")
        w.writeheader()
        for r in subset:
            w.writerow({k: r.get(k, "") for k in write_fields})
    print(f"Wrote wave subset '{wave}': {out} ({len(subset)} mailboxes)")


def throttle_check(rows, concurrency, mb_per_min):
    """Estimate per-wave run time from data volume, concurrency, and a per-slot throughput budget.

    mb_per_min is the assumed sustained throughput PER concurrent slot (verify against your source's
    throttling and your observed pilot rate — this is a planning estimate, not a guarantee).
    """
    waves = {}
    for r in rows:
        w = (r.get("wave") or "unassigned").strip() or "unassigned"
        try:
            mb = float(r.get("size_mb") or 0)
        except ValueError:
            mb = 0.0
        d = waves.setdefault(w, {"count": 0, "mb": 0.0})
        d["count"] += 1
        d["mb"] += mb

    rate = max(mb_per_min, 1) * max(concurrency, 1)
    print(f"Throttle budget: {concurrency} concurrent slot(s) x {mb_per_min} MB/min "
          f"= ~{rate:.0f} MB/min aggregate")
    print(f"{'Wave':<14}{'Mailboxes':>10}{'GB':>8}{'Est. min':>10}{'Est. hrs':>10}")
    print("-" * 52)
    for name in sorted(waves):
        d = waves[name]
        minutes = d["mb"] / rate
        print(f"{name:<14}{d['count']:>10}{d['mb']/1024:>8.1f}{minutes:>10.0f}{minutes/60:>10.1f}")
    print("-" * 52)
    print("NOTE: estimates are planning aids — validate against your pilot's observed rate and "
          "your source's documented throttling limits (verify for your version).")


def main():
    ap = argparse.ArgumentParser(description="GWMME mapping/config helper + throttle-budget check "
                                             "(read-only / generate-only).")
    ap.add_argument("--mapping", required=True, help="Mapping CSV (master or wave-assigned).")
    ap.add_argument("--validate", action="store_true", help="Validate mapping integrity.")
    ap.add_argument("--wave", help="Write the subset CSV for this wave (with --out).")
    ap.add_argument("--out", default="gwmme-wave-subset.csv", help="Output path for --wave subset.")
    ap.add_argument("--throttle-check", action="store_true",
                    help="Print per-wave concurrency/run-time estimate.")
    ap.add_argument("--concurrency", type=int, default=4,
                    help="Concurrent mailbox slots for throttle estimate (default 4).")
    ap.add_argument("--mb-per-min", type=float, default=300.0,
                    help="Assumed sustained MB/min per slot for throttle estimate (default 300).")
    args = ap.parse_args()

    rows, fields = load(args.mapping)
    if not (args.validate or args.wave or args.throttle_check):
        sys.exit("Nothing to do: choose --validate, --wave, and/or --throttle-check.")

    failed = False
    if args.validate:
        problems = validate(rows)
        if problems:
            failed = True
            print("RESULT: FAIL — mapping integrity problems:")
            for p in problems[:20]:
                print(f"  - {p}")
            if len(problems) > 20:
                print(f"  … and {len(problems) - 20} more")
        else:
            print(f"RESULT: PASS — {len(rows)} rows, 1:1 source->target, no duplicates.")

    if args.wave:
        write_subset(rows, fields, args.wave, args.out)

    if args.throttle_check:
        throttle_check(rows, args.concurrency, args.mb_per_min)

    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
