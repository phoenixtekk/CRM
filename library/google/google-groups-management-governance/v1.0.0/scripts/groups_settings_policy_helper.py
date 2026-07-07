#!/usr/bin/env python3
# groups_settings_policy_helper.py — Groups settings/ownership config helper + baseline check (dry-run default)
#
# PURPOSE: The one write-capable tool. Applies a group's per-type Groups settings + ownership to the
#          policy (Steps 3.2/3.5), and provides a read-only "check-baseline" mode for the org-wide
#          Admin baseline (Gate 2 / Test 2). SAFE-BY-DEFAULT: every write mode is DRY-RUN unless --apply
#          is passed; it prints a before/after diff and never touches anything it did not name.
# HOW TO RUN:
#   Baseline check (read-only):  python groups_settings_policy_helper.py check-baseline --domain corp.example
#   Apply type settings (dry):   python groups_settings_policy_helper.py apply-settings \
#                                    --group dl-finance-all@corp.example --type distribution --dry-run
#   Apply type settings (write): ... --apply
#   Set owner group (dry/apply): python groups_settings_policy_helper.py set-owner \
#                                    --group <g> --set-owner sec-groups-owners@corp.example [--apply]
#   (Python 3.10+, OAuth/ADC. Read modes use *.readonly scopes; --apply needs the WRITE scopes in
#    Requirement 2.6. `pip install google-api-python-client google-auth`. See --help.)
# EXPECTED RESULTS: a printed diff of the settings/ownership that WOULD change (dry-run) or DID change
#          (--apply); check-baseline prints OK/NON-COMPLIANT per item and exits 1 if any item fails.
#
# SAFETY: dry-run by default; no credentials/keys embedded (auth resolved at runtime); writes only the
#         explicit fields for the named group/type. Nothing is deleted.

import argparse
import json
import sys

RO = ["https://www.googleapis.com/auth/admin.directory.group.readonly",
      "https://www.googleapis.com/auth/admin.directory.group.member.readonly",
      "https://www.googleapis.com/auth/apps.groups.settings"]
RW = ["https://www.googleapis.com/auth/admin.directory.group",
      "https://www.googleapis.com/auth/admin.directory.group.member",
      "https://www.googleapis.com/auth/apps.groups.settings"]

# Per-type settings the helper writes (mirrors Step 1.1). Only these fields are ever touched.
TYPE_SETTINGS = {
    "distribution":  {"whoCanJoin": "INVITED_CAN_JOIN", "whoCanPostMessage": "ALL_IN_DOMAIN_CAN_POST",
                      "whoCanViewGroup": "ALL_IN_DOMAIN_CAN_VIEW",
                      "whoCanViewMembership": "ALL_MANAGERS_CAN_VIEW", "allowExternalMembers": "false"},
    "security":      {"whoCanJoin": "INVITED_CAN_JOIN", "whoCanPostMessage": "NONE_CAN_POST",
                      "whoCanViewGroup": "ALL_MANAGERS_CAN_VIEW",
                      "whoCanViewMembership": "ALL_MANAGERS_CAN_VIEW", "allowExternalMembers": "false"},
    "collaboration": {"whoCanJoin": "CAN_REQUEST_TO_JOIN", "whoCanPostMessage": "ALL_MEMBERS_CAN_POST",
                      "whoCanViewGroup": "ALL_MEMBERS_CAN_VIEW",
                      "whoCanViewMembership": "ALL_MEMBERS_CAN_VIEW", "allowExternalMembers": "false"},
    "external":      {"whoCanJoin": "INVITED_CAN_JOIN", "whoCanPostMessage": "ALL_MEMBERS_CAN_POST",
                      "whoCanViewGroup": "ALL_MEMBERS_CAN_VIEW",
                      "whoCanViewMembership": "ALL_MEMBERS_CAN_VIEW", "allowExternalMembers": "true"},
}


def build(scopes):
    try:
        import google.auth
        from googleapiclient.discovery import build as gbuild
    except ImportError:
        print("ERROR: pip install google-api-python-client google-auth", file=sys.stderr)
        sys.exit(2)
    creds, _ = google.auth.default(scopes=scopes)
    directory = gbuild("admin", "directory_v1", credentials=creds, cache_discovery=False)
    settings = gbuild("groupssettings", "v1", credentials=creds, cache_discovery=False)
    return directory, settings


def cmd_check_baseline(args):
    """Read-only org-wide Groups baseline check (Gate 2 / Test 2)."""
    directory, _ = build(RO)
    results, ok = [], True
    # Owner group must exist as a security group.
    try:
        g = directory.groups().get(groupKey=f"sec-groups-owners@{args.domain}").execute()
        results.append(("owner group sec-groups-owners exists", True, g.get("email")))
    except Exception:
        results.append(("owner group sec-groups-owners exists", False, "MISSING"))
        ok = False
    # NOTE: org-wide "who can create groups" / "default access" / inbound external-posting live in
    # Admin-console sharing settings and the Groups-for-Business service config; the Directory API does
    # not expose them uniformly across tenants. This check verifies the API-visible pieces and PROMPTS
    # the operator to confirm the console values recorded in Step 0.2 — verify in your tenant.
    console_items = ["who-can-create-groups = admins/allow-listed",
                     "default access = restricted/internal",
                     "allow external members (org default) = OFF",
                     "inbound external posting = restricted"]
    print(f"Baseline check — domain={args.domain}\n")
    for label, good, detail in results:
        print(f"  [{'OK ' if good else 'FAIL'}] {label}  ({detail})")
    print("\n  Confirm these console settings match your Step 0.2 record (verify in your tenant):")
    for c in console_items:
        print(f"      · {c}")
    if args.json:
        print(json.dumps({"domain": args.domain, "api_checks": [
            {"item": l, "ok": g} for (l, g, _d) in results], "console_confirm": console_items}, indent=2))
    return 0 if ok else 1


def diff_settings(current, desired):
    return {k: (current.get(k), v) for k, v in desired.items() if current.get(k) != v}


def cmd_apply_settings(args):
    apply = args.apply
    directory, settings = build(RW if apply else RO)
    desired = TYPE_SETTINGS.get(args.type)
    if desired is None:
        print(f"ERROR: unknown --type {args.type} (choose {list(TYPE_SETTINGS)})", file=sys.stderr)
        return 2
    current = settings.groups().get(groupUniqueId=args.group, alt="json").execute()
    delta = diff_settings(current, desired)
    print(f"{'APPLY' if apply else 'DRY-RUN'} settings — group={args.group} type={args.type}")
    if not delta:
        print("  already conformant — no change.")
        return 0
    for field, (old, new) in delta.items():
        print(f"  {field}: {old!r} -> {new!r}")
    if apply:
        settings.groups().patch(groupUniqueId=args.group, body=desired).execute()
        print("  applied.")
    else:
        print("  (dry-run — re-run with --apply inside the change window to write)")
    return 0


def cmd_set_owner(args):
    apply = args.apply
    directory, _ = build(RW if apply else RO)
    body = {"email": args.set_owner, "role": "OWNER"}
    print(f"{'APPLY' if apply else 'DRY-RUN'} set-owner — group={args.group} owner={args.set_owner}")
    existing = {m.get("email", "").lower(): m for m in
                directory.members().list(groupKey=args.group).execute().get("members", [])}
    if args.set_owner.lower() in existing and existing[args.set_owner.lower()].get("role") == "OWNER":
        print("  owner already present with OWNER role — no change.")
        return 0
    if apply:
        if args.set_owner.lower() in existing:
            directory.members().patch(groupKey=args.group, memberKey=args.set_owner,
                                      body={"role": "OWNER"}).execute()
        else:
            directory.members().insert(groupKey=args.group, body=body).execute()
        print("  applied.")
    else:
        print(f"  would add/promote {args.set_owner} to OWNER (dry-run)")
    return 0


def main():
    ap = argparse.ArgumentParser(description="Groups settings/ownership helper + baseline check (dry-run default).")
    sub = ap.add_subparsers(dest="cmd", required=True)

    b = sub.add_parser("check-baseline", help="Read-only org-wide baseline check (Gate 2)")
    b.add_argument("--domain", required=True)
    b.add_argument("--json", action="store_true")
    b.set_defaults(func=cmd_check_baseline)

    s = sub.add_parser("apply-settings", help="Apply a type's Groups settings to a group")
    s.add_argument("--group", required=True)
    s.add_argument("--type", required=True, choices=list(TYPE_SETTINGS))
    g = s.add_mutually_exclusive_group()
    g.add_argument("--dry-run", action="store_true", default=True)
    g.add_argument("--apply", action="store_true")
    s.set_defaults(func=cmd_apply_settings)

    o = sub.add_parser("set-owner", help="Ensure an owner group holds OWNER on a group")
    o.add_argument("--group", required=True)
    o.add_argument("--set-owner", required=True)
    og = o.add_mutually_exclusive_group()
    og.add_argument("--dry-run", action="store_true", default=True)
    og.add_argument("--apply", action="store_true")
    o.set_defaults(func=cmd_set_owner)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
