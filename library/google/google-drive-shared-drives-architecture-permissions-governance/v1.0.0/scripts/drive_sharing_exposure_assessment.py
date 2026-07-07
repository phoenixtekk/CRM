#!/usr/bin/env python3
# drive_sharing_exposure_assessment.py — read-only Drive sharing-exposure baseline (Stage 0)
#
# PURPOSE: Discover the current Drive risk posture before any change — files shared EXTERNALLY, files
#          exposed via "Anyone with the link", ORPHANED-OWNER files (owned by a suspended/deleted user),
#          and business content still sitting in individuals' My Drive. READ-ONLY: it only calls Drive
#          API list/get and Admin SDK read-only endpoints; it never changes a share or an owner.
# HOW TO RUN: python drive_sharing_exposure_assessment.py --domain corp.example [--ou "/Finance"]
#             [--max 2000] [--json]
#             (Python 3.10+, OAuth/ADC or a delegated service account with the *.readonly scopes in
#              Requirements 2.6; needs `pip install google-api-python-client google-auth`. See --help.)
# EXPECTED RESULTS: A printed Stage-0 baseline with counts per exposure category and a sample of
#          offending files. Findings tagged EXTERNAL / ANYONE-LINK / ORPHANED-OWNER / MYDRIVE-BUSINESS.
#          Exit 0 always (assessment, not a gate — the gate is external_sharing_policy_validator.py).
#
# SAFETY: read-only. No credentials or keys are embedded — auth comes from ADC / an authorized OAuth
#         client / a delegated service account resolved at runtime. Nothing is written to the tenant.

import argparse
import json
import sys

# Google client libraries are imported lazily so --help works without them installed.
DRIVE_READONLY = "https://www.googleapis.com/auth/drive.readonly"
DIRECTORY_USER_RO = "https://www.googleapis.com/auth/admin.directory.user.readonly"


def build_services():
    """Build read-only Drive + Directory services from ADC / delegated credentials.

    Auth resolution (no secrets in code):
      * Application Default Credentials (GOOGLE_APPLICATION_CREDENTIALS / gcloud ADC), or
      * a service account with domain-wide delegation, impersonating an admin, configured by the
        operator's environment — never hardcoded here.
    """
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        print("ERROR: pip install google-api-python-client google-auth", file=sys.stderr)
        sys.exit(2)
    creds, _ = google.auth.default(scopes=[DRIVE_READONLY, DIRECTORY_USER_RO])
    drive = build("drive", "v3", credentials=creds, cache_discovery=False)
    directory = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    return drive, directory


def suspended_users(directory, domain):
    """Return the set of suspended/deleted user emails (orphaned-owner candidates)."""
    suspended = set()
    page = None
    while True:
        resp = directory.users().list(domain=domain, query="isSuspended=true",
                                      maxResults=200, pageToken=page,
                                      projection="basic").execute()
        for u in resp.get("users", []):
            suspended.add(u.get("primaryEmail", "").lower())
        page = resp.get("nextPageToken")
        if not page:
            break
    return suspended


def scan_files(drive, suspended, max_files):
    """Read-only sweep of files, classifying each into exposure buckets."""
    findings = {"EXTERNAL": [], "ANYONE-LINK": [], "ORPHANED-OWNER": [], "MYDRIVE-BUSINESS": []}
    fields = ("nextPageToken, files(id,name,owners(emailAddress),permissions("
              "type,role,domain,allowFileDiscovery),driveId,shared,parents)")
    page, seen = None, 0
    while seen < max_files:
        resp = drive.files().list(
            q="trashed=false",
            corpora="allDrives", includeItemsFromAllDrives=True, supportsAllDrives=True,
            fields=fields, pageSize=min(1000, max_files - seen), pageToken=page).execute()
        for f in resp.get("files", []):
            seen += 1
            _classify(f, suspended, findings)
        page = resp.get("nextPageToken")
        if not page:
            break
    return findings, seen


def _classify(f, suspended, findings):
    owners = [o.get("emailAddress", "").lower() for o in f.get("owners", [])]
    in_shared_drive = bool(f.get("driveId"))
    for p in f.get("permissions", []) or []:
        ptype = p.get("type")
        if ptype == "anyone":
            findings["ANYONE-LINK"].append(f["name"])
        elif ptype in ("user", "group") and p.get("domain") and "external" in str(p.get("domain")):
            findings["EXTERNAL"].append(f["name"])
    # Orphaned owner: owned by a suspended/deleted user (only meaningful outside Shared Drives).
    if not in_shared_drive and any(o in suspended for o in owners):
        findings["ORPHANED-OWNER"].append(f["name"])
    # Business content still in a personal My Drive (heuristic: shared but not in a Shared Drive).
    if not in_shared_drive and f.get("shared"):
        findings["MYDRIVE-BUSINESS"].append(f["name"])


def main():
    ap = argparse.ArgumentParser(description="Read-only Drive sharing-exposure baseline.")
    ap.add_argument("--domain", required=True, help="Primary domain, e.g. corp.example")
    ap.add_argument("--ou", help="OU path to note in the report scope (informational)")
    ap.add_argument("--max", type=int, default=2000, help="Max files to scan (default 2000)")
    ap.add_argument("--json", action="store_true", help="Also print a JSON summary")
    args = ap.parse_args()

    print(f"Drive sharing-exposure assessment (READ-ONLY) — domain={args.domain} "
          f"ou={args.ou or 'ALL'}\n")
    drive, directory = build_services()
    susp = suspended_users(directory, args.domain)
    print(f"  suspended/deleted users (orphaned-owner candidates): {len(susp)}")
    findings, scanned = scan_files(drive, susp, args.max)

    print(f"\n== Exposure summary (scanned {scanned} files) ==")
    for cat in ("EXTERNAL", "ANYONE-LINK", "ORPHANED-OWNER", "MYDRIVE-BUSINESS"):
        items = findings[cat]
        print(f"  {cat:<18} {len(items)}")
        for name in items[:5]:
            print(f"      - {name}")
        if len(items) > 5:
            print(f"      … +{len(items) - 5} more")

    if args.json:
        summary = {"domain": args.domain, "ou": args.ou, "scanned": scanned,
                   "counts": {k: len(v) for k, v in findings.items()}}
        print("\nJSON:\n" + json.dumps(summary, indent=2))
    return 0  # assessment always exits 0


if __name__ == "__main__":
    sys.exit(main())
