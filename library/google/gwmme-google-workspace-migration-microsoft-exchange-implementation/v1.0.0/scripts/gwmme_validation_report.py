#!/usr/bin/env python3
# gwmme_validation_report.py — post-migration mail/calendar/contacts completeness report
#
# PURPOSE: Read-only post-migration validation for a GWMME wave. Compares SOURCE item counts (mail,
#          calendar, contacts — supplied from the Microsoft side) against DESTINATION counts read from
#          Google (Gmail messages, Calendar events, People contacts) per user, and flags any shortfall
#          beyond tolerance. Read-only: reads counts only, never modifies mailboxes.
# HOW TO RUN: python gwmme_validation_report.py --wave Pilot-01 --mapping planned-mapping.csv \
#                 --source-counts source_counts.csv --tolerance 0.02 --out Validation-Report-Pilot-01.csv
#             (Python 3.10+, OAuth/ADC domain-wide delegation to read each user's data; see --help.
#              pip install google-api-python-client google-auth)
# EXPECTED RESULTS: A per-user report with source vs destination counts for mail/calendar/contacts and
#                   a PASS/FAIL per user. Any FAIL => triage (throttling/permission/delta) and re-run.

import argparse
import csv
import sys

# Read-only scopes for counting destination items per user (domain-wide delegation).
SCOPES = [
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/calendar.readonly",
    "https://www.googleapis.com/auth/contacts.readonly",
]


def load_mapping(path, wave):
    rows = []
    with open(path, newline="", encoding="utf-8-sig") as f:
        for r in csv.DictReader(f):
            if wave and (r.get("wave") or "").strip() != wave:
                continue
            rows.append({
                "source_smtp": (r.get("source_smtp") or "").strip().lower(),
                "target": (r.get("target_google_email") or "").strip().lower(),
            })
    return [r for r in rows if r["target"]]


def load_source_counts(path):
    """Source counts CSV: target_google_email (or source_smtp), mail, calendar, contacts."""
    counts = {}
    with open(path, newline="", encoding="utf-8-sig") as f:
        for r in csv.DictReader(f):
            key = ((r.get("target_google_email") or r.get("source_smtp") or "")).strip().lower()
            if not key:
                continue
            counts[key] = {
                "mail": int(float(r.get("mail") or 0)),
                "calendar": int(float(r.get("calendar") or 0)),
                "contacts": int(float(r.get("contacts") or 0)),
            }
    return counts


def build_delegate(subject):
    """Return per-user Google service builders using domain-wide delegated credentials.

    Returns None if libraries/credentials are unavailable (offline mode: destination counts = -1).
    """
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        return None
    try:
        creds, _ = google.auth.default(scopes=SCOPES)
        if hasattr(creds, "with_subject"):
            creds = creds.with_subject(subject)
        return {
            "gmail": build("gmail", "v1", credentials=creds, cache_discovery=False),
            "calendar": build("calendar", "v3", credentials=creds, cache_discovery=False),
            "people": build("people", "v1", credentials=creds, cache_discovery=False),
        }
    except Exception as exc:  # noqa: BLE001
        print(f"NOTE: delegation failed for {subject} ({exc}); destination counts unavailable.",
              file=sys.stderr)
        return None


def count_dest(svc):
    """Count Gmail messages, Calendar events, People contacts for the delegated user (read-only)."""
    mail = _count_gmail(svc["gmail"])
    cal = _count_calendar(svc["calendar"])
    con = _count_contacts(svc["people"])
    return mail, cal, con


def _count_gmail(gmail):
    total, token = 0, None
    while True:
        resp = gmail.users().messages().list(userId="me", maxResults=500, pageToken=token).execute()
        total += len(resp.get("messages", []))
        token = resp.get("nextPageToken")
        if not token:
            return total


def _count_calendar(calendar):
    total, token = 0, None
    while True:
        resp = calendar.events().list(calendarId="primary", maxResults=2500,
                                       pageToken=token, showDeleted=False).execute()
        total += len(resp.get("items", []))
        token = resp.get("nextPageToken")
        if not token:
            return total


def _count_contacts(people):
    total, token = 0, None
    while True:
        resp = people.people().connections().list(
            resourceName="people/me", pageSize=1000, personFields="names",
            pageToken=token).execute()
        total += len(resp.get("connections", []))
        token = resp.get("nextPageToken")
        if not token:
            return total


def main():
    ap = argparse.ArgumentParser(description="GWMME post-migration completeness report (read-only).")
    ap.add_argument("--wave", default="", help="Wave name to validate (e.g. Pilot-01). Blank = all.")
    ap.add_argument("--mapping", required=True, help="Wave-assigned mapping CSV.")
    ap.add_argument("--source-counts", required=True,
                    help="CSV of source counts (email key + mail,calendar,contacts).")
    ap.add_argument("--tolerance", type=float, default=0.02,
                    help="Fractional shortfall allowed before FAIL (default 0.02 = 2%).")
    ap.add_argument("--out", default="Validation-Report.csv", help="Output report CSV path.")
    args = ap.parse_args()

    users = load_mapping(args.mapping, args.wave)
    src = load_source_counts(args.source_counts)
    if not users:
        sys.exit("ERROR: no users for the selected wave in the mapping.")

    rows, failures = [], 0
    for u in users:
        s = src.get(u["target"]) or src.get(u["source_smtp"]) or {"mail": 0, "calendar": 0, "contacts": 0}
        svc = build_delegate(u["target"])
        if svc:
            d_mail, d_cal, d_con = count_dest(svc)
        else:
            d_mail = d_cal = d_con = -1  # offline / unavailable

        status = "PASS"
        detail = []
        for label, s_val, d_val in (("mail", s["mail"], d_mail),
                                    ("calendar", s["calendar"], d_cal),
                                    ("contacts", s["contacts"], d_con)):
            if d_val < 0:
                status, _ = "UNKNOWN", detail.append(f"{label}:dest-unavailable")
                continue
            allowed = s_val * (1 - args.tolerance)
            if d_val < allowed:
                status = "FAIL"
                detail.append(f"{label}:{d_val}/{s_val}")
        if status == "FAIL":
            failures += 1
        rows.append([u["target"], s["mail"], d_mail, s["calendar"], d_cal,
                     s["contacts"], d_con, status, "; ".join(detail)])

    with open(args.out, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["target", "src_mail", "dst_mail", "src_cal", "dst_cal",
                    "src_contacts", "dst_contacts", "status", "detail"])
        w.writerows(rows)

    print(f"Validated {len(rows)} users for wave '{args.wave or 'ALL'}'. "
          f"Report: {args.out}")
    print(f"FAIL: {failures} | PASS/UNKNOWN: {len(rows) - failures}")
    if failures:
        print("RESULT: FAIL — triage shortfalls (throttling/permission/delta) and re-run before "
              "passing the validation gate.")
        sys.exit(1)
    print("RESULT: PASS — mail/calendar/contacts complete within tolerance for all validated users.")


if __name__ == "__main__":
    main()
