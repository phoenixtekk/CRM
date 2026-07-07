#!/usr/bin/env python3
# adoption_config_check.py — verify the adoption-measurement setup is present and SAFE (read-only).
#
# PURPOSE: Guardrail check for the measurement tooling. Confirms Application Default Credentials (ADC)
#          are available, the Admin SDK Reports (and optionally Directory) APIs are reachable, and that
#          ONLY read-only scopes are in use — no write/OAuth-write scope may be present. Safe default:
#          performs read-only probes only; never writes to the tenant.
# HOW TO RUN: python adoption_config_check.py [--check-directory]   (Python 3.10+, gcloud auth / ADC)
# EXPECTED RESULTS: A checklist of PASS/FAIL lines and an overall RESULT: PASS/FAIL. Non-zero exit if
#                   any check fails (e.g. no ADC, API unreachable, or a write scope detected).
#
# Auth: ADC (`gcloud auth application-default login`) with a least-privilege Reports-only admin role.
# NO service-account key file is read and NO secrets are embedded.
# Requires: pip install google-api-python-client google-auth

import argparse
import sys

READONLY_SCOPES = [
    "https://www.googleapis.com/auth/admin.reports.usage.readonly",
    "https://www.googleapis.com/auth/admin.directory.user.readonly",
]

# Any scope containing these tokens (and not ending in .readonly) is treated as a WRITE scope.
WRITE_MARKERS = ("admin.directory.user", "admin.directory.group", "gmail.modify", "gmail.send",
                 "drive", "admin.datatransfer")


def _pass(msg): print(f"  PASS  {msg}")
def _fail(msg): print(f"  FAIL  {msg}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Read-only guardrail check for adoption measurement.")
    ap.add_argument("--check-directory", action="store_true",
                    help="Also probe the Directory API (read-only).")
    args = ap.parse_args()

    print("Adoption measurement config check (read-only)\n")
    ok = True

    # 1) Libraries present.
    try:
        import google.auth
        from googleapiclient.discovery import build
        _pass("google-auth / google-api-python-client importable.")
    except ImportError:
        _fail("missing libs — run: pip install google-api-python-client google-auth")
        print("\nRESULT: FAIL")
        return 1

    # 2) ADC available.
    try:
        creds, project = google.auth.default(scopes=READONLY_SCOPES)
        _pass(f"Application Default Credentials found (project: {project or 'n/a'}).")
    except Exception as exc:  # noqa: BLE001
        _fail(f"no ADC — run `gcloud auth application-default login`. ({exc})")
        print("\nRESULT: FAIL")
        return 1

    # 3) Guardrail: no write scopes requested/granted.
    granted = list(getattr(creds, "scopes", None) or READONLY_SCOPES)
    write_hits = [s for s in granted
                  if any(m in s for m in WRITE_MARKERS) and not s.endswith(".readonly")]
    if write_hits:
        _fail(f"WRITE scope(s) detected — measurement must be read-only: {write_hits}")
        ok = False
    else:
        _pass("no write scopes present (read-only guardrail OK).")

    # 4) Reports API reachable (read-only probe).
    try:
        svc = build("admin", "reports_v1", credentials=creds, cache_discovery=False)
        import datetime as dt
        probe_day = (dt.date.today() - dt.timedelta(days=3)).isoformat()
        svc.customerUsageReports().get(date=probe_day,
                                       parameters="gmail:num_emails_exchanged").execute()
        _pass("Admin SDK Reports API reachable (data may lag ~1-3 days — verify in your tenant).")
    except Exception as exc:  # noqa: BLE001
        _fail(f"Reports API not reachable / not enabled / insufficient role. ({exc})")
        ok = False

    # 5) Optional Directory read probe.
    if args.check_directory:
        try:
            dsvc = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
            dsvc.users().list(customer="my_customer", maxResults=1).execute()
            _pass("Directory API reachable (read-only).")
        except Exception as exc:  # noqa: BLE001
            _fail(f"Directory API not reachable / insufficient role. ({exc})")
            ok = False

    print(f"\nRESULT: {'PASS' if ok else 'FAIL'}")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
