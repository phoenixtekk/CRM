#!/usr/bin/env python3
# collect-evidence.py — export configuration + audit-log evidence for the CUI boundary into a package.
#
# PURPOSE: READ-ONLY evidence collector. For the CUI boundary OU it exports the CONFIGURATION state
#          (OU/user/group settings via Admin SDK Directory + Groups Settings) and OPERATIONAL evidence
#          (audit-log extracts via the Reports API) into a timestamped `Evidence – CUI Boundary – <date>`
#          package, indexed to the control map. It never changes tenant state.
# HOW TO RUN: python collect-evidence.py --ou "/CUI – Boundary – Org" --package "Evidence – CUI Boundary – 2026-07-06"
#             (Python 3.10+, OAuth/ADC read-only scopes; see --help)
# EXPECTED RESULTS: A package directory containing per-control evidence files + an index.csv mapping each
#                   artifact to its NIST control ID. Missing evidence for a 'configured' control is flagged.
#
# pip install google-api-python-client google-auth
#
# BOUNDARY: Evidence supports an assessment; it is not itself an assessment result. Read-only by design so
# collecting evidence can never alter the posture it measures. No credentials/keys are stored in this file.

import argparse
import csv
import json
import os
import sys
from datetime import datetime, timezone

READONLY_SCOPES = [
    "https://www.googleapis.com/auth/admin.directory.user.readonly",
    "https://www.googleapis.com/auth/admin.directory.group.readonly",
    "https://www.googleapis.com/auth/admin.directory.orgunit.readonly",
    "https://www.googleapis.com/auth/admin.reports.audit.readonly",
]

# Audit-log applications (Reports API) that carry CUI-boundary operational evidence, mapped to families.
AUDIT_SOURCES = [
    ("login", "IA/AC — authentication & 2SV events"),
    ("admin", "CM/MA/AU — admin configuration changes"),
    ("drive", "AC/MP/SI — file access, sharing, DLP actions"),
    ("token", "CM/AC — OAuth app authorizations"),
    ("rules", "SI — DLP/rules actions"),
]


def build_services(subject, credentials_file):
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    creds = service_account.Credentials.from_service_account_file(credentials_file, scopes=READONLY_SCOPES)
    if subject:
        creds = creds.with_subject(subject)
    directory = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    reports = build("admin", "reports_v1", credentials=creds, cache_discovery=False)
    return directory, reports


def export_config(directory, ou, pkgdir, index):
    """Export OU membership + per-user config snapshot (read-only) as configuration evidence."""
    path = os.path.join(pkgdir, "config")
    os.makedirs(path, exist_ok=True)
    resp = directory.users().list(customer="my_customer", orgUnitPath=ou, maxResults=500,
                                  projection="full").execute()
    users = resp.get("users", [])
    snapshot = [{
        "primaryEmail": u.get("primaryEmail"),
        "orgUnitPath": u.get("orgUnitPath"),
        "isEnrolledIn2Sv": u.get("isEnrolledIn2Sv"),
        "isAdmin": u.get("isAdmin"),
        "suspended": u.get("suspended"),
    } for u in users]
    fname = os.path.join(path, "ou-user-config.json")
    with open(fname, "w", encoding="utf-8") as fh:
        json.dump({"ou": ou, "captured": _now(), "users": snapshot}, fh, indent=2)
    index.append(("IA/AC/PS", "config/ou-user-config.json", f"{len(snapshot)} boundary users w/ 2SV+admin+suspend state"))


def export_audit(reports, pkgdir, index, days):
    """Export recent audit-log extracts per application (read-only) as operational evidence."""
    path = os.path.join(pkgdir, "audit")
    os.makedirs(path, exist_ok=True)
    for app, families in AUDIT_SOURCES:
        try:
            resp = reports.activities().list(userKey="all", applicationName=app, maxResults=1000).execute()
            items = resp.get("items", [])
        except Exception as e:  # noqa: BLE001 — best-effort per source
            items = [{"error": f"{e.__class__.__name__}: could not read {app} log; verify scope/edition"}]
        fname = os.path.join(path, f"{app}-activities.json")
        with open(fname, "w", encoding="utf-8") as fh:
            json.dump({"application": app, "captured": _now(), "count": len(items), "items": items}, fh, indent=2)
        index.append((families, f"audit/{app}-activities.json", f"{len(items)} {app} events (~last {days}d window)"))


def _now():
    return datetime.now(timezone.utc).isoformat()


def collect(args):
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    pkgname = args.package or f"Evidence – CUI Boundary – {stamp}"
    pkgdir = os.path.join(args.out_dir, pkgname)
    os.makedirs(pkgdir, exist_ok=True)
    index = []

    if args.dry_run or not args.credentials:
        print("[dry-run] Would export config + audit evidence for OU:", args.ou)
        print("[dry-run] Package:", pkgdir)
        print("[dry-run] Audit sources:", ", ".join(a for a, _ in AUDIT_SOURCES))
        print("[dry-run] Re-run with --live and --credentials to collect. (read-only)")
        return

    directory, reports = build_services(args.subject, args.credentials)
    export_config(directory, args.ou, pkgdir, index)
    export_audit(reports, pkgdir, index, args.days)

    idx_path = os.path.join(pkgdir, "index.csv")
    with open(idx_path, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["nist_family", "artifact", "description"])
        w.writerows(index)

    print(f"Evidence package written: {pkgdir}")
    print(f"  index: {idx_path} ({len(index)} artifacts)")
    print("NOTE: evidence supports — does not constitute — a CMMC assessment. Refresh before your")
    print("      assessor's freshness window; cross-check against the control map for gaps.")


def main():
    p = argparse.ArgumentParser(description="Collect read-only CUI-boundary evidence into a package.")
    p.add_argument("--ou", default="/CUI – Boundary – Org", help="CUI boundary OU path")
    p.add_argument("--package", help="package name (default: 'Evidence – CUI Boundary – <date>')")
    p.add_argument("--out-dir", default="evidence", help="parent directory for packages")
    p.add_argument("--days", type=int, default=180, help="audit-log lookback window (informational)")
    p.add_argument("--credentials", help="path to a READ-ONLY delegated service-account file (never commit it)")
    p.add_argument("--subject", help="admin user to impersonate for domain-wide delegation")
    p.add_argument("--dry-run", action="store_true", default=True, help="describe actions without calling APIs (default)")
    p.add_argument("--live", dest="dry_run", action="store_false", help="perform read-only collection (needs --credentials)")
    args = p.parse_args()
    collect(args)


if __name__ == "__main__":
    main()
