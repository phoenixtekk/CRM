#!/usr/bin/env python3
# oauth-app-inventory.py — inventory connected third-party OAuth apps + scopes for Google Workspace
#
# PURPOSE: Read-only discovery. Enumerates connected third-party apps, the OAuth scopes they hold,
#          and how many users granted each, from the Admin SDK Reports API (OAuth-token activity)
#          and the Directory API (domain-wide tokens); risk-scores each app (HIGH/MEDIUM/LOW/UNKNOWN)
#          against a scope-sensitivity reference. Produces "App Inventory - Org-Wide - v1". READ-ONLY.
# HOW TO RUN: python oauth-app-inventory.py [--days 180] [--out app-inventory.json]
#             [--scope-ref scope-sensitivity.json] [--check-auth]
#             (Python 3.10+, gcloud ADC or a delegated service account; see --help)
# EXPECTED RESULTS: A JSON inventory of apps with scopes, grant counts, and a risk tier per app,
#                   plus a stdout summary. No changes are ever made.
#
# Auth: Application Default Credentials (`gcloud auth application-default login`) as an admin, OR a
# service account with domain-wide delegation for the read-only scopes below. NO keys in code.
# Requires: pip install google-api-python-client google-auth

import argparse
import json
import sys
from collections import defaultdict

# Least-privilege, READ-ONLY scopes this tool needs.
READONLY_SCOPES = [
    "https://www.googleapis.com/auth/admin.reports.audit.readonly",
    "https://www.googleapis.com/auth/admin.directory.user.security",
]

# Fallback sensitivity hints used ONLY if no --scope-ref file is supplied. Google's authoritative
# restricted/sensitive scope list changes over time — VERIFY for your tenant and prefer a maintained
# reference file produced by scope-config-helper.py. Anything unmatched is scored UNKNOWN, never LOW.
DEFAULT_SENSITIVITY_HINTS = {
    "restricted": [
        "auth/gmail",             # full Gmail
        "auth/drive",             # full Drive
        "auth/admin.directory",   # directory admin
        "auth/apps.groups",       # groups admin
        "auth/cloud-platform",    # broad GCP
    ],
    "sensitive": [
        "auth/calendar",
        "auth/contacts",
        "auth/spreadsheets",
        "auth/documents",
    ],
    "basic": [
        "auth/userinfo.email",
        "auth/userinfo.profile",
        "openid",
    ],
}

RISK_FROM_TIER = {"restricted": "HIGH", "sensitive": "MEDIUM", "basic": "LOW"}


def build_service(api, version):
    """Build an Admin SDK client using ADC. Import lazily so --help works without the libs."""
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        sys.exit("ERROR: pip install google-api-python-client google-auth")
    creds, _ = google.auth.default(scopes=READONLY_SCOPES)
    return build(api, version, credentials=creds, cache_discovery=False)


def check_auth():
    try:
        import google.auth
    except ImportError:
        sys.exit("ERROR: pip install google-api-python-client google-auth")
    creds, project = google.auth.default(scopes=READONLY_SCOPES)
    principal = getattr(creds, "service_account_email", None) or "user (ADC)"
    print("Auth OK")
    print(f"  principal: {principal}")
    print(f"  project:   {project}")
    print(f"  scopes:    {', '.join(READONLY_SCOPES)}")


def load_scope_ref(path):
    if not path:
        return DEFAULT_SENSITIVITY_HINTS, True
    with open(path, encoding="utf-8") as fh:
        return json.load(fh), False


def scope_tier(scope, ref):
    """Return the sensitivity tier for one scope, or 'unknown' if not matched by any hint."""
    for tier in ("restricted", "sensitive", "basic"):
        for hint in ref.get(tier, []):
            if hint in scope:
                return tier
    return "unknown"


def app_risk(scopes, ref):
    """Highest-severity tier across an app's scopes drives the risk label."""
    tiers = {scope_tier(s, ref) for s in scopes}
    if "unknown" in tiers and not (tiers & {"restricted", "sensitive"}):
        return "UNKNOWN"
    if "restricted" in tiers:
        return "HIGH"
    if "sensitive" in tiers:
        return "MEDIUM"
    if "basic" in tiers:
        return "LOW"
    return "UNKNOWN"


def collect_tokens(admin_directory):
    """Enumerate domain tokens (connected apps + scopes) per user via Directory API tokens.list.

    Returns {client_id: {"display": name, "scopes": set(), "users": set()}}.
    """
    apps = defaultdict(lambda: {"display": "", "scopes": set(), "users": set()})
    users_page = None
    while True:
        resp = (
            admin_directory.users()
            .list(customer="my_customer", maxResults=200, pageToken=users_page,
                  projection="basic", orderBy="email")
            .execute()
        )
        for user in resp.get("users", []):
            email = user.get("primaryEmail")
            try:
                tokens = admin_directory.tokens().list(userKey=email).execute()
            except Exception as exc:  # noqa: BLE001 - continue past per-user errors
                print(f"  WARN: tokens.list failed for {email}: {exc}", file=sys.stderr)
                continue
            for tok in tokens.get("items", []):
                cid = tok.get("clientId", "?")
                rec = apps[cid]
                rec["display"] = tok.get("displayText") or rec["display"]
                rec["users"].add(email)
                for s in tok.get("scopes", []):
                    rec["scopes"].add(s)
        users_page = resp.get("nextPageToken")
        if not users_page:
            break
    return apps


def main():
    ap = argparse.ArgumentParser(description="Read-only OAuth connected-app + scope inventory.")
    ap.add_argument("--days", type=int, default=180,
                    help="Look-back window (informational; token inventory is current-state).")
    ap.add_argument("--out", default="app-inventory.json", help="Output inventory JSON path.")
    ap.add_argument("--scope-ref", help="Scope-sensitivity reference JSON (from scope-config-helper).")
    ap.add_argument("--check-auth", action="store_true", help="Print auth principal/scopes and exit.")
    args = ap.parse_args()

    if args.check_auth:
        check_auth()
        return

    ref, using_default = load_scope_ref(args.scope_ref)
    if using_default:
        print("NOTE: using built-in scope-sensitivity hints; supply --scope-ref for an authoritative,"
              " tenant-verified classification.", file=sys.stderr)

    directory = build_service("admin", "directory_v1")
    print("Enumerating domain tokens (this reads every user's connected apps)...")
    apps = collect_tokens(directory)

    inventory = []
    for cid, rec in apps.items():
        scopes = sorted(rec["scopes"])
        risk = app_risk(scopes, ref)
        inventory.append({
            "artifact": "App Inventory - Org-Wide - v1",
            "client_id": cid,
            "display": rec["display"],
            "user_count": len(rec["users"]),
            "scopes": scopes,
            "scope_tiers": {s: scope_tier(s, ref) for s in scopes},
            "risk": risk,
        })
    inventory.sort(key=lambda a: (a["risk"] != "HIGH", a["risk"] != "UNKNOWN", -a["user_count"]))

    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump({"artifact": "App Inventory - Org-Wide - v1", "apps": inventory}, fh, indent=2)

    counts = defaultdict(int)
    for a in inventory:
        counts[a["risk"]] += 1
    print(f"\nInventory written to {args.out} ({len(inventory)} apps)")
    for tier in ("HIGH", "MEDIUM", "LOW", "UNKNOWN"):
        print(f"  {tier:<8} {counts[tier]}")
    if counts["HIGH"] or counts["UNKNOWN"]:
        print("\nReview HIGH-risk (restricted/sensitive scopes) and UNKNOWN-scope apps before Trusting.")


if __name__ == "__main__":
    main()
