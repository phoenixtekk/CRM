#!/usr/bin/env python3
# pod_capacity_planner.py — model AI-delivery pod/squad structure and check capacity
#
# PURPOSE: Reads a pod-topology definition (pods, roles, allocations, demand) and reports whether
#          each pod is staffable and within capacity, flags missing interfaces and single-role
#          points of failure. Read-only: it never writes unless you pass --out.
# HOW TO RUN: python pod_capacity_planner.py --topology topology.json [--out plan.csv]
#             (Python 3.10+; run with no args to emit a sample topology to stdout; see --help)
# EXPECTED RESULTS: A per-pod capacity table on stdout. Exit code 0 = all pods OK; exit code 1 =
#                   one or more pods over capacity or missing a required interface (the fail signal).

import argparse
import json
import sys

REQUIRED_INTERFACES = ("intake", "handoff", "escalation")
CORE_ROLES = ("data_platform_engineer", "ml_ai_engineer", "qa_validation", "privacy_liaison",
              "pod_lead")


def sample_topology() -> dict:
    """A minimal, illustrative topology (no real names) used when no --topology is given."""
    return {
        "program": "Program",
        "capacity_unit": "person-weeks-per-sprint",
        "pods": [
            {
                "name": "Synthetic-EHR Delivery Pod",
                "owns": "synthetic EHR generation slice",
                "interfaces": ["intake", "handoff", "escalation"],
                "roles": {
                    "data_platform_engineer": 2, "ml_ai_engineer": 1, "qa_validation": 1,
                    "privacy_liaison": 1, "pod_lead": 1, "product_clinical_sme": 1,
                },
                "capacity": 12.0,
                "demand": 10.0,
            },
            {
                "name": "Twin-Validation Pod",
                "owns": "fidelity/privacy validation slice",
                "interfaces": ["intake", "handoff"],  # missing escalation -> will be flagged
                "roles": {
                    "data_platform_engineer": 1, "ml_ai_engineer": 1, "qa_validation": 2,
                    "privacy_liaison": 1, "pod_lead": 1,
                },
                "capacity": 8.0,
                "demand": 9.5,  # over capacity -> will be flagged
            },
        ],
    }


def analyze_pod(pod: dict) -> dict:
    name = pod.get("name", "<unnamed>")
    interfaces = set(pod.get("interfaces", []))
    roles = pod.get("roles", {}) or {}
    capacity = float(pod.get("capacity", 0.0))
    demand = float(pod.get("demand", 0.0))

    missing_interfaces = [i for i in REQUIRED_INTERFACES if i not in interfaces]
    missing_roles = [r for r in CORE_ROLES if roles.get(r, 0) < 1]
    # single point of failure: a core role staffed by exactly one person
    spof_roles = [r for r in CORE_ROLES if roles.get(r, 0) == 1]

    over_capacity = demand > capacity
    utilization = (demand / capacity) if capacity > 0 else float("inf")

    ok = not missing_interfaces and not missing_roles and not over_capacity
    return {
        "pod": name,
        "capacity": capacity,
        "demand": demand,
        "utilization_pct": round(utilization * 100, 1) if capacity > 0 else None,
        "over_capacity": over_capacity,
        "missing_interfaces": missing_interfaces,
        "missing_core_roles": missing_roles,
        "spof_core_roles": spof_roles,
        "ok": ok,
    }


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description="Model AI-delivery pods/squads and check capacity.")
    p.add_argument("--topology", help="Path to topology JSON. If omitted, a sample is used.")
    p.add_argument("--out", help="Optional CSV path to write the capacity plan (opt-in write).")
    p.add_argument("--emit-sample", action="store_true",
                   help="Print a sample topology JSON to stdout and exit.")
    args = p.parse_args(argv)

    if args.emit_sample:
        print(json.dumps(sample_topology(), indent=2))
        return 0

    if args.topology:
        try:
            with open(args.topology, "r", encoding="utf-8") as fh:
                topo = json.load(fh)
        except (OSError, json.JSONDecodeError) as e:
            print(f"ERROR: could not read topology: {e}", file=sys.stderr)
            return 2
    else:
        print("NOTE: no --topology given; using built-in sample "
              "(pass --emit-sample to see it).", file=sys.stderr)
        topo = sample_topology()

    rows = [analyze_pod(pod) for pod in topo.get("pods", [])]
    if not rows:
        print("ERROR: topology has no pods.", file=sys.stderr)
        return 2

    unit = topo.get("capacity_unit", "capacity-units")
    print(f"Pod capacity plan — program '{topo.get('program', 'Program')}' (unit: {unit})")
    print("-" * 72)
    any_fail = False
    for r in rows:
        status = "OK" if r["ok"] else "ATTENTION"
        if not r["ok"]:
            any_fail = True
        print(f"[{status}] {r['pod']}")
        print(f"    demand {r['demand']} / capacity {r['capacity']}  "
              f"(util {r['utilization_pct']}%)  over_capacity={r['over_capacity']}")
        if r["missing_interfaces"]:
            print(f"    MISSING interfaces: {', '.join(r['missing_interfaces'])}")
        if r["missing_core_roles"]:
            print(f"    MISSING core roles: {', '.join(r['missing_core_roles'])}")
        if r["spof_core_roles"]:
            print(f"    single-person core roles (SPOF risk): "
                  f"{', '.join(r['spof_core_roles'])}")

    if args.out:
        try:
            import csv
            fields = ["pod", "capacity", "demand", "utilization_pct", "over_capacity",
                      "missing_interfaces", "missing_core_roles", "spof_core_roles", "ok"]
            with open(args.out, "w", newline="", encoding="utf-8") as fh:
                w = csv.DictWriter(fh, fieldnames=fields)
                w.writeheader()
                for r in rows:
                    row = dict(r)
                    for k in ("missing_interfaces", "missing_core_roles", "spof_core_roles"):
                        row[k] = ";".join(row[k])
                    w.writerow(row)
            print(f"\nWrote capacity plan to {args.out}")
        except OSError as e:
            print(f"ERROR: could not write --out: {e}", file=sys.stderr)
            return 2

    print("-" * 72)
    if any_fail:
        print("RESULT: FAIL — at least one pod needs attention (see ATTENTION above).")
        return 1
    print("RESULT: PASS — all pods staffable and within capacity.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
