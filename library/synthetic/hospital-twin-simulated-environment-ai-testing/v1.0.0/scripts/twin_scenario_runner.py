#!/usr/bin/env python3
# twin_scenario_runner.py — scenario runner + AI plug-in harness for the hospital twin.
#
# PURPOSE: Runs a scenario (or a whole suite) through the twin, invokes the AI-under-test at each
#          plug-in point via an adapter (built-in 'mock' or your 'real' adapter), captures the AI's
#          outputs, and scores them against each scenario's expected/unacceptable behavior. Dry-run
#          by default; writes the Twin Evaluation Record only with --commit.
# HOW TO RUN: python twin_scenario_runner.py --config "Twin Scope Config - Pilot - v1.json" \
#             --scenario path/to/scenario.json --ai-adapter mock [--commit]  (Python 3.10+; --help)
# EXPECTED RESULTS: Per-scenario PASS/FAIL on stdout and an overall pass-rate vs. the scenario gate.
#                   With --commit, a Twin Evaluation Record JSON is written.
#
# Safe by default: the 'real' adapter must be an isolated, non-production callable you register; this
# harness makes no network calls itself and reads only synthetic scenario data. --dry-run is default.

import argparse
import glob
import importlib
import json
import os
import sys
from datetime import datetime, timezone


def _now():
    return datetime.now(timezone.utc).isoformat()


# ---- AI adapters -----------------------------------------------------------------------------
# A scenario names, per plug-in point, an "expected" acceptable label and an "unacceptable" label.
# An adapter maps a twin event/state to a label. The mock adapter is deterministic for wiring tests
# and reproducibility. The real adapter is loaded from a module:function you provide, and MUST run
# inside the isolated environment against only synthetic data.

def mock_adapter(plugin_input):
    """Deterministic stand-in: echoes the scenario's own 'expected' label so wiring can be proven."""
    return {"label": plugin_input.get("expected", "no-op"), "adapter": "mock"}


def load_real_adapter(spec):
    """spec = 'module.path:function'. The function takes a dict, returns {'label': ...}."""
    if not spec or ":" not in spec:
        raise ValueError("real adapter requires --adapter-spec 'module.path:function'")
    mod_name, func_name = spec.split(":", 1)
    mod = importlib.import_module(mod_name)
    func = getattr(mod, func_name)
    return lambda plugin_input: {"label": func(plugin_input), "adapter": spec}


# ---- scenario execution ----------------------------------------------------------------------

def run_scenario(scenario, adapter):
    """Advance the scenario's plug-in points, invoke the adapter, score against expected/unacceptable."""
    name = scenario.get("name", "unnamed")
    critical = bool(scenario.get("critical", False))
    plugin_points = scenario.get("plugin_points", [])
    results = []
    unacceptable_seen = False
    matched = 0

    for pt in plugin_points:
        out = adapter(pt)
        label = out.get("label")
        expected = pt.get("expected")
        unacceptable = pt.get("unacceptable")
        is_unacceptable = (label == unacceptable)
        is_expected = (label == expected)
        if is_unacceptable:
            unacceptable_seen = True
        if is_expected:
            matched += 1
        results.append({
            "point": pt.get("id"),
            "ai_label": label,
            "expected": expected,
            "match": is_expected,
            "unacceptable": is_unacceptable,
        })

    total = len(plugin_points) or 1
    scenario_pass = (matched == total) and not unacceptable_seen
    return {
        "scenario": name,
        "critical": critical,
        "points_total": len(plugin_points),
        "points_matched": matched,
        "unacceptable_seen": unacceptable_seen,
        "pass": scenario_pass,
        "detail": results,
    }


def load_scenarios(args):
    paths = []
    if args.scenario:
        paths = [args.scenario]
    elif args.scenario_suite:
        paths = sorted(glob.glob(os.path.join(args.scenario_suite, "*.json")))
    scenarios = []
    for path in paths:
        with open(path, encoding="utf-8") as fh:
            scenarios.append(json.load(fh))
    return scenarios


def main(argv=None):
    p = argparse.ArgumentParser(description="Scenario runner + AI plug-in harness (safe by default).")
    p.add_argument("--config", required=True, help="Twin Scope Config JSON path")
    src = p.add_mutually_exclusive_group(required=True)
    src.add_argument("--scenario", help="a single scenario .json")
    src.add_argument("--scenario-suite", help="directory of scenario .json files")
    p.add_argument("--ai-adapter", choices=["mock", "real"], default="mock",
                   help="which AI adapter to invoke at plug-in points")
    p.add_argument("--adapter-spec", help="(real) 'module.path:function' isolated, synthetic-only")
    p.add_argument("--gate-passrate", type=float, default=1.0,
                   help="minimum scenario pass-rate to meet the scenario gate (0..1)")
    p.add_argument("--commit", action="store_true",
                   help="write the Twin Evaluation Record (default dry-run: score only)")
    p.add_argument("--out", default="Twin Evaluation Record - Pilot - v1.json",
                   help="evaluation record output path (only written with --commit)")
    args = p.parse_args(argv)

    if not os.path.exists(args.config):
        print(f"ERROR: config not found: {args.config}", file=sys.stderr)
        return 2

    if args.ai_adapter == "mock":
        adapter = mock_adapter
    else:
        try:
            adapter = load_real_adapter(args.adapter_spec)
        except Exception as exc:  # noqa: BLE001 — surface adapter wiring errors clearly
            print(f"ERROR loading real adapter: {exc}", file=sys.stderr)
            return 2

    scenarios = load_scenarios(args)
    if not scenarios:
        print("ERROR: no scenarios found.", file=sys.stderr)
        return 2

    results = [run_scenario(s, adapter) for s in scenarios]
    passed = sum(1 for r in results if r["pass"])
    total = len(results)
    pass_rate = passed / total if total else 0.0
    critical_fail = any(r["critical"] and not r["pass"] for r in results)
    gate_met = (pass_rate >= args.gate_passrate) and not critical_fail

    mode = "COMMIT" if args.commit else "DRY-RUN"
    print(f"[{mode}] AI evaluation via '{args.ai_adapter}' adapter over {total} scenario(s)")
    for r in results:
        flag = "PASS" if r["pass"] else "FAIL"
        crit = " [CRITICAL]" if r["critical"] else ""
        print(f"  {flag}{crit}  {r['scenario']}  "
              f"({r['points_matched']}/{r['points_total']} points"
              f"{', UNACCEPTABLE' if r['unacceptable_seen'] else ''})")
    print(f"  pass-rate: {pass_rate:.2f}  gate: {args.gate_passrate:.2f}  "
          f"critical-fail: {critical_fail}")
    print(f"  SCENARIO GATE: {'MET' if gate_met else 'NOT MET'}")

    if args.commit:
        record = {
            "artifact_name": "Twin Evaluation Record - Pilot - v1",
            "generated_at": _now(),
            "config": args.config,
            "ai_adapter": args.ai_adapter,
            "scenario_count": total,
            "passed": passed,
            "pass_rate": round(pass_rate, 4),
            "gate_passrate": args.gate_passrate,
            "critical_fail": critical_fail,
            "gate_met": gate_met,
            "results": results,
            "note": "Passing the twin informs, but does not replace, the human decision to authorize "
                    "production use. Synthetic data only; isolated non-production run.",
        }
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(record, fh, indent=2)
        print(f"Wrote evaluation record -> {args.out}")
    else:
        print("Dry-run: no evaluation record written. Re-run with --commit to persist.")

    return 0 if gate_met else 1


if __name__ == "__main__":
    sys.exit(main())
