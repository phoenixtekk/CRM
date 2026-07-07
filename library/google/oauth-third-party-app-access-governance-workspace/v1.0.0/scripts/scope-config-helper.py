#!/usr/bin/env python3
# scope-config-helper.py — build/validate the OAuth scope-sensitivity reference used for risk scoring
#
# PURPOSE: Scope/config helper, READ-ONLY. Loads and validates the scope-sensitivity reference
#          (restricted/sensitive/basic tiers), reports which scopes seen in the app inventory are
#          UNKNOWN to the reference (so they get manual triage instead of being treated as low-risk),
#          and emits a reviewable scope-classification file the other tools consume. Makes NO changes
#          to any tenant.
# HOW TO RUN: python scope-config-helper.py --emit-template scope-sensitivity.json   (write a starter)
#             python scope-config-helper.py --scope-ref scope-sensitivity.json \
#                 [--inventory app-inventory.json] [--out scope-classification.json]
#             (Python 3.10+; no cloud auth needed — operates on local JSON)
# EXPECTED RESULTS: Validation of the reference (no scope in two tiers), a list of UNKNOWN scopes
#                   found in the inventory for triage, and a scope-classification.json for the risk
#                   model. Nothing is changed in the tenant.
#
# IMPORTANT: Google's authoritative restricted/sensitive OAuth scope list changes over time. This
# helper does NOT invent the classification — it manages a reviewable reference you populate/verify
# against Google's current "OAuth API scopes" / "restricted & sensitive scopes" documentation for
# YOUR tenant. Unknown scopes are surfaced, never silently downgraded.

import argparse
import json
import sys

TIERS = ("restricted", "sensitive", "basic")

# A STARTER template only — VERIFY and extend against Google's current published scope classification
# for your tenant. This is not an authoritative or complete list.
TEMPLATE = {
    "_note": "STARTER ONLY. Verify/extend against Google's current OAuth scope classification for "
             "your tenant. Match on substring; more specific entries win by tier precedence "
             "(restricted > sensitive > basic).",
    "restricted": [
        "https://www.googleapis.com/auth/gmail.readonly",
        "https://www.googleapis.com/auth/gmail.modify",
        "https://mail.google.com/",
        "https://www.googleapis.com/auth/drive",
        "https://www.googleapis.com/auth/admin.directory.user",
        "https://www.googleapis.com/auth/cloud-platform"
    ],
    "sensitive": [
        "https://www.googleapis.com/auth/calendar",
        "https://www.googleapis.com/auth/contacts",
        "https://www.googleapis.com/auth/drive.file",
        "https://www.googleapis.com/auth/spreadsheets"
    ],
    "basic": [
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/userinfo.profile",
        "openid"
    ]
}


def emit_template(path):
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(TEMPLATE, fh, indent=2)
    print(f"Wrote starter scope-sensitivity reference to {path}")
    print("VERIFY/extend it against Google's current scope classification before using it to score risk.")


def validate_ref(ref):
    """Ensure no scope string is listed under more than one tier."""
    seen, dupes = {}, []
    for tier in TIERS:
        for s in ref.get(tier, []):
            if s in seen and seen[s] != tier:
                dupes.append((s, seen[s], tier))
            seen[s] = tier
    return dupes


def tier_of(scope, ref):
    for tier in TIERS:  # precedence: restricted first
        for hint in ref.get(tier, []):
            if hint in scope:
                return tier
    return "unknown"


def main():
    ap = argparse.ArgumentParser(description="Build/validate the OAuth scope-sensitivity reference.")
    ap.add_argument("--emit-template", metavar="PATH", help="Write a starter reference file and exit.")
    ap.add_argument("--scope-ref", help="Existing scope-sensitivity reference JSON to validate/use.")
    ap.add_argument("--inventory", help="app-inventory.json to check for UNKNOWN scopes.")
    ap.add_argument("--out", default="scope-classification.json", help="Emit classification for the tools.")
    args = ap.parse_args()

    if args.emit_template:
        emit_template(args.emit_template)
        return
    if not args.scope_ref:
        sys.exit("ERROR: pass --scope-ref (or --emit-template to create a starter).")

    with open(args.scope_ref, encoding="utf-8") as fh:
        ref = json.load(fh)

    dupes = validate_ref(ref)
    if dupes:
        print("VALIDATION ERRORS — scope listed in multiple tiers:")
        for s, t1, t2 in dupes:
            print(f"  {s}: {t1} and {t2}")
        sys.exit(1)
    counts = {t: len(ref.get(t, [])) for t in TIERS}
    print(f"Reference OK  (restricted={counts['restricted']}, sensitive={counts['sensitive']}, "
          f"basic={counts['basic']})")

    unknown = set()
    if args.inventory:
        with open(args.inventory, encoding="utf-8") as fh:
            for a in json.load(fh).get("apps", []):
                for s in a.get("scopes", []):
                    if tier_of(s, ref) == "unknown":
                        unknown.add(s)
        if unknown:
            print(f"\n{len(unknown)} UNKNOWN scope(s) in inventory — triage against Google's docs:")
            for s in sorted(unknown):
                print(f"  {s}")
        else:
            print("\nAll inventory scopes are classified by the reference.")

    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump({"reference": ref, "unknown_scopes": sorted(unknown)}, fh, indent=2)
    print(f"\nScope-classification written to {args.out} (consumed by the inventory/validation tools).")


if __name__ == "__main__":
    main()
