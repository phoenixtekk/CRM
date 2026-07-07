#!/usr/bin/env python3
# gwsdk_tenant_discovery.py — read-only Workspace discovery / assessment report (Directory API)
#
# PURPOSE: Read-only. Produce "Discovery Report – Tenant – Assess": user counts, OU distribution,
#          license/usage signals, and suspended accounts, from the Directory API. Never writes.
# HOW TO RUN: python gwsdk_tenant_discovery.py --subject reports-admin@corp.example --out ./reports
#             (Python 3.10+, ADC; scope: admin.directory.user.readonly)
# EXPECTED RESULTS: A dated CSV + JSON "Discovery Report – Tenant – Assess" and a printed summary.
#                   Exit 0 on success. Makes zero write calls.
#
# No secrets in code: credentials via ADC or --credentials path (never committed).
# pip install google-api-python-client google-auth

from __future__ import annotations

import argparse
import csv
import json
import os
import sys
import time
from datetime import datetime, timezone

SCOPE = "https://www.googleapis.com/auth/admin.directory.user.readonly"
ARTIFACT = "Discovery Report – Tenant – Assess"


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Read-only Workspace discovery/assessment report.")
    p.add_argument("--subject", required=True, help="Impersonation subject (least-privilege admin) email.")
    p.add_argument("--customer", default="my_customer", help="Customer ID (default: my_customer).")
    p.add_argument("--out", default=".", help="Output directory for the report artifacts.")
    p.add_argument("--credentials", default=None, help="Optional secured credential path. Omit for ADC.")
    p.add_argument("--max-retries", type=int, default=5, help="Retry cap for 429/5xx backoff.")
    return p.parse_args()


def build_service(subject: str, cred_path: str | None):
    try:
        import google.auth
        from google.oauth2 import service_account
        from googleapiclient.discovery import build
    except ImportError:
        sys.exit("Run: pip install google-api-python-client google-auth")
    if cred_path:
        creds = service_account.Credentials.from_service_account_file(cred_path, scopes=[SCOPE])
        creds = creds.with_subject(subject)
    else:
        creds, _ = google.auth.default(scopes=[SCOPE])
        if hasattr(creds, "with_subject"):
            creds = creds.with_subject(subject)
    return build("admin", "directory_v1", credentials=creds, cache_discovery=False)


def list_all_users(service, customer: str, max_retries: int) -> list[dict]:
    """Paginate every user with exponential-backoff retry on 429/5xx."""
    from googleapiclient.errors import HttpError

    users: list[dict] = []
    page_token = None
    while True:
        attempt = 0
        while True:
            try:
                resp = service.users().list(
                    customer=customer, maxResults=500, orderBy="email",
                    pageToken=page_token,
                    projection="full",
                ).execute()
                break
            except HttpError as exc:
                status = getattr(exc.resp, "status", None)
                if status in (429, 500, 503) and attempt < max_retries:
                    sleep = min(2 ** attempt, 30)
                    print(f"  [retry] HTTP {status}; backing off {sleep}s", file=sys.stderr)
                    time.sleep(sleep)
                    attempt += 1
                    continue
                raise
        users.extend(resp.get("users", []))
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    return users


def summarize(users: list[dict]) -> dict:
    ou_dist: dict[str, int] = {}
    suspended = 0
    admins = 0
    two_sv = 0
    licensed_hint = 0
    for u in users:
        ou = u.get("orgUnitPath", "/")
        ou_dist[ou] = ou_dist.get(ou, 0) + 1
        if u.get("suspended"):
            suspended += 1
        if u.get("isAdmin") or u.get("isDelegatedAdmin"):
            admins += 1
        if u.get("isEnrolledIn2Sv"):
            two_sv += 1
        # Directory does not return license SKUs; presence of a mailbox/last login is a usage signal.
        if u.get("lastLoginTime") and u["lastLoginTime"] != "1970-01-01T00:00:00.000Z":
            licensed_hint += 1
    return {
        "total_users": len(users),
        "suspended": suspended,
        "active": len(users) - suspended,
        "admins": admins,
        "enrolled_2sv": two_sv,
        "users_with_login_activity": licensed_hint,
        "ou_distribution": dict(sorted(ou_dist.items())),
    }


def write_artifacts(users: list[dict], summary: dict, out_dir: str) -> tuple[str, str]:
    os.makedirs(out_dir, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    base = f"discovery-report-tenant-assess-{stamp}"
    csv_path = os.path.join(out_dir, base + ".csv")
    json_path = os.path.join(out_dir, base + ".json")

    with open(csv_path, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["primaryEmail", "orgUnitPath", "suspended", "isAdmin", "isEnrolledIn2Sv",
                    "lastLoginTime", "creationTime"])
        for u in sorted(users, key=lambda x: x.get("primaryEmail", "")):
            w.writerow([u.get("primaryEmail", ""), u.get("orgUnitPath", "/"),
                        u.get("suspended", False), u.get("isAdmin", False),
                        u.get("isEnrolledIn2Sv", False), u.get("lastLoginTime", ""),
                        u.get("creationTime", "")])

    with open(json_path, "w", encoding="utf-8") as fh:
        json.dump({"artifact": ARTIFACT, "generated": stamp, "summary": summary}, fh, indent=2)
    return csv_path, json_path


def main() -> int:
    args = parse_args()
    print(f"# {ARTIFACT} (read-only) — subject {args.subject}")
    service = build_service(args.subject, args.credentials)
    users = list_all_users(service, args.customer, args.max_retries)
    summary = summarize(users)
    csv_path, json_path = write_artifacts(users, summary, args.out)

    print(json.dumps(summary, indent=2))
    print(f"\nWrote: {csv_path}\nWrote: {json_path}")
    print("Discovery complete (no writes performed).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
