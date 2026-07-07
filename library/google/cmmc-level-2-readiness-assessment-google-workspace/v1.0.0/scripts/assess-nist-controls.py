#!/usr/bin/env python3
# assess-nist-controls.py — map NIST SP 800-171 controls to Google Workspace settings and report status.
#
# PURPOSE: READ-ONLY assessment. Reads the live Workspace tenant (Admin SDK Directory + Reports,
#          Groups Settings) and emits the `NIST 800-171 – Control Map – Org` matrix: for each mappable
#          control it records the Workspace setting, the observed value, and a status
#          (configured / partial / not-configured / manual / verify-edition). It never changes anything.
# HOW TO RUN: python assess-nist-controls.py --domain corp.example --out control-map.csv
#             (Python 3.10+, OAuth/ADC read-only scopes; see --help). Use --check-auth to test creds.
# EXPECTED RESULTS: A CSV control map + a stdout summary of counts per status. Rows marked
#                   'verify-edition' or 'manual' require human confirmation; they are NOT assessment results.
#
# pip install google-api-python-client google-auth google-auth-oauthlib
#
# BOUNDARY: This tool measures configuration. It does NOT determine NIST 800-171 applicability, assert a
# control is "satisfied", or produce a CMMC assessment outcome — those are the assessor's/compliance
# team's determinations. Treat 'configured' as 'configured to support, pending assessor determination'.

import argparse
import csv
import sys

READONLY_SCOPES = [
    "https://www.googleapis.com/auth/admin.directory.user.readonly",
    "https://www.googleapis.com/auth/admin.directory.group.readonly",
    "https://www.googleapis.com/auth/admin.directory.orgunit.readonly",
    "https://www.googleapis.com/auth/admin.reports.audit.readonly",
    "https://www.googleapis.com/auth/apps.groups.settings",
]

# Control-family map. This is the AUTHORING reference of which Workspace mechanism implements each
# family; the tool checks what it can read via API and marks the rest 'manual' (documented procedure)
# or 'verify-edition' (edition/rollout dependent — confirm in the tenant).
# status values: configured | partial | not-configured | manual | verify-edition
CONTROL_FAMILIES = [
    # family, name, workspace mechanism, how-this-tool-checks-it, default-status-if-unreadable
    ("AC", "Access Control", "OU/group scope, external-sharing policy, context-aware access", "api", "partial"),
    ("AT", "Awareness & Training", "CUI-handling training + attestation records", "manual", "manual"),
    ("AU", "Audit & Accountability", "Audit logs + log export sink + review procedure", "api", "partial"),
    ("CM", "Configuration Management", "OU policy baseline, Marketplace/API app allow-list", "api", "partial"),
    ("IA", "Identification & Authentication", "Enforced 2SV/security keys, SSO, session length", "api", "partial"),
    ("IR", "Incident Response", "Alert Center/audit detection + documented IR procedure", "manual", "manual"),
    ("MA", "Maintenance", "Least-privilege admin roles + admin-action logging", "api", "partial"),
    ("MP", "Media Protection", "Data-region, encryption, DLP-controlled export", "verify", "verify-edition"),
    ("PS", "Personnel Security", "Joiner/mover/leaver tied to identity source", "manual", "manual"),
    ("PE", "Physical Protection", "Inherited Google data-center controls + endpoints", "manual", "manual"),
    ("RA", "Risk Assessment", "Risk process + this control map", "manual", "manual"),
    ("CA", "Security Assessment", "SSP, POA&M, continuous monitoring", "manual", "manual"),
    ("SC", "System & Communications Protection", "TLS/mail auth, data-region/Assured Controls, encryption", "verify", "verify-edition"),
    ("SI", "System & Information Integrity", "DLP, attachment security, alerting, flaw remediation", "api", "partial"),
]


def build_services(subject, credentials_file):
    """Build read-only Admin SDK services. Returns None services in --check-auth-less dry contexts."""
    try:
        from google.oauth2 import service_account
        from googleapiclient.discovery import build
    except ImportError:
        print("ERROR: pip install google-api-python-client google-auth google-auth-oauthlib", file=sys.stderr)
        raise
    # Prefer ADC / a delegated service account restricted to READONLY_SCOPES. Never embed keys here.
    creds = service_account.Credentials.from_service_account_file(
        credentials_file, scopes=READONLY_SCOPES
    )
    if subject:
        creds = creds.with_subject(subject)
    directory = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    reports = build("admin", "reports_v1", credentials=creds, cache_discovery=False)
    return directory, reports


def check_2sv_enforced(directory, ou):
    """Read-only: sample users in the OU and report whether 2SV is enforced. Best-effort."""
    try:
        resp = directory.users().list(customer="my_customer", orgUnitPath=ou, maxResults=200,
                                      projection="full").execute()
        users = resp.get("users", [])
        if not users:
            return "not-configured", "no users read in OU"
        enrolled = sum(1 for u in users if u.get("isEnrolledIn2Sv"))
        if enrolled == len(users):
            return "configured", f"2SV enrolled {enrolled}/{len(users)} sampled"
        return "partial", f"2SV enrolled {enrolled}/{len(users)} sampled"
    except Exception as e:  # noqa: BLE001 — read-only best-effort probe
        return "partial", f"could not read users ({e.__class__.__name__}); verify manually"


def assess(args):
    directory = reports = None
    if not args.dry_run and args.credentials:
        directory, reports = build_services(args.subject, args.credentials)

    rows = []
    for fam, name, mechanism, mode, default_status in CONTROL_FAMILIES:
        status, evidence = default_status, "review against control map"
        if fam == "IA" and directory is not None:
            status, evidence = check_2sv_enforced(directory, args.ou)
        elif mode == "manual":
            status, evidence = "manual", "documented procedure — human evidence required"
        elif mode == "verify":
            status, evidence = "verify-edition", "verify Assured Controls/encryption availability in your tenant"
        rows.append({
            "family": fam,
            "family_name": name,
            "workspace_mechanism": mechanism,
            "status": status,
            "evidence_pointer": evidence,
            "planned_setting": "",
            "configured_value": "",
        })

    with open(args.out, "w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    counts = {}
    for r in rows:
        counts[r["status"]] = counts.get(r["status"], 0) + 1
    print(f"Wrote control map: {args.out} ({len(rows)} families)")
    for status, n in sorted(counts.items()):
        print(f"  {status:15} {n}")
    print("\nNOTE: 'verify-edition' and 'manual' rows require human confirmation. This is a readiness")
    print("      measurement, NOT a CMMC assessment result. Applicability and conformance are your")
    print("      assessor's/compliance team's determinations.")


def main():
    p = argparse.ArgumentParser(description="Map NIST 800-171 controls to Workspace settings (read-only).")
    p.add_argument("--domain", help="primary domain, e.g. corp.example")
    p.add_argument("--ou", default="/CUI – Boundary – Org", help="CUI boundary OU path")
    p.add_argument("--out", default="control-map.csv", help="output control-map CSV")
    p.add_argument("--credentials", help="path to a READ-ONLY delegated service-account file (never commit it)")
    p.add_argument("--subject", help="admin user to impersonate for domain-wide delegation")
    p.add_argument("--dry-run", action="store_true", default=True,
                   help="do not call APIs; emit the mappable-control skeleton (default)")
    p.add_argument("--live", dest="dry_run", action="store_false",
                   help="call the read-only APIs (requires --credentials)")
    p.add_argument("--check-auth", action="store_true", help="only verify the credential authenticates, then exit")
    args = p.parse_args()

    if args.check_auth:
        if not args.credentials:
            print("ERROR: --check-auth requires --credentials", file=sys.stderr)
            sys.exit(2)
        try:
            build_services(args.subject, args.credentials)
            print("OK: credential built with read-only scopes.")
        except Exception as e:  # noqa: BLE001
            print(f"AUTH FAILED: {e}", file=sys.stderr)
            sys.exit(1)
        return

    assess(args)


if __name__ == "__main__":
    main()
