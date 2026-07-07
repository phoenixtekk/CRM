#!/usr/bin/env python3
# gwsdk_sharing_audit_report.py — Drive external-sharing & login/admin audit report (read-only)
#
# PURPOSE: Read-only. Generate two evidence artifacts: "Sharing Report – External – Validate" (Drive
#          files shared outside the domain, via Drive API) and/or "Audit Report – Login – Validate"
#          (login/admin activity via Reports API). Never writes.
# HOW TO RUN: python gwsdk_sharing_audit_report.py --subject reports-admin@corp.example \
#             --report sharing --domain corp.example --out ./reports
#             --report login --days 7                        (Python 3.10+, ADC)
#             scopes: drive.readonly (sharing) / admin.reports.audit.readonly (login)
# EXPECTED RESULTS: Dated CSV+JSON artifact(s) + a summary count. Exit 0 on success. No writes.
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
from datetime import datetime, timedelta, timezone

DRIVE_SCOPE = "https://www.googleapis.com/auth/drive.readonly"
REPORTS_SCOPE = "https://www.googleapis.com/auth/admin.reports.audit.readonly"


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Read-only Drive-sharing / login-audit report generator.")
    p.add_argument("--subject", required=True, help="Impersonation subject (least-privilege admin) email.")
    p.add_argument("--report", required=True, choices=["sharing", "login", "admin"],
                   help="sharing = external Drive exposure; login/admin = Reports API activity.")
    p.add_argument("--domain", help="Your primary domain (required for --report sharing) e.g. corp.example.")
    p.add_argument("--days", type=int, default=7, help="Look-back window for login/admin reports.")
    p.add_argument("--out", default=".", help="Output directory.")
    p.add_argument("--credentials", default=None, help="Optional secured credential path. Omit for ADC.")
    p.add_argument("--max-retries", type=int, default=5, help="Retry cap for 429/5xx backoff.")
    return p.parse_args()


def build_service(api: str, version: str, scope: str, subject: str, cred_path: str | None):
    try:
        import google.auth
        from google.oauth2 import service_account
        from googleapiclient.discovery import build
    except ImportError:
        sys.exit("Run: pip install google-api-python-client google-auth")
    if cred_path:
        creds = service_account.Credentials.from_service_account_file(cred_path, scopes=[scope])
        creds = creds.with_subject(subject)
    else:
        creds, _ = google.auth.default(scopes=[scope])
        if hasattr(creds, "with_subject"):
            creds = creds.with_subject(subject)
    return build(api, version, credentials=creds, cache_discovery=False)


def with_retry(request, max_retries: int):
    from googleapiclient.errors import HttpError
    attempt = 0
    while True:
        try:
            return request.execute()
        except HttpError as exc:
            status = getattr(exc.resp, "status", None)
            if status in (429, 500, 503) and attempt < max_retries:
                sleep = min(2 ** attempt, 30)
                print(f"  [retry] HTTP {status}; backing off {sleep}s", file=sys.stderr)
                time.sleep(sleep)
                attempt += 1
                continue
            raise


def stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def write_artifacts(name_slug: str, artifact: str, rows: list[dict], fields: list[str],
                    out_dir: str, extra: dict) -> tuple[str, str]:
    os.makedirs(out_dir, exist_ok=True)
    s = stamp()
    base = f"{name_slug}-{s}"
    csv_path = os.path.join(out_dir, base + ".csv")
    json_path = os.path.join(out_dir, base + ".json")
    with open(csv_path, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=fields)
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in fields})
    with open(json_path, "w", encoding="utf-8") as fh:
        json.dump({"artifact": artifact, "generated": s, "count": len(rows), **extra}, fh, indent=2)
    return csv_path, json_path


def report_sharing(args) -> int:
    if not args.domain:
        sys.exit("--report sharing requires --domain <your primary domain>.")
    service = build_service("drive", "v3", DRIVE_SCOPE, args.subject, args.credentials)
    artifact = "Sharing Report – External – Validate"
    rows: list[dict] = []
    page_token = None
    domain = args.domain.lower()
    while True:
        resp = with_retry(service.files().list(
            q="trashed = false",
            fields="nextPageToken, files(id, name, owners(emailAddress), permissions("
                   "type, emailAddress, domain, role))",
            pageSize=100, corpora="allDrives", includeItemsFromAllDrives=True,
            supportsAllDrives=True, pageToken=page_token,
        ), args.max_retries)
        for f in resp.get("files", []):
            external = []
            for perm in f.get("permissions", []) or []:
                if perm.get("type") == "anyone":
                    external.append("anyone")
                elif perm.get("type") == "domain" and perm.get("domain", "").lower() != domain:
                    external.append(f"domain:{perm.get('domain')}")
                elif perm.get("type") == "user":
                    addr = (perm.get("emailAddress") or "")
                    if addr and not addr.lower().endswith("@" + domain):
                        external.append(addr)
            if external:
                owner = (f.get("owners") or [{}])[0].get("emailAddress", "")
                rows.append({"fileId": f["id"], "name": f.get("name", ""), "owner": owner,
                             "externalGrants": "; ".join(external)})
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    csv_p, json_p = write_artifacts("sharing-report-external-validate", artifact, rows,
                                    ["fileId", "name", "owner", "externalGrants"], args.out,
                                    {"domain": args.domain})
    print(f"{artifact}: {len(rows)} externally-shared file(s).")
    print(f"Wrote: {csv_p}\nWrote: {json_p}")
    return 0


def report_activity(args, app: str) -> int:
    service = build_service("admin", "reports_v1", REPORTS_SCOPE, args.subject, args.credentials)
    artifact = "Audit Report – Login – Validate" if app == "login" else "Audit Report – Admin – Validate"
    start = (datetime.now(timezone.utc) - timedelta(days=args.days)).strftime("%Y-%m-%dT%H:%M:%SZ")
    rows: list[dict] = []
    page_token = None
    while True:
        resp = with_retry(service.activities().list(
            userKey="all", applicationName=app, startTime=start, maxResults=1000, pageToken=page_token,
        ), args.max_retries)
        for item in resp.get("items", []):
            actor = item.get("actor", {}).get("email", "")
            ip = item.get("ipAddress", "")
            t = item.get("id", {}).get("time", "")
            for ev in item.get("events", []):
                rows.append({"time": t, "actor": actor, "ipAddress": ip,
                             "eventName": ev.get("name", ""), "type": ev.get("type", "")})
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    slug = "audit-report-login-validate" if app == "login" else "audit-report-admin-validate"
    csv_p, json_p = write_artifacts(slug, artifact, rows,
                                    ["time", "actor", "ipAddress", "eventName", "type"], args.out,
                                    {"applicationName": app, "lookbackDays": args.days,
                                     "note": "Reports API events can lag; verify current latency "
                                             "for your event types in Google docs."})
    print(f"{artifact}: {len(rows)} event(s) over {args.days} day(s).")
    print(f"Wrote: {csv_p}\nWrote: {json_p}")
    return 0


def main() -> int:
    args = parse_args()
    print(f"# Report '{args.report}' (read-only) — subject {args.subject}")
    if args.report == "sharing":
        return report_sharing(args)
    return report_activity(args, app=args.report)


if __name__ == "__main__":
    raise SystemExit(main())
