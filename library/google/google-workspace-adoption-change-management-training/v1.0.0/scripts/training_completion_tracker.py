#!/usr/bin/env python3
# training_completion_tracker.py — compute per-role training completion and apply the go-live gate.
#
# PURPOSE: Join an LMS/roster COMPLETIONS export to a WAVE roster, compute per-role completion of the
#          role's "Learning Path - <Role> - v1", apply the go-live completion gate, and list
#          stragglers. Safe default: read-only over its input files; writes only a report CSV.
# HOW TO RUN: python training_completion_tracker.py --completions lms_export.csv --roster wave.csv
#             --wave "Wave 0" [--required-rate 0.90] [--out completion.csv]  (Python 3.10+, stdlib only)
# EXPECTED RESULTS: A per-role completion table + GATE: PASS/FAIL, and a CSV of results incl. stragglers.
#                   Non-zero exit if any role is below the required rate (so it can gate go-live).
#
# Input formats (CSV headers):
#   roster.csv      : email,role[,wave]                 (in-scope users for the wave)
#   completions.csv : email,course,status              (status "complete"/"completed"/"pass" counts)
# No credentials, no API calls, no secrets.

import argparse
import csv
import sys
from collections import defaultdict

DONE = {"complete", "completed", "pass", "passed", "done", "yes", "true", "1"}


def read_csv(path: str) -> list[dict]:
    try:
        with open(path, newline="", encoding="utf-8") as fh:
            return list(csv.DictReader(fh))
    except FileNotFoundError:
        sys.exit(f"ERROR: file not found: {path}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Track training completion and apply the go-live gate.")
    ap.add_argument("--completions", required=True, help="LMS export CSV: email,course,status")
    ap.add_argument("--roster", required=True, help="Wave roster CSV: email,role[,wave]")
    ap.add_argument("--wave", default="", help="Wave label (informational, used in output).")
    ap.add_argument("--required-rate", type=float, default=0.90,
                    help="Per-role completion rate required to pass the go-live gate (default 0.90).")
    ap.add_argument("--out", default="completion_report.csv", help="Output CSV path.")
    args = ap.parse_args()

    if not 0 < args.required_rate <= 1:
        sys.exit("ERROR: --required-rate must be in (0, 1].")

    completed = {
        (r.get("email") or "").strip().lower()
        for r in read_csv(args.completions)
        if (r.get("status") or "").strip().lower() in DONE
    }

    by_role: dict[str, list[str]] = defaultdict(list)
    for r in read_csv(args.roster):
        email = (r.get("email") or "").strip().lower()
        role = (r.get("role") or "Unassigned").strip()
        if email:
            by_role[role].append(email)

    print(f"Training completion  (wave: {args.wave or 'n/a'}, required: {args.required_rate:.0%})")
    print(f"{'Role':22} {'Total':>6} {'Done':>6} {'Rate':>7} {'Gate':>6}")
    rows, failed = [], 0
    for role, emails in sorted(by_role.items()):
        total = len(emails)
        done = sum(1 for e in emails if e in completed)
        rate = (done / total) if total else 0.0
        gate = "PASS" if rate >= args.required_rate else "FAIL"
        if gate == "FAIL":
            failed += 1
        stragglers = [e for e in emails if e not in completed]
        print(f"{role:22} {total:6d} {done:6d} {rate:6.0%} {gate:>6}")
        rows.append({"wave": args.wave, "role": role, "path": f"Learning Path - {role} - v1",
                     "total": total, "completed": done, "rate": f"{rate:.4f}", "gate": gate,
                     "stragglers": ";".join(stragglers)})

    with open(args.out, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["wave", "role", "path", "total", "completed",
                                           "rate", "gate", "stragglers"])
        w.writeheader()
        w.writerows(rows)

    print(f"\nWrote {args.out} (read-only over inputs).")
    if failed:
        print(f"GATE: FAIL — {failed} role(s) below {args.required_rate:.0%}. "
              f"Do not go live for those roles until met.")
        return 1
    print(f"GATE: PASS — all roles meet {args.required_rate:.0%} completion.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
