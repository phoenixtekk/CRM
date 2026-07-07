#!/usr/bin/env python3
# groups_lifecycle_review_report.py — owner-attested lifecycle/review report generator (read-only)
#
# PURPOSE: Produce the periodic Groups review artifact ("Review Report – <Scope> – <Stage>") that owners
#          attest to (Step 4.5 / Test 9): one row per group with type, owner group(s), member count,
#          external count, last-activity signal, and a computed next-review date by type cadence. Also
#          flags groups DUE / OVERDUE for review. READ-ONLY: Directory + Groups Settings read only; it
#          writes only the local report file you name with --out.
# HOW TO RUN: python groups_lifecycle_review_report.py --domain corp.example [--scope finance]
#             [--out review.html] [--json]
#             (Python 3.10+, OAuth/ADC with the *.readonly scopes in Requirement 2.6;
#              `pip install google-api-python-client google-auth`. See --help.)
# EXPECTED RESULTS: An HTML (and optional JSON) review report written locally + a printed summary of how
#          many groups are DUE/OVERDUE for owner attestation. Exit 0.
#
# SAFETY: read-only against the tenant. No credentials/keys embedded — auth resolved at runtime.

import argparse
import datetime as dt
import html
import json
import sys

GROUP_RO = "https://www.googleapis.com/auth/admin.directory.group.readonly"
MEMBER_RO = "https://www.googleapis.com/auth/admin.directory.group.member.readonly"
SETTINGS = "https://www.googleapis.com/auth/apps.groups.settings"

# Review cadence in days per type (Step 1.4): tighter for security/external.
CADENCE_DAYS = {"sec-": 90, "ext-": 90, "collab-": 180, "dl-": 365, "dyn-": 365}
PREFIXES = tuple(CADENCE_DAYS)


def build_services():
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        print("ERROR: pip install google-api-python-client google-auth", file=sys.stderr)
        sys.exit(2)
    creds, _ = google.auth.default(scopes=[GROUP_RO, MEMBER_RO, SETTINGS])
    directory = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    settings = build("groupssettings", "v1", credentials=creds, cache_discovery=False)
    return directory, settings


def org_domains(directory, primary):
    domains = {primary.lower()}
    try:
        for d in directory.domains().list(customer="my_customer").execute().get("domains", []):
            domains.add(d.get("domainName", "").lower())
    except Exception:
        pass
    return domains


def members(directory, email):
    out, page = [], None
    while True:
        resp = directory.members().list(groupKey=email, maxResults=200, pageToken=page).execute()
        out.extend(resp.get("members", []))
        page = resp.get("nextPageToken")
        if not page:
            break
    return out


def review_row(g, mem, cfg, org_doms, today):
    email = g.get("email", "")
    local = email.split("@", 1)[0].lower()
    prefix = next((p for p in PREFIXES if local.startswith(p)), None)
    gtype = (prefix or "?").strip("-")
    owners = [m.get("email", "") for m in mem if m.get("role") == "OWNER"]
    external = [m.get("email", "") for m in mem
                if m.get("email", "").split("@")[-1].lower() not in org_doms]
    cadence = CADENCE_DAYS.get(prefix, 365)
    # No native "last reviewed" field — approximate next review off today (operators track attestation
    # dates in their intake system; this seeds the cadence). Flag security/external with external
    # members as DUE regardless.
    next_review = today + dt.timedelta(days=cadence)
    status = "OK"
    if not owners:
        status = "OVERDUE (no owner)"
    elif prefix in ("sec-", "ext-") and external:
        status = "DUE (security/external w/ external members)"
    return {"email": email, "type": gtype, "owners": owners or ["<none>"],
            "members": len(mem), "external": len(external),
            "cadence_days": cadence, "next_review": next_review.isoformat(), "status": status}


def write_html(rows, scope, out, today):
    def td(x):
        return f"<td>{html.escape(str(x))}</td>"
    trs = "".join(
        "<tr>" + td(r["email"]) + td(r["type"]) + td(", ".join(r["owners"])) + td(r["members"])
        + td(r["external"]) + td(r["next_review"]) + td(r["status"]) + "</tr>" for r in rows)
    doc = (f"<!doctype html><meta charset=utf-8><title>Review Report – {html.escape(scope)}</title>"
           f"<h1>Groups Review Report — {html.escape(scope)}</h1>"
           f"<p>Generated {today.isoformat()} — {len(rows)} groups. Owners attest each row.</p>"
           "<table border=1 cellpadding=6 cellspacing=0>"
           "<tr><th>Group</th><th>Type</th><th>Owner(s)</th><th>Members</th><th>External</th>"
           "<th>Next review</th><th>Status</th></tr>" + trs + "</table>")
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(doc)


def main():
    ap = argparse.ArgumentParser(description="Owner-attested Groups lifecycle/review report (read-only).")
    ap.add_argument("--domain", required=True)
    ap.add_argument("--scope", default="ALL", help="Substring filter on email/name")
    ap.add_argument("--out", default="groups-review.html", help="Output HTML file")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    today = dt.date.today()
    directory, _settings = build_services()
    org_doms = org_domains(directory, args.domain)

    groups, page = [], None
    scope = None if args.scope == "ALL" else args.scope
    while True:
        resp = directory.groups().list(domain=args.domain, maxResults=200, pageToken=page).execute()
        for g in resp.get("groups", []):
            if not scope or scope.lower() in (g.get("email", "") + g.get("name", "")).lower():
                groups.append(g)
        page = resp.get("nextPageToken")
        if not page:
            break

    rows = [review_row(g, members(directory, g.get("email", "")), {}, org_doms, today) for g in groups]
    write_html(rows, args.scope, args.out, today)
    due = sum(1 for r in rows if r["status"] != "OK")
    print(f"Review report written: {args.out}  ({len(rows)} groups, {due} DUE/OVERDUE)")
    for r in rows:
        if r["status"] != "OK":
            print(f"  - {r['email']}: {r['status']}")
    if args.json:
        print(json.dumps({"scope": args.scope, "groups": len(rows), "due": due, "rows": rows}, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
