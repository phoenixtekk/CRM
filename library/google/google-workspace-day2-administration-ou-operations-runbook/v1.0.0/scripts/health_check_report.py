#!/usr/bin/env python3
# health_check_report.py — read-only Google Workspace health/monitoring report from the Admin SDK
#                          Reports API; renders an HTML summary for the daily/weekly health cadence.
#
# PURPOSE: Monitoring/health report generator for Gate G3. Pulls recent activity (login, admin, drive/
#          token events) from the Admin SDK Reports API for the last N days and renders an HTML health
#          report — login summary, admin-activity summary, external-sharing summary, top-risk section.
#          READ-ONLY — reads audit logs only, changes nothing.
# HOW TO RUN: python health_check_report.py --days 7 --output health-check.html
#             (Python 3.10+, OAuth/ADC or DWD service account, read-only Reports scope; see --help)
# EXPECTED RESULTS: an HTML file with dated summaries and a top-risk list; stdout prints headline
#                   counts. Exit 0 on success.
#
# Read-only scope (live): https://www.googleapis.com/auth/admin.reports.audit.readonly
# No keys are stored in this file. Requires (live): pip install google-api-python-client google-auth ;
# without libs/credential it renders a clearly-labelled SAMPLE report so the format is inspectable.

import argparse
import html
import sys
from collections import Counter
from datetime import datetime, timedelta, timezone

READONLY_SCOPES = ["https://www.googleapis.com/auth/admin.reports.audit.readonly"]

# Reports API application names this tool summarizes.
APPS = ["login", "admin", "drive", "token"]

SAMPLE = {
    "login": [{"name": "login_success", "actor": "user.a@example.com"},
              {"name": "login_failure", "actor": "user.b@example.com"},
              {"name": "login_success", "actor": "user.a@example.com"},
              {"name": "suspicious_login", "actor": "user.c@example.com"}],
    "admin": [{"name": "ASSIGN_ROLE", "actor": "admin@example.com"},
              {"name": "CHANGE_APPLICATION_SETTING", "actor": "admin@example.com"}],
    "drive": [{"name": "change_user_access", "actor": "user.d@example.com", "external": True},
              {"name": "change_document_visibility", "actor": "user.e@example.com", "external": True}],
    "token": [{"name": "authorize", "actor": "user.f@example.com"}],
}


def _build_service():
    try:
        import google.auth
        from googleapiclient.discovery import build
    except Exception:
        return None
    try:
        creds, _ = google.auth.default(scopes=READONLY_SCOPES)
        return build("admin", "reports_v1", credentials=creds, cache_discovery=False)
    except Exception as exc:
        print(f"[info] no live credential ({exc.__class__.__name__}); rendering SAMPLE report.",
              file=sys.stderr)
        return None


def _fetch_app(svc, app, start_time):
    events, tok = [], None
    while True:
        resp = svc.activities().list(userKey="all", applicationName=app, startTime=start_time,
                                     maxResults=1000, pageToken=tok).execute()
        for act in resp.get("items", []):
            actor = act.get("actor", {}).get("email", "unknown")
            for ev in act.get("events", []):
                external = any(p.get("name") in ("visibility", "target_domain")
                               and str(p.get("value")).lower() in ("shared_externally", "public")
                               for p in ev.get("parameters", []))
                events.append({"name": ev.get("name"), "actor": actor, "external": external})
        tok = resp.get("nextPageToken")
        if not tok:
            break
    return events


def gather(days, offline):
    if offline:
        return dict(SAMPLE), True
    svc = _build_service()
    if svc is None:
        return dict(SAMPLE), True
    start_time = (datetime.now(timezone.utc) - timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%SZ")
    data = {}
    for app in APPS:
        try:
            data[app] = _fetch_app(svc, app, start_time)
        except Exception as exc:
            print(f"[warn] could not read '{app}' activities: {exc}", file=sys.stderr)
            data[app] = []
    return data, False


def _section(title, counter):
    rows = "".join(f"<tr><td>{html.escape(str(k))}</td><td>{v}</td></tr>"
                   for k, v in counter.most_common(15)) or "<tr><td colspan=2>none</td></tr>"
    return (f"<h2>{html.escape(title)}</h2><table border=1 cellpadding=6 cellspacing=0>"
            f"<tr><th>Event</th><th>Count</th></tr>{rows}</table>")


def build_html(data, days, sample):
    login = Counter(e["name"] for e in data.get("login", []))
    admin = Counter(e["name"] for e in data.get("admin", []))
    ext_share = [e for e in data.get("drive", []) if e.get("external")]
    ext_counter = Counter(e["actor"] for e in ext_share)

    risks = []
    if login.get("suspicious_login"):
        risks.append(f"{login['suspicious_login']} suspicious login event(s) — investigate.")
    if login.get("login_failure", 0) > 50:
        risks.append(f"{login['login_failure']} login failures — possible spraying/lockout.")
    if any(n in admin for n in ("ASSIGN_ROLE", "CHANGE_APPLICATION_SETTING")):
        risks.append("Admin privilege/config changes occurred — confirm each was change-controlled.")
    if ext_share:
        risks.append(f"{len(ext_share)} external-sharing event(s) — review against sharing policy.")
    risk_html = "".join(f"<li>{html.escape(r)}</li>" for r in risks) or "<li>No top risks flagged.</li>"

    banner = ("<p style='background:#fee;padding:8px'><b>SAMPLE DATA</b> — no live credential; "
              "format preview only.</p>" if sample else "")
    generated = datetime.now(timezone.utc).isoformat()
    return f"""<!doctype html><meta charset=utf-8>
<title>Workspace Health Check</title>
<h1>Google Workspace Health Check</h1>
<p>Window: last {days} day(s) &middot; Generated {html.escape(generated)}</p>
{banner}
<h2>Top risks</h2><ul>{risk_html}</ul>
{_section("Login summary", login)}
{_section("Admin activity summary", admin)}
{_section("External-sharing by actor", ext_counter)}
<p>Read-only report from the Admin SDK Reports API. Retain as health/audit evidence.</p>
"""


def main():
    ap = argparse.ArgumentParser(description="Read-only Workspace health-check report (Reports API).")
    ap.add_argument("--days", type=int, default=7, help="Look-back window in days (default 7).")
    ap.add_argument("--output", default="health-check.html", help="HTML output path.")
    ap.add_argument("--offline", action="store_true", help="Render the SAMPLE report (no API calls).")
    args = ap.parse_args()

    data, sample = gather(args.days, args.offline)
    with open(args.output, "w", encoding="utf-8") as fh:
        fh.write(build_html(data, args.days, sample))

    total = sum(len(v) for v in data.values())
    print(f"Health check written to {args.output}  ({'SAMPLE' if sample else 'live'} data)")
    print(f"  events summarized : {total} across {', '.join(APPS)}")
    print(f"  window            : last {args.days} day(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
