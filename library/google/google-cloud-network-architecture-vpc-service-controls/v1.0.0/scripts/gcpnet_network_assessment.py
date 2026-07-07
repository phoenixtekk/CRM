#!/usr/bin/env python3
# gcpnet_network_assessment.py — read-only Google Cloud network exposure assessment
#
# PURPOSE: Inventory VPCs, subnets, Private Google Access, external IPs, permissive firewall rules,
#          and existing VPC Service Controls perimeters for a project/org, to baseline exposure
#          before designing the Shared VPC + perimeters. READ-ONLY — never mutates anything.
# HOW TO RUN: python gcpnet_network_assessment.py --project PROJECT_ID [--org ORG_ID] [--json out.json]
#             (Python 3.10+, gcloud auth / ADC; uses the gcloud CLI. See --help.)
# EXPECTED RESULTS: A printed exposure summary plus optional JSON. Flags subnets WITHOUT Private
#          Google Access, 0.0.0.0/0 firewall allows, external IPs, and whether any perimeter exists.

import argparse
import json
import shutil
import subprocess
import sys


def gcloud_json(args):
    """Run a gcloud command returning JSON; return [] on any failure (read-only, tolerant)."""
    exe = shutil.which("gcloud")
    if not exe:
        print("ERROR: gcloud not found on PATH. Install the Google Cloud SDK.", file=sys.stderr)
        sys.exit(2)
    cmd = [exe] + args + ["--format=json"]
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        print(f"WARN: timed out: {' '.join(args)}", file=sys.stderr)
        return []
    if out.returncode != 0:
        print(f"WARN: gcloud failed ({' '.join(args)}): {out.stderr.strip()}", file=sys.stderr)
        return []
    try:
        return json.loads(out.stdout or "[]")
    except json.JSONDecodeError:
        return []


def assess(project, org):
    findings = {"project": project, "org": org, "networks": [], "subnets_without_pga": [],
                "open_egress_or_ingress": [], "external_ips": [], "perimeters": [], "notes": []}

    networks = gcloud_json(["compute", "networks", "list", f"--project={project}"])
    findings["networks"] = [n.get("name") for n in networks]

    subnets = gcloud_json(["compute", "networks", "subnets", "list", f"--project={project}"])
    for s in subnets:
        if not s.get("privateIpGoogleAccess", False):
            findings["subnets_without_pga"].append(
                {"name": s.get("name"), "region": s.get("region", "").split("/")[-1]})

    fw = gcloud_json(["compute", "firewall-rules", "list", f"--project={project}"])
    for r in fw:
        ranges = r.get("sourceRanges", []) + r.get("destinationRanges", [])
        if "0.0.0.0/0" in ranges:
            findings["open_egress_or_ingress"].append(
                {"name": r.get("name"), "direction": r.get("direction"), "ranges": ranges})

    addrs = gcloud_json(["compute", "addresses", "list", f"--project={project}"])
    for a in addrs:
        if a.get("addressType") == "EXTERNAL":
            findings["external_ips"].append({"name": a.get("name"), "address": a.get("address")})

    if org:
        policies = gcloud_json(["access-context-manager", "policies", "list", f"--organization={org}"])
        for p in policies:
            pol = p.get("name", "").split("/")[-1]
            perims = gcloud_json(["access-context-manager", "perimeters", "list", f"--policy={pol}"])
            for per in perims:
                findings["perimeters"].append(per.get("title") or per.get("name"))
        if not findings["perimeters"]:
            findings["notes"].append("No VPC Service Controls perimeter found — exfiltration is NOT "
                                     "bounded at the API layer yet.")
    else:
        findings["notes"].append("No --org supplied; skipped VPC-SC perimeter inventory.")

    return findings


def print_summary(f):
    print("=" * 68)
    print(f"NETWORK EXPOSURE ASSESSMENT — project={f['project']} org={f['org']}")
    print("=" * 68)
    print(f"VPC networks:                {', '.join(f['networks']) or '(none)'}")
    print(f"Subnets WITHOUT Private Google Access: {len(f['subnets_without_pga'])}")
    for s in f["subnets_without_pga"]:
        print(f"    - {s['name']} ({s['region']})  <- enable Private Google Access")
    print(f"Firewall rules touching 0.0.0.0/0:    {len(f['open_egress_or_ingress'])}")
    for r in f["open_egress_or_ingress"]:
        print(f"    - {r['name']} [{r['direction']}] {r['ranges']}")
    print(f"External IP addresses in use:         {len(f['external_ips'])}")
    print(f"VPC-SC perimeters:          {', '.join(f['perimeters']) or '(none)'}")
    for n in f["notes"]:
        print(f"NOTE: {n}")
    print("-" * 68)
    risk = (len(f["subnets_without_pga"]) + len(f["open_egress_or_ingress"])
            + (0 if f["perimeters"] else 1))
    print(f"EXPOSURE SIGNALS: {risk}  (0 = private + bounded; higher = more to remediate)")
    print("=" * 68)


def main():
    ap = argparse.ArgumentParser(description="Read-only Google Cloud network exposure assessment.")
    ap.add_argument("--project", required=True, help="Target project ID to assess.")
    ap.add_argument("--org", help="Organization ID (for VPC-SC perimeter inventory).")
    ap.add_argument("--json", help="Write full findings to this JSON file.")
    args = ap.parse_args()

    findings = assess(args.project, args.org)
    print_summary(findings)
    if args.json:
        with open(args.json, "w", encoding="utf-8") as fh:
            json.dump(findings, fh, indent=2)
        print(f"Wrote {args.json}")


if __name__ == "__main__":
    main()
