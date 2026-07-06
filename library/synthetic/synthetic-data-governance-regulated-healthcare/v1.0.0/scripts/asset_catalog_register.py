#!/usr/bin/env python3
# asset_catalog_register.py — register synthetic/test assets into the catalog with lineage
#
# PURPOSE: Maintain the JSON-backed "Synthetic Asset Catalog - Enterprise - v1" (metadata only).
#          Register each governed synthetic/test asset with its id, target model (FHIR/OMOP/native),
#          environment, generator/source, PARENT asset (lineage), reference statistics used, and
#          steward; and list/query the catalog. Safe by default: writes are DRY-RUN unless --commit,
#          and the catalog holds metadata only -- never asset payloads and never real PHI.
# HOW TO RUN: python asset_catalog_register.py register --id ... --catalog catalog.json [--commit]   (Python 3.10+; see --help)
# EXPECTED RESULTS: In dry-run, a preview of the record to be added and "(dry-run) not written". With
#          --commit, the record is appended (or updated) and the catalog file is saved. `list`/`show`
#          print current records. Registering a derived asset whose --parent is not in the catalog
#          warns (broken lineage).

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

CATALOG_NAME = "Synthetic Asset Catalog - Enterprise - v1"
TARGET_MODELS = {"FHIR", "OMOP", "native", "other"}


def now_iso():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load_catalog(path):
    p = Path(path)
    if not p.exists():
        return {"catalog_name": CATALOG_NAME, "assets": []}
    try:
        data = json.loads(p.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        sys.exit(f"ERROR: catalog is not valid JSON ({path}): {e}")
    data.setdefault("catalog_name", CATALOG_NAME)
    data.setdefault("assets", [])
    return data


def save_catalog(path, data):
    Path(path).write_text(json.dumps(data, indent=2), encoding="utf-8")


def find(assets, asset_id):
    for a in assets:
        if a.get("id") == asset_id:
            return a
    return None


def cmd_register(args):
    if args.target_model not in TARGET_MODELS:
        sys.exit(f"ERROR: --target-model must be one of {sorted(TARGET_MODELS)}")
    data = load_catalog(args.catalog)
    assets = data["assets"]

    origin = args.generator or args.source
    if not origin:
        sys.exit("ERROR: an asset needs an origin -- supply --generator or --source (lineage).")

    if args.parent and not find(assets, args.parent):
        print(f"WARNING: parent asset '{args.parent}' is not in the catalog -- lineage would be "
              f"broken. Register the parent first, or omit --parent for a root asset.")

    record = {
        "id": args.id,
        "target_model": args.target_model,
        "environment": args.environment,
        "generator": args.generator or None,
        "source": args.source or None,
        "parent": args.parent or None,
        "reference_stats": args.reference_stats or None,
        "steward": args.steward,
        "classification": None,       # set by classify_approve_tracker.py
        "approval_status": None,      # set by classify_approve_tracker.py
        "consumed_in_shared": bool(args.consumed_in_shared),
        "registered_at": now_iso(),
    }

    existing = find(assets, args.id)
    action = "UPDATE" if existing else "ADD"
    print(f"[{action}] into {CATALOG_NAME}:")
    print(json.dumps(record, indent=2))

    if not args.commit:
        print("\n(dry-run) not written. Re-run with --commit to save.")
        return 0

    if existing:
        # Preserve classification/approval already set by the tracker.
        for keep in ("classification", "approval_status"):
            record[keep] = existing.get(keep)
        assets[assets.index(existing)] = record
    else:
        assets.append(record)
    save_catalog(args.catalog, data)
    print(f"\nCommitted. Catalog now holds {len(assets)} asset(s): {args.catalog}")
    return 0


def cmd_list(args):
    data = load_catalog(args.catalog)
    assets = data["assets"]
    if args.environment:
        assets = [a for a in assets if a.get("environment") == args.environment]
    print(f"{CATALOG_NAME}: {len(assets)} asset(s)")
    for a in assets:
        lineage = a.get("generator") or a.get("source") or "NO-ORIGIN"
        parent = f" <- {a['parent']}" if a.get("parent") else ""
        print(f"  {a.get('id'):<28} model={a.get('target_model'):<7} env={a.get('environment'):<14} "
              f"origin={lineage}{parent} class={a.get('classification') or '-'}")
    return 0


def cmd_show(args):
    data = load_catalog(args.catalog)
    a = find(data["assets"], args.id)
    if not a:
        sys.exit(f"ERROR: asset '{args.id}' not found in {args.catalog}")
    print(json.dumps(a, indent=2))
    return 0


def main():
    ap = argparse.ArgumentParser(description="Synthetic-asset catalog & lineage register (metadata only).")
    sub = ap.add_subparsers(dest="cmd", required=True)

    r = sub.add_parser("register", help="Register (or update) an asset with lineage.")
    r.add_argument("--catalog", required=True, help="Path to the catalog JSON (created if absent).")
    r.add_argument("--id", required=True, help="Stable asset id, e.g. 'synthetic-ehr-pilot-v1'.")
    r.add_argument("--target-model", required=True, help=f"One of {sorted(TARGET_MODELS)}.")
    r.add_argument("--environment", required=True, help="Where the asset lives, e.g. 'pilot-sandbox'.")
    r.add_argument("--generator", default=None, help="Generating tool/pattern (e.g. 'Synthea-pattern').")
    r.add_argument("--source", default=None, help="Source system/dataset if not generator-produced.")
    r.add_argument("--parent", default=None, help="Parent asset id if derived (lineage).")
    r.add_argument("--reference-stats", default=None,
                   help="Reference statistics used for fidelity, if any (metadata label only).")
    r.add_argument("--steward", required=True, help="Named steward accountable for this record.")
    r.add_argument("--consumed-in-shared", action="store_true",
                   help="Mark if this asset is consumed in a shared AI/QA env (approval required).")
    r.add_argument("--commit", action="store_true", help="Write the change (default: dry-run).")
    r.set_defaults(func=cmd_register)

    l = sub.add_parser("list", help="List catalog assets.")
    l.add_argument("--catalog", required=True)
    l.add_argument("--environment", default=None, help="Filter by environment.")
    l.set_defaults(func=cmd_list)

    s = sub.add_parser("show", help="Show one asset record.")
    s.add_argument("--catalog", required=True)
    s.add_argument("--id", required=True)
    s.set_defaults(func=cmd_show)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
