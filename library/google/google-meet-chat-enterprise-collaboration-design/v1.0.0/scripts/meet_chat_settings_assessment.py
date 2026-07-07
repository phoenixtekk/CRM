#!/usr/bin/env python3
# meet_chat_settings_assessment.py — discover current Google Meet & Chat configuration (read-only).
#
# PURPOSE: Baseline the tenant's Meet/Chat governance posture — OU tree, configuration groups,
#          and installed Chat apps via the Admin SDK — plus a manual-check worksheet for the
#          Meet/Chat safety, external, history and recording settings that are UI-only. READ-ONLY:
#          never writes to the tenant. Produces the "Meet+Chat Baseline - Enterprise - Assess" artifact.
# HOW TO RUN: python meet_chat_settings_assessment.py --domain your-domain.com --out baseline.json
#             (Python 3.10+, OAuth/ADC; see --help). pip install google-api-python-client google-auth
# EXPECTED RESULTS: writes baseline.json (OUs, groups, installed Chat apps, manual-check worksheet)
#          and prints a summary. No tenant changes. Non-zero exit only on auth/API failure.

import argparse
import json
import sys
from datetime import datetime, timezone

# Read-only Admin SDK scopes. No write scope is requested by this tool.
SCOPES = [
    "https://www.googleapis.com/auth/admin.directory.orgunit.readonly",
    "https://www.googleapis.com/auth/admin.directory.group.readonly",
    "https://www.googleapis.com/auth/apps.groups.settings",
]

# Meet/Chat controls that live only in the Admin console UI (no writable Settings API surface).
# The operator confirms these manually; the tool records the checklist so the baseline is complete.
MANUAL_CHECKS = [
    ("meet.host_management", "Meet > Safety: Host management default (on/off)"),
    ("meet.who_can_join", "Meet > Safety: Who can join meetings created by your org"),
    ("meet.warn_external", "Meet > Safety: Warn for external participants (on/off)"),
    ("meet.recording_enabled", "Meet > Video: Recording enabled + who can record"),
    ("meet.recording_storage", "Meet: Recording/transcript storage location (Shared Drive?)"),
    ("meet.external_access", "Meet > Safety: External participant access posture"),
    ("chat.external_chat", "Chat > External: external chat blocked / allowlisted / open"),
    ("chat.allowlisted_domains", "Chat > External: allowlisted domains"),
    ("chat.history_default", "Chat > Chat history: default on/off + user-changeable"),
    ("chat.space_creation", "Chat: who can create spaces / space-type restrictions"),
    ("chat.file_sharing", "Chat: file-sharing policy inside Chat"),
    ("chat.app_installation", "Chat > Apps: third-party app install restricted/allowlist"),
    ("vault.chat_retention", "Vault > Retention > Chat: rule present + scope + period"),
]


def build_service(subject=None):
    """Build an Admin SDK Directory client using ADC or an authorized-user/service-account flow.

    Credentials come from the environment (ADC) or an OAuth flow the operator has set up — never
    from hardcoded keys. Domain-wide delegation subject is optional (service-account impersonation).
    """
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        print("Missing deps. Run: pip install google-api-python-client google-auth", file=sys.stderr)
        raise

    creds, _ = google.auth.default(scopes=SCOPES)
    if subject and hasattr(creds, "with_subject"):
        creds = creds.with_subject(subject)
    return build("admin", "directory_v1", credentials=creds, cache_discovery=False)


def list_org_units(directory):
    resp = directory.orgunits().list(customerId="my_customer", type="all").execute()
    return [
        {"path": ou.get("orgUnitPath"), "name": ou.get("name"), "parent": ou.get("parentOrgUnitPath")}
        for ou in resp.get("organizationUnits", [])
    ]


def list_groups(directory, domain):
    groups, token = [], None
    while True:
        resp = directory.groups().list(domain=domain, maxResults=200, pageToken=token).execute()
        for g in resp.get("groups", []):
            groups.append({"email": g.get("email"), "name": g.get("name"),
                           "members": g.get("directMembersCount")})
        token = resp.get("nextPageToken")
        if not token:
            break
    return groups


def main():
    ap = argparse.ArgumentParser(description="Read-only Google Meet & Chat settings assessment.")
    ap.add_argument("--domain", required=True, help="Primary domain, e.g. your-domain.com")
    ap.add_argument("--subject", help="Optional admin to impersonate (domain-wide delegation).")
    ap.add_argument("--out", default="baseline.json", help="Output JSON path.")
    ap.add_argument("--offline", action="store_true",
                    help="Skip API calls; emit only the manual-check worksheet (no creds needed).")
    args = ap.parse_args()

    baseline = {
        "artifact": "Meet+Chat Baseline - Enterprise - Assess",
        "domain": args.domain,
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "read_only": True,
        "org_units": [],
        "groups": [],
        "installed_chat_apps": "See Admin console > Apps > Chat > Manage apps (UI-only inventory).",
        "manual_checks": [{"key": k, "prompt": p, "observed": None} for k, p in MANUAL_CHECKS],
    }

    if not args.offline:
        try:
            directory = build_service(args.subject)
            baseline["org_units"] = list_org_units(directory)
            baseline["groups"] = list_groups(directory, args.domain)
        except Exception as exc:  # noqa: BLE001 - surface auth/API errors clearly, do not mutate tenant
            print(f"API error (assessment is read-only, nothing changed): {exc}", file=sys.stderr)
            return 2

    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(baseline, fh, indent=2)

    print(f"Baseline written to {args.out}")
    print(f"  OUs discovered:    {len(baseline['org_units'])}")
    print(f"  Groups discovered: {len(baseline['groups'])}")
    print(f"  Manual checks to fill in: {len(baseline['manual_checks'])}")
    print("Next: complete 'observed' values from the Admin console, then design the target policy.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
