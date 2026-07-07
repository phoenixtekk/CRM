#!/usr/bin/env python3
# meet_chat_settings_config_helper.py — plan/apply Meet & Chat policy to an OU or group (dry-run default).
#
# PURPOSE: Turn a reviewed design.json (target Meet/Chat controls per scope) into an ordered,
#          named change plan and, only with --apply, execute the changes it CAN make via the Admin
#          SDK (e.g. group membership for scoping groups). Console-only controls are emitted as an
#          operator run-book, never faked. SAFE BY DEFAULT: --dry-run prints the plan and changes
#          nothing; --apply is required to write and is gated per change.
# HOW TO RUN: python meet_chat_settings_config_helper.py --config design.json --scope ou:/Sales --dry-run
#             then, under change control: ... --scope ou:/Sales --apply
#             (Python 3.10+, OAuth/ADC; see --help). pip install google-api-python-client google-auth
# EXPECTED RESULTS: dry-run prints the named change plan + console run-book and exits 0 with no
#          tenant change; --apply performs only the API-supported changes and logs each one.

import argparse
import json
import sys
from datetime import datetime, timezone

# Only membership writes are performed by this tool; console-only policy is never auto-applied.
WRITE_SCOPES = ["https://www.googleapis.com/auth/admin.directory.group.member"]

# Controls that must be set in the Admin console UI (no writable API). Emitted as a run-book.
CONSOLE_CONTROLS = {
    "meet_safety": "Apps > Google Chat/Meet > Meet > Safety settings: host mgmt, who-can-join, warn-external.",
    "meet_recording": "Meet > Video settings: enable recording for scope; restrict recorders; storage -> Shared Drive.",
    "meet_external": "Meet > Safety: external participant access posture for this scope.",
    "chat_external": "Chat > External chat: blocked/allowlist-only + allowlisted domains for this scope.",
    "chat_history": "Chat > Chat history: default on/off + user-changeable for this scope.",
    "chat_space_creation": "Chat: who can create spaces / space-type restrictions for this scope.",
    "chat_file_sharing": "Chat: file-sharing policy inside Chat for this scope.",
    "chat_app_allowlist": "Chat > Apps: restrict install to allowlist; add approved bots.",
    "vault_retention": "Vault > Retention > Chat: create/scope the retention rule (real period).",
}


def build_directory(subject=None):
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        print("Missing deps. Run: pip install google-api-python-client google-auth", file=sys.stderr)
        raise
    creds, _ = google.auth.default(scopes=WRITE_SCOPES)
    if subject and hasattr(creds, "with_subject"):
        creds = creds.with_subject(subject)
    return build("admin", "directory_v1", credentials=creds, cache_discovery=False)


def load_config(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def plan_for_scope(config, scope):
    """Build a named, ordered change plan for one scope from the reviewed design."""
    scoped = config.get("scopes", {}).get(scope, {})
    if not scoped:
        return None
    plan = []
    # API-applicable: ensure scoping-group memberships (e.g. approved recorders, partners).
    for grp in scoped.get("group_memberships", []):
        plan.append({
            "kind": "api",
            "name": grp.get("artifact", f"Group Membership - {grp.get('group')} - Enforce"),
            "action": "add_members",
            "group": grp["group"],
            "members": grp.get("members", []),
        })
    # Console-only: emit as run-book steps in the design's declared order.
    for control in scoped.get("console_controls", []):
        key = control if isinstance(control, str) else control.get("key")
        desc = CONSOLE_CONTROLS.get(key, f"(unknown control: {key})")
        plan.append({
            "kind": "console",
            "name": (control.get("artifact") if isinstance(control, dict)
                     else f"{key} - {scope} - Configure"),
            "action": "operator_set",
            "instruction": desc,
            "target": (control.get("value") if isinstance(control, dict) else None),
        })
    return plan


def apply_api_step(directory, step, dry_run):
    added = []
    for member in step["members"]:
        if dry_run:
            added.append((member, "PLANNED"))
            continue
        try:
            directory.members().insert(
                groupKey=step["group"], body={"email": member, "role": "MEMBER"}
            ).execute()
            added.append((member, "ADDED"))
        except Exception as exc:  # noqa: BLE001 - already-a-member etc. is non-fatal, keep going
            added.append((member, f"SKIPPED ({exc})"))
    return added


def main():
    ap = argparse.ArgumentParser(description="Plan/apply Meet & Chat policy to a scope (dry-run default).")
    ap.add_argument("--config", required=True, help="Reviewed design.json.")
    ap.add_argument("--scope", required=True, help="Scope key, e.g. ou:/Sales or group:partners@...")
    ap.add_argument("--subject", help="Admin to impersonate (domain-wide delegation).")
    group = ap.add_mutually_exclusive_group()
    group.add_argument("--dry-run", action="store_true", default=True, help="Plan only (default).")
    group.add_argument("--apply", action="store_true", help="Execute API-supported changes.")
    args = ap.parse_args()
    dry_run = not args.apply

    config = load_config(args.config)
    plan = plan_for_scope(config, args.scope)
    if plan is None:
        print(f"No design entry for scope '{args.scope}' in {args.config}.", file=sys.stderr)
        return 2

    mode = "DRY-RUN (no changes)" if dry_run else "APPLY (writing API-supported changes)"
    print(f"=== Meet/Chat config helper — scope {args.scope} — {mode} ===")
    print(f"Generated: {datetime.now(timezone.utc).isoformat()}\n")

    directory = None
    if not dry_run:
        directory = build_directory(args.subject)

    api_steps = [s for s in plan if s["kind"] == "api"]
    console_steps = [s for s in plan if s["kind"] == "console"]

    print("API-applicable changes:")
    if not api_steps:
        print("  (none)")
    for step in api_steps:
        print(f"  * {step['name']} -> add members to {step['group']}")
        for member, status in apply_api_step(directory, step, dry_run):
            print(f"      - {member}: {status}")

    print("\nConsole run-book (set manually in the Admin console — never auto-applied):")
    if not console_steps:
        print("  (none)")
    for i, step in enumerate(console_steps, 1):
        tgt = f"  target={step['target']}" if step.get("target") is not None else ""
        print(f"  {i}. {step['name']}\n     {step['instruction']}{tgt}")

    print("\nDone." if not dry_run else "\nDry-run complete. Re-run with --apply under change control.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
