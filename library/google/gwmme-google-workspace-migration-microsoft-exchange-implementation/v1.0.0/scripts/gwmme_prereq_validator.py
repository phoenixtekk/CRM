#!/usr/bin/env python3
# gwmme_prereq_validator.py — validate GWMME prerequisites before installing/running the tool
#
# PURPOSE: Read-only readiness check for a GWMME migration. Verifies host reachability to the source
#          Exchange/EWS endpoint and to Google endpoints, that the Google destination service identity
#          can authenticate (Directory API), and that the master mapping is well-formed. Read-only:
#          performs no migration and changes nothing.
# HOW TO RUN: python gwmme_prereq_validator.py --ews-host mail.example.com \
#                 --mapping Mapping-Users-Master.csv --domain example.com
#             (Python 3.10+, OAuth/ADC; see --help. pip install google-api-python-client google-auth)
# EXPECTED RESULTS: A checklist of PASS/FAIL lines. Any FAIL means resolve (Requirements/Troubleshooting)
#                   before installing GWMME or running any wave. Exit code 0 only if all checks pass.

import argparse
import csv
import socket
import sys
import urllib.request

SCOPES = ["https://www.googleapis.com/auth/admin.directory.user.readonly"]
GOOGLE_ENDPOINTS = ["https://admin.googleapis.com", "https://www.googleapis.com"]


def check(name, ok, detail=""):
    print(f"[{'PASS' if ok else 'FAIL'}] {name}" + (f" — {detail}" if detail else ""))
    return ok


def tcp_reachable(host, port, timeout=6):
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True, f"{host}:{port} reachable"
    except OSError as exc:
        return False, f"{host}:{port} unreachable ({exc})"


def https_reachable(url, timeout=8):
    try:
        req = urllib.request.Request(url, method="HEAD")
        with urllib.request.urlopen(req, timeout=timeout) as resp:  # noqa: S310 - fixed Google hosts
            return True, f"HTTP {resp.status}"
    except Exception as exc:  # noqa: BLE001
        # A TLS/HTTP response (even 4xx) still proves reachability; only connection errors fail.
        msg = str(exc)
        if any(code in msg for code in ("403", "404", "401", "405")):
            return True, f"reachable ({msg})"
        return False, msg


def validate_mapping(path, domain):
    required = {"source_smtp", "target_google_email"}
    seen_src, seen_tgt, problems = set(), set(), []
    try:
        with open(path, newline="", encoding="utf-8-sig") as f:
            reader = csv.DictReader(f)
            have = {c.lower().strip() for c in (reader.fieldnames or [])}
            missing = required - have
            if missing:
                return False, f"missing columns: {', '.join(sorted(missing))}", 0
            n = 0
            for i, r in enumerate(reader, start=2):
                n += 1
                src = (r.get("source_smtp") or "").strip().lower()
                tgt = (r.get("target_google_email") or "").strip().lower()
                if not src or not tgt:
                    problems.append(f"row {i}: blank source/target")
                    continue
                if src in seen_src:
                    problems.append(f"row {i}: duplicate source {src}")
                if tgt in seen_tgt:
                    problems.append(f"row {i}: duplicate target {tgt}")
                if domain and not tgt.endswith("@" + domain):
                    problems.append(f"row {i}: target {tgt} not in @{domain}")
                seen_src.add(src)
                seen_tgt.add(tgt)
    except FileNotFoundError:
        return False, "mapping file not found", 0
    if problems:
        return False, "; ".join(problems[:8]) + (" …" if len(problems) > 8 else ""), n
    return True, f"{n} rows, 1:1 source->target", n


def check_google_auth(domain):
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        return False, "google-api-python-client/google-auth not installed"
    try:
        creds, _ = google.auth.default(scopes=SCOPES)
        service = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
        service.users().list(domain=domain, maxResults=1).execute()
        return True, "Directory API reachable with current credentials"
    except Exception as exc:  # noqa: BLE001
        return False, f"auth/API failed ({exc})"


def main():
    ap = argparse.ArgumentParser(description="Validate GWMME prerequisites (read-only).")
    ap.add_argument("--ews-host", required=True,
                    help="Source Exchange/EWS hostname (e.g. outlook.office365.com or on-prem host).")
    ap.add_argument("--ews-port", type=int, default=443, help="Source EWS port (default 443).")
    ap.add_argument("--mapping", required=True, help="Path to Mapping-Users-Master.csv.")
    ap.add_argument("--domain", required=True, help="Target Google Workspace domain.")
    ap.add_argument("--skip-google-auth", action="store_true",
                    help="Skip the live Google auth check (offline validation).")
    args = ap.parse_args()

    results = []
    ok, detail = tcp_reachable(args.ews_host, args.ews_port)
    results.append(check("Source EWS endpoint reachable", ok, detail))

    for url in GOOGLE_ENDPOINTS:
        ok, detail = https_reachable(url)
        results.append(check(f"Google endpoint {url}", ok, detail))

    ok, detail, _ = validate_mapping(args.mapping, args.domain)
    results.append(check("Mapping – Users – Master well-formed", ok, detail))

    if args.skip_google_auth:
        print("[SKIP] Google service identity auth (--skip-google-auth)")
    else:
        ok, detail = check_google_auth(args.domain)
        results.append(check("Service Identity – Google – Migration authorized", ok, detail))

    print("-" * 60)
    if all(results):
        print("RESULT: PASS — all prerequisites green. Safe to install/configure GWMME.")
        sys.exit(0)
    print("RESULT: FAIL — resolve the failed checks before running any migration wave.")
    sys.exit(1)


if __name__ == "__main__":
    main()
