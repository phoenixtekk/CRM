#!/usr/bin/env python3
# gwmme_batch_planner.py — throttle-aware wave planner for GWMME migrations
#
# PURPOSE: Plan migration waves (batches) from the master mapping, respecting a throttling budget.
#          Groups mailboxes into waves sized by count and total data volume, isolates oversized
#          mailboxes into their own smaller waves, and writes the wave assignment back. Dry-run by
#          default: prints/writes a plan; never runs GWMME or moves data.
# HOW TO RUN: python gwmme_batch_planner.py --mapping Mapping-Users-Master.csv \
#                 --max-per-wave 25 --max-wave-gb 50 --big-mailbox-gb 10 --out planned-mapping.csv
#             (Python 3.10+; standard library only. Use --apply to overwrite --mapping in place.)
# EXPECTED RESULTS: A wave-assigned mapping CSV plus a per-wave summary (count, total GB). Oversized
#                   mailboxes land in dedicated 'Big-NN' waves. Review before executing waves in GWMME.

import argparse
import csv
import sys


def load_mapping(path):
    rows = []
    with open(path, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        fields = list(reader.fieldnames or [])
        for r in reader:
            r.setdefault("wave", "")
            try:
                r["_size_gb"] = float(r.get("size_mb") or 0) / 1024.0
            except ValueError:
                r["_size_gb"] = 0.0
            rows.append(r)
    if "wave" not in fields:
        fields.append("wave")
    return rows, fields


def plan_waves(rows, max_per_wave, max_wave_gb, big_gb, pilot_size):
    # Pilot wave first: a small representative set (largest calendar/item mailboxes are good pilots,
    # here we simply take the first N after sorting by size for a representative spread).
    ordered = sorted(rows, key=lambda r: r["_size_gb"])
    pilot = ordered[:pilot_size]
    for r in pilot:
        r["wave"] = "Pilot-01"
    remaining = ordered[pilot_size:]

    big = [r for r in remaining if r["_size_gb"] >= big_gb]
    normal = [r for r in remaining if r["_size_gb"] < big_gb]

    # Oversized mailboxes: one (or few) per dedicated Big wave.
    for i, r in enumerate(big, start=1):
        r["wave"] = f"Big-{i:02d}"

    # Normal mailboxes: fill waves up to count AND volume budget.
    wave_num, count, vol = 1, 0, 0.0
    for r in normal:
        if count >= max_per_wave or (vol + r["_size_gb"] > max_wave_gb and count > 0):
            wave_num += 1
            count, vol = 0, 0.0
        r["wave"] = f"Wave-{wave_num:02d}"
        count += 1
        vol += r["_size_gb"]
    return rows


def summarize(rows):
    waves = {}
    for r in rows:
        w = waves.setdefault(r["wave"], {"count": 0, "gb": 0.0})
        w["count"] += 1
        w["gb"] += r["_size_gb"]
    print(f"{'Wave':<12}{'Mailboxes':>10}{'Total GB':>12}")
    print("-" * 34)
    for name in sorted(waves):
        print(f"{name:<12}{waves[name]['count']:>10}{waves[name]['gb']:>12.1f}")
    print("-" * 34)
    print(f"{'TOTAL':<12}{sum(w['count'] for w in waves.values()):>10}"
          f"{sum(w['gb'] for w in waves.values()):>12.1f}")


def main():
    ap = argparse.ArgumentParser(description="Throttle-aware GWMME wave planner (dry-run by default).")
    ap.add_argument("--mapping", required=True, help="Mapping-Users-Master.csv (needs size_mb).")
    ap.add_argument("--max-per-wave", type=int, default=25, help="Max mailboxes per normal wave.")
    ap.add_argument("--max-wave-gb", type=float, default=50.0, help="Max total GB per normal wave.")
    ap.add_argument("--big-mailbox-gb", type=float, default=10.0,
                    help="Mailboxes >= this GB get isolated Big-NN waves.")
    ap.add_argument("--pilot-size", type=int, default=5, help="Mailboxes in the pilot wave.")
    ap.add_argument("--out", default="gwmme-planned-mapping.csv", help="Output CSV path.")
    ap.add_argument("--apply", action="store_true",
                    help="Write the plan back into --mapping in place (default: write to --out only).")
    args = ap.parse_args()

    rows, fields = load_mapping(args.mapping)
    if not rows:
        sys.exit("ERROR: mapping is empty.")
    plan_waves(rows, args.max_per_wave, args.max_wave_gb, args.big_mailbox_gb, args.pilot_size)
    summarize(rows)

    out_path = args.mapping if args.apply else args.out
    mode = "in place (--apply)" if args.apply else "to --out"
    write_fields = [c for c in fields if not c.startswith("_")]
    with open(out_path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=write_fields, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in write_fields})
    print(f"\nWrote wave-assigned mapping {mode}: {out_path}")
    print("NOTE: dry-run planner only — review waves, then run them in GWMME per Implementation §F.")


if __name__ == "__main__":
    main()
