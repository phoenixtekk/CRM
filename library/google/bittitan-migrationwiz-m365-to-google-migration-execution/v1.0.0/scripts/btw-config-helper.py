#!/usr/bin/env python3
# btw-config-helper.py — endpoint-config + throttling-health helper for a MigrationWiz move (read-only)
#
# PURPOSE: Verify the two things a MigrationWiz project needs before a pass runs, and watch provider limits
#          during one. --check-delegation confirms the Google target service account's domain-wide delegation
#          resolves the required read scopes and (best-effort) that the source app registration is reachable;
#          --check-throttle samples the Google target API and reports whether calls are being throttled/backed
#          off so you can tune the "BTW Throttle - Project Concurrency - Per Wave" profile. Read-only: no
#          config is changed and no MigrationWiz API is called. Provider limits are "verify for your version".
# HOW TO RUN: python btw-config-helper.py --check-delegation --google-sa-file sa.json --google-subject admin@corp.example
#             python btw-config-helper.py --check-throttle   --google-sa-file sa.json --google-subject admin@corp.example [--samples 20]
#             (Python 3.10+; read-only Admin SDK scopes; see --help)
# EXPECTED RESULTS: A pass/fail on delegation, or a throttling summary (throttled sample count + advice). Exit 0
#             if healthy; exit 2 if delegation fails or sustained throttling is detected.
#
# Optional live checks require:  pip install google-api-python-client google-auth
# No credentials are hardcoded; nothing is written. Source-side app-registration validation is best-effort
# (an optional Graph token via GRAPH_TOKEN); the authoritative source-consent step is done in Entra per
# MigrationWiz's source-endpoint docs (verify for your version).

import argparse
import os
import sys
import time

DIR_SCOPE = "https://www.googleapis.com/auth/admin.directory.user.readonly"


def _google_directory(sa_file, subject, scopes):
    from google.oauth2 import service_account
    import google.auth
    from googleapiclient.discovery import build
    if sa_file:
        creds = service_account.Credentials.from_service_account_file(sa_file, scopes=scopes)
        if subject:
            creds = creds.with_subject(subject)
    else:
        creds, _ = google.auth.default(scopes=scopes)
    return build("admin", "directory_v1", credentials=creds, cache_discovery=False)


def check_delegation(sa_file, subject, graph_token):
    print("== BTW config check: target delegation + source reachability ==")
    ok = True

    # Target: domain-wide delegation must resolve a read call impersonating an admin.
    if not subject:
        print("  [GAP] --google-subject not provided; cannot confirm delegation impersonation.")
        ok = False
    try:
        directory = _google_directory(sa_file, subject, [DIR_SCOPE])
        directory.users().list(customer="my_customer", maxResults=1, projection="basic").execute()
        print(f"  [OK ] Target delegation resolves read scope as {subject}.")
    except Exception as exc:  # noqa: BLE001
        print(f"  [GAP] Target delegation failed: {exc}. Authorize the SA client ID for the required")
        print("        scopes in Admin console -> Security -> API controls -> Domain-wide delegation.")
        ok = False

    # Source: best-effort reachability of the Entra app registration via a supplied Graph token.
    if graph_token:
        try:
            import urllib.request
            req = urllib.request.Request(
                "https://graph.microsoft.com/v1.0/organization",
                headers={"Authorization": f"Bearer {graph_token}"})
            with urllib.request.urlopen(req, timeout=30):
                print("  [OK ] Source Graph token reachable (app registration usable).")
        except Exception as exc:  # noqa: BLE001
            print(f"  [GAP] Source Graph token not usable: {exc}")
            ok = False
    else:
        print("  [..] No GRAPH_TOKEN — confirm the source app registration consent in Entra manually")
        print("       per MigrationWiz's source-endpoint docs (verify for your version).")

    return ok


def check_throttle(sa_file, subject, samples):
    print("== BTW throttling health (BTW Throttle - Project Concurrency - Per Wave) ==")
    try:
        directory = _google_directory(sa_file, subject, [DIR_SCOPE])
    except Exception as exc:  # noqa: BLE001
        print(f"  [GAP] Cannot build client: {exc}")
        return False

    throttled, errors = 0, 0
    for i in range(samples):
        try:
            directory.users().list(customer="my_customer", maxResults=1, projection="basic").execute()
        except Exception as exc:  # noqa: BLE001
            msg = str(exc).lower()
            if "429" in msg or "rate" in msg or "quota" in msg or "userratelimit" in msg:
                throttled += 1
            else:
                errors += 1
        time.sleep(0.2)

    rate = throttled / samples * 100 if samples else 0
    print(f"  Samples: {samples}  Throttled: {throttled} ({rate:.0f}%)  Other errors: {errors}")
    if rate >= 10:
        print("  [WARN] Sustained throttling — LOWER project concurrency per btw-wave-planner.py guidance")
        print("         and re-check. Verify the provider's current limits for your tenant.")
        return False
    print("  [OK ] No sustained throttling in this sample. Proceed; keep monitoring during the pass.")
    return True


def main():
    ap = argparse.ArgumentParser(description="MigrationWiz endpoint-config + throttling-health helper (read-only).")
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check-delegation", action="store_true",
                      help="Verify target domain-wide delegation + source reachability.")
    mode.add_argument("--check-throttle", action="store_true",
                      help="Sample the target API for throttling/backoff.")
    ap.add_argument("--google-sa-file", help="Google service-account JSON (read-only scopes).")
    ap.add_argument("--google-subject", help="Admin to impersonate via domain-wide delegation.")
    ap.add_argument("--graph-token-env", default="GRAPH_TOKEN",
                    help="Env var with a Microsoft Graph bearer token (optional, source reachability).")
    ap.add_argument("--samples", type=int, default=20, help="Throttle-check sample count (default 20).")
    args = ap.parse_args()

    if args.check_delegation:
        ok = check_delegation(args.google_sa_file, args.google_subject,
                              os.getenv(args.graph_token_env or ""))
    else:
        ok = check_throttle(args.google_sa_file, args.google_subject, args.samples)

    print("\nRESULT:", "PASS" if ok else "FAIL")
    sys.exit(0 if ok else 2)


if __name__ == "__main__":
    main()
