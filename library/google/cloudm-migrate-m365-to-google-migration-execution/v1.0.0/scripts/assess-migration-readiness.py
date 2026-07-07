#!/usr/bin/env python3
# assess-migration-readiness.py — read-only M365->Google migration readiness assessment
#
# PURPOSE: Read-only. Sizes an M365->Google Workspace migration from the Google destination
#          directory (users/licenses via the Admin SDK) plus an optional source inventory export
#          (mailbox/OneDrive/SharePoint sizes), and flags readiness gaps. Never writes anything.
# HOW TO RUN: python assess-migration-readiness.py --source-inventory src.csv [--domain corp.example]
#             (Python 3.10+, OAuth/ADC; see --help). pip install google-api-python-client google-auth
# EXPECTED RESULTS: A per-domain readiness summary (destination user/license counts, source sizes,
#          unmapped/over-quota flags) and an overall READY / NOT READY signal on stdout.
#
# SAFETY: read-only. No writes, no credentials in code (OAuth/ADC). No secrets committed.

import argparse
import csv
import sys
from collections import defaultdict

# Admin SDK Directory scope (read-only). CloudM's own connector scopes are separate and documented
# by CloudM ("verify for your version"); this tool only reads the Google directory.
DIRECTORY_SCOPE = "https://www.googleapis.com/auth/admin.directory.user.readonly"


def get_directory_service(delegated_admin=None):
    """Build a read-only Admin SDK Directory client using ADC / OAuth.

    Uses Application Default Credentials (ADC). For domain-wide impersonation, set
    --delegated-admin to a super-admin the service account is authorized to impersonate.
    No key material is read from source; configure ADC in the environment.
    """
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        sys.exit("Missing deps. Run: pip install google-api-python-client google-auth")

    creds, _ = google.auth.default(scopes=[DIRECTORY_SCOPE])
    if delegated_admin and hasattr(creds, "with_subject"):
        creds = creds.with_subject(delegated_admin)
    return build("admin", "directory_v1", credentials=creds, cache_discovery=False)


def fetch_destination_users(service, domain=None):
    """Page through Google Workspace users (read-only)."""
    users, page_token = [], None
    while True:
        req = service.users().list(
            customer="my_customer",
            domain=domain,
            maxResults=500,
            orderBy="email",
            pageToken=page_token,
            projection="basic",
        )
        resp = req.execute()
        for u in resp.get("users", []):
            users.append(
                {
                    "email": u.get("primaryEmail", "").lower(),
                    "suspended": bool(u.get("suspended", False)),
                    "licensed": not u.get("suspended", False),
                }
            )
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    return users


def load_source_inventory(path):
    """Load an M365 source export.

    Expected columns (case-insensitive; extras ignored):
      upn, primary_smtp, mailbox_size_gb, onedrive_size_gb, sharepoint_size_gb
    """
    rows = []
    with open(path, newline="", encoding="utf-8-sig") as fh:
        reader = csv.DictReader(fh)
        norm = {c: (c or "").strip().lower() for c in (reader.fieldnames or [])}
        for raw in reader:
            r = {norm.get(k, k): v for k, v in raw.items()}
            rows.append(
                {
                    "upn": (r.get("upn") or r.get("primary_smtp") or "").strip().lower(),
                    "mailbox_gb": _to_float(r.get("mailbox_size_gb")),
                    "onedrive_gb": _to_float(r.get("onedrive_size_gb")),
                    "sharepoint_gb": _to_float(r.get("sharepoint_size_gb")),
                }
            )
    return rows


def _to_float(v):
    try:
        return round(float(str(v).replace(",", "").strip()), 2)
    except (TypeError, ValueError):
        return 0.0


def assess(dest_users, source_rows, large_mailbox_gb):
    dest_by_email = {u["email"] for u in dest_users}
    licensed = sum(1 for u in dest_users if u["licensed"])

    totals = defaultdict(float)
    unmapped, large = [], []
    for r in source_rows:
        totals["mailbox_gb"] += r["mailbox_gb"]
        totals["onedrive_gb"] += r["onedrive_gb"]
        totals["sharepoint_gb"] += r["sharepoint_gb"]
        if r["upn"] and r["upn"] not in dest_by_email:
            unmapped.append(r["upn"])
        if r["mailbox_gb"] >= large_mailbox_gb:
            large.append((r["upn"], r["mailbox_gb"]))
    return {
        "dest_total": len(dest_users),
        "dest_licensed": licensed,
        "source_total": len(source_rows),
        "totals_gb": {k: round(v, 1) for k, v in totals.items()},
        "unmapped": unmapped,
        "large_mailboxes": sorted(large, key=lambda x: -x[1]),
    }


def main():
    p = argparse.ArgumentParser(description="Read-only M365->Google migration readiness assessment.")
    p.add_argument("--source-inventory", help="CSV export of M365 source sizes (see --help columns).")
    p.add_argument("--domain", help="Limit destination directory read to this domain.")
    p.add_argument("--delegated-admin", help="Super-admin to impersonate via DWD (optional).")
    p.add_argument("--large-mailbox-gb", type=float, default=25.0,
                   help="Flag mailboxes at/over this size for pre-stage attention (default 25).")
    args = p.parse_args()

    print("== Migration Readiness Assessment (read-only) ==")
    try:
        svc = get_directory_service(args.delegated_admin)
        dest_users = fetch_destination_users(svc, args.domain)
    except Exception as exc:  # noqa: BLE001 - surface any auth/API failure clearly
        sys.exit(f"ERROR reading Google directory: {exc}")

    source_rows = load_source_inventory(args.source_inventory) if args.source_inventory else []
    result = assess(dest_users, source_rows, args.large_mailbox_gb)

    print(f"Destination Google users:   {result['dest_total']} "
          f"({result['dest_licensed']} active/licensed)")
    print(f"Source M365 users (export): {result['source_total']}")
    if source_rows:
        t = result["totals_gb"]
        print(f"Source data to move (GB):   mail={t['mailbox_gb']} "
              f"onedrive={t['onedrive_gb']} sharepoint={t['sharepoint_gb']}")
        print(f"Unmapped source users:      {len(result['unmapped'])}")
        for u in result["unmapped"][:20]:
            print(f"    - {u} has no destination Google account")
        if len(result["unmapped"]) > 20:
            print(f"    ... and {len(result['unmapped']) - 20} more")
        print(f"Large mailboxes (>= {args.large_mailbox_gb}GB, pre-stage early): "
              f"{len(result['large_mailboxes'])}")

    ready = bool(dest_users) and (not source_rows or not result["unmapped"])
    print("\nRESULT:", "READY (no blocking gaps found)" if ready
          else "NOT READY (resolve flagged gaps before migrating)")
    sys.exit(0 if ready else 2)


if __name__ == "__main__":
    main()
