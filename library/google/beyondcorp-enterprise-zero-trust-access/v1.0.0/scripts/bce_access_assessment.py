#!/usr/bin/env python3
# bce_access_assessment.py — read-only BeyondCorp Enterprise zero-trust readiness assessment
#
# PURPOSE: Discover the current access posture before any change — existing Access Context Manager
#          policies/levels, which resources already have IAP enabled, and firewall rules that broadly
#          expose SSH or HTTP(S) (a flat-trust / VPN-dependency signal). READ-ONLY: it never modifies
#          anything; it only runs `gcloud ... list/describe` commands.
# HOW TO RUN: python bce_access_assessment.py --org <ORG_ID> --project <PROJECT_ID> [--json]
#             (Python 3.10+, requires the gcloud CLI on PATH and `gcloud auth login` / ADC; see --help)
# EXPECTED RESULTS: A printed Stage-0 baseline. Findings tagged FLAT-TRUST indicate broad exposure that
#          zero trust should remove (e.g. 0.0.0.0/0 SSH). Exit code 0 always (assessment, not a gate).

import argparse
import json
import shutil
import subprocess
import sys

# The documented IAP TCP-forwarding source range. Verify against current Google IAP docs.
IAP_TCP_FORWARDING_RANGE = "35.235.240.0/20"
BROAD_RANGES = {"0.0.0.0/0", "::/0"}
SENSITIVE_PORTS = {"22", "3389", "80", "443"}


def run_gcloud(args, dry_note=False):
    """Run a read-only gcloud command and return parsed JSON (or [] on error)."""
    if not shutil.which("gcloud"):
        print("ERROR: gcloud CLI not found on PATH. Install the Google Cloud SDK.", file=sys.stderr)
        sys.exit(2)
    cmd = ["gcloud"] + args + ["--format=json"]
    if dry_note:
        print(f"  [read-only] {' '.join(cmd)}")
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        print(f"  WARN: timed out: {' '.join(cmd)}", file=sys.stderr)
        return []
    if out.returncode != 0:
        print(f"  WARN: command failed ({out.returncode}): {out.stderr.strip().splitlines()[:1]}",
              file=sys.stderr)
        return []
    try:
        return json.loads(out.stdout or "[]")
    except json.JSONDecodeError:
        return []


def assess_access_policies(org_id):
    print("== Access Context Manager policies ==")
    policies = run_gcloud(["access-context-manager", "policies", "list",
                           f"--organization={org_id}"])
    if not policies:
        print("  FLAT-TRUST: no access policy found — access levels cannot be defined yet "
              "(see requirement 2.1).")
        return {"policies": [], "levels": []}
    all_levels = []
    for p in policies:
        pid = p.get("name", "").split("/")[-1]
        print(f"  policy: {p.get('name')}  title={p.get('title')}")
        levels = run_gcloud(["access-context-manager", "levels", "list", f"--policy={pid}"])
        for lv in levels:
            has_device = "devicePolicy" in json.dumps(lv)
            tag = "identity/network-only (no device condition)" if not has_device else "has device condition"
            print(f"    level: {lv.get('title')}  [{tag}]")
            all_levels.append({"title": lv.get("title"), "has_device": has_device})
        if not levels:
            print("    (no access levels defined under this policy)")
    return {"policies": [p.get("name") for p in policies], "levels": all_levels}


def assess_iap_targets(project):
    print("\n== IAP-eligible resources ==")
    findings = []
    backends = run_gcloud(["compute", "backend-services", "list", f"--project={project}"])
    for b in backends:
        iap_on = bool(b.get("iap", {}).get("enabled"))
        state = "IAP ENABLED" if iap_on else "FLAT-TRUST: IAP not enabled"
        print(f"  backend-service: {b.get('name')}  [{state}]")
        findings.append({"backend": b.get("name"), "iap_enabled": iap_on})
    if not backends:
        print("  (no load-balancer backend services in this project)")
    instances = run_gcloud(["compute", "instances", "list", f"--project={project}"])
    print(f"  compute instances: {len(instances)} (candidates for IAP TCP forwarding)")
    return findings


def assess_firewalls(project):
    print("\n== Firewall exposure (flat-trust signals) ==")
    findings = []
    rules = run_gcloud(["compute", "firewall-rules", "list", f"--project={project}"])
    for r in rules:
        if r.get("direction") != "INGRESS" or r.get("disabled"):
            continue
        sources = set(r.get("sourceRanges", []))
        ports = set()
        for allowed in r.get("allowed", []):
            ports.update(allowed.get("ports", []) or [])
        broad = sources & BROAD_RANGES
        sensitive = ports & SENSITIVE_PORTS
        if broad and (sensitive or not ports):
            print(f"  FLAT-TRUST: rule {r.get('name')} allows {sorted(broad)} "
                  f"on ports {sorted(ports) or 'ALL'} — zero trust should remove this.")
            findings.append({"rule": r.get("name"), "sources": sorted(broad),
                             "ports": sorted(ports)})
        elif "22" in ports and IAP_TCP_FORWARDING_RANGE in sources:
            print(f"  OK: rule {r.get('name')} scopes SSH to the IAP range "
                  f"{IAP_TCP_FORWARDING_RANGE}.")
    if not findings:
        print("  No broad SSH/HTTP(S) ingress rules detected.")
    return findings


def main():
    ap = argparse.ArgumentParser(description="Read-only BeyondCorp Enterprise zero-trust assessment.")
    ap.add_argument("--org", required=True, help="GCP Organization ID")
    ap.add_argument("--project", required=True, help="Pilot project ID to assess")
    ap.add_argument("--json", action="store_true", help="Also print a JSON summary at the end")
    args = ap.parse_args()

    print(f"BeyondCorp Enterprise assessment (READ-ONLY) — org={args.org} project={args.project}\n")
    acm = assess_access_policies(args.org)
    iap = assess_iap_targets(args.project)
    fw = assess_firewalls(args.project)

    print("\n== Summary ==")
    print(f"  access levels defined: {len(acm['levels'])}")
    print(f"  backends with IAP on : {sum(1 for f in iap if f['iap_enabled'])}/{len(iap)}")
    print(f"  flat-trust firewall findings: {len(fw)}")
    if args.json:
        print("\nJSON:\n" + json.dumps({"acm": acm, "iap": iap, "firewalls": fw}, indent=2))
    # Read-only assessment always exits 0; the gate is bce_policy_guardrail_check.py.
    return 0


if __name__ == "__main__":
    sys.exit(main())
