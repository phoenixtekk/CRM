#!/usr/bin/env python3
# migration-health-check.py — check connection health and watch a running wave for throughput/throttling.
#
# PURPOSE: Read-only health monitor. Verifies the Microsoft 365 + Google connection prerequisites are reachable
#          (scopes/consent, domain-wide delegation, API reachability) and, while a wave runs, watches a
#          progress/log export for throughput, error rate, and SUSTAINED throttling (Graph 429 / Google rate
#          limits) — signaling when to back off. Never writes to Microsoft 365 or Google.
# HOW TO RUN: python migration-health-check.py --connections --dry-run
#             python migration-health-check.py --wave "Migration Wave - Finance - Pilot" --watch --progress progress.csv
#             (Python 3.10+, OAuth/ADC; pip install google-api-python-client google-auth msgraph-core azure-identity)
# EXPECTED RESULTS: Prints a health/connection report or a live wave summary; exit non-zero if a gate fails
#                   (unreachable connection, error rate above threshold, or sustained throttling).

import argparse
import csv
import os
import sys

ERROR_RATE_THRESHOLD = 0.02       # >2% item error rate fails the gate
THROTTLE_SUSTAINED = 5            # >=5 throttling responses in the window = sustained -> back off


def parse_args():
    p = argparse.ArgumentParser(description="GWSMigrate connection + wave health check (read-only).")
    p.add_argument("--connections", action="store_true", help="Check both connections' reachability/scopes.")
    p.add_argument("--wave", help="Wave name to watch (Migration Wave - <Scope> - <Stage>).")
    p.add_argument("--watch", action="store_true", help="Summarize the wave progress export.")
    p.add_argument("--progress", help="Path to a progress/log CSV exported from the console (items,errors,throttles).")
    p.add_argument("--dry-run", action="store_true", help="Do not hit live APIs; report intended checks.")
    return p.parse_args()


def check_connections(dry_run):
    checks = [
        ("Connection - Microsoft 365 - Source", "Entra app reachable; Graph scopes consented (read-only probe)."),
        ("Connection - Google Workspace - Target", "Service account delegation authorized; Admin SDK reachable."),
    ]
    print("=== Connection health ===")
    if dry_run:
        for name, what in checks:
            print(f"  [dry-run] would verify {name}: {what}")
        print("  (Run without --dry-run once OAuth/ADC is configured to probe live.)")
        return 0
    try:
        from googleapiclient.discovery import build  # noqa: F401
        from google.oauth2 import service_account  # noqa: F401
        from azure.identity import DefaultAzureCredential  # noqa: F401
    except ImportError:
        sys.exit("Missing deps: pip install google-api-python-client google-auth msgraph-core azure-identity "
                 "(or use --dry-run).")
    # Wire minimal read-only probes here: Graph GET /organization and Admin SDK Directory users.list(maxResults=1).
    sys.exit("Live connection probe not wired in this template. Add read-only Graph + Admin SDK probes, "
             "or use --dry-run. No secrets in code — use OAuth/ADC.")


def watch_wave(wave, progress):
    if not progress or not os.path.isfile(progress):
        sys.exit("--watch needs --progress <console progress/log CSV export> "
                 "(columns: items,errors,throttles).")
    items = errors = throttles = 0
    with open(progress, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            items += int(row.get("items", 0) or 0)
            errors += int(row.get("errors", 0) or 0)
            throttles += int(row.get("throttles", 0) or 0)
    rate = (errors / items) if items else 0.0
    print(f"=== Watch: {wave} ===")
    print(f"  items processed : {items:,}")
    print(f"  errors          : {errors:,}  ({rate:.2%})")
    print(f"  throttle events : {throttles:,}")
    status = 0
    if rate > ERROR_RATE_THRESHOLD:
        print(f"  FAIL: error rate {rate:.2%} > {ERROR_RATE_THRESHOLD:.0%} threshold — investigate before scaling.")
        status = 1
    if throttles >= THROTTLE_SUSTAINED:
        print(f"  FAIL: {throttles} throttle events (>= {THROTTLE_SUSTAINED}) — SUSTAINED throttling. "
              "Lower concurrency in the throttling plan and re-run.")
        status = 1
    if status == 0:
        print("  PASS: error rate within threshold; no sustained throttling.")
    return status


def main():
    args = parse_args()
    if args.connections:
        rc = check_connections(args.dry_run)
        if not args.watch:
            sys.exit(rc)
    if args.watch:
        if not args.wave:
            sys.exit("--watch requires --wave.")
        sys.exit(watch_wave(args.wave, args.progress))
    if not args.connections:
        sys.exit("Nothing to do: pass --connections and/or --wave ... --watch. See --help.")


if __name__ == "__main__":
    main()
