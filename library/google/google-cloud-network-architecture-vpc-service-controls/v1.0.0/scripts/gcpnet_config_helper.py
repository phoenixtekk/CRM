#!/usr/bin/env python3
# gcpnet_config_helper.py — scope/config helper: emit expected config & check live drift (read-only)
#
# PURPOSE: Single source of the intended network artifact names/scope for this solution. Emits a
#          starter config (network, subnet, firewall policies, access level, perimeter names) and, with
#          --check, compares the live environment to that intent and reports drift. READ-ONLY — never
#          mutates; safe to run any time.
# HOW TO RUN: python gcpnet_config_helper.py --emit                       # print a config template
#             python gcpnet_config_helper.py --org ORG --host-project HOST --policy POLICY_ID --check
#             (Python 3.10+, gcloud auth / ADC; see --help.)
# EXPECTED RESULTS: With --emit, a YAML-ish config template to fill in. With --check, per-artifact
#          PRESENT/MISSING lines and a "NO DRIFT" / "DRIFT" verdict.

import argparse
import json
import shutil
import subprocess
import sys

# The solution's canonical artifact names (must match the Implementation guide).
EXPECTED = {
    "network": "vpc-prod-shared",
    "subnet": "sn-prod-use4",
    "hierarchical_firewall_policy": "HFW – Org – Baseline",
    "network_firewall_policy": "NFW – Prod – Workload",
    "psc_endpoint": "psc-googleapis",
    "access_level_title": "Access Level – Corp-Managed – v1",
    "perimeter_title": "Perimeter – Prod – v1",
}


def gcloud_json(args):
    exe = shutil.which("gcloud")
    if not exe:
        print("ERROR: gcloud not found on PATH.", file=sys.stderr)
        sys.exit(2)
    res = subprocess.run([exe] + args + ["--format=json"], capture_output=True, text=True, timeout=120)
    if res.returncode != 0:
        return []
    try:
        return json.loads(res.stdout or "[]")
    except json.JSONDecodeError:
        return []


def emit():
    print("# GCPNET intended configuration — fill in the CAPITALIZED values, keep artifact names.")
    print("org_id: ORG_ID")
    print("host_project: net-host-prod            # Net-Host – Prod – Shared-VPC")
    print("region: us-east4")
    print("ip_plan:")
    print("  primary: 10.20.0.0/20")
    print("  pods: 10.21.0.0/16        # only where GKE is in scope")
    print("  services: 10.22.0.0/20")
    print("artifacts:")
    for k, v in EXPECTED.items():
        print(f"  {k}: \"{v}\"")
    print("restricted_services:        # VERIFY current VPC-SC coverage per service in your org")
    print("  - storage.googleapis.com")
    print("  - bigquery.googleapis.com")
    print("  - aiplatform.googleapis.com   # Vertex AI / Gemini — confirm coverage in-tenant")


def check(org, host_project, policy):
    print("=" * 64)
    print("CONFIG DRIFT CHECK (read-only)")
    print("=" * 64)
    drift = 0

    nets = {n.get("name") for n in gcloud_json(
        ["compute", "networks", "list", f"--project={host_project}"])}
    drift += _line("network", EXPECTED["network"], EXPECTED["network"] in nets)

    subs = {s.get("name") for s in gcloud_json(
        ["compute", "networks", "subnets", "list", f"--project={host_project}"])}
    drift += _line("subnet", EXPECTED["subnet"], EXPECTED["subnet"] in subs)

    fwd = {f.get("name") for f in gcloud_json(
        ["compute", "forwarding-rules", "list", f"--project={host_project}", "--global"])}
    drift += _line("psc_endpoint", EXPECTED["psc_endpoint"], EXPECTED["psc_endpoint"] in fwd,
                   soft=True)

    if policy:
        levels = {l.get("title") for l in gcloud_json(
            ["access-context-manager", "levels", "list", f"--policy={policy}"])}
        drift += _line("access_level", EXPECTED["access_level_title"],
                       EXPECTED["access_level_title"] in levels)
        perims = {p.get("title") for p in gcloud_json(
            ["access-context-manager", "perimeters", "list", f"--policy={policy}"])}
        drift += _line("perimeter", EXPECTED["perimeter_title"],
                       EXPECTED["perimeter_title"] in perims)
    else:
        print("  (no --policy given; skipped access level + perimeter checks)")

    print("-" * 64)
    print("NO DRIFT — live config matches intent." if drift == 0
          else f"DRIFT — {drift} expected artifact(s) missing/renamed. Reconcile before expanding.")
    return drift


def _line(label, name, present, soft=False):
    tag = "PRESENT" if present else ("MISSING(optional)" if soft else "MISSING")
    print(f"  [{label}] '{name}': {tag}")
    return 0 if present or soft else 1


def main():
    ap = argparse.ArgumentParser(description="Scope/config helper + drift check (read-only).")
    ap.add_argument("--emit", action="store_true", help="Print a config template and exit.")
    ap.add_argument("--check", action="store_true", help="Check live environment for drift.")
    ap.add_argument("--org", help="Organization ID.")
    ap.add_argument("--host-project", help="Shared VPC host project ID (for --check).")
    ap.add_argument("--policy", help="Access Context Manager policy ID (for --check).")
    args = ap.parse_args()

    if args.emit and not args.check:
        emit()
        return
    if args.check:
        if not args.host_project:
            ap.error("--check requires --host-project (and ideally --policy).")
        sys.exit(1 if check(args.org, args.host_project, args.policy) else 0)
    emit()  # default action


if __name__ == "__main__":
    main()
