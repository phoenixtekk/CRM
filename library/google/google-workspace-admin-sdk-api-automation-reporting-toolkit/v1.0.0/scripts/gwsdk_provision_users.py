#!/usr/bin/env python3
# gwsdk_provision_users.py — idempotent user/OU/license provisioning automation (dry-run by default)
#
# PURPOSE: Reconcile Directory users to a desired-state CSV (OU move, suspend/unsuspend, org attributes).
#          SAFE-BY-DEFAULT: computes and prints a plan; makes NO change unless --apply is passed.
#          Writes a reversible change log so a run can be reverted (--revert <log>).
# HOW TO RUN: python gwsdk_provision_users.py --subject provisioning-admin@corp.example \
#             --desired ./finance-ou.csv                 # dry-run plan (default, no changes)
#             ... add --apply to execute; ... --revert change-log.json to roll back
#             (Python 3.10+, ADC; read scope for plan, admin.directory.user only for --apply)
# EXPECTED RESULTS: A per-user plan (CREATE/UPDATE/MOVE/SUSPEND/NOOP). Re-running the plan on an
#                   already-reconciled tenant shows all NOOP (idempotent). Exit 0 on success.
#
# No secrets in code: credentials via ADC or --credentials path (never committed).
# pip install google-api-python-client google-auth

from __future__ import annotations

import argparse
import csv
import json
import os
import sys
import time
from datetime import datetime, timezone

READ_SCOPE = "https://www.googleapis.com/auth/admin.directory.user.readonly"
WRITE_SCOPE = "https://www.googleapis.com/auth/admin.directory.user"
ARTIFACT = "Provisioning Run – Finance-OU – Pilot"

# Desired-state fields we reconcile. Keep this list minimal and reviewable.
MANAGED_FIELDS = ("orgUnitPath", "suspended", "givenName", "familyName")


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Idempotent user/OU provisioning (dry-run by default).")
    p.add_argument("--subject", required=True, help="Impersonation subject (provisioning admin) email.")
    p.add_argument("--desired", help="Desired-state CSV (primaryEmail, orgUnitPath, suspended, givenName, familyName).")
    p.add_argument("--revert", help="Path to a change log produced by a prior --apply run; reverse it.")
    p.add_argument("--apply", action="store_true", help="Execute changes. WITHOUT this flag, dry-run only.")
    p.add_argument("--out", default=".", help="Directory for the change log / plan artifacts.")
    p.add_argument("--credentials", default=None, help="Optional secured credential path. Omit for ADC.")
    p.add_argument("--max-retries", type=int, default=5, help="Retry cap for 429/5xx backoff.")
    return p.parse_args()


def build_service(subject: str, cred_path: str | None, need_write: bool):
    try:
        import google.auth
        from google.oauth2 import service_account
        from googleapiclient.discovery import build
    except ImportError:
        sys.exit("Run: pip install google-api-python-client google-auth")
    scopes = [WRITE_SCOPE] if need_write else [READ_SCOPE]
    if cred_path:
        creds = service_account.Credentials.from_service_account_file(cred_path, scopes=scopes)
        creds = creds.with_subject(subject)
    else:
        creds, _ = google.auth.default(scopes=scopes)
        if hasattr(creds, "with_subject"):
            creds = creds.with_subject(subject)
    return build("admin", "directory_v1", credentials=creds, cache_discovery=False)


def with_retry(request, max_retries: int):
    from googleapiclient.errors import HttpError
    attempt = 0
    while True:
        try:
            return request.execute()
        except HttpError as exc:
            status = getattr(exc.resp, "status", None)
            if status in (429, 500, 503) and attempt < max_retries:
                sleep = min(2 ** attempt, 30)
                print(f"  [retry] HTTP {status}; backing off {sleep}s", file=sys.stderr)
                time.sleep(sleep)
                attempt += 1
                continue
            raise


def read_desired(path: str) -> dict[str, dict]:
    desired: dict[str, dict] = {}
    with open(path, newline="", encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            email = (row.get("primaryEmail") or "").strip().lower()
            if not email:
                continue
            rec = {"primaryEmail": email}
            if row.get("orgUnitPath"):
                rec["orgUnitPath"] = row["orgUnitPath"].strip()
            if row.get("suspended") not in (None, ""):
                rec["suspended"] = str(row["suspended"]).strip().lower() in ("1", "true", "yes")
            if row.get("givenName"):
                rec["givenName"] = row["givenName"].strip()
            if row.get("familyName"):
                rec["familyName"] = row["familyName"].strip()
            desired[email] = rec
    return desired


def get_current(service, email: str, max_retries: int) -> dict | None:
    from googleapiclient.errors import HttpError
    try:
        return with_retry(service.users().get(userKey=email, projection="full"), max_retries)
    except HttpError as exc:
        if getattr(exc.resp, "status", None) == 404:
            return None
        raise


def diff_user(desired: dict, current: dict | None) -> tuple[str, dict, dict]:
    """Return (action, changes, prior_values). NOOP if already in desired state."""
    if current is None:
        return "CREATE", {k: v for k, v in desired.items() if k != "primaryEmail"}, {}
    changes: dict = {}
    prior: dict = {}
    for field in MANAGED_FIELDS:
        if field not in desired:
            continue
        cur_val = current.get("name", {}).get(field) if field in ("givenName", "familyName") else current.get(field)
        if cur_val != desired[field]:
            changes[field] = desired[field]
            prior[field] = cur_val
    if not changes:
        return "NOOP", {}, {}
    action = "MOVE" if "orgUnitPath" in changes and len(changes) == 1 else "UPDATE"
    return action, changes, prior


def build_body(changes: dict) -> dict:
    body: dict = {}
    name: dict = {}
    for k, v in changes.items():
        if k in ("givenName", "familyName"):
            name[k] = v
        else:
            body[k] = v
    if name:
        body["name"] = name
    return body


def apply_change(service, email: str, action: str, changes: dict, max_retries: int) -> None:
    if action == "CREATE":
        # Password intentionally not set here; org policy should drive account creation/onboarding.
        raise SystemExit(f"CREATE for {email}: refuse to invent a password. Create via your onboarding "
                         f"process, then let this tool reconcile OU/attributes.")
    with_retry(service.users().update(userKey=email, body=build_body(changes)), max_retries)


def plan_and_run(args) -> int:
    desired = read_desired(args.desired)
    read_service = build_service(args.subject, args.credentials, need_write=False)

    plan = []
    for email, want in sorted(desired.items()):
        current = get_current(read_service, email, args.max_retries)
        action, changes, prior = diff_user(want, current)
        plan.append({"email": email, "action": action, "changes": changes, "prior": prior})

    counts: dict[str, int] = {}
    for item in plan:
        counts[item["action"]] = counts.get(item["action"], 0) + 1
        if item["action"] != "NOOP":
            print(f"  {item['action']:7} {item['email']}: {item['changes']}")
    print(f"\nPlan for '{ARTIFACT}': " + ", ".join(f"{k}={v}" for k, v in sorted(counts.items())))

    if not args.apply:
        print("DRY-RUN — no changes made. Re-run with --apply (change-controlled) to execute.")
        return 0

    write_service = build_service(args.subject, args.credentials, need_write=True)
    change_log = []
    for item in plan:
        if item["action"] == "NOOP":
            continue
        apply_change(write_service, item["email"], item["action"], item["changes"], args.max_retries)
        change_log.append(item)
        print(f"  applied {item['action']} {item['email']}")

    os.makedirs(args.out, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    log_path = os.path.join(args.out, f"provisioning-run-finance-ou-pilot-{stamp}.json")
    with open(log_path, "w", encoding="utf-8") as fh:
        json.dump({"artifact": ARTIFACT, "applied": stamp, "changes": change_log}, fh, indent=2)
    print(f"\nAPPLIED. Reversible change log: {log_path}")
    print("To roll back: python gwsdk_provision_users.py --subject <s> --revert " + log_path + "  (dry-run, then --apply)")
    return 0


def revert(args) -> int:
    with open(args.revert, encoding="utf-8") as fh:
        log = json.load(fh)
    items = [i for i in log.get("changes", []) if i["action"] in ("UPDATE", "MOVE") and i.get("prior")]
    for item in items:
        print(f"  REVERT {item['email']}: restore {item['prior']}")
    print(f"\nRevert plan: {len(items)} user(s).")
    if not args.apply:
        print("DRY-RUN — no changes made. Add --apply to execute the revert.")
        return 0
    write_service = build_service(args.subject, args.credentials, need_write=True)
    from googleapiclient.errors import HttpError  # noqa: F401 (surface errors)
    for item in items:
        apply_change(write_service, item["email"], "UPDATE", item["prior"], args.max_retries)
        print(f"  reverted {item['email']}")
    print("Revert applied.")
    return 0


def main() -> int:
    args = parse_args()
    if args.revert:
        return revert(args)
    if not args.desired:
        sys.exit("Provide --desired <csv> (or --revert <log>).")
    print(f"# {ARTIFACT} — {'APPLY' if args.apply else 'DRY-RUN'} — subject {args.subject}")
    return plan_and_run(args)


if __name__ == "__main__":
    raise SystemExit(main())
