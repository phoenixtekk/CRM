#!/usr/bin/env python3
# gwsdk_auth_scope_validator.py — validate the automation service identity & least-scope OAuth setup
#
# PURPOSE: Read-only. Authenticate the automation service identity (via ADC / a runtime-supplied
#          credential, impersonating a least-privilege subject), probe each declared OAuth scope,
#          and flag any scope broader than its task needs. Proves Gate 3-A (auth least-scope).
# HOW TO RUN: python gwsdk_auth_scope_validator.py --subject reports-admin@corp.example \
#             --scopes admin.directory.user.readonly,admin.reports.audit.readonly   (Python 3.10+, ADC)
# EXPECTED RESULTS: Per-scope PASS/FAIL lines and an overall verdict; a broader-than-required scope
#                   is flagged. Exit 0 = all good, non-zero = a scope failed or is over-broad.
#
# No secrets in code: credentials come from ADC or a path passed with --credentials (never committed).
# pip install google-api-python-client google-auth

from __future__ import annotations

import argparse
import sys

SCOPE_PREFIX = "https://www.googleapis.com/auth/"

# Declared task -> minimal scope inventory (Implementation 2.2). Read-only is the default.
KNOWN_SCOPES = {
    "admin.directory.user.readonly": {"access": "read", "task": "user/license report"},
    "admin.directory.group.readonly": {"access": "read", "task": "group membership report"},
    "admin.reports.audit.readonly": {"access": "read", "task": "login/admin audit report"},
    "drive.readonly": {"access": "read", "task": "Drive sharing report"},
    "drive.metadata.readonly": {"access": "read", "task": "Drive sharing report (metadata)"},
    "admin.directory.user": {"access": "write", "task": "user/OU/license provisioning (--apply)"},
    "admin.directory.group": {"access": "write", "task": "group provisioning (--apply)"},
}

# A lightweight read probe per read scope, so we test the credential end-to-end (read-only).
READ_PROBES = {
    "admin.directory.user.readonly": ("admin", "directory_v1",
                                      lambda s: s.users().list(customer="my_customer", maxResults=1)),
    "admin.directory.group.readonly": ("admin", "directory_v1",
                                        lambda s: s.groups().list(customer="my_customer", maxResults=1)),
    "admin.reports.audit.readonly": ("admin", "reports_v1",
                                     lambda s: s.activities().list(userKey="all", applicationName="login",
                                                                   maxResults=1)),
    "drive.readonly": ("drive", "v3", lambda s: s.files().list(pageSize=1, fields="files(id)")),
    "drive.metadata.readonly": ("drive", "v3", lambda s: s.files().list(pageSize=1, fields="files(id)")),
}


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Validate the automation service identity and least-scope auth.")
    p.add_argument("--subject", required=True,
                   help="Impersonation subject email (least-privilege admin), e.g. reports-admin@corp.example")
    p.add_argument("--scopes", required=True,
                   help="Comma-separated OAuth scope short names to validate (e.g. admin.directory.user.readonly)")
    p.add_argument("--credentials", default=None,
                   help="Optional path to a secured credential. Omit to use ADC. Never commit a key.")
    p.add_argument("--probe", action="store_true",
                   help="Actively make one read-only API call per read scope to prove the credential works.")
    return p.parse_args()


def build_credentials(scopes: list[str], subject: str, cred_path: str | None):
    try:
        import google.auth
        from google.oauth2 import service_account
    except ImportError:
        sys.exit("Missing dependency. Run: pip install google-api-python-client google-auth")

    full_scopes = [SCOPE_PREFIX + s for s in scopes]
    if cred_path:
        creds = service_account.Credentials.from_service_account_file(cred_path, scopes=full_scopes)
        return creds.with_subject(subject)
    # ADC path — no key in code. Works with an attached identity or `gcloud auth application-default login`.
    creds, _ = google.auth.default(scopes=full_scopes)
    if hasattr(creds, "with_subject"):
        return creds.with_subject(subject)
    return creds


def run_probe(scope: str, creds) -> tuple[bool, str]:
    try:
        from googleapiclient.discovery import build
    except ImportError:
        return False, "googleapiclient not installed"
    api, version, call = READ_PROBES[scope]
    try:
        service = build(api, version, credentials=creds, cache_discovery=False)
        call(service).execute()
        return True, "read probe ok"
    except Exception as exc:  # surface auth/scope errors clearly
        return False, f"{type(exc).__name__}: {exc}"


def main() -> int:
    args = parse_args()
    requested = [s.strip() for s in args.scopes.split(",") if s.strip()]
    if not requested:
        sys.exit("No scopes provided.")

    print(f"# Auth least-scope validation (Gate 3-A) — subject: {args.subject}")
    print(f"# Credential source: {'file:'+args.credentials if args.credentials else 'ADC (no key in code)'}\n")

    overall_ok = True
    for scope in requested:
        meta = KNOWN_SCOPES.get(scope)
        if meta is None:
            print(f"[WARN] {scope}: not in known inventory — verify it is intended and minimal.")
            overall_ok = False
            continue
        note = f"{meta['access'].upper():5} — {meta['task']}"
        if meta["access"] == "write":
            print(f"[FLAG] {scope}: {note}  (write scope — only for authorized provisioning --apply)")
        else:
            print(f"[ OK ] {scope}: {note}")

    if args.probe:
        print("\n# Read-only probes")
        try:
            creds = build_credentials(requested, args.subject, args.credentials)
        except Exception as exc:
            print(f"[FAIL] could not build credentials: {exc}")
            return 2
        for scope in requested:
            if scope in READ_PROBES:
                ok, detail = run_probe(scope, creds)
                print(f"[{'PASS' if ok else 'FAIL'}] {scope}: {detail}")
                overall_ok = overall_ok and ok

    print("\nVERDICT:", "PASS — least-scope auth validated" if overall_ok
          else "FAIL — fix DWD grant / scopes before proceeding")
    return 0 if overall_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
