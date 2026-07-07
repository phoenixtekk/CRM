#!/usr/bin/env python3
# drive_governance_report.py — Shared Drive governance & lifecycle report (HTML/JSON)
#
# PURPOSE: Generate the governance/lifecycle report a quarterly access review needs — every Shared
#          Drive with its Manager (owner) group, member groups + roles, external-share and orphaned-owner
#          exposure (merged from the assessment JSON), and lifecycle flags (stale/empty Drive, Drive
#          missing a Manager group). READ-ONLY: it reads Drive/permissions and writes only a local report
#          file — it never changes the tenant.
# HOW TO RUN: python drive_governance_report.py --catalog drive-catalog.csv \
#               [--exposure post-finance.json] --out finance-governance.html [--format html|json]
#             (Python 3.10+, OAuth/ADC read-only scopes per Requirements 2.6;
#              `pip install google-api-python-client google-auth`. See --help.)
# EXPECTED RESULTS: A local HTML (or JSON) report enumerating each Shared Drive, its owner/member groups
#          and roles, exposure counts, and lifecycle flags. Exit 0 on success.
#
# SAFETY: read-only against the tenant; the ONLY write is the local report file (--out). No credentials
#         or keys embedded; auth via ADC / delegated service account.

import argparse
import datetime as dt
import html
import json
import os
import sys

DRIVE_RO = "https://www.googleapis.com/auth/drive.readonly"
STALE_DAYS = 180


def build_drive():
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        print("ERROR: pip install google-api-python-client google-auth", file=sys.stderr)
        sys.exit(2)
    creds, _ = google.auth.default(scopes=[DRIVE_RO])
    return build("drive", "v3", credentials=creds, cache_discovery=False)


def list_shared_drives(drive):
    drives, page = [], None
    while True:
        resp = drive.drives().list(pageSize=100, pageToken=page,
                                   fields="nextPageToken, drives(id,name,createdTime)").execute()
        drives.extend(resp.get("drives", []))
        page = resp.get("nextPageToken")
        if not page:
            break
    return drives


def drive_detail(drive, drive_id):
    perms = drive.permissions().list(
        fileId=drive_id, supportsAllDrives=True, useDomainAdminAccess=True,
        fields="permissions(type,role,emailAddress,domain)").execute().get("permissions", [])
    members = [{"who": p.get("emailAddress") or p.get("domain"), "type": p.get("type"),
                "role": p.get("role")} for p in perms]
    # Content presence (empty-Drive flag): does the Drive hold any non-trashed file?
    files = drive.files().list(
        q="trashed=false", driveId=drive_id, corpora="drive",
        includeItemsFromAllDrives=True, supportsAllDrives=True,
        pageSize=1, fields="files(id)").execute().get("files", [])
    return members, bool(files)


def lifecycle_flags(dr, members, has_content):
    flags = []
    if not any(m["role"] == "organizer" for m in members):
        flags.append("NO-MANAGER-GROUP")
    if any(m["type"] == "user" for m in members):
        flags.append("HAS-INDIVIDUAL-MEMBER")
    if not has_content:
        flags.append("EMPTY-DRIVE")
    created = dr.get("createdTime", "")
    try:
        age = (dt.datetime.now(dt.timezone.utc)
               - dt.datetime.fromisoformat(created.replace("Z", "+00:00"))).days
        if age > STALE_DAYS and not has_content:
            flags.append("STALE-EMPTY")
    except ValueError:
        pass
    return flags


def render_html(rows, exposure, out):
    now = dt.datetime.now(dt.timezone.utc).isoformat()
    parts = ["<!doctype html><meta charset='utf-8'>",
             "<title>Drive Governance Report</title>",
             "<h1>Drive &amp; Shared Drives Governance Report</h1>",
             f"<p>Generated {html.escape(now)} — read-only.</p>",
             "<table border='1' cellpadding='6' cellspacing='0'>",
             "<tr><th>Shared Drive</th><th>Manager (owner) group</th><th>Members (role)</th>"
             "<th>Lifecycle flags</th></tr>"]
    for r in rows:
        mgr = ", ".join(m["who"] for m in r["members"] if m["role"] == "organizer") or "—"
        mem = "<br>".join(f"{html.escape(str(m['who']))} ({m['role']}/{m['type']})"
                          for m in r["members"] if m["role"] != "organizer") or "—"
        flags = ", ".join(r["flags"]) or "ok"
        parts.append(f"<tr><td>{html.escape(r['name'])}</td><td>{html.escape(mgr)}</td>"
                     f"<td>{mem}</td><td>{html.escape(flags)}</td></tr>")
    parts.append("</table>")
    if exposure:
        parts.append("<h2>Exposure (from assessment)</h2><ul>")
        for k, v in exposure.get("counts", {}).items():
            parts.append(f"<li>{html.escape(k)}: {v}</li>")
        parts.append("</ul>")
    with open(out, "w", encoding="utf-8") as fh:
        fh.write("\n".join(parts))


def main():
    ap = argparse.ArgumentParser(description="Shared Drive governance & lifecycle report (read-only).")
    ap.add_argument("--catalog", help="Catalog CSV (informational — expected Drives)")
    ap.add_argument("--exposure", help="Assessment JSON to merge exposure counts from")
    ap.add_argument("--out", required=True, help="Output report path (.html or .json)")
    ap.add_argument("--format", choices=["html", "json"], help="Override format (else inferred from --out)")
    args = ap.parse_args()

    exposure = None
    if args.exposure and os.path.exists(args.exposure):
        with open(args.exposure, encoding="utf-8") as fh:
            exposure = json.load(fh)

    drive = build_drive()
    rows = []
    for dr in list_shared_drives(drive):
        members, has_content = drive_detail(drive, dr["id"])
        rows.append({"name": dr["name"], "members": members,
                     "flags": lifecycle_flags(dr, members, has_content)})
        print(f"  {dr['name']}: {len(members)} members, flags={rows[-1]['flags'] or ['ok']}")

    fmt = args.format or ("json" if args.out.lower().endswith(".json") else "html")
    if fmt == "json":
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump({"drives": rows, "exposure": exposure}, fh, indent=2)
    else:
        render_html(rows, exposure, args.out)
    print(f"\nReport written: {args.out} ({len(rows)} Shared Drives)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
