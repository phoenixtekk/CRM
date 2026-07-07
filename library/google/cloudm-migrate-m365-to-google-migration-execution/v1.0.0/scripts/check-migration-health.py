#!/usr/bin/env python3
# check-migration-health.py — destination account/license + throttling health check between passes
#
# PURPOSE: Read-only health check to run between migration passes. Verifies destination Google
#          accounts for a wave exist, are active/licensed, and are not suspended, and summarizes any
#          throttling/error signals from a CloudM run-log export so drift is caught before it
#          compounds across waves. Writes nothing.
# HOW TO RUN: python check-migration-health.py --userlist userlist.csv [--run-log cloudm-log.csv]
#             (Python 3.10+, OAuth/ADC; see --help). pip install google-api-python-client google-auth
# EXPECTED RESULTS: Per-user account/license health + an aggregate throttling/error summary, with a
#          HEALTHY / ATTENTION signal on stdout.
#
# SAFETY: read-only (Directory readonly scope + local log parse). No writes. OAuth/ADC; no secrets.

import argparse
import csv
import sys
from collections import Counter

DIRECTORY_SCOPE = "https://www.googleapis.com/auth/admin.directory.user.readonly"

# Substrings that indicate provider throttling / transient limits in a run-log status/message column.
THROTTLE_HINTS = ("429", "throttl", "rate limit", "quota", "backoff", "too many requests")


def get_directory_service(delegated_admin=None):
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        sys.exit("Missing deps. Run: pip install google-api-python-client google-auth")
    creds, _ = google.auth.default(scopes=[DIRECTORY_SCOPE])
    if delegated_admin and hasattr(creds, "with_subject"):
        creds = creds.with_subject(delegated_admin)
    return build("admin", "directory_v1", credentials=creds, cache_discovery=False)


def load_userlist(path):
    users = []
    with open(path, newline="", encoding="utf-8-sig") as fh:
        reader = csv.DictReader(fh)
        norm = {c: (c or "").strip().lower() for c in (reader.fieldnames or [])}
        for raw in reader:
            r = {norm.get(k, k): v for k, v in raw.items()}
            dest = (r.get("destinationemail") or r.get("dest") or r.get("email") or "").strip().lower()
            if dest:
                users.append(dest)
    return users


def check_account(service, email):
    """Return account health for one destination user (read-only)."""
    try:
        u = service.users().get(userKey=email, projection="basic").execute()
    except Exception as exc:  # noqa: BLE001 - includes 404 for missing accounts
        return {"email": email, "exists": False, "detail": str(exc).split("\n")[0]}
    return {
        "email": email,
        "exists": True,
        "suspended": bool(u.get("suspended", False)),
        "archived": bool(u.get("archived", False)),
        "2sv_enrolled": bool(u.get("isEnrolledIn2Sv", False)),
    }


def parse_run_log(path):
    """Summarize a CloudM run-log CSV export (status/message columns). Advisory only."""
    statuses = Counter()
    throttles = 0
    errors = 0
    total = 0
    with open(path, newline="", encoding="utf-8-sig") as fh:
        reader = csv.DictReader(fh)
        norm = {c: (c or "").strip().lower() for c in (reader.fieldnames or [])}
        for raw in reader:
            r = {norm.get(k, k): (v or "") for k, v in raw.items()}
            total += 1
            status = (r.get("status") or "").strip().lower()
            message = (r.get("message") or r.get("detail") or "").lower()
            statuses[status or "unknown"] += 1
            blob = f"{status} {message}"
            if any(h in blob for h in THROTTLE_HINTS):
                throttles += 1
            if "error" in status or "fail" in status:
                errors += 1
    return {"total": total, "statuses": statuses, "throttles": throttles, "errors": errors}


def main():
    p = argparse.ArgumentParser(description="Destination account/license + throttling health check.")
    p.add_argument("--userlist", required=True, help="User-list CSV with DestinationEmail column.")
    p.add_argument("--run-log", help="Optional CloudM run-log CSV export to summarize.")
    p.add_argument("--delegated-admin", help="Super-admin to impersonate via DWD (optional).")
    args = p.parse_args()

    print("== Migration Health Check (read-only) ==")
    users = load_userlist(args.userlist)
    if not users:
        sys.exit("No destination users in --userlist.")

    try:
        svc = get_directory_service(args.delegated_admin)
    except Exception as exc:  # noqa: BLE001
        sys.exit(f"ERROR building directory client: {exc}")

    missing, suspended, ok = [], [], 0
    for email in users:
        h = check_account(svc, email)
        if not h["exists"]:
            missing.append(email)
        elif h["suspended"] or h["archived"]:
            suspended.append(email)
        else:
            ok += 1

    print(f"Destination accounts checked: {len(users)}")
    print(f"  Healthy (active):     {ok}")
    print(f"  Missing:              {len(missing)}")
    print(f"  Suspended/archived:   {len(suspended)}")
    for e in missing[:15]:
        print(f"    MISSING  {e}")
    for e in suspended[:15]:
        print(f"    INACTIVE {e}")

    log_attention = False
    if args.run_log:
        summary = parse_run_log(args.run_log)
        print("\nRun-log summary (advisory):")
        print(f"  Items: {summary['total']}  errors: {summary['errors']}  "
              f"throttling-signals: {summary['throttles']}")
        for status, n in summary["statuses"].most_common(6):
            print(f"    {status:20s} {n}")
        if summary["throttles"] or summary["errors"]:
            log_attention = True
            print("  NOTE: throttling/errors present — tune concurrency down; re-delta failed items.")

    attention = bool(missing or suspended) or log_attention
    print("\nRESULT:", "ATTENTION NEEDED" if attention else "HEALTHY")
    sys.exit(2 if attention else 0)


if __name__ == "__main__":
    main()
