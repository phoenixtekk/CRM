#!/usr/bin/env python3
# adoption_metrics_report.py — pull Google Workspace adoption/usage metrics (read-only) and trend them.
#
# PURPOSE: Read the Google Admin SDK Reports API (Workspace customer usage) READ-ONLY to compute
#          per-app active-usage counts (Gmail, Drive, Docs, Meet, Chat, Gemini where reported),
#          optionally filtered to an OU/wave and compared against a saved baseline, and emit a
#          per-app TREND signal. Safe default: read-only; never writes to the tenant.
# HOW TO RUN: python adoption_metrics_report.py --days 30 [--ou "Wave 0"] [--baseline base.csv]
#             [--target-rate 0.70] [--out adoption.csv]   (Python 3.10+, gcloud auth / ADC; see --help)
# EXPECTED RESULTS: A CSV + stdout table of per-app active users; with --baseline, prints TREND: UP/
#                   FLAT/DOWN per app. Non-zero exit if auth/API is unavailable.
#
# Auth: Application Default Credentials (ADC). Run `gcloud auth application-default login` with an
# account holding a least-privilege Reports-only admin role, OR use a service account via domain-wide
# delegation. NO service-account key is read from disk by this script and NO secrets are embedded.
# Requires: pip install google-api-python-client google-auth  (Admin SDK Reports API enabled).

import argparse
import csv
import datetime as dt
import sys

# Read-only scope only. Presence of any write scope would be a guardrail violation.
READONLY_SCOPES = ["https://www.googleapis.com/auth/admin.reports.usage.readonly"]

# Reports API "customerUsageReports" parameters we surface, mapped to friendly app names.
# These parameter names come from Google's public Reports API docs; availability depends on the
# tenant edition and can lag ~1-3 days. Verify in your tenant.
USAGE_PARAMS = {
    "Gmail": "gmail:num_emails_exchanged",
    "Drive": "drive:num_items_created",
    "Docs": "docs:num_docs_edited_users",
    "Meet": "meet:num_meetings",
    "Chat": "chat:active_users",
    "Gemini": "gemini:active_users",  # Gemini reporting is edition/rollout dependent — verify in your tenant.
}


def _client():
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        sys.exit("ERROR: pip install google-api-python-client google-auth  (see header).")
    try:
        creds, _ = google.auth.default(scopes=READONLY_SCOPES)
    except Exception as exc:  # noqa: BLE001
        sys.exit(f"ERROR: no Application Default Credentials. Run "
                 f"`gcloud auth application-default login`. ({exc})")
    return build("admin", "reports_v1", credentials=creds, cache_discovery=False)


def fetch_usage(service, day: str) -> dict:
    """Return {app_name: numeric_value} for a single date (YYYY-MM-DD), read-only."""
    result = {name: None for name in USAGE_PARAMS}
    params = ",".join(USAGE_PARAMS.values())
    try:
        resp = service.customerUsageReports().get(date=day, parameters=params).execute()
    except Exception as exc:  # noqa: BLE001
        print(f"  WARN: Reports API returned no data for {day} ({exc}); "
              f"data can lag 1-3 days — verify in your tenant.", file=sys.stderr)
        return result
    for report in resp.get("usageReports", []):
        for p in report.get("parameters", []):
            for app, pname in USAGE_PARAMS.items():
                if p.get("name") == pname:
                    result[app] = p.get("intValue") or p.get("stringValue")
    return result


def load_baseline(path: str) -> dict:
    base = {}
    try:
        with open(path, newline="", encoding="utf-8") as fh:
            for row in csv.DictReader(fh):
                try:
                    base[row["app"]] = float(row["active_value"])
                except (KeyError, ValueError, TypeError):
                    continue
    except FileNotFoundError:
        print(f"  WARN: baseline {path} not found; trend comparison skipped.", file=sys.stderr)
    return base


def main() -> int:
    ap = argparse.ArgumentParser(description="Read-only Google Workspace adoption metrics report.")
    ap.add_argument("--days", type=int, default=30,
                    help="Look back this many days for the most recent available report (default 30).")
    ap.add_argument("--ou", default=None,
                    help="Label only (e.g. wave/OU name) recorded in output; customer usage is tenant-wide.")
    ap.add_argument("--baseline", default=None, help="Baseline CSV to compute TREND against.")
    ap.add_argument("--target-rate", type=float, default=None,
                    help="Optional target multiplier vs baseline to flag as met (e.g. 0.70).")
    ap.add_argument("--out", default="adoption_report.csv", help="Output CSV path.")
    args = ap.parse_args()

    service = _client()

    # Walk back from (today - 2) to find the most recent day the Reports API has data for.
    today = dt.date.today()
    usage, used_day = {}, None
    for delta in range(2, args.days + 2):
        day = (today - dt.timedelta(days=delta)).isoformat()
        usage = fetch_usage(service, day)
        if any(v is not None for v in usage.values()):
            used_day = day
            break
    if used_day is None:
        print("No usage data returned in the look-back window. Verify Reports access in your tenant.",
              file=sys.stderr)
        return 2

    baseline = load_baseline(args.baseline) if args.baseline else {}

    print(f"Adoption report  (data date: {used_day}"
          + (f", label: {args.ou}" if args.ou else "") + ")")
    print(f"{'App':10} {'Active':>12} {'Baseline':>12} {'Trend':>8}")
    rows = []
    for app in USAGE_PARAMS:
        raw = usage.get(app)
        val = float(raw) if raw not in (None, "") else 0.0
        base = baseline.get(app)
        trend = ""
        if base is not None:
            if val > base * 1.01:
                trend = "UP"
            elif val < base * 0.99:
                trend = "DOWN"
            else:
                trend = "FLAT"
            if args.target_rate is not None and base > 0 and val >= base * (1 + args.target_rate):
                trend += "*"  # met target uplift
        print(f"{app:10} {val:12.0f} "
              f"{('' if base is None else f'{base:.0f}'):>12} {trend:>8}")
        rows.append({"app": app, "date": used_day, "label": args.ou or "",
                     "active_value": val, "baseline_value": "" if base is None else base,
                     "trend": trend})

    with open(args.out, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["app", "date", "label", "active_value",
                                           "baseline_value", "trend"])
        w.writeheader()
        w.writerows(rows)
    print(f"\nWrote {args.out} (read-only report; no tenant changes).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
