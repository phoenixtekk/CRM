#!/usr/bin/env python3
# syngov_config.py — scaffold and validate the synthetic-data governance register store
#
# PURPOSE: Scope & config helper. `scaffold` generates the starter JSON registers (empty catalog,
#          empty classification/approval log, and a control-map skeleton SEEDED from the declared
#          control set) into the Governance Register Store layout. `validate` checks the
#          classification scheme and roles config for the invariants the other tools rely on. Safe by
#          default: scaffold is DRY-RUN unless --commit and never overwrites an existing file; all
#          files are metadata only, never real PHI.
# HOW TO RUN: python syngov_config.py scaffold --store ./store --control-set set.json [--commit]   |   python syngov_config.py validate --scheme scheme.json --roles roles.json   (Python 3.10+; see --help)
# EXPECTED RESULTS: scaffold dry-run lists the files it would create; --commit writes only the missing
#          ones. validate prints PASS/FAIL per check (exit 1 on any failure), e.g. scheme has 3-5
#          values each with a handling rule, and roles define distinct owner/steward/reviewer/consumer.

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

CATALOG_NAME = "Synthetic Asset Catalog - Enterprise - v1"
LOG_NAME = "Classification & Approval Log - Enterprise - v1"
MAP_NAME = "Governance Control Map - Enterprise - v1"


def now_iso():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load_json(path, what):
    p = Path(path)
    if not p.exists():
        sys.exit(f"ERROR: {what} not found: {path}")
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        sys.exit(f"ERROR: {what} is not valid JSON ({path}): {e}")


def cmd_scaffold(args):
    control_set = load_json(args.control_set, "declared control set")
    declared = control_set.get("controls", control_set if isinstance(control_set, list) else [])

    store = Path(args.store)
    catalog = {"catalog_name": CATALOG_NAME, "generated_at": now_iso(), "assets": []}
    log = {"log_name": LOG_NAME, "generated_at": now_iso(), "classifications": {}, "approvals": []}
    control_map = {
        "map_name": MAP_NAME,
        "generated_at": now_iso(),
        "declared_control_set": control_set.get("name", args.control_set),
        "mappings": [
            {
                "control_id": (c.get("id") if isinstance(c, dict) else c),
                "status": "not-addressed",          # honest default; steward fills in
                "governance_control": "",
                "evidence": None,
            }
            for c in declared
        ],
    }

    plan = {
        "catalog.json": catalog,
        "classification_approval_log.json": log,
        "control_map.json": control_map,
    }

    print(f"Governance Register Store layout under: {store}")
    to_write = []
    for name, content in plan.items():
        target = store / name
        if target.exists():
            print(f"  [skip ] {name} (already exists -- not overwritten)")
        else:
            print(f"  [new  ] {name} ({len(json.dumps(content))} bytes)")
            to_write.append((target, content))

    if not args.commit:
        print("\n(dry-run) nothing written. Re-run with --commit to create the missing files.")
        return 0

    store.mkdir(parents=True, exist_ok=True)
    for target, content in to_write:
        target.write_text(json.dumps(content, indent=2), encoding="utf-8")
    print(f"\nCommitted {len(to_write)} file(s) into {store}. "
          f"Control map seeded with {len(control_map['mappings'])} declared control(s), all "
          f"'not-addressed' until you map them.")
    return 0


def cmd_validate(args):
    ok = True

    scheme = load_json(args.scheme, "classification scheme")
    values = scheme.get("values", scheme if isinstance(scheme, list) else [])
    n = len(values)
    if 3 <= n <= 5:
        print(f"[PASS] classification scheme has {n} values (recommended 3-5).")
    else:
        print(f"[FAIL] classification scheme has {n} values (keep it to 3-5).")
        ok = False
    for v in values:
        name = v if isinstance(v, str) else v.get("name")
        rule = None if isinstance(v, str) else v.get("handling_rule")
        if not rule:
            print(f"[FAIL] classification '{name}' has no handling_rule.")
            ok = False
    if all((not isinstance(v, str)) and v.get("handling_rule") for v in values) and values:
        print("[PASS] every classification value has a handling rule.")

    roles = load_json(args.roles, "roles config")
    required = ["owner", "steward", "reviewer", "consumer"]
    missing = [r for r in required if not roles.get(r)]
    if missing:
        print(f"[FAIL] roles config missing: {missing} (need owner/steward/reviewer/consumer).")
        ok = False
    else:
        print("[PASS] owner, steward, reviewer, consumer all assigned.")
        # separation-of-duties advisory: reviewer should not equal every consumer
        reviewer = str(roles.get("reviewer")).strip().lower()
        consumers = roles.get("consumer")
        consumers = consumers if isinstance(consumers, list) else [consumers]
        if reviewer in {str(c).strip().lower() for c in consumers}:
            print("[WARN] reviewer is also listed as a consumer -- ensure requester != approver "
                  "on any given release (separation of duties).")

    print(f"\nVALIDATION: {'PASS' if ok else 'FAIL'}")
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser(description="Synthetic-data governance scope & config helper.")
    sub = ap.add_subparsers(dest="cmd", required=True)

    sc = sub.add_parser("scaffold", help="Create starter registers seeded from the declared control set.")
    sc.add_argument("--store", required=True, help="Target Governance Register Store directory.")
    sc.add_argument("--control-set", required=True, help="Declared Control Set - Enterprise - v1 JSON.")
    sc.add_argument("--commit", action="store_true", help="Write missing files (default: dry-run).")
    sc.set_defaults(func=cmd_scaffold)

    va = sub.add_parser("validate", help="Validate the classification scheme and roles config.")
    va.add_argument("--scheme", required=True, help="Classification Scheme - Enterprise - v1 JSON.")
    va.add_argument("--roles", required=True, help="Governance Roles - Enterprise - v1 JSON.")
    va.set_defaults(func=cmd_validate)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
