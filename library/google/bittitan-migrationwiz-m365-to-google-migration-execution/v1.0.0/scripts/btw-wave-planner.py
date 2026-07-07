#!/usr/bin/env python3
# btw-wave-planner.py — pre-stage/delta wave planner + throttling guidance for a MigrationWiz move
#
# PURPOSE: Turn a flat user list into balanced migration waves and, per project, emit a pre-stage/delta pass
#          schedule ("BTW Pass - Pre-Stage - Per Wave" / "BTW Pass - Delta Cutover - Per Wave") plus a
#          throttling profile ("BTW Throttle - Project Concurrency - Per Wave") with concurrency guidance that
#          keeps passes within provider limits. Planning only: dry-run by default, writes no config, calls no
#          MigrationWiz API. Provider limits and MigrationWiz concurrency controls are "verify for your version".
# HOW TO RUN: python btw-wave-planner.py --in users.csv --wave-size 250 --prestage-age-days 30 \
#             [--target-items-per-hour 90000] [--out plan.json]   (Python 3.10+; stdlib only; see --help)
# EXPECTED RESULTS: A printed wave/pass table + throttling guidance and an optional JSON plan. Advisory only —
#             always confirm the concurrency ceiling against the provider's current limits for your tenant.
#
# Standard-library only (csv, argparse, json, math). No credentials used or needed.
# Input CSV (header): user[,data_gb]  — user identifier and optional per-user data volume in GB.

import argparse
import csv
import json
import math
import sys


def load_users(path):
    with open(path, newline="", encoding="utf-8-sig") as fh:
        rows = list(csv.DictReader(fh))
    users = []
    for r in rows:
        u = (r.get("user") or "").strip()
        if not u:
            continue
        try:
            gb = float(r.get("data_gb") or 0)
        except ValueError:
            gb = 0.0
        users.append({"user": u, "data_gb": gb})
    if not users:
        print(f"ERROR: no users in {path} (expected header 'user[,data_gb]').", file=sys.stderr)
        sys.exit(2)
    return users


def make_waves(users, wave_size):
    """Split into waves of <= wave_size, keeping the pilot (wave 0) small and representative-sized."""
    waves = []
    # Wave 0 (pilot) is intentionally small.
    pilot_size = min(len(users), max(10, wave_size // 10))
    waves.append({"wave": 0, "label": "BTW Wave - Pilot - Wave 0", "users": users[:pilot_size]})
    rest = users[pilot_size:]
    for idx, start in enumerate(range(0, len(rest), wave_size), start=1):
        chunk = rest[start:start + wave_size]
        waves.append({"wave": idx, "label": f"BTW Wave - Segment{idx} - Per Wave", "users": chunk})
    return waves


def plan_wave(wave, prestage_age_days, items_per_hour, avg_items_per_gb):
    n = len(wave["users"])
    total_gb = round(sum(u["data_gb"] for u in wave["users"]), 1)
    est_items = int(total_gb * avg_items_per_gb)
    prestage_hours = round(est_items / items_per_hour, 1) if items_per_hour else None
    # Delta is only recent change; estimate as a small fraction of pre-stage.
    delta_hours = round((prestage_hours or 0) * 0.1, 1) if prestage_hours else None
    return {
        "wave": wave["wave"],
        "label": wave["label"],
        "users": n,
        "total_gb": total_gb,
        "prestage_pass": "BTW Pass - Pre-Stage - Per Wave",
        "prestage_age_filter_days": prestage_age_days,
        "est_prestage_hours": prestage_hours,
        "delta_pass": "BTW Pass - Delta Cutover - Per Wave",
        "est_delta_hours": delta_hours,
        "throttle_profile": "BTW Throttle - Project Concurrency - Per Wave",
    }


def main():
    ap = argparse.ArgumentParser(description="Plan MigrationWiz pre-stage/delta waves + throttling guidance.")
    ap.add_argument("--in", dest="infile", required=True, help="Users CSV (header: user[,data_gb]).")
    ap.add_argument("--wave-size", type=int, default=250,
                    help="Max users per production wave (default 250 — verify per-project limits for your version).")
    ap.add_argument("--prestage-age-days", type=int, default=30,
                    help="Pre-stage age filter: bulk-move items older than N days (default 30).")
    ap.add_argument("--target-items-per-hour", type=int, default=90000,
                    help="Assumed sustained target items/hour for estimates (advisory; verify for your tenant).")
    ap.add_argument("--avg-items-per-gb", type=int, default=4000,
                    help="Assumed items per GB for item-count estimates (advisory).")
    ap.add_argument("--out", help="Write the JSON plan here.")
    args = ap.parse_args()

    users = load_users(args.infile)
    waves = make_waves(users, args.wave_size)
    plans = [plan_wave(w, args.prestage_age_days, args.target_items_per_hour, args.avg_items_per_gb)
             for w in waves]

    print("== BTW Wave Plan (pre-stage/delta) — advisory, dry-run ==")
    print(f"  {len(users)} users -> {len(waves)} wave(s); pre-stage age filter: "
          f">{args.prestage_age_days} days old\n")
    hdr = f"  {'Wave':<6}{'Label':<30}{'Users':>6}{'GB':>8}{'Pre-stage h':>12}{'Delta h':>9}"
    print(hdr)
    print("  " + "-" * (len(hdr) - 2))
    for p in plans:
        print(f"  {p['wave']:<6}{p['label']:<30}{p['users']:>6}{p['total_gb']:>8}"
              f"{str(p['est_prestage_hours']):>12}{str(p['est_delta_hours']):>9}")

    print("\n== Throttling guidance (BTW Throttle - Project Concurrency - Per Wave) ==")
    print("  - Pre-stage heavy, delta light: bulk-move older items ahead of cutover; the delta pass")
    print("    at cutover moves only what changed since pre-stage.")
    print("  - Start conservative on target concurrency; watch for sustained backoff/429s with")
    print("    btw-throttle-health-check.py and LOWER concurrency rather than raising it.")
    print(f"  - Estimates assume ~{args.target_items_per_hour} items/hour sustained — VERIFY the current")
    print("    provider limits for your tenant and MigrationWiz's concurrency controls for your version.")

    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump({"artifact": "BTW Wave Plan", "waves": plans,
                       "assumptions": {"items_per_hour": args.target_items_per_hour,
                                       "avg_items_per_gb": args.avg_items_per_gb,
                                       "prestage_age_days": args.prestage_age_days}}, fh, indent=2)
        print(f"\n  Plan written: {args.out}")
    sys.exit(0)


if __name__ == "__main__":
    main()
