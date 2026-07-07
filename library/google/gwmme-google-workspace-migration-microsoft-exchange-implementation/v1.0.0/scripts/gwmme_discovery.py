#!/usr/bin/env python3
# gwmme_discovery.py — discover source mailboxes vs. Google target users and emit a mapping skeleton
#
# PURPOSE: Read-only assessment for a GWMME (Exchange/M365 -> Gmail) migration. Reconciles a source
#          mailbox inventory (from the Microsoft side) against provisioned Google Workspace users via
#          the Admin SDK Directory API, and writes a source->target mapping CSV skeleton plus a gap
#          report. Read-only: never writes to either tenant.
# HOW TO RUN: python gwmme_discovery.py --source-inventory source_mailboxes.csv \
#                 --domain example.com --out-mapping Mapping-Users-Master.csv --out-report gaps.csv
#             (Python 3.10+, OAuth/ADC; see --help. pip install google-api-python-client google-auth)
# EXPECTED RESULTS: A mapping CSV (one row per matched mailbox) and a gap report listing sources with
#                   no Google target and Google users with no source mailbox. Nonzero gaps => resolve
#                   before building waves.

import argparse
import csv
import sys

# Read-only Directory scope; the Google side is only ENUMERATED here, never modified.
SCOPES = ["https://www.googleapis.com/auth/admin.directory.user.readonly"]


def load_source_inventory(path):
    """Load the source mailbox inventory CSV.

    Expected columns (case-insensitive): primary_smtp (required), display_name, item_count, size_mb.
    This file is produced from the Microsoft source (read-only) outside this script.
    """
    rows = []
    with open(path, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        cols = {c.lower().strip(): c for c in (reader.fieldnames or [])}
        if "primary_smtp" not in cols:
            sys.exit("ERROR: source inventory must have a 'primary_smtp' column.")
        for r in reader:
            rows.append({
                "primary_smtp": (r.get(cols["primary_smtp"], "") or "").strip().lower(),
                "display_name": (r.get(cols.get("display_name", ""), "") or "").strip(),
                "item_count": (r.get(cols.get("item_count", ""), "") or "").strip(),
                "size_mb": (r.get(cols.get("size_mb", ""), "") or "").strip(),
            })
    return [r for r in rows if r["primary_smtp"]]


def fetch_google_users(domain):
    """Enumerate active Google Workspace users for the domain (read-only Directory API).

    Returns a dict keyed by lowercased primaryEmail. Falls back to an empty dict with a clear
    message if Google client libraries or credentials are unavailable, so the mapping skeleton
    can still be produced offline.
    """
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        print("NOTE: google-api-python-client/google-auth not installed; "
              "skipping live Google lookup (offline skeleton only).", file=sys.stderr)
        return {}

    try:
        creds, _ = google.auth.default(scopes=SCOPES)
        service = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    except Exception as exc:  # noqa: BLE001 - surface any auth/build problem, stay read-only
        print(f"NOTE: could not initialize Directory API ({exc}); offline skeleton only.",
              file=sys.stderr)
        return {}

    users = {}
    page_token = None
    while True:
        resp = service.users().list(
            domain=domain, maxResults=500, orderBy="email",
            pageToken=page_token, projection="basic", query="isSuspended=false",
        ).execute()
        for u in resp.get("users", []):
            email = (u.get("primaryEmail") or "").lower()
            if email:
                users[email] = u.get("name", {}).get("fullName", "")
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    return users


def main():
    ap = argparse.ArgumentParser(description="GWMME discovery: reconcile source mailboxes with "
                                             "Google users and emit a mapping skeleton (read-only).")
    ap.add_argument("--source-inventory", required=True,
                    help="CSV of source mailboxes (primary_smtp[,display_name,item_count,size_mb]).")
    ap.add_argument("--domain", required=True, help="Primary Google Workspace domain to enumerate.")
    ap.add_argument("--out-mapping", default="Mapping-Users-Master.csv",
                    help="Output mapping CSV path (default: Mapping-Users-Master.csv).")
    ap.add_argument("--out-report", default="gwmme-gap-report.csv",
                    help="Output gap-report CSV path.")
    ap.add_argument("--target-domain", default=None,
                    help="Target Google domain if different from source local part's domain "
                         "(default: --domain).")
    args = ap.parse_args()

    target_domain = args.target_domain or args.domain
    source = load_source_inventory(args.source_inventory)
    google_users = fetch_google_users(args.domain)
    print(f"Source mailboxes: {len(source)} | Google users enumerated: {len(google_users)}")

    matched, unmatched_source = [], []
    for m in source:
        local = m["primary_smtp"].split("@", 1)[0]
        candidate = f"{local}@{target_domain}".lower()
        if not google_users or candidate in google_users:
            matched.append((m, candidate))
        else:
            unmatched_source.append((m, candidate))

    source_locals = {m["primary_smtp"].split("@", 1)[0] for m in source}
    orphan_targets = [e for e in google_users
                      if e.split("@", 1)[0] not in source_locals] if google_users else []

    with open(args.out_mapping, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["source_smtp", "target_google_email", "display_name",
                    "item_count", "size_mb", "wave"])
        for m, tgt in matched:
            w.writerow([m["primary_smtp"], tgt, m["display_name"],
                        m["item_count"], m["size_mb"], ""])

    with open(args.out_report, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["issue", "value", "note"])
        for m, tgt in unmatched_source:
            w.writerow(["source_without_target", m["primary_smtp"],
                        f"no Google user {tgt}; provision/license before migrating"])
        for e in orphan_targets:
            w.writerow(["target_without_source", e, "Google user with no source mailbox (out of scope?)"])

    print(f"Wrote mapping skeleton: {args.out_mapping} ({len(matched)} rows)")
    print(f"Wrote gap report: {args.out_report} "
          f"({len(unmatched_source)} unmatched sources, {len(orphan_targets)} orphan targets)")
    if unmatched_source:
        print("RESULT: FAIL — resolve unmatched sources (provision targets) before building waves.")
        sys.exit(1)
    print("RESULT: PASS — every source has a candidate target. Review the report, then assign waves.")


if __name__ == "__main__":
    main()
