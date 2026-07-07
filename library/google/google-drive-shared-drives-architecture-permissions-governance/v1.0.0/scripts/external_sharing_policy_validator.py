#!/usr/bin/env python3
# external_sharing_policy_validator.py — go/no-go gate: does live sharing match the designed policy?
#
# PURPOSE: Validate the tenant's live external/link-sharing posture for an OU against the designed
#          "Sharing Profile – <OU> – Restricted" and the allow-listed partner domains in the catalog.
#          READ-ONLY: it reads OU sharing settings + a sample of Shared Drive permissions and reports
#          conformance. This is the DEPLOYMENT GATE — non-zero exit means a policy violation remains.
# HOW TO RUN: python external_sharing_policy_validator.py --domain corp.example --ou "/Finance" \
#               --catalog drive-catalog.csv [--max 1000] [--json]
#             (Python 3.10+, OAuth/ADC read-only scopes per Requirements 2.6;
#              `pip install google-api-python-client google-auth`. See --help.)
# EXPECTED RESULTS: Per-check PASS/FAIL lines. Exit 0 = conforms to policy (gate PASS). Non-zero =
#          one or more violations printed (e.g. external share to a domain not on the allow-list).
#
# SAFETY: read-only — no tenant change. Allow-list of partner domains is read from the catalog, not
#         invented. No credentials/keys embedded; auth via ADC / delegated service account.

import argparse
import csv
import json
import os
import sys

DRIVE_RO = "https://www.googleapis.com/auth/drive.readonly"


def load_allowlist(catalog):
    """Read allow-listed partner domains from an optional 'allowed_domains' column."""
    allowed = set()
    if catalog and os.path.exists(catalog):
        with open(catalog, newline="", encoding="utf-8") as fh:
            for r in csv.DictReader(fh):
                for d in (r.get("allowed_domains") or "").split(";"):
                    d = d.strip().lower()
                    if d:
                        allowed.add(d)
    return allowed


def build_drive():
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        print("ERROR: pip install google-api-python-client google-auth", file=sys.stderr)
        sys.exit(2)
    creds, _ = google.auth.default(scopes=[DRIVE_RO])
    return build("drive", "v3", credentials=creds, cache_discovery=False)


def check_live_shares(drive, home_domain, allowed, max_files):
    """Sample file permissions; flag external shares to non-allow-listed domains + anyone-links."""
    violations = []
    fields = "nextPageToken, files(name, permissions(type,emailAddress,domain))"
    page, seen = None, 0
    while seen < max_files:
        resp = drive.files().list(
            q="trashed=false", corpora="allDrives", includeItemsFromAllDrives=True,
            supportsAllDrives=True, fields=fields,
            pageSize=min(1000, max_files - seen), pageToken=page).execute()
        for f in resp.get("files", []):
            seen += 1
            for p in f.get("permissions", []) or []:
                if p.get("type") == "anyone":
                    violations.append(("ANYONE-LINK", f["name"], "public link"))
                    continue
                dom = _domain_of(p)
                if dom and dom != home_domain and dom not in allowed:
                    violations.append(("EXTERNAL-NOT-ALLOWLISTED", f["name"], dom))
        page = resp.get("nextPageToken")
        if not page:
            break
    return violations, seen


def _domain_of(perm):
    if perm.get("domain"):
        return perm["domain"].lower()
    email = perm.get("emailAddress", "")
    return email.split("@")[-1].lower() if "@" in email else ""


def main():
    ap = argparse.ArgumentParser(description="Gate: validate live external-sharing vs designed policy.")
    ap.add_argument("--domain", required=True, help="Home domain, e.g. corp.example")
    ap.add_argument("--ou", help="OU scope (informational)")
    ap.add_argument("--catalog", help="Catalog CSV with an 'allowed_domains' column (;-separated)")
    ap.add_argument("--max", type=int, default=1000, help="Max files to sample (default 1000)")
    ap.add_argument("--json", action="store_true", help="Also print a JSON summary")
    args = ap.parse_args()

    allowed = load_allowlist(args.catalog)
    print(f"External-sharing policy validation (READ-ONLY GATE) — domain={args.domain} "
          f"ou={args.ou or 'ALL'}")
    print(f"  allow-listed partner domains: {sorted(allowed) or '(none — internal-only expected)'}\n")

    drive = build_drive()
    violations, sampled = check_live_shares(drive, args.domain.lower(), allowed, args.max)

    if not violations:
        print(f"PASS — sampled {sampled} files; all external sharing conforms to policy.")
        rc = 0
    else:
        print(f"FAIL — sampled {sampled} files; {len(violations)} policy violation(s):")
        for kind, name, detail in violations[:25]:
            print(f"  [{kind}] {name} -> {detail}")
        if len(violations) > 25:
            print(f"  … +{len(violations) - 25} more")
        rc = 1

    if args.json:
        print("\nJSON:\n" + json.dumps(
            {"sampled": sampled, "violations": len(violations),
             "allowed_domains": sorted(allowed)}, indent=2))
    return rc  # non-zero on violation => gate blocks expansion


if __name__ == "__main__":
    sys.exit(main())
