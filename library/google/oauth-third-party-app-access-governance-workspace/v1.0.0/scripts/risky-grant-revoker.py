#!/usr/bin/env python3
# risky-grant-revoker.py — revoke high-risk standing OAuth grants (Token Revocation runbook)
#
# PURPOSE: Policy/guardrail — token revocation, DRY-RUN by default, WRITE gated behind --apply. From
#          the inventory, targets HIGH-risk (or vetted-Blocked) standing (user, app) grants and, only
#          with --apply, revokes them via the Directory API tokens.delete, writing an evidence log.
#          Executes "Token Revocation - Risky-Grants - Runbook". SAFE BY DEFAULT: lists what it would
#          revoke and changes nothing unless --apply is passed.
# HOW TO RUN: python risky-grant-revoker.py --inventory app-inventory.json [--risk HIGH]
#             [--blocked blocked-client-ids.txt] [--dry-run|--apply] [--evidence revocation-log.json]
#             (Python 3.10+, gcloud ADC or delegated SA with admin.directory.user.security; --help)
# EXPECTED RESULTS: Dry-run prints the exact (user, app) grants that WOULD be revoked and makes no
#                   change. With --apply it revokes each and writes an evidence log; re-inventory then
#                   no longer shows those grants. Revocation forces re-consent and is irreversible —
#                   run dry-run and obtain approver sign-off first.
#
# NOTE: tokens.delete requires the (userKey, clientId) grant to exist for that user. The inventory
# from oauth-app-inventory.py records the users per app so targeting is precise. NO keys in code.

import argparse
import json
import sys

WRITE_SCOPES = ["https://www.googleapis.com/auth/admin.directory.user.security"]


def build_directory():
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        sys.exit("ERROR: pip install google-api-python-client google-auth")
    creds, _ = google.auth.default(scopes=WRITE_SCOPES)
    return build("admin", "directory_v1", credentials=creds, cache_discovery=False)


def load_inventory(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh).get("apps", [])


def load_blocklist(path):
    if not path:
        return set()
    with open(path, encoding="utf-8") as fh:
        return {ln.strip() for ln in fh if ln.strip() and not ln.startswith("#")}


def targets(apps, risk, blocked_ids):
    """An app is targeted if its risk >= threshold OR it is on the vetted-Blocked list."""
    order = {"HIGH": 3, "MEDIUM": 2, "LOW": 1, "UNKNOWN": 2}
    threshold = order.get(risk, 3)
    out = []
    for a in apps:
        if order.get(a.get("risk", "UNKNOWN"), 0) >= threshold or a["client_id"] in blocked_ids:
            out.append(a)
    return out


def main():
    ap = argparse.ArgumentParser(description="Revoke high-risk standing OAuth grants (gated).")
    ap.add_argument("--inventory", required=True, help="app-inventory.json (must include per-app users).")
    ap.add_argument("--risk", default="HIGH", choices=["HIGH", "MEDIUM"], help="Minimum risk to target.")
    ap.add_argument("--blocked", help="Optional file of vetted-Blocked client_ids (one per line).")
    grp = ap.add_mutually_exclusive_group()
    grp.add_argument("--dry-run", action="store_true", help="Preview only (default).")
    grp.add_argument("--apply", action="store_true", help="Actually revoke (requires approver sign-off).")
    ap.add_argument("--evidence", default="revocation-log.json")
    args = ap.parse_args()

    apply = args.apply and not args.dry_run
    apps = load_inventory(args.inventory)
    blocked_ids = load_blocklist(args.blocked)
    tgt = targets(apps, args.risk, blocked_ids)

    grants = []
    for a in tgt:
        for user in a.get("users", []):  # inventory may store per-app user list
            grants.append({"user": user, "client_id": a["client_id"],
                           "display": a.get("display", ""), "risk": a.get("risk")})

    print(f"Revocation plan  (min-risk={args.risk}, mode={'APPLY' if apply else 'DRY-RUN'})")
    print(f"  {len(tgt)} app(s), {len(grants)} (user, app) grant(s) targeted\n")
    for g in tgt:
        print(f"  {g.get('risk'):<7} {g.get('display') or g['client_id']}  "
              f"({len(g.get('users', []))} user grants)")

    if not grants:
        print("\nNothing to revoke.")
        return
    if not apply:
        print("\nDRY-RUN: no tokens revoked. Revocation forces re-consent and is irreversible — "
              "obtain approver sign-off, then re-run with --apply.")
        return

    directory = build_directory()
    results = []
    for g in grants:
        try:
            directory.tokens().delete(userKey=g["user"], clientId=g["client_id"]).execute()
            g["status"] = "revoked"
        except Exception as exc:  # noqa: BLE001
            g["status"] = f"error: {exc}"
        results.append(g)
        print(f"  {g['status']:<10} {g['user']} -> {g.get('display') or g['client_id']}")

    with open(args.evidence, "w", encoding="utf-8") as fh:
        json.dump({"runbook": "Token Revocation - Risky-Grants - Runbook", "results": results}, fh, indent=2)
    ok = sum(1 for r in results if r["status"] == "revoked")
    print(f"\nRevoked {ok}/{len(results)} grants. Evidence log: {args.evidence}")
    print("Communicate to affected users — legitimate apps will require re-consent.")


if __name__ == "__main__":
    main()
