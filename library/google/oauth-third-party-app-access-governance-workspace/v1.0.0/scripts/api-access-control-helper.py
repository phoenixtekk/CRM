#!/usr/bin/env python3
# api-access-control-helper.py — plan/preview Trusted/Limited/Blocked app access-control changes
#
# PURPOSE: Configuration helper, DRY-RUN by default. Takes a classification plan (each app ->
#          Trusted | Limited | Blocked) and the current app inventory, and prints the current-vs-
#          intended access level per app, flagging any change that could break a legitimate app.
#          Applies nothing unless --apply is passed. Drives "Trusted/Limited/Blocked Apps - Org-Wide
#          - v1".
# HOW TO RUN: python api-access-control-helper.py --plan classification.json
#             [--inventory app-inventory.json] [--scope pilot-ou|org] [--dry-run|--apply]
#             (Python 3.10+, gcloud ADC; see --help)
# EXPECTED RESULTS: A per-app change plan on stdout (ADD/CHANGE/UNCHANGED + break-risk flags). With
#                   --dry-run (default) NOTHING is changed. With --apply it emits the exact console
#                   steps / settings to enact, and records an apply-log — it does NOT silently flip
#                   tenant-wide settings.
#
# App access control (Trusted/Limited/Blocked), Marketplace settings, and the unconfigured-app policy
# live in Admin console -> Security -> Access and data control -> API controls. Some of these are set
# in the console UI; this helper produces the exact, reviewable change set (and, where a supported
# Admin API exists for your tenant/edition, the request payloads) so the operator applies a vetted,
# named plan rather than ad-hoc clicks. VERIFY console paths in your tenant. NO keys in code.

import argparse
import json
import sys

VALID_LEVELS = {"Trusted", "Limited", "Blocked"}
# Lowering a Trusted/holding app that has sensitive/restricted scopes is the classic break risk.
BREAK_RISK_RISKS = {"HIGH", "MEDIUM"}


def load_json(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def index_inventory(inv):
    return {a["client_id"]: a for a in inv.get("apps", [])} if inv else {}


def main():
    ap = argparse.ArgumentParser(description="Preview/apply Trusted/Limited/Blocked app access control.")
    ap.add_argument("--plan", required=True,
                    help="Classification plan JSON: {\"apps\":[{\"client_id\":..,\"level\":\"Trusted\"}]}")
    ap.add_argument("--inventory", help="app-inventory.json (for current scopes/risk + break-risk flags).")
    ap.add_argument("--scope", default="org", help="Apply scope label: 'org' or an OU/group id (e.g. pilot-ou).")
    grp = ap.add_mutually_exclusive_group()
    grp.add_argument("--dry-run", action="store_true", help="Preview only (default).")
    grp.add_argument("--apply", action="store_true", help="Emit the enact steps + write an apply-log.")
    ap.add_argument("--apply-log", default="access-control-apply-log.json")
    args = ap.parse_args()

    apply = args.apply and not args.dry_run
    plan = load_json(args.plan)
    inv = index_inventory(load_json(args.inventory)) if args.inventory else {}

    changes, break_flags = [], []
    for entry in plan.get("apps", []):
        cid = entry.get("client_id", "?")
        level = entry.get("level")
        if level not in VALID_LEVELS:
            sys.exit(f"ERROR: app {cid} has invalid level {level!r} (Trusted|Limited|Blocked).")
        cur = inv.get(cid, {})
        current_level = cur.get("access_level", "Unconfigured")
        risk = cur.get("risk", "UNKNOWN")
        action = "UNCHANGED" if current_level == level else ("ADD" if current_level == "Unconfigured" else "CHANGE")
        break_risk = level in {"Limited", "Blocked"} and risk in BREAK_RISK_RISKS and current_level == "Trusted"
        rec = {"client_id": cid, "display": cur.get("display", entry.get("display", "")),
               "risk": risk, "from": current_level, "to": level, "action": action,
               "scope": args.scope, "break_risk": break_risk}
        changes.append(rec)
        if break_risk:
            break_flags.append(rec)

    print(f"Access-control plan  (scope={args.scope}, mode={'APPLY' if apply else 'DRY-RUN'})\n")
    for c in changes:
        flag = "  <-- BREAK-RISK: verify this app is not business-critical" if c["break_risk"] else ""
        print(f"  [{c['action']:<9}] {c['to']:<8} {c['risk']:<7} {c['display'] or c['client_id']}{flag}")

    if break_flags:
        print(f"\n{len(break_flags)} app(s) flagged BREAK-RISK. Pilot these on 'App-Access Pilot - "
              "Pilot-OU - v1' and confirm before org-wide expansion.")

    if not apply:
        print("\nDRY-RUN: no changes made. Re-run with --apply after review + approver sign-off.")
        return

    print("\nAPPLY — enact these named settings in Admin console -> Security -> Access and data "
          "control -> API controls -> App access control (VERIFY paths in your tenant):")
    for c in changes:
        if c["action"] != "UNCHANGED":
            print(f"  - Set '{c['display'] or c['client_id']}' to {c['to']} for scope {c['scope']}")
    with open(args.apply_log, "w", encoding="utf-8") as fh:
        json.dump({"scope": args.scope, "changes": changes}, fh, indent=2)
    print(f"\nApply-log written to {args.apply_log} (evidence for change control).")


if __name__ == "__main__":
    main()
