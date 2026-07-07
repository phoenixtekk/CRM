#!/usr/bin/env python3
# wave-batch-builder.py — group in-scope users/sites into migration waves and compute a throttling plan.
#
# PURPOSE: From the source baseline, build named migration-wave batch files (Migration Wave - <Scope> - <Stage>)
#          and a throttling plan (per-node concurrency + request-rate ceilings) sized to stay under source/target
#          API limits. Dry-run by default: writes local batch/plan files only; --calibrate retunes from pilot results.
# HOW TO RUN: python wave-batch-builder.py --dry-run --baseline baseline-source.json --wave-size 250 --out waves/
#             python wave-batch-builder.py --calibrate --from validate-pilot/ --out waves/   (Python 3.10+)
# EXPECTED RESULTS: Writes per-wave CSV batches + throttling-plan.json to --out and prints a wave/throttling summary.
#                   No network calls; no writes to Microsoft 365 or Google.

import argparse
import json
import math
import os
import sys

# Conservative starting ceilings. Verify current API limits for your version/tenant and calibrate from the pilot.
DEFAULT_CONCURRENCY_PER_NODE = 8      # parallel transfer threads per worker node
DEFAULT_GRAPH_RPS = 12               # Microsoft Graph requests/sec ceiling (conservative)
DEFAULT_GOOGLE_RPS = 10              # Google API requests/sec ceiling (conservative)


def parse_args():
    p = argparse.ArgumentParser(description="Build migration-wave batches + a throttling plan (dry-run).")
    mode = p.add_mutually_exclusive_group(required=True)
    mode.add_argument("--dry-run", action="store_true", help="Build waves from the baseline (default safe mode).")
    mode.add_argument("--calibrate", action="store_true", help="Retune throttling from pilot validation output.")
    p.add_argument("--baseline", help="baseline-source.json from node-sizing-assessment.py (--dry-run).")
    p.add_argument("--from", dest="from_dir", help="Pilot validation output dir (--calibrate).")
    p.add_argument("--wave-size", type=int, default=250, help="Users per wave.")
    p.add_argument("--stage", default="Pilot", help="Stage label for wave names (Pilot, Prod, Delta).")
    p.add_argument("--nodes", type=int, default=0, help="Worker nodes (default: from baseline sizing).")
    p.add_argument("--out", default="waves/", help="Output directory.")
    return p.parse_args()


def throttling_plan(nodes):
    nodes = max(1, nodes)
    return {
        "worker_nodes": nodes,
        "concurrency_per_node": DEFAULT_CONCURRENCY_PER_NODE,
        "total_concurrency": nodes * DEFAULT_CONCURRENCY_PER_NODE,
        "graph_rps_ceiling": DEFAULT_GRAPH_RPS,
        "google_rps_ceiling": DEFAULT_GOOGLE_RPS,
        "note": "Conservative starting ceilings. Verify current source/target API limits for your version and "
                "calibrate from the pilot (--calibrate). Watch live with migration-health-check.py --watch.",
    }


def build_waves(args):
    if not args.baseline or not os.path.isfile(args.baseline):
        sys.exit("--dry-run needs a valid --baseline baseline-source.json (from node-sizing-assessment.py).")
    with open(args.baseline, encoding="utf-8") as f:
        baseline = json.load(f)

    user_count = baseline["inventory"]["mailboxes"]["count"]
    nodes = args.nodes or baseline["sizing"]["recommended_worker_nodes"]
    n_waves = max(1, math.ceil(user_count / max(args.wave_size, 1)))
    os.makedirs(args.out, exist_ok=True)

    manifest = []
    for i in range(1, n_waves + 1):
        start = (i - 1) * args.wave_size + 1
        end = min(i * args.wave_size, user_count)
        name = f"Migration Wave - Group{i:02d} - {args.stage}"
        path = os.path.join(args.out, f"wave-{i:02d}-{args.stage.lower()}.csv")
        with open(path, "w", encoding="utf-8") as f:
            f.write("wave_name,user_index_start,user_index_end,user_count\n")
            f.write(f"{name},{start},{end},{end - start + 1}\n")
        manifest.append({"wave_name": name, "file": os.path.basename(path),
                         "user_count": end - start + 1})

    plan = throttling_plan(nodes)
    with open(os.path.join(args.out, "throttling-plan.json"), "w", encoding="utf-8") as f:
        json.dump(plan, f, indent=2)
    with open(os.path.join(args.out, "wave-manifest.json"), "w", encoding="utf-8") as f:
        json.dump({"waves": manifest, "throttling": plan}, f, indent=2)

    print(f"[dry-run] {n_waves} waves of up to {args.wave_size} users -> {args.out}")
    for m in manifest[:5]:
        print(f"  {m['wave_name']:<40} {m['user_count']:>5} users")
    if n_waves > 5:
        print(f"  ... and {n_waves - 5} more")
    print(f"Throttling: {plan['worker_nodes']} nodes x {plan['concurrency_per_node']} = "
          f"{plan['total_concurrency']} concurrent; Graph<= {plan['graph_rps_ceiling']} rps, "
          f"Google<= {plan['google_rps_ceiling']} rps (conservative — calibrate from pilot).")
    return 0


def calibrate(args):
    if not args.from_dir or not os.path.isdir(args.from_dir):
        sys.exit("--calibrate needs --from <pilot validation output dir>.")
    metrics_path = os.path.join(args.from_dir, "pilot-metrics.json")
    if not os.path.isfile(metrics_path):
        print(f"No pilot-metrics.json in {args.from_dir}; keeping conservative defaults.")
        observed = {}
    else:
        with open(metrics_path, encoding="utf-8") as f:
            observed = json.load(f)
    # If the pilot ran with no sustained throttling and error rate under threshold, raise ceilings modestly.
    factor = 1.25 if observed.get("throttling_events", 1) == 0 and observed.get("error_rate", 1.0) < 0.01 else 1.0
    plan = throttling_plan(args.nodes or 1)
    plan["graph_rps_ceiling"] = round(plan["graph_rps_ceiling"] * factor)
    plan["google_rps_ceiling"] = round(plan["google_rps_ceiling"] * factor)
    plan["calibration_factor"] = factor
    os.makedirs(args.out, exist_ok=True)
    with open(os.path.join(args.out, "throttling-plan.json"), "w", encoding="utf-8") as f:
        json.dump(plan, f, indent=2)
    print(f"Calibrated throttling (factor {factor}): Graph<= {plan['graph_rps_ceiling']} rps, "
          f"Google<= {plan['google_rps_ceiling']} rps. Wrote throttling-plan.json -> {args.out}")
    return 0


def main():
    args = parse_args()
    sys.exit(calibrate(args) if args.calibrate else build_waves(args))


if __name__ == "__main__":
    main()
