#!/usr/bin/env python3
# assess_governance_readiness.py — profile the current state of synthetic-data governance
#
# PURPOSE: Read a METADATA-ONLY inventory of existing synthetic/test assets plus a set of
#          governance-foundation flags, and emit the "Synthetic Data Governance - Enterprise -
#          Readiness" baseline: how many assets have no lineage / no classification / no approval,
#          and which governance foundations (policy, roles, scheme, control-set) exist. Read-only:
#          it never writes governance state and never touches asset payloads or real PHI.
# HOW TO RUN: python assess_governance_readiness.py --inventory inventory.json [--foundations found.json] [--json out.json]   (Python 3.10+; see --help)
# EXPECTED RESULTS: A printed readiness report with shadow-asset counts and foundation gaps. The
#          shadow-asset count is the "before" baseline and the metric that should trend DOWN as
#          governance is applied. Exit code 0 always (assessment, not a gate).

import argparse
import json
import sys
from pathlib import Path

VALID_CLASSES = None  # scheme is org-defined; here we only check "is a classification present"

FOUNDATION_KEYS = [
    ("policy", "Synthetic Data Governance Policy - Enterprise - v1"),
    ("roles", "Governance Roles - Enterprise - v1"),
    ("classification_scheme", "Classification Scheme - Enterprise - v1"),
    ("control_set", "Declared Control Set - Enterprise - v1"),
]


def load_json(path, what):
    p = Path(path)
    if not p.exists():
        sys.exit(f"ERROR: {what} not found: {path}")
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        sys.exit(f"ERROR: {what} is not valid JSON ({path}): {e}")


def asset_has_lineage(a):
    # An asset has lineage if it records where it came from. A parent is only expected for derived
    # assets, so origin (generator/source) alone satisfies lineage.
    origin = (a.get("generator") or a.get("source") or "").strip()
    return bool(origin)


def asset_has_classification(a):
    return bool((a.get("classification") or "").strip())


def asset_has_approval(a):
    # Approval only matters for assets consumed in a shared environment.
    if not a.get("consumed_in_shared"):
        return True  # not consumed -> approval not required -> not a gap
    return (a.get("approval_status") or "").strip().lower() == "approved"


def assess(inventory, foundations):
    assets = inventory.get("assets", inventory if isinstance(inventory, list) else [])
    total = len(assets)
    no_lineage = [a for a in assets if not asset_has_lineage(a)]
    no_class = [a for a in assets if not asset_has_classification(a)]
    consumed = [a for a in assets if a.get("consumed_in_shared")]
    no_approval = [a for a in consumed if not asset_has_approval(a)]

    found = {}
    for key, name in FOUNDATION_KEYS:
        found[key] = {"present": bool(foundations.get(key)), "artifact": name}

    return {
        "report_name": "Synthetic Data Governance - Enterprise - Readiness",
        "total_assets": total,
        "assets_no_lineage": len(no_lineage),
        "assets_no_classification": len(no_class),
        "assets_consumed_in_shared": len(consumed),
        "consumed_no_approval": len(no_approval),
        "foundations": found,
        "shadow_asset_ids": sorted(
            {a.get("id", "?") for a in (no_lineage + no_class + no_approval)}
        ),
    }


def pct(n, d):
    return f"{(100.0 * n / d):.0f}%" if d else "n/a"


def print_report(r):
    print(f"=== {r['report_name']} ===")
    t = r["total_assets"]
    print(f"Total synthetic/test assets in inventory : {t}")
    print(f"  no recorded lineage (origin)           : {r['assets_no_lineage']} ({pct(r['assets_no_lineage'], t)})")
    print(f"  no classification                      : {r['assets_no_classification']} ({pct(r['assets_no_classification'], t)})")
    print(f"  consumed in a shared env               : {r['assets_consumed_in_shared']}")
    print(f"    of those, NOT approved               : {r['consumed_no_approval']}")
    print("Governance foundations:")
    for key, meta in r["foundations"].items():
        mark = "PRESENT" if meta["present"] else "MISSING"
        print(f"  [{mark:7}] {meta['artifact']}")
    shadow = r["shadow_asset_ids"]
    print(f"Distinct shadow assets (missing lineage/class/approval): {len(shadow)}")
    if shadow:
        preview = ", ".join(shadow[:10]) + (" ..." if len(shadow) > 10 else "")
        print(f"  {preview}")
    print("\nNOTE: This is a governance-readiness baseline (method + evidence). It is NOT a "
          "compliance determination; HIPAA/HITRUST and disclosure-risk decisions remain with your "
          "privacy/compliance/legal functions.")


def main():
    ap = argparse.ArgumentParser(
        description="Baseline synthetic-data governance readiness from a metadata-only inventory."
    )
    ap.add_argument("--inventory", required=True,
                    help="Path to a metadata-only asset inventory JSON (list or {\"assets\": [...]}).")
    ap.add_argument("--foundations", default=None,
                    help="Optional JSON of foundation flags: {policy, roles, classification_scheme, control_set}.")
    ap.add_argument("--json", default=None, help="Optional path to write the report as JSON.")
    args = ap.parse_args()

    inventory = load_json(args.inventory, "inventory")
    foundations = load_json(args.foundations, "foundations") if args.foundations else {}

    report = assess(inventory, foundations)
    print_report(report)

    if args.json:
        Path(args.json).write_text(json.dumps(report, indent=2), encoding="utf-8")
        print(f"\nWrote report JSON: {args.json}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
