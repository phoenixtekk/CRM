#!/usr/bin/env python3
# scenario_config.py — scaffold, edit, and validate the harness config + scenario suite
#
# PURPOSE: Create and maintain the reproducible harness configuration (target model, domains, scenario
#          suite) that drives generate_harness.py. Keeps runs reviewable and version-controllable. SAFE BY
#          DEFAULT: only writes the config file you name (a config, never patient data); no real PHI.
# HOW TO RUN: python scenario_config.py init --target-model fhir --domains patients,encounters,labs \
#               --out harness-config.json
#             python scenario_config.py add-scenario --config harness-config.json --name diabetes-panel \
#               --size 200 --require-condition E11 --require-lab HbA1c
#             python scenario_config.py validate --config harness-config.json
#             (Python 3.10+; see --help)
# EXPECTED RESULTS: init writes a config; add-scenario appends a scenario; validate prints OK when the
#                   config is internally consistent (exit 0) or lists problems (exit 1).

import argparse
import json
import os
import sys

TARGET_MODELS = {"fhir", "omop", "native"}
KNOWN_DOMAINS = {"patients", "encounters", "conditions", "medications", "labs", "vitals"}


def load_config(path):
    if not os.path.isfile(path):
        raise SystemExit(f"config not found: {path} (run 'init' first)")
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def save_config(path, config):
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(config, fh, indent=2)


def cmd_init(args):
    domains = [d.strip() for d in args.domains.split(",") if d.strip()]
    unknown = [d for d in domains if d not in KNOWN_DOMAINS]
    if unknown:
        print(f"  WARN: unrecognized domain(s) {unknown} — supported: {sorted(KNOWN_DOMAINS)}")
    if "patients" not in domains:
        domains.insert(0, "patients")  # patients are always required as the root entity
        print("  note: 'patients' added — it is the root entity for every record")
    config = {
        "artifact": "Synthetic EHR – Harness Design – Pilot",
        "target_model": args.target_model,
        "domains": domains,
        "scenarios": [],
    }
    if os.path.exists(args.out) and not args.force:
        raise SystemExit(f"{args.out} exists — pass --force to overwrite")
    save_config(args.out, config)
    print(f"  wrote config -> {args.out}")
    print(f"    target model: {args.target_model}")
    print(f"    domains     : {', '.join(domains)}")
    return 0


def cmd_add_scenario(args):
    config = load_config(args.config)
    if any(s.get("name") == args.name for s in config.get("scenarios", [])):
        raise SystemExit(f"scenario '{args.name}' already exists in {args.config}")
    scenario = {
        "name": args.name,
        "size": args.size,
        "require_condition": args.require_condition,
        "require_lab": args.require_lab,
    }
    config.setdefault("scenarios", []).append(scenario)
    save_config(args.config, config)
    print(f"  added scenario '{args.name}' (size {args.size}) -> {args.config}")
    if args.require_condition:
        print(f"    requires condition: {args.require_condition}")
    if args.require_lab:
        print(f"    requires lab: {args.require_lab}")
    return 0


def cmd_validate(args):
    config = load_config(args.config)
    problems = []

    tm = str(config.get("target_model", "")).lower()
    if tm not in TARGET_MODELS:
        problems.append(f"target_model '{tm}' is not one of {sorted(TARGET_MODELS)}")

    domains = config.get("domains", [])
    if not domains:
        problems.append("no domains defined")
    if "patients" not in domains:
        problems.append("'patients' domain missing (root entity required)")
    for d in domains:
        if d not in KNOWN_DOMAINS:
            problems.append(f"unrecognized domain '{d}'")

    names = set()
    for sc in config.get("scenarios", []):
        nm = sc.get("name")
        if not nm:
            problems.append("a scenario has no name")
        elif nm in names:
            problems.append(f"duplicate scenario name '{nm}'")
        names.add(nm)
        if sc.get("size", 0) <= 0:
            problems.append(f"scenario '{nm}' has non-positive size")
        # a required condition implies the conditions domain is in scope
        if sc.get("require_condition") and "conditions" not in domains:
            problems.append(f"scenario '{nm}' requires a condition but 'conditions' domain is not in scope")
        if sc.get("require_lab") and "labs" not in domains:
            problems.append(f"scenario '{nm}' requires a lab but 'labs' domain is not in scope")

    print(f"=== validate {args.config} ===")
    print(f"  target model: {tm}")
    print(f"  domains     : {', '.join(domains)}")
    print(f"  scenarios   : {len(config.get('scenarios', []))}")
    if problems:
        print("\n  PROBLEMS:")
        for p in problems:
            print(f"    - {p}")
        print("\n  RESULT: FAIL")
        return 1
    print("\n  RESULT: OK")
    return 0


def main():
    ap = argparse.ArgumentParser(description="Scaffold/edit/validate the synthetic-EHR harness config.")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_init = sub.add_parser("init", help="create a new harness config")
    p_init.add_argument("--target-model", required=True, choices=sorted(TARGET_MODELS))
    p_init.add_argument("--domains", default="patients,encounters,conditions,medications,labs,vitals")
    p_init.add_argument("--out", required=True, help="path to write the config JSON")
    p_init.add_argument("--force", action="store_true", help="overwrite an existing config")
    p_init.set_defaults(func=cmd_init)

    p_add = sub.add_parser("add-scenario", help="append a scenario to the suite")
    p_add.add_argument("--config", required=True)
    p_add.add_argument("--name", required=True)
    p_add.add_argument("--size", type=int, required=True, help="minimum cohort size for this scenario")
    p_add.add_argument("--require-condition", help="condition code the scenario must contain (e.g. E11)")
    p_add.add_argument("--require-lab", help="lab name the scenario must contain (e.g. HbA1c)")
    p_add.set_defaults(func=cmd_add_scenario)

    p_val = sub.add_parser("validate", help="check the config is internally consistent")
    p_val.add_argument("--config", required=True)
    p_val.set_defaults(func=cmd_validate)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
