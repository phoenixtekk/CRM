#!/usr/bin/env python3
# plan-migration-waves.py — wave planner + throttling guidance for CloudM migration passes
#
# PURPOSE: Read-only planning. Groups a user list into sequenced migration waves (pilot first,
#          then department cohorts), orders pre-stage/delta passes, and computes concurrency
#          guidance to stay under Microsoft Graph / Google API throttling ceilings. Writes nothing
#          remote; optional local plan CSV only with --apply.
# HOW TO RUN: python plan-migration-waves.py --userlist userlist.csv [--wave-size 250] [--apply]
#             (Python 3.10+; standard library only). See --help.
# EXPECTED RESULTS: A printed wave plan (pilot + numbered department waves) with per-wave pre-stage/
#          delta sequencing and a recommended concurrency ceiling. Advisory only.
#
# SAFETY: read-only planning; --apply writes only a local plan CSV. No credentials, no secrets, no
#          remote calls. Throttling numbers are guidance — real provider limits vary; verify.

import argparse
import csv
import math
import sys
from collections import defaultdict

# Advisory concurrency ceilings. Provider throttling (Microsoft Graph/Exchange, Gmail/Drive) is
# dynamic and tenant-dependent; these are conservative starting points to tune down when throttled.
DEFAULT_MAX_CONCURRENT_USERS = 40   # simultaneous user migrations across the platform
PILOT_WAVE_SIZE = 40                # pilot cohort target


def load_userlist(path):
    rows = []
    with open(path, newline="", encoding="utf-8-sig") as fh:
        reader = csv.DictReader(fh)
        norm = {c: (c or "").strip().lower() for c in (reader.fieldnames or [])}
        for raw in reader:
            r = {norm.get(k, k): v for k, v in raw.items()}
            src = (r.get("sourceemail") or r.get("source") or r.get("upn") or "").strip().lower()
            dept = (r.get("department") or r.get("dept") or "Unassigned").strip() or "Unassigned"
            size = _to_float(r.get("mailbox_size_gb")) + _to_float(r.get("onedrive_size_gb"))
            if src:
                rows.append({"source": src, "dept": dept, "size_gb": size})
    return rows


def _to_float(v):
    try:
        return float(str(v).replace(",", "").strip())
    except (TypeError, ValueError):
        return 0.0


def plan_waves(rows, wave_size, pilot_size, max_concurrent):
    """Build a pilot wave, then department-cohort waves capped at wave_size."""
    waves = []

    # Pilot: spread across departments, prefer a mix of sizes.
    by_size = sorted(rows, key=lambda r: r["size_gb"], reverse=True)
    pilot = by_size[:max(1, pilot_size)] if rows else []
    pilot_src = {r["source"] for r in pilot}
    waves.append({"name": "Migration Wave – Pilot – Wave0", "users": pilot})

    remaining = [r for r in rows if r["source"] not in pilot_src]
    by_dept = defaultdict(list)
    for r in remaining:
        by_dept[r["dept"]].append(r)

    idx = 1
    for dept in sorted(by_dept):
        members = by_dept[dept]
        for chunk_start in range(0, len(members), wave_size):
            chunk = members[chunk_start:chunk_start + wave_size]
            waves.append({
                "name": f"Migration Wave – {dept} – Wave{idx}",
                "users": chunk,
            })
            idx += 1

    for w in waves:
        n = len(w["users"])
        total_gb = round(sum(u["size_gb"] for u in w["users"]), 1)
        # Concurrency: don't exceed the ceiling; scale down for very large cohorts.
        conc = min(max_concurrent, max(1, n))
        w["metrics"] = {"users": n, "total_gb": total_gb, "concurrency": conc}
    return waves


def print_plan(waves):
    print("== Migration Wave Plan (advisory; tune throttling live) ==")
    print(f"{'Wave':45s} {'Users':>6s} {'Data GB':>9s} {'Concurrency':>12s}")
    for w in waves:
        m = w["metrics"]
        print(f"{w['name']:45s} {m['users']:>6d} {m['total_gb']:>9.1f} {m['concurrency']:>12d}")
    print("\nSequencing per wave:")
    print("  1) Scan (read-only baseline)")
    print("  2) Pre-stage (bulk historical copy, off-hours, ahead of change window)")
    print("  3) Delta (in change window) -> MX cutover -> post-cutover Delta")
    print("  4) Validate (validate-migration-report.py) before closing the wave")
    print("\nThrottling guidance:")
    print("  - Start at the shown concurrency; on repeated HTTP 429 / provider backoff, halve it.")
    print("  - Keep total simultaneous user migrations across ALL running waves under the ceiling.")
    print("  - Provider limits (Microsoft Graph/Exchange, Gmail/Drive) vary by tenant — verify.")


def write_plan_csv(path, waves):
    with open(path, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["Wave", "SourceEmail", "Department", "SizeGB"])
        for wave in waves:
            for u in wave["users"]:
                w.writerow([wave["name"], u["source"], u["dept"], round(u["size_gb"], 2)])


def main():
    p = argparse.ArgumentParser(description="Plan CloudM migration waves + throttling guidance.")
    p.add_argument("--userlist", required=True, help="User-list CSV (from build-migration-userlist.py).")
    p.add_argument("--wave-size", type=int, default=250, help="Max users per production wave (default 250).")
    p.add_argument("--pilot-size", type=int, default=PILOT_WAVE_SIZE, help="Pilot cohort size.")
    p.add_argument("--max-concurrent", type=int, default=DEFAULT_MAX_CONCURRENT_USERS,
                   help="Advisory ceiling on simultaneous user migrations.")
    p.add_argument("--out", default="wave-plan.csv", help="Plan CSV path (with --apply).")
    p.add_argument("--apply", action="store_true", help="Write the plan CSV (default is print-only).")
    args = p.parse_args()

    rows = load_userlist(args.userlist)
    if not rows:
        sys.exit("No users found in --userlist. Nothing to plan.")

    waves = plan_waves(rows, args.wave_size, args.pilot_size, args.max_concurrent)
    print_plan(waves)
    print(f"\nTotal users: {len(rows)}  |  Total waves: {len(waves)} "
          f"(1 pilot + {len(waves) - 1} production)")

    if args.apply:
        write_plan_csv(args.out, waves)
        print(f"Wrote plan to {args.out}.")
    else:
        print("Print-only. Re-run with --apply to write the plan CSV.")


if __name__ == "__main__":
    main()
