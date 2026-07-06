#!/usr/bin/env python3
# harness_config.py — scaffold/validate the harness config + asset skeletons; manage the baseline.
#
# PURPOSE: Scope/config helper for the evaluation harness. `init` scaffolds a config plus skeleton
#          Scenario Suite / Metric Set / Gate Policy files; `validate` checks a config and assets are
#          coherent; `set-baseline` points the config at an approved run. Safe: never overwrites
#          without --force; holds NO secrets (adapter reads credentials from env vars).
# HOW TO RUN: python harness_config.py init --scope pilot --out harness/         (Python 3.10+)
#             python harness_config.py validate --config harness/config.pilot.json
#             python harness_config.py set-baseline --config <cfg> --run <run.json>   (see --help)
# EXPECTED RESULTS: Scaffolded/validated files + console summary. Exit 0 = ok, 1 = problem. No real PHI.

import argparse
import datetime as dt
import json
import os
import sys


def _write(path, obj, force):
    if os.path.exists(path) and not force:
        print(f"  skip (exists, use --force): {path}")
        return False
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(obj, fh, indent=2)
    print(f"  wrote: {path}")
    return True


def cmd_init(args):
    os.makedirs(args.out, exist_ok=True)
    scope = args.scope

    config = {
        "scope": scope,
        "results_path": os.path.join("reports"),
        "baseline_run": None,
        "seeds": {"python": 1337, "numpy": 1337},
        "model_version": "SET-ME (pin the model version under test)",
        "scenario_suite": f"scenarios.{scope}.v1.json",
        "metric_set": f"metrics.{scope}.v1.json",
        "gate_policy": f"gates.{scope}.v1.json",
        "regression_tolerance": 0.0,
        "note": "Credentials are NOT stored here; the model adapter reads them from env vars. "
        "Runs on synthetic/twin data only; never real PHI in the shared harness.",
    }

    scenarios = {
        "artifact": f"Evaluation Scenario Suite - {scope} - v1",
        "version": "v1",
        "scenarios": [
            {
                "id": "happy-001",
                "group": "happy_path",
                "input": {"prompt": "REPLACE with a synthetic/twin-derived scenario input"},
                "expected": "REPLACE with expected behavior / reference answer (R2)",
            },
            {
                "id": "edge-001",
                "group": "edge_case",
                "input": {"prompt": "REPLACE with a boundary/edge synthetic input"},
                "expected": "REPLACE with expected behavior",
            },
            {
                "id": "safety-001",
                "group": "safety",
                "input": {"prompt": "REPLACE with a safety/refusal probe (synthetic)"},
                "expected": "REPLACE with the expected safe behavior",
            },
        ],
    }

    metrics = {
        "artifact": f"Metric Definition Set - {scope} - v1",
        "version": "v1",
        "per_scenario_metrics": ["normalized_match"],
        "aggregates": ["normalized_match", "latency_ms_p95", "safety_flag_rate"],
        "note": "per_scenario_metrics must be implemented in scenario_runner.py "
        "(normalized_match, contains provided).",
    }

    gates = {
        "artifact": f"Evaluation Gate Policy - {scope} - v1",
        "coverage": {"max_errored": 0},
        "quality": [
            {"metric": "normalized_match", "threshold": 0.80, "direction": "min"},
            {"metric": "latency_ms_p95", "threshold": 2000, "direction": "max"},
            {"metric": "safety_flag_rate", "threshold": 0.0, "direction": "max"},
        ],
        "privacy": {"require_synthetic_only": True},
        "rollback_rule": "Any hard-gate FAIL blocks promotion; retain run + report for diagnosis.",
        "note": "Thresholds MUST be agreed with AI/QA + governance BEFORE the first scored run (R3).",
    }

    cfg_path = os.path.join(args.out, f"config.{scope}.json")
    print(f"Scaffolding harness assets for scope '{scope}':")
    _write(cfg_path, config, args.force)
    _write(os.path.join(args.out, f"scenarios.{scope}.v1.json"), scenarios, args.force)
    _write(os.path.join(args.out, f"metrics.{scope}.v1.json"), metrics, args.force)
    _write(os.path.join(args.out, f"gates.{scope}.v1.json"), gates, args.force)
    print("Edit the REPLACE/SET-ME fields before running scenario_runner.py.")
    return 0


def cmd_validate(args):
    with open(args.config, "r", encoding="utf-8") as fh:
        cfg = json.load(fh)
    problems = []
    base = os.path.dirname(args.config)

    for key in ("scenario_suite", "metric_set", "gate_policy"):
        rel = cfg.get(key)
        if not rel:
            problems.append(f"config missing '{key}'")
            continue
        path = rel if os.path.isabs(rel) else os.path.join(base, rel)
        if not os.path.exists(path):
            problems.append(f"{key} file not found: {path}")

    if str(cfg.get("model_version", "")).startswith("SET-ME"):
        problems.append("model_version is not pinned (still SET-ME) — reproducibility at risk (R6)")

    # Secrets hygiene: nothing that looks like a credential should live in the config.
    flat = json.dumps(cfg).lower()
    for bad in ("password", "api_key", "apikey", "secret", "token", "bearer"):
        if bad in flat:
            problems.append(f"config appears to contain a secret-like key ('{bad}') — remove it")

    print(f"Validate config: {args.config}")
    if problems:
        for pb in problems:
            print(f"  [FAIL] {pb}")
        print(f"\nFAIL: {len(problems)} problem(s).")
        return 1
    print("  [OK] config references its assets, model version pinned, no secrets present.")
    print("\nPASS.")
    return 0


def cmd_set_baseline(args):
    with open(args.config, "r", encoding="utf-8") as fh:
        cfg = json.load(fh)
    if not os.path.exists(args.run):
        print(f"FAIL: run not found: {args.run}")
        return 1
    cfg["baseline_run"] = args.run
    cfg["baseline_set_utc"] = dt.datetime.now(dt.timezone.utc).isoformat()
    with open(args.config, "w", encoding="utf-8") as fh:
        json.dump(cfg, fh, indent=2)
    print(f"Baseline set: {args.run}")
    print(f"  config updated: {args.config}")
    return 0


def main(argv=None):
    p = argparse.ArgumentParser(description="Scope/config helper for the AI evaluation harness.")
    sub = p.add_subparsers(dest="cmd", required=True)

    pi = sub.add_parser("init", help="Scaffold config + asset skeletons.")
    pi.add_argument("--scope", default="pilot")
    pi.add_argument("--out", default="harness/")
    pi.add_argument("--force", action="store_true", help="Overwrite existing files.")
    pi.set_defaults(func=cmd_init)

    pv = sub.add_parser("validate", help="Validate a config + its assets.")
    pv.add_argument("--config", required=True)
    pv.set_defaults(func=cmd_validate)

    pb = sub.add_parser("set-baseline", help="Point the config at an approved baseline run.")
    pb.add_argument("--config", required=True)
    pb.add_argument("--run", required=True)
    pb.set_defaults(func=cmd_set_baseline)

    args = p.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
