#!/usr/bin/env python3
# champion_roster_planner.py — build wave-aligned champion cohorts and check coverage ratio.
#
# PURPOSE: Turn a CSV of business-unit champion NOMINATIONS plus the migration WAVE schedule into
#          wave-aligned "Champion Cohort - <BU> - Wave N" assignments, and check each wave's coverage
#          against a target ratio (users per champion), flagging any wave UNDER_RATIO. Safe default:
#          this is a planning/report tool — it writes a plan CSV only and changes nothing in the tenant.
# HOW TO RUN: python champion_roster_planner.py --roster nominations.csv --waves waves.csv
#             [--ratio 75] [--out champion_plan.csv]   (Python 3.10+; standard library only)
# EXPECTED RESULTS: A plan CSV + stdout coverage table; prints UNDER_RATIO for any wave that lacks
#                   enough champions. Non-zero exit if any wave is under ratio (so it can gate a step).
#
# Input formats (CSV headers):
#   nominations.csv : name,email,business_unit,wave            (one champion per row)
#   waves.csv       : wave,business_unit,user_count            (planned users per BU per wave)
# No credentials, no API calls, no secrets.

import argparse
import csv
import math
import sys
from collections import defaultdict


def read_csv(path: str) -> list[dict]:
    try:
        with open(path, newline="", encoding="utf-8") as fh:
            return list(csv.DictReader(fh))
    except FileNotFoundError:
        sys.exit(f"ERROR: file not found: {path}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Plan champion cohorts and check coverage ratio.")
    ap.add_argument("--roster", required=True, help="Nominations CSV: name,email,business_unit,wave")
    ap.add_argument("--waves", required=True, help="Waves CSV: wave,business_unit,user_count")
    ap.add_argument("--ratio", type=int, default=75,
                    help="Target users per champion (default 75; tune per Requirements #6).")
    ap.add_argument("--out", default="champion_plan.csv", help="Output plan CSV path.")
    args = ap.parse_args()

    if args.ratio <= 0:
        sys.exit("ERROR: --ratio must be a positive integer.")

    noms = read_csv(args.roster)
    waves = read_csv(args.waves)

    # champions[(wave, bu)] = [emails]
    champions: dict[tuple[str, str], list[str]] = defaultdict(list)
    for r in noms:
        wave = (r.get("wave") or "").strip()
        bu = (r.get("business_unit") or "").strip()
        email = (r.get("email") or r.get("name") or "").strip()
        if wave and bu and email:
            champions[(wave, bu)].append(email)

    rows, under = [], 0
    print(f"{'Cohort':38} {'Users':>7} {'Champs':>7} {'Need':>6} {'Status':>12}")
    for w in waves:
        wave = (w.get("wave") or "").strip()
        bu = (w.get("business_unit") or "").strip()
        try:
            users = int(float(w.get("user_count") or 0))
        except ValueError:
            users = 0
        have = len(champions.get((wave, bu), []))
        need = math.ceil(users / args.ratio) if users else 0
        status = "OK" if have >= need else "UNDER_RATIO"
        if status == "UNDER_RATIO":
            under += 1
        cohort = f"Champion Cohort - {bu} - {wave}"
        print(f"{cohort:38} {users:7d} {have:7d} {need:6d} {status:>12}")
        rows.append({"cohort": cohort, "wave": wave, "business_unit": bu,
                     "user_count": users, "champions": have, "champions_needed": need,
                     "shortfall": max(0, need - have), "status": status,
                     "champion_emails": ";".join(champions.get((wave, bu), []))})

    with open(args.out, "w", newline="", encoding="utf-8") as fh:
        wcsv = csv.DictWriter(fh, fieldnames=["cohort", "wave", "business_unit", "user_count",
                                              "champions", "champions_needed", "shortfall",
                                              "status", "champion_emails"])
        wcsv.writeheader()
        wcsv.writerows(rows)

    print(f"\nWrote {args.out} (plan only; no tenant changes).")
    if under:
        print(f"GATE: FAIL — {under} wave/BU cohort(s) UNDER_RATIO. Recruit champions before proceeding.")
        return 1
    print("GATE: PASS — all wave/BU cohorts meet the champion ratio.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
