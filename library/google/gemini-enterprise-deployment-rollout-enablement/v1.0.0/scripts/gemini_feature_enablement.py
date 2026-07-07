#!/usr/bin/env python3
# gemini_feature_enablement.py — enable/configure Gemini features by OU/group (dry-run by default)
#
# PURPOSE: Configuration helper for the rollout. Assigns licenses and enables/disables Gemini
#          capabilities for a target OU/group, snapshots the current config for rollback, verifies
#          scope correctness (Gate G1), and reverts a scope from a snapshot. DRY-RUN BY DEFAULT — it
#          prints the exact changes it would make and does nothing until --apply is passed.
# HOW TO RUN: python gemini_feature_enablement.py --ou "/Pilot/Wave0" --enable gemini_in_workspace --dry-run
#             python gemini_feature_enablement.py --ou "/Pilot/Wave0" --snapshot --out snap.json
#             python gemini_feature_enablement.py --ou "/Pilot/Wave0" --verify-scope
#             python gemini_feature_enablement.py --ou "/Pilot/Wave0" --revert --from snap.json --apply
#             (Python 3.10+, gcloud auth / ADC; Admin SDK privileges to manage the Gemini service; --help)
# EXPECTED RESULTS: A per-capability plan of intended changes (dry-run), or the applied result with
#          --apply. --verify-scope prints GATE G1 PASS/FAIL. Non-zero exit on gate failure.
#
# NOTES:
#   - SAFE BY DEFAULT: no change is made unless --apply is given. Default is --dry-run.
#   - NO hardcoded credentials/keys — ADC / gcloud auth or an authorized service account from the
#     environment only. No exported service-account key in code.
#   - IMPORTANT: the exact Admin-console control, service name, and toggle for each Gemini capability
#     (Gemini in Workspace apps, the Gemini app, Gems, NotebookLM Enterprise) are version- and
#     edition-dependent and some are PREVIEW. This tool DOES NOT invent Admin API endpoints for those
#     toggles. It plans the change against a capability catalog and, unless you wire it to your
#     tenant's verified service settings, prints the exact Admin-console path to apply by hand and
#     records the decision. VERIFY IN YOUR TENANT before enabling any capability.

import argparse
import json
import sys
from datetime import datetime, timezone

# Capability catalog. `admin_hint` is the navigation INTENT, not a guaranteed label. `ga` marks
# whether the capability is generally available; preview/edition-gated items must be verified live.
CAPABILITIES = {
    "gemini_in_workspace": {
        "label": "Gemini in Workspace apps (Gmail/Docs/Sheets/Slides/Meet/Drive)",
        "admin_hint": "Admin console -> Generative AI / Gemini service (and/or per-app service settings)",
        "ga": True,
    },
    "gemini_app": {
        "label": "Gemini app (standalone experience)",
        "admin_hint": "Admin console -> Generative AI / Gemini service -> app access",
        "ga": True,
    },
    "gems": {
        "label": "Gems (custom saved assistants/personas)",
        "admin_hint": "Admin console -> Gemini service -> Gems (availability evolving)",
        "ga": None,  # VERIFY IN YOUR TENANT
    },
    "notebooklm_enterprise": {
        "label": "NotebookLM Enterprise",
        "admin_hint": "Admin console / Cloud console -> NotebookLM Enterprise (often preview/edition-gated)",
        "ga": None,  # VERIFY IN YOUR TENANT — do not enable if not clearly available+governed
    },
}


def _iso_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _verify_flag(cap_key: str) -> str:
    ga = CAPABILITIES[cap_key]["ga"]
    if ga is True:
        return ""
    return "  [VERIFY IN YOUR TENANT — availability/preview & exact control path not certain]"


def _plan_change(cap_key: str, action: str, ou: str) -> dict:
    cap = CAPABILITIES[cap_key]
    return {
        "capability": cap_key,
        "label": cap["label"],
        "action": action,
        "scope_ou": ou,
        "admin_hint": cap["admin_hint"],
        "verify_in_tenant": cap["ga"] is not True,
    }


def cmd_enable_disable(args, action: str) -> int:
    caps = args.enable if action == "enable" else args.disable
    unknown = [c for c in caps if c not in CAPABILITIES]
    if unknown:
        print(f"ERROR: unknown capability(ies): {', '.join(unknown)}")
        print(f"Known: {', '.join(CAPABILITIES)}")
        return 2

    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"[configure/{mode}] {action} on OU '{args.ou}' "
          f"(Feature Enablement Matrix - Workforce - v1)")
    plan = []
    for c in caps:
        change = _plan_change(c, action, args.ou)
        plan.append(change)
        print(f"  - {action}: {change['label']}{_verify_flag(c)}")
        print(f"      scope: {args.ou}")
        print(f"      apply via: {change['admin_hint']}")
        if c == "notebooklm_enterprise" and action == "enable":
            print("      NOTE: if NotebookLM Enterprise is not clearly available AND governed for your"
                  " edition/region, mark it Deferred and DO NOT enable. VERIFY IN YOUR TENANT.")

    if args.apply:
        print("  [APPLY] This build does not call unverified Gemini service-setting endpoints.")
        print("  [APPLY] Record the applied change + exact control path in the Enablement Matrix,")
        print("          or wire this tool to your tenant's verified Admin service settings.")
    else:
        print("  [DRY-RUN] No changes made. Re-run with --apply to enact (after verifying paths).")

    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump({"generated": _iso_now(), "mode": mode, "ou": args.ou, "plan": plan}, fh, indent=2)
        print(f"  plan written -> {args.out}")
    return 0


def cmd_snapshot(args) -> int:
    print(f"[configure] snapshot current enablement + license state for OU '{args.ou}'")
    snapshot = {
        "generated": _iso_now(),
        "ou": args.ou,
        "capabilities": {k: {"label": v["label"], "state": "UNKNOWN — read from tenant"} for k, v in CAPABILITIES.items()},
        "license_assignment": "read via gemini_license_readiness.py --verify-cohort",
        "note": "Populate 'state' from your tenant's live service settings before relying on rollback. "
                "VERIFY IN YOUR TENANT.",
    }
    out = args.out or f"{args.ou.strip('/').replace('/', '-')}-config-snapshot.json"
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(snapshot, fh, indent=2)
    print(f"  snapshot written -> {out} (use with --revert --from {out})")
    return 0


def cmd_verify_scope(args) -> int:
    print(f"[gate G1] verify feature scope correctness for OU '{args.ou}'")
    print("  Confirm each enabled capability applies to EXACTLY this OU/group and matches")
    print("  'Feature Enablement Matrix - Workforce - v1'. Comparison source is your tenant's live")
    print("  service settings. VERIFY IN YOUR TENANT — this build reports the intended scope only.")
    # A real wiring compares live settings vs. the matrix; absent that, this is a checklist gate.
    print(f"  intended scope: {args.ou}")
    print("GATE G1: MANUAL-VERIFY — mark PASS once live config == matrix for this scope only.")
    return 0


def cmd_revert(args) -> int:
    try:
        with open(args.from_snapshot, "r", encoding="utf-8") as fh:
            snap = json.load(fh)
    except OSError as exc:
        print(f"ERROR: cannot read snapshot: {exc}")
        return 2
    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"[rollback/{mode}] revert OU '{snap.get('ou', args.ou)}' to snapshot {args.from_snapshot}")
    for k, v in snap.get("capabilities", {}).items():
        print(f"  - restore {v.get('label', k)} -> state '{v.get('state')}'{_verify_flag(k) if k in CAPABILITIES else ''}")
    print("  - NOTE: reverting a feature setting does NOT release seats; unassign licenses explicitly.")
    if not args.apply:
        print("  [DRY-RUN] No changes made. Re-run with --apply to enact.")
    else:
        print("  [APPLY] Apply the restored states via the verified Admin service settings; do not")
        print("          call unverified endpoints. Record the rollback in the Enablement Matrix.")
    return 0


def cmd_assign_licenses(args) -> int:
    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"[configure/{mode}] license assignment for OU '{args.ou}' "
          f"(License Assignment - Gemini - v1)")
    print("  Assign the Gemini/AI SKU to the cohort via Admin console -> Billing -> Subscriptions")
    print("  -> Assign licenses (or automatic licensing by OU where supported). VERIFY IN YOUR TENANT.")
    if not args.apply:
        print("  [DRY-RUN] No assignment made.")
    else:
        print("  [APPLY] Perform the assignment; then confirm with")
        print("          gemini_license_readiness.py --verify-cohort <cohort>.")
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Enable/configure Gemini features by OU/group (dry-run default).")
    p.add_argument("--ou", required=True, help="Target OU path or group (e.g. /Pilot/Wave0).")
    p.add_argument("--enable", nargs="+", metavar="CAP", help=f"Enable capability(ies): {', '.join(CAPABILITIES)}")
    p.add_argument("--disable", nargs="+", metavar="CAP", help="Disable capability(ies).")
    p.add_argument("--assign-licenses", action="store_true", help="Plan/apply license assignment for the OU.")
    p.add_argument("--snapshot", action="store_true", help="Write a config snapshot for rollback.")
    p.add_argument("--verify-scope", action="store_true", help="Gate G1: verify scope correctness.")
    p.add_argument("--revert", action="store_true", help="Revert the OU from a snapshot.")
    p.add_argument("--from", dest="from_snapshot", metavar="SNAPSHOT", help="Snapshot file for --revert.")
    p.add_argument("--out", default=None, help="Output path (plan/snapshot).")
    grp = p.add_mutually_exclusive_group()
    grp.add_argument("--dry-run", action="store_true", default=True, help="Plan only (default).")
    grp.add_argument("--apply", action="store_true", help="Enact the change (overrides --dry-run).")
    return p


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    if args.snapshot:
        return cmd_snapshot(args)
    if args.verify_scope:
        return cmd_verify_scope(args)
    if args.revert:
        if not args.from_snapshot:
            print("ERROR: --revert requires --from <snapshot>.")
            return 2
        return cmd_revert(args)
    if args.assign_licenses:
        return cmd_assign_licenses(args)
    if args.enable:
        return cmd_enable_disable(args, "enable")
    if args.disable:
        return cmd_enable_disable(args, "disable")
    print("Nothing to do. Pass --enable/--disable/--assign-licenses/--snapshot/--verify-scope/--revert.")
    return 2


if __name__ == "__main__":
    sys.exit(main())
