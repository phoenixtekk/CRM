#!/usr/bin/env python3
# scenario_runner.py — run scenarios against a Model Under Test adapter and record metrics.
#
# PURPOSE: Load an Evaluation Scenario Suite + Metric Definition Set, call the model through an
#          abstract Model Under Test (MUT) adapter, compute per-scenario metrics, and write an
#          "Evaluation Run" record. Dry-run by default; --commit persists. Model is plugged via an
#          abstract predict() interface — NO vendor SDK is wrapped here (see the vendor's docs).
# HOW TO RUN: python scenario_runner.py --config harness/config.pilot.json \
#               --scenarios scenarios.json --metrics metrics.json \
#               --adapter module:predict [--commit]   (Python 3.10+; see --help)
# EXPECTED RESULTS: A run summary on stdout; with --commit, a Run Record JSON in the results store.
#                   Exit 0 if all scenarios executed, 1 if any scenario errored. Never writes real PHI.

import argparse
import datetime as dt
import importlib
import json
import os
import statistics
import sys


def load_json(path):
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def resolve_adapter(spec):
    """spec is 'module:function' or 'module:Class.method'. Returns a callable predict(input)->dict.

    The adapter is the abstract Model Under Test contract. A built-in 'fixture' adapter is provided
    for testing the harness without any real model. Real adapters wrap whatever the model exposes;
    for a vendor framework, wrap that vendor's DOCUMENTED client call (verify against your version).
    """
    if spec == "fixture":
        return _fixture_predict
    if ":" not in spec:
        raise ValueError("adapter must be 'module:callable' or the built-in 'fixture'")
    mod_name, attr = spec.split(":", 1)
    mod = importlib.import_module(mod_name)
    obj = mod
    for part in attr.split("."):
        obj = getattr(obj, part)
    if not callable(obj):
        raise ValueError(f"adapter target '{spec}' is not callable")
    return obj


def _fixture_predict(scenario_input):
    """Deterministic stub: echoes an 'expected' hint if present so metric wiring can be validated
    without a real model. Purely for harness self-test; contains no real data."""
    expected = ""
    if isinstance(scenario_input, dict):
        expected = str(scenario_input.get("_fixture_answer", ""))
    return {"output": expected, "latency_ms": 1.0, "safety_flags": []}


# ---- metric implementations (standard-library only) ------------------------------------------------

def _norm(s):
    return " ".join(str(s).strip().lower().split())


def metric_normalized_match(output, expected):
    return 1.0 if _norm(output) == _norm(expected) else 0.0


def metric_contains(output, expected):
    return 1.0 if _norm(expected) in _norm(output) else 0.0


PER_SCENARIO_METRICS = {
    "normalized_match": metric_normalized_match,
    "contains": metric_contains,
}


def aggregate(metric_name, values):
    if not values:
        return None
    if metric_name.endswith("_p95"):
        vals = sorted(values)
        idx = min(len(vals) - 1, int(round(0.95 * (len(vals) - 1))))
        return vals[idx]
    if metric_name in ("safety_flag_rate",):
        return sum(values) / len(values)
    # default: mean
    return statistics.fmean(values)


def run(config, scenarios, metrics_def, adapter):
    seed_note = config.get("seeds")
    per_scenario = []
    errored = 0
    latencies = []
    safety_flags_hits = []

    metric_series = {m: [] for m in metrics_def.get("per_scenario_metrics", [])}

    for sc in scenarios.get("scenarios", []):
        sid = sc.get("id", "?")
        try:
            result = adapter(sc.get("input"))
            output = result.get("output", "")
            latency = float(result.get("latency_ms", 0.0))
            flags = result.get("safety_flags", []) or []
            latencies.append(latency)
            safety_flags_hits.append(1.0 if flags else 0.0)

            scored = {}
            expected = sc.get("expected", "")
            for m in metrics_def.get("per_scenario_metrics", []):
                fn = PER_SCENARIO_METRICS.get(m)
                if fn is None:
                    scored[m] = None
                    continue
                val = fn(output, expected)
                scored[m] = val
                metric_series[m].append(val)

            per_scenario.append(
                {
                    "id": sid,
                    "status": "ok",
                    "group": sc.get("group"),
                    "latency_ms": latency,
                    "safety_flags": flags,
                    "metrics": scored,
                }
            )
        except Exception as exc:  # a scenario failing to run is a coverage failure, not a crash
            errored += 1
            per_scenario.append({"id": sid, "status": "error", "error": str(exc)})

    aggregates = {}
    for m, series in metric_series.items():
        aggregates[m] = aggregate(m, series)
    if latencies:
        aggregates["latency_ms_p95"] = aggregate("latency_ms_p95", latencies)
    aggregates["safety_flag_rate"] = aggregate("safety_flag_rate", safety_flags_hits) if safety_flags_hits else 0.0

    return {
        "scenario_count": len(scenarios.get("scenarios", [])),
        "executed": len(per_scenario) - errored,
        "errored": errored,
        "aggregates": aggregates,
        "per_scenario": per_scenario,
        "seeds": seed_note,
    }


def main(argv=None):
    p = argparse.ArgumentParser(description="Run scenarios against a Model Under Test adapter.")
    p.add_argument("--config", required=True, help="Harness config JSON (results path, seeds, versions).")
    p.add_argument("--scenarios", required=True, help="Evaluation Scenario Suite JSON.")
    p.add_argument("--metrics", required=True, help="Metric Definition Set JSON.")
    p.add_argument(
        "--adapter",
        default="fixture",
        help="Model Under Test adapter as 'module:callable', or built-in 'fixture' for self-test.",
    )
    p.add_argument(
        "--commit",
        action="store_true",
        help="Persist the Run Record to the results store. Default is DRY-RUN (prints only).",
    )
    args = p.parse_args(argv)

    config = load_json(args.config)
    scenarios = load_json(args.scenarios)
    metrics_def = load_json(args.metrics)
    adapter = resolve_adapter(args.adapter)

    summary = run(config, scenarios, metrics_def, adapter)
    run_id = "run-" + dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")

    record = {
        "artifact": "Evaluation Run",
        "run_id": run_id,
        "generated_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "scope": config.get("scope", "pilot"),
        "scenario_suite_version": scenarios.get("version"),
        "metric_set_version": metrics_def.get("version"),
        "model_version": config.get("model_version"),
        "adapter": args.adapter,
        "summary": {k: v for k, v in summary.items() if k != "per_scenario"},
        "per_scenario": summary["per_scenario"],
        "note": "Runs on synthetic/twin data in an isolated environment. Never real PHI.",
    }

    print(f"Evaluation Run - {config.get('scope', 'pilot')} - {run_id}")
    print(f"  scenarios: {summary['scenario_count']}  executed: {summary['executed']}  errored: {summary['errored']}")
    for m, v in summary["aggregates"].items():
        print(f"  {m}: {v}")

    if args.commit:
        results_dir = os.path.join(config.get("results_path", "reports"), "runs")
        os.makedirs(results_dir, exist_ok=True)
        out_path = os.path.join(results_dir, f"{run_id}.json")
        with open(out_path, "w", encoding="utf-8") as fh:
            json.dump(record, fh, indent=2)
        print(f"  committed: {out_path}")
    else:
        print("  DRY-RUN: no Run Record written (pass --commit to persist).")

    return 0 if summary["errored"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
