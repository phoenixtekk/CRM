#!/usr/bin/env python3
# ops_config_helper.py — safe operations helper backing the lifecycle runbooks (offboarding, group and
#                        Shared-Drive lifecycle); prints the exact API calls it WOULD make by default.
#
# PURPOSE: Operations/config helper for the runbook library. Standardizes routine lifecycle inputs and,
#          by DEFAULT (--dry-run), prints the exact Admin SDK actions it would take WITHOUT changing
#          anything. Write actions require an explicit --apply and an interactive confirmation.
# HOW TO RUN: python ops_config_helper.py offboard --user leaver@example.com            # dry-run (default)
#             python ops_config_helper.py offboard --user leaver@example.com --apply     # gated write
#             python ops_config_helper.py group-lifecycle --email team@example.com --action archive
#             (Python 3.10+, OAuth/ADC or DWD service account; see --help)
# EXPECTED RESULTS: dry-run prints a numbered checklist of the API calls that would run and exits 0
#                   without side effects. --apply performs them only after confirmation.
#
# SAFE-BY-DEFAULT: no write occurs unless --apply is passed AND the operator confirms. No keys are
# stored in this file; live writes (with --apply) need write scopes you grant deliberately, e.g.
#   https://www.googleapis.com/auth/admin.directory.user     (offboard: suspend/reset)
#   https://www.googleapis.com/auth/admin.directory.group    (group lifecycle)
# Requires (live): pip install google-api-python-client google-auth . Dry-run needs no libraries.

import argparse
import sys
from datetime import datetime, timezone


def offboard_plan(user):
    """The documented offboarding checklist as a list of (label, api_hint) steps."""
    return [
        ("Reset sign-in cookies / require re-auth", f"users.update {user} (changePasswordAtNextLogin/reset)"),
        ("Suspend the account", f"users.update {user} suspended=true"),
        ("Revoke OAuth tokens / app passwords", f"tokens.delete for {user} (all clientIds)"),
        ("Sign out all sessions", f"users.signOut {user}"),
        ("Transfer Drive/data ownership", "Data Transfer API: create transfer to the manager/successor"),
        ("Remove from admin roles (if any)", f"roleAssignments.delete for {user}"),
        ("Remove from groups", f"members.delete {user} from each group"),
        ("Move to a departed-users OU / hold if under legal hold", "users.update orgUnitPath=/Departed"),
    ]


def group_lifecycle_plan(email, action):
    if action == "archive":
        return [
            ("Set group access to restricted", f"groups settings: whoCanJoin/postMessage lockdown ({email})"),
            ("Remove external members", f"members.list/delete external members of {email}"),
            ("Tag group as archived", f"groups.update {email} name/description prefix 'ARCHIVED-'"),
        ]
    if action == "delete":
        return [("Delete the group (irreversible)", f"groups.delete {email}")]
    return [("(no-op) unknown action", action)]


def print_plan(title, steps, dry_run):
    stamp = datetime.now(timezone.utc).isoformat()
    mode = "DRY-RUN (no changes)" if dry_run else "APPLY (writes pending confirmation)"
    print(f"{title} — {mode} — {stamp}")
    for i, (label, hint) in enumerate(steps, 1):
        print(f"  {i:>2}. {label}")
        print(f"        would call: {hint}")
    print(f"  ({len(steps)} step(s))")


def apply_steps(steps):
    """Placeholder for real writes. Deliberately not wired to a live tenant in this reference so the
    tool cannot cause accidental changes. Wire each step to its Admin SDK call for your environment,
    keeping the confirmation gate below."""
    print("[apply] Live write execution is intentionally not wired in this reference tool.")
    print("[apply] Implement each step against the Admin SDK for your tenant, preserving the")
    print("[apply] --apply + confirmation gate. No changes were made.")
    return 0


def main():
    ap = argparse.ArgumentParser(description="Safe-by-default operations helper for lifecycle runbooks.")
    sub = ap.add_subparsers(dest="command", required=True)

    off = sub.add_parser("offboard", help="Print/execute the user offboarding checklist.")
    off.add_argument("--user", required=True, help="Primary email of the departing user.")

    grp = sub.add_parser("group-lifecycle", help="Archive/delete a group.")
    grp.add_argument("--email", required=True, help="Group email address.")
    grp.add_argument("--action", choices=["archive", "delete"], required=True)

    for p in (off, grp):
        p.add_argument("--apply", action="store_true",
                       help="Actually perform the actions (requires confirmation). Default is dry-run.")

    args = ap.parse_args()
    dry_run = not getattr(args, "apply", False)

    if args.command == "offboard":
        steps = offboard_plan(args.user)
        title = f"Runbook - User Offboarding - Production :: {args.user}"
    elif args.command == "group-lifecycle":
        steps = group_lifecycle_plan(args.email, args.action)
        title = f"Runbook - Group Lifecycle - Production :: {args.email} [{args.action}]"
    else:  # pragma: no cover
        ap.error("unknown command")
        return 2

    print_plan(title, steps, dry_run)

    if dry_run:
        print("Dry-run complete — no changes made. Re-run with --apply to execute.")
        return 0

    confirm = input("Type EXACTLY 'APPLY' to perform these writes: ").strip()
    if confirm != "APPLY":
        print("Not confirmed — aborting without changes.")
        return 1
    return apply_steps(steps)


if __name__ == "__main__":
    sys.exit(main())
