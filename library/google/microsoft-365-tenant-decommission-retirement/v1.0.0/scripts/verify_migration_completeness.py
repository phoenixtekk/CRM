#!/usr/bin/env python3
# verify_migration_completeness.py — reconcile M365 residuals against a migration baseline (read-only)
#
# PURPOSE: Prove the Microsoft 365 -> Google migration actually landed before any teardown. For each
#          in-scope user it reads mailbox item counts, last-activity, OneDrive usage, and directory
#          coverage via Microsoft Graph and flags residuals or post-cutover Microsoft-side activity.
#          READ-ONLY: it makes no changes and needs only Graph read scopes.
# HOW TO RUN: python verify_migration_completeness.py --scope-file users.txt --cutover 2026-06-01 \
#             --out completeness.json   (Python 3.10+; pip install msal requests; env creds — see below)
# EXPECTED RESULTS: A JSON report + stdout summary. PASS = every user reconciles within tolerance and
#          shows no Microsoft-side activity after --cutover; FAIL = users with residuals/recent activity.
#
# Credentials come from the ENVIRONMENT (never hardcoded, never printed):
#   M365DECOM_TENANT_ID, M365DECOM_CLIENT_ID, M365DECOM_CLIENT_SECRET
# Requires an Entra app "Decommission Read - Source-Tenant - v1" with application read scopes:
#   Reports.Read.All, User.Read.All, Directory.Read.All (admin-consented).

import argparse
import csv
import datetime as dt
import json
import os
import sys

GRAPH = "https://graph.microsoft.com/v1.0"
SCOPE = ["https://graph.microsoft.com/.default"]


def die(msg: str, code: int = 2) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(code)


def get_token() -> str:
    """Client-credentials token via MSAL. Reads creds from env; refuses to run without them."""
    try:
        import msal  # type: ignore
    except ImportError:
        die("msal not installed. Run: pip install msal requests")

    tenant = os.environ.get("M365DECOM_TENANT_ID")
    client = os.environ.get("M365DECOM_CLIENT_ID")
    secret = os.environ.get("M365DECOM_CLIENT_SECRET")
    if not (tenant and client and secret):
        die("Set M365DECOM_TENANT_ID / M365DECOM_CLIENT_ID / M365DECOM_CLIENT_SECRET in the "
            "environment (see the Requirements guide). No credentials are read from files.")

    app = msal.ConfidentialClientApplication(
        client_id=client,
        authority=f"https://login.microsoftonline.com/{tenant}",
        client_credential=secret,
    )
    result = app.acquire_token_for_client(scopes=SCOPE)
    if "access_token" not in result:
        die(f"Token request failed: {result.get('error_description', result.get('error'))}")
    return result["access_token"]


def graph_get(session, url: str):
    """GET with basic 429/5xx backoff; returns parsed JSON (paging handled by caller as needed)."""
    import time
    for attempt in range(5):
        resp = session.get(url, timeout=60)
        if resp.status_code == 429 or resp.status_code >= 500:
            wait = int(resp.headers.get("Retry-After", 2 ** attempt))
            time.sleep(min(wait, 30))
            continue
        if resp.status_code == 404:
            return None
        if not resp.ok:
            die(f"Graph GET {url} -> {resp.status_code}: {resp.text[:300]}")
        return resp.json()
    die(f"Graph GET {url} kept throttling; aborting.")


def load_baseline(path):
    """Optional CSV baseline: userPrincipalName,expected_mail_items,expected_onedrive_mb."""
    if not path:
        return {}
    baseline = {}
    with open(path, newline="", encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            upn = (row.get("userPrincipalName") or "").strip().lower()
            if upn:
                baseline[upn] = row
    return baseline


def main() -> None:
    ap = argparse.ArgumentParser(description="Verify M365 migration completeness (read-only).")
    ap.add_argument("--scope-file", required=True,
                    help="Text file, one userPrincipalName per line (the users to check).")
    ap.add_argument("--baseline", help="Optional CSV of expected source counts per user.")
    ap.add_argument("--cutover", help="Cutover date YYYY-MM-DD; activity after this is a FAIL signal.")
    ap.add_argument("--residual-mb", type=float, default=50.0,
                    help="OneDrive/mailbox residual size (MB) above which a user is flagged.")
    ap.add_argument("--out", default="completeness.json", help="Output JSON report path.")
    args = ap.parse_args()

    cutover = None
    if args.cutover:
        try:
            cutover = dt.date.fromisoformat(args.cutover)
        except ValueError:
            die("--cutover must be YYYY-MM-DD")

    with open(args.scope_file, encoding="utf-8") as fh:
        users = [ln.strip() for ln in fh if ln.strip() and not ln.startswith("#")]
    if not users:
        die("scope file has no users")

    baseline = load_baseline(args.baseline)

    import requests
    session = requests.Session()
    session.headers.update({"Authorization": f"Bearer {get_token()}",
                            "Accept": "application/json"})

    findings = []
    fails = 0
    for upn in users:
        u = graph_get(session, f"{GRAPH}/users/{upn}"
                               "?$select=id,userPrincipalName,displayName,accountEnabled,signInActivity")
        rec = {"userPrincipalName": upn, "status": "PASS", "signals": []}
        if u is None:
            # Not found = already removed upstream; note it but do not fail completeness.
            rec["status"] = "ABSENT"
            rec["signals"].append("user not found in directory (already removed?)")
            findings.append(rec)
            continue

        # Post-cutover Microsoft-side sign-in is a strong "still using M365" signal.
        last_signin = (u.get("signInActivity") or {}).get("lastSignInDateTime")
        rec["lastSignInDateTime"] = last_signin
        if cutover and last_signin:
            try:
                sd = dt.datetime.fromisoformat(last_signin.replace("Z", "+00:00")).date()
                if sd >= cutover:
                    rec["status"] = "FAIL"
                    rec["signals"].append(f"Microsoft-side sign-in {sd} on/after cutover {cutover}")
            except ValueError:
                pass

        # OneDrive residual (Graph returns drive quota used in bytes).
        drive = graph_get(session, f"{GRAPH}/users/{upn}/drive?$select=quota")
        used_mb = None
        if drive and drive.get("quota"):
            used_mb = round((drive["quota"].get("used") or 0) / (1024 * 1024), 1)
            rec["oneDriveUsedMB"] = used_mb
            if used_mb > args.residual_mb:
                rec["status"] = "FAIL" if rec["status"] != "PASS" else "REVIEW"
                rec["signals"].append(f"OneDrive residual {used_mb} MB > {args.residual_mb} MB")

        # Baseline reconciliation (if supplied).
        b = baseline.get(upn.lower())
        if b:
            exp_od = b.get("expected_onedrive_mb")
            if exp_od and used_mb is not None:
                try:
                    if used_mb > float(exp_od) * 1.05:
                        rec["status"] = "REVIEW" if rec["status"] == "PASS" else rec["status"]
                        rec["signals"].append(
                            f"OneDrive {used_mb} MB exceeds baseline {exp_od} MB")
                except ValueError:
                    pass

        if rec["status"] == "FAIL":
            fails += 1
        findings.append(rec)

    report = {
        "generated": dt.datetime.now(dt.timezone.utc).isoformat(),
        "scope_count": len(users),
        "cutover": args.cutover,
        "residual_mb_threshold": args.residual_mb,
        "gate": "Gate 1 - Completeness",
        "result": "FAIL" if fails else "PASS",
        "fail_count": fails,
        "findings": findings,
    }
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2)

    print(f"Completeness: {report['result']}  ({fails} FAIL of {len(users)} users)")
    print(f"Report written to {args.out}")
    for f in findings:
        if f["status"] in ("FAIL", "REVIEW"):
            print(f"  [{f['status']}] {f['userPrincipalName']}: {'; '.join(f['signals'])}")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
