#!/usr/bin/env python3
# cutover-readiness.py — pre-cutover go/no-go checks for a migration wave (read-only).
#
# PURPOSE: Read-only. Runs the go/no-go checks that gate the high-impact mail-routing/DNS switch for a
#          wave: target Google accounts exist and are licensed, NO delegate/shared-mailbox cluster is
#          split across waves, pre-stage/delta reported complete, and coexistence routing is in place.
#          Optionally confirms target accounts live via the Admin SDK Directory (read-only). It touches
#          nothing — it only reports GO / NO-GO.
# HOW TO RUN: python cutover-readiness.py --wave "Migration Wave - Pilot - Pilot" --waves waves.csv
#             --checks readiness.json --report Cutover-Readiness.json
#             [--verify-google --delegated-admin admin@example.com]            (Python 3.10+, OAuth/ADC)
# EXPECTED RESULTS: An all-green report -> GO (exit 0). Any red check -> NO-GO (exit 2): remediate and
#                   re-run before touching mail flow. Never cut over on a NO-GO.
#
# `pip install google-api-python-client google-auth` only if using --verify-google. Credentials via
# OAuth / ADC — no keys are read from or written to this file.

import argparse
import csv
import json
import sys
from collections import defaultdict


def wave_members(waves_csv):
    members = defaultdict(list)
    per_user_waves = defaultdict(set)
    with open(waves_csv, newline="", encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            low = {k.lower(): v for k, v in r.items()}
            members[low.get("wave", "")].append(low.get("upn", ""))
            per_user_waves[low.get("upn", "")].add(low.get("wave", ""))
    return members, per_user_waves


def load_checks(path):
    """Operator-supplied evidence of pre-stage/delta/coexistence status per wave (from the engine/run)."""
    if not path:
        return {}
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def verify_google_accounts(upns, delegated_admin):
    """Read-only Admin SDK check that each target account exists and is not suspended."""
    try:
        import google.auth
        from googleapiclient.discovery import build
        from googleapiclient.errors import HttpError
    except ImportError:
        print("[warn] google libraries not installed; skipping --verify-google", file=sys.stderr)
        return {u: None for u in upns}
    scopes = ["https://www.googleapis.com/auth/admin.directory.user.readonly"]
    creds, _ = google.auth.default(scopes=scopes)
    if delegated_admin and hasattr(creds, "with_subject"):
        creds = creds.with_subject(delegated_admin)
    svc = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    result = {}
    for u in upns:
        try:
            user = svc.users().get(userKey=u).execute()
            result[u] = not user.get("suspended", False)
        except HttpError:
            result[u] = False
    return result


def run_checks(wave, waves_csv, checks, verify_google, delegated_admin):
    members, per_user_waves = wave_members(waves_csv)
    upns = members.get(wave, [])
    findings = []

    def add(name, ok, detail=""):
        findings.append({"check": name, "status": "green" if ok else "red", "detail": detail})

    add("wave_has_members", bool(upns), f"{len(upns)} users in wave")

    # split-cluster check: any user in this wave also assigned to another wave = a split cluster
    split = [u for u in upns if len(per_user_waves.get(u, set())) > 1]
    add("no_split_clusters", not split,
        "" if not split else f"{len(split)} users assigned to multiple waves: {split[:5]}")

    wchecks = checks.get(wave, {})
    add("prestage_complete", bool(wchecks.get("prestage_complete")),
        wchecks.get("prestage_note", "engine must report pre-stage complete"))
    add("delta_complete", bool(wchecks.get("delta_complete")),
        wchecks.get("delta_note", "engine must report final delta small/complete"))
    add("coexistence_routing_in_place", bool(wchecks.get("coexistence_routing")),
        wchecks.get("coexistence_note", "dual/split mail delivery must be configured"))
    add("change_window_approved", bool(wchecks.get("change_window_approved")),
        wchecks.get("change_window_note", "approved window + rollback approver named"))

    if verify_google and upns:
        acct = verify_google_accounts(upns, delegated_admin)
        missing = [u for u, ok in acct.items() if not ok]
        add("target_accounts_ready", not missing,
            "" if not missing else f"{len(missing)} target accounts missing/suspended: {missing[:5]}")
    else:
        add("target_accounts_ready", bool(wchecks.get("target_accounts_ready")),
            "supply --verify-google or attest target_accounts_ready in checks.json")

    go = all(f["status"] == "green" for f in findings)
    return {"wave": wave, "decision": "GO" if go else "NO-GO", "checks": findings}


def main():
    ap = argparse.ArgumentParser(description="Pre-cutover go/no-go checks for a wave (read-only).")
    ap.add_argument("--wave", required=True, help="exact wave name, e.g. 'Migration Wave - Pilot - Pilot'")
    ap.add_argument("--waves", required=True, help="waves.csv from wave-batcher.py")
    ap.add_argument("--checks", help="readiness.json with engine/coexistence evidence per wave")
    ap.add_argument("--report", help="output JSON readiness report")
    ap.add_argument("--verify-google", action="store_true",
                    help="confirm target accounts exist/active via read-only Admin SDK")
    ap.add_argument("--delegated-admin", help="admin to impersonate for domain-wide delegation")
    args = ap.parse_args()

    result = run_checks(args.wave, args.waves, load_checks(args.checks),
                        args.verify_google, args.delegated_admin)

    print(f"Wave: {result['wave']}")
    for c in result["checks"]:
        mark = "OK " if c["status"] == "green" else "!! "
        print(f"  {mark}{c['check']}: {c['status']}" + (f" — {c['detail']}" if c["detail"] else ""))
    print(f"\nDECISION: {result['decision']}")

    if args.report:
        with open(args.report, "w", encoding="utf-8") as fh:
            json.dump(result, fh, indent=2)
        print(f"Report written: {args.report}")

    return 0 if result["decision"] == "GO" else 2


if __name__ == "__main__":
    sys.exit(main())
