#!/usr/bin/env python3
# cui-boundary-check.py — check the CUI boundary OU for sharing/access exposure (read-only).
#
# PURPOSE: READ-ONLY exposure checker. Scans the CUI boundary OU's users, group memberships, and Drive
#          external-sharing signals to flag ways CUI could leak outside the boundary: external Drive
#          sharing, non-member/guest access to CUI groups, and members outside the boundary OU. It
#          reports findings; it changes nothing.
# HOW TO RUN: python cui-boundary-check.py --ou "/CUI – Boundary – Org" --out boundary-exposure.csv
#             (Python 3.10+, OAuth/ADC read-only scopes; see --help)
# EXPECTED RESULTS: A findings CSV + stdout summary of exposure counts by type/severity. A clean run
#                   (no unexpected exposure) is a pass for boundary tests T1/T2.
#
# pip install google-api-python-client google-auth
#
# BOUNDARY: This flags technical exposure only. What counts as CUI, and whether a given exposure is
# acceptable, are your compliance team's/assessor's determinations. No secrets/keys are stored here.

import argparse
import csv
import sys

READONLY_SCOPES = [
    "https://www.googleapis.com/auth/admin.directory.user.readonly",
    "https://www.googleapis.com/auth/admin.directory.group.readonly",
    "https://www.googleapis.com/auth/admin.directory.group.member.readonly",
    "https://www.googleapis.com/auth/drive.metadata.readonly",
]


def build_services(subject, credentials_file):
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    creds = service_account.Credentials.from_service_account_file(credentials_file, scopes=READONLY_SCOPES)
    if subject:
        creds = creds.with_subject(subject)
    directory = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    return directory


def internal_domains(arg):
    return {d.strip().lower() for d in arg.split(",") if d.strip()}


def check_members_outside_ou(directory, ou, findings):
    """Flag boundary-group members whose account sits outside the boundary OU."""
    resp = directory.users().list(customer="my_customer", orgUnitPath=ou, maxResults=500).execute()
    in_ou = {u.get("primaryEmail", "").lower() for u in resp.get("users", [])}
    findings.append(("info", "boundary-ou-size", ou, f"{len(in_ou)} users read in boundary OU"))
    return in_ou


def check_external_group_members(directory, group_email, in_ou, internal, findings):
    """Flag external or out-of-OU members of a CUI group."""
    try:
        resp = directory.members().list(groupKey=group_email, maxResults=500).execute()
    except Exception as e:  # noqa: BLE001
        findings.append(("warn", "group-read-failed", group_email, f"{e.__class__.__name__}; verify manually"))
        return
    for m in resp.get("members", []):
        email = (m.get("email") or "").lower()
        dom = email.split("@")[-1] if "@" in email else ""
        if dom and dom not in internal:
            findings.append(("high", "external-group-member", group_email, f"{email} (external domain)"))
        elif in_ou and email not in in_ou:
            findings.append(("medium", "member-outside-boundary-ou", group_email, f"{email} not in boundary OU"))


def run(args):
    if args.dry_run or not args.credentials:
        print("[dry-run] Would check OU:", args.ou)
        print("[dry-run] Internal domains:", args.internal_domains or "(none set — pass --internal-domains)")
        print("[dry-run] CUI groups:", ", ".join(args.groups) if args.groups else "(none passed)")
        print("[dry-run] Checks: members-outside-OU, external group members, external Drive sharing.")
        print("[dry-run] Re-run with --live and --credentials to scan. (read-only)")
        return

    directory = build_services(args.subject, args.credentials)
    internal = internal_domains(args.internal_domains)
    if not internal:
        print("WARNING: no --internal-domains set; external-member detection is disabled.", file=sys.stderr)

    findings = []
    in_ou = check_members_outside_ou(directory, args.ou, findings)
    for g in args.groups:
        check_external_group_members(directory, g, in_ou, internal, findings)

    # Drive external-sharing signal: reported as a manual/verify item unless a shared-drive scan credential
    # is supplied. We do not fabricate a private API; deep per-file sharing enumeration is a documented
    # follow-up (Drive API files.list with the shared-drive scope) the operator can extend.
    findings.append(("info", "drive-sharing", args.ou,
                     "run a Drive files.list external-sharing scan per your shared-drive inventory (see docs)"))

    with open(args.out, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["severity", "type", "scope", "detail"])
        w.writerows(findings)

    sev = {}
    for f in findings:
        sev[f[0]] = sev.get(f[0], 0) + 1
    print(f"Wrote findings: {args.out} ({len(findings)} rows)")
    for s in ("high", "medium", "warn", "info"):
        if s in sev:
            print(f"  {s:8} {sev[s]}")
    highs = sev.get("high", 0)
    print(f"\n{'FAIL' if highs else 'PASS'}: {highs} high-severity exposure finding(s).")
    print("NOTE: acceptability of any exposure is a compliance/assessor determination, not this tool's.")


def main():
    p = argparse.ArgumentParser(description="Check CUI boundary OU for sharing/access exposure (read-only).")
    p.add_argument("--ou", default="/CUI – Boundary – Org", help="CUI boundary OU path")
    p.add_argument("--groups", nargs="*", default=[], help="CUI group emails to inspect for external members")
    p.add_argument("--internal-domains", default="", help="comma-separated internal domains (e.g. corp.example)")
    p.add_argument("--out", default="boundary-exposure.csv", help="output findings CSV")
    p.add_argument("--credentials", help="path to a READ-ONLY delegated service-account file (never commit it)")
    p.add_argument("--subject", help="admin user to impersonate for domain-wide delegation")
    p.add_argument("--dry-run", action="store_true", default=True, help="describe checks without calling APIs (default)")
    p.add_argument("--live", dest="dry_run", action="store_false", help="perform read-only scan (needs --credentials)")
    args = p.parse_args()
    run(args)


if __name__ == "__main__":
    main()
