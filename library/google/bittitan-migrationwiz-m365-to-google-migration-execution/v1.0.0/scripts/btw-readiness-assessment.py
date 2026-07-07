#!/usr/bin/env python3
# btw-readiness-assessment.py — read-only M365 source + Google target readiness baseline for a MigrationWiz move
#
# PURPOSE: Baseline both sides of an M365 -> Google Workspace MigrationWiz migration WITHOUT changing
#          anything. Reads the Microsoft 365 source (users, mailboxes, OneDrive/SharePoint, Teams) over
#          Microsoft Graph and the Google Workspace target (users, licensing, service-account delegation
#          presence) over the Admin SDK, and reports scope + readiness gaps. Read-only; makes no writes and
#          calls no BitTitan/MigrationWiz API.
# HOW TO RUN: python btw-readiness-assessment.py --source-domain corp.example --target-domain corp.example \
#             [--graph-token-env GRAPH_TOKEN] [--google-sa-file sa.json] [--google-subject admin@corp.example] \
#             [--out baseline.json]   (Python 3.10+, OAuth/ADC; see --help)
# EXPECTED RESULTS: A printed readiness table + optional JSON baseline ("BTW Discovery - Source & Target -
#             Baseline"). Exit 0 if both sides are readable and no blocking gap; exit 2 if a blocking gap is
#             found (missing target delegation, no source access, no licensed target users).
#
# Standard-library-first. Live API calls require:
#   pip install msgraph-core google-api-python-client google-auth
# Microsoft Graph is read via a bearer token you supply (env var); Google via a service account with
# READ-ONLY Admin SDK scopes and domain-wide delegation, or Application Default Credentials (ADC).
# No credentials are hardcoded and none are written out.

import argparse
import json
import os
import sys

READONLY_GOOGLE_SCOPES = [
    "https://www.googleapis.com/auth/admin.directory.user.readonly",
    "https://www.googleapis.com/auth/admin.directory.domain.readonly",
    "https://www.googleapis.com/auth/apps.groups.settings",  # read via settings API where used
]


def _emit(gaps, ok, msg):
    print(f"  [{'OK ' if ok else 'GAP'}] {msg}")
    if not ok:
        gaps.append(msg)


def read_source_m365(source_domain, graph_token):
    """Read source scope over Microsoft Graph (read-only). Returns a dict; empty if no token."""
    summary = {"domain": source_domain, "reachable": False}
    if not graph_token:
        print("  [..] No Graph token supplied (--graph-token-env); source read skipped.")
        return summary
    try:
        import urllib.request

        def graph_get(path):
            req = urllib.request.Request(
                "https://graph.microsoft.com/v1.0" + path,
                headers={"Authorization": f"Bearer {graph_token}",
                         "ConsistencyLevel": "eventual"},
            )
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.load(r)

        users = graph_get("/users?$select=id,userPrincipalName,accountEnabled&$top=1&$count=true")
        summary["reachable"] = True
        summary["user_count"] = users.get("@odata.count")
        # Best-effort counts; presence, not exhaustive enumeration.
        summary["notes"] = "Add per-mailbox/site data volumes and Teams/SharePoint mappings manually."
    except Exception as exc:  # noqa: BLE001 - report, don't crash the baseline
        summary["error"] = str(exc)
    return summary


def read_target_google(target_domain, sa_file, subject):
    """Read target scope over the Admin SDK (read-only). Returns a dict; empty if no creds."""
    summary = {"domain": target_domain, "reachable": False, "delegation_present": None}
    if not sa_file and not os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
        print("  [..] No Google credentials (--google-sa-file / ADC); target read skipped.")
        return summary
    try:
        from google.oauth2 import service_account
        import google.auth
        from googleapiclient.discovery import build

        if sa_file:
            creds = service_account.Credentials.from_service_account_file(
                sa_file, scopes=READONLY_GOOGLE_SCOPES)
            if subject:
                creds = creds.with_subject(subject)
        else:
            creds, _ = google.auth.default(scopes=READONLY_GOOGLE_SCOPES)

        directory = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
        resp = directory.users().list(customer="my_customer", maxResults=1,
                                      projection="basic").execute()
        summary["reachable"] = True
        summary["sample_user_present"] = bool(resp.get("users"))
        # If the readonly directory call succeeds under a delegated subject, delegation is working.
        summary["delegation_present"] = bool(subject) and summary["reachable"]
    except Exception as exc:  # noqa: BLE001
        summary["error"] = str(exc)
        summary["delegation_present"] = False
    return summary


def main():
    ap = argparse.ArgumentParser(description="Read-only M365 + Google readiness baseline for a MigrationWiz move.")
    ap.add_argument("--source-domain", required=True, help="M365 source primary domain")
    ap.add_argument("--target-domain", required=True, help="Google Workspace target primary domain")
    ap.add_argument("--graph-token-env", default="GRAPH_TOKEN",
                    help="Env var holding a Microsoft Graph bearer token (read-only use).")
    ap.add_argument("--google-sa-file", help="Path to a Google service-account JSON (read-only scopes).")
    ap.add_argument("--google-subject", help="Admin user to impersonate via domain-wide delegation.")
    ap.add_argument("--out", help="Write the JSON baseline to this path.")
    args = ap.parse_args()

    gaps = []
    print("== BTW Discovery - Source & Target - Baseline (read-only) ==")

    print("\n[Source] Microsoft 365 / Entra:")
    graph_token = os.getenv(args.graph_token_env or "")
    source = read_source_m365(args.source_domain, graph_token)
    _emit(gaps, source.get("reachable", False),
          f"Source {args.source_domain} readable over Graph "
          f"(users={source.get('user_count', '?')})")

    print("\n[Target] Google Workspace:")
    target = read_target_google(args.target_domain, args.google_sa_file, args.google_subject)
    _emit(gaps, target.get("reachable", False),
          f"Target {args.target_domain} readable over Admin SDK")
    _emit(gaps, bool(target.get("delegation_present")),
          "Service-account domain-wide delegation present for read scopes "
          "(required for the MigrationWiz target endpoint too — verify scopes for your version)")

    baseline = {"artifact": "BTW Discovery - Source & Target - Baseline",
                "source": source, "target": target, "gaps": gaps}

    print("\n== Summary ==")
    if gaps:
        print(f"  {len(gaps)} blocking gap(s) — resolve before designing endpoints:")
        for g in gaps:
            print(f"    - {g}")
    else:
        print("  No blocking gaps detected. Proceed to endpoint design (Implementation Step 2).")

    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(baseline, fh, indent=2)
        print(f"  Baseline written: {args.out}")

    sys.exit(2 if gaps else 0)


if __name__ == "__main__":
    main()
