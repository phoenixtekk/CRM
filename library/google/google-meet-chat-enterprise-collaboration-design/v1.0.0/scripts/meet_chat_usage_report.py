#!/usr/bin/env python3
# meet_chat_usage_report.py — Meet & Chat usage/adoption + external-exposure report (Reports API, read-only).
#
# PURPOSE: Summarize Meet and Chat activity and external exposure from the Admin SDK Reports API
#          (customer + user usage / activity) to size adoption and spot ungoverned external use.
#          READ-ONLY: pulls report data only; makes no configuration changes.
# HOW TO RUN: python meet_chat_usage_report.py --domain your-domain.com --days 30 --out usage.csv
#             (Python 3.10+, OAuth/ADC; see --help). pip install google-api-python-client google-auth
# EXPECTED RESULTS: writes usage.csv (per-day Meet/Chat usage metrics) and prints a summary; the
#          pass signal is a coherent adoption/external picture to inform the design. No tenant change.

import argparse
import csv
import sys
from datetime import datetime, timezone, timedelta

# Read-only Reports API scope.
SCOPES = ["https://www.googleapis.com/auth/admin.reports.usage.readonly"]

# Customer-usage parameters of interest (names per the Admin SDK Reports "meet"/"chat" apps).
# Availability of specific parameters varies by edition/version — the tool records whatever is
# returned and flags any that are absent (verify for your tenant), never inventing values.
INTEREST = [
    "meet:num_calls",
    "meet:call_minutes",
    "meet:num_external_participants",
    "chat:active_users",
    "chat:messages_sent",
    "chat:rooms_active",
]


def build_reports(subject=None):
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        print("Missing deps. Run: pip install google-api-python-client google-auth", file=sys.stderr)
        raise
    creds, _ = google.auth.default(scopes=SCOPES)
    if subject and hasattr(creds, "with_subject"):
        creds = creds.with_subject(subject)
    return build("admin", "reports_v1", credentials=creds, cache_discovery=False)


def fetch_customer_usage(reports, day):
    """Return {param: value} for one date from customerUsageReports; empty if not yet available."""
    resp = reports.customerUsageReports().get(date=day).execute()
    out = {}
    for report in resp.get("usageReports", []):
        for param in report.get("parameters", []):
            name = param.get("name")
            value = param.get("intValue", param.get("stringValue"))
            if name:
                out[name] = value
    return out


def main():
    ap = argparse.ArgumentParser(description="Meet & Chat usage/adoption report (Reports API, read-only).")
    ap.add_argument("--domain", required=True)
    ap.add_argument("--days", type=int, default=30, help="Look-back window in days (default 30).")
    ap.add_argument("--subject", help="Admin to impersonate (domain-wide delegation).")
    ap.add_argument("--out", default="usage.csv")
    args = ap.parse_args()

    reports = build_reports(args.subject)
    # Reports data lags ~2-3 days; start the window a few days back.
    end = datetime.now(timezone.utc).date() - timedelta(days=3)
    rows = []
    missing_params = set(INTEREST)

    for i in range(args.days):
        day = (end - timedelta(days=i)).isoformat()
        try:
            usage = fetch_customer_usage(reports, day)
        except Exception as exc:  # noqa: BLE001 - a not-yet-available date is expected, keep going
            print(f"  {day}: no data ({exc})", file=sys.stderr)
            continue
        if not usage:
            continue
        row = {"date": day}
        for param in INTEREST:
            if param in usage:
                row[param] = usage[param]
                missing_params.discard(param)
            else:
                row[param] = ""
        rows.append(row)

    fields = ["date"] + INTEREST
    with open(args.out, "w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        for row in sorted(rows, key=lambda r: r["date"]):
            writer.writerow(row)

    print(f"Usage report written to {args.out} ({len(rows)} day(s) with data).")
    if missing_params:
        print("Parameters not returned by your tenant/edition (verify for your version): "
              + ", ".join(sorted(missing_params)))
    print("Use external-participant / external-chat signals to prioritize the external-access design.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
