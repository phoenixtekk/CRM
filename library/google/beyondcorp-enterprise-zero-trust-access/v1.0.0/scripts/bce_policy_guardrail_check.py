#!/usr/bin/env python3
# bce_policy_guardrail_check.py — zero-trust guardrail / posture check (read-only gate)
#
# PURPOSE: Flag weak BeyondCorp Enterprise configuration that undermines zero trust: IAP bindings with
#          no access-level condition, over-broad principals (allUsers/allAuthenticatedUsers), access
#          levels lacking a device/context condition, and SSH firewall rules not scoped to the IAP
#          range. READ-ONLY. High-severity findings are meant to BLOCK VPN retirement (Stage 5).
# HOW TO RUN: python bce_policy_guardrail_check.py --project <P> --policy <ACM_POLICY_ID>
#             [--backend-service <BES> ...] [--json]
#             (Python 3.10+, gcloud on PATH, ADC/`gcloud auth`; see --help)
# EXPECTED RESULTS: A findings list with severities. Exit 0 = clean (no HIGH findings, gate passes);
#          exit 1 = at least one HIGH finding (gate fails — remediate before Stage 5).

import argparse
import json
import shutil
import subprocess
import sys

IAP_TCP_FORWARDING_RANGE = "35.235.240.0/20"
BROAD_RANGES = {"0.0.0.0/0", "::/0"}
BROAD_PRINCIPALS = {"allUsers", "allAuthenticatedUsers"}


def have_gcloud():
    if not shutil.which("gcloud"):
        print("ERROR: gcloud CLI not found on PATH.", file=sys.stderr)
        sys.exit(2)


def gcloud_json(args):
    out = subprocess.run(["gcloud"] + args + ["--format=json"], capture_output=True, text=True)
    if out.returncode != 0:
        print(f"  WARN: {' '.join(args)} -> {out.stderr.strip().splitlines()[:1]}", file=sys.stderr)
        return None
    try:
        return json.loads(out.stdout or "null")
    except json.JSONDecodeError:
        return None


def add(findings, severity, code, message):
    findings.append({"severity": severity, "code": code, "message": message})
    print(f"  [{severity}] {code}: {message}")


def check_access_levels(findings, policy):
    print("== Access levels ==")
    levels = gcloud_json(["access-context-manager", "levels", "list", f"--policy={policy}"])
    if levels is None:
        add(findings, "MEDIUM", "ACM_UNREADABLE",
            "Could not read access levels — verify policyAdmin/reader access.")
        return
    if not levels:
        add(findings, "HIGH", "ACM_NO_LEVELS",
            "No access levels defined — IAP bindings cannot be context-conditioned.")
        return
    for lv in levels:
        blob = json.dumps(lv)
        if "devicePolicy" not in blob and "custom" not in lv:
            add(findings, "MEDIUM", "ACM_NO_DEVICE",
                f"Access level '{lv.get('title')}' has no device condition (identity/network only).")
        else:
            print(f"  OK: access level '{lv.get('title')}' includes a device/custom condition.")


def check_iap_bindings(findings, project, backend_services):
    print("\n== IAP bindings ==")
    if not backend_services:
        print("  (no --backend-service given; skipping web IAP binding checks)")
        return
    for bes in backend_services:
        policy = gcloud_json(["iap", "web", "get-iam-policy", f"--project={project}",
                              "--resource-type=backend-services", f"--service={bes}"])
        if not policy:
            add(findings, "MEDIUM", "IAP_POLICY_UNREADABLE",
                f"Could not read IAP IAM policy for '{bes}'.")
            continue
        for b in policy.get("bindings", []):
            role = b.get("role", "")
            members = b.get("members", [])
            broad = set(members) & BROAD_PRINCIPALS
            if broad and role.startswith("roles/iap."):
                add(findings, "HIGH", "IAP_BROAD_PRINCIPAL",
                    f"'{bes}': over-broad principal {sorted(broad)} on {role}.")
            if role in ("roles/iap.httpsResourceAccessor", "roles/iap.tunnelResourceAccessor"):
                if not b.get("condition"):
                    add(findings, "HIGH", "IAP_NO_CONDITION",
                        f"'{bes}': {role} binding has NO access-level condition (identity-only, "
                        f"not zero trust).")
                else:
                    print(f"  OK: '{bes}' {role} is context-conditioned "
                          f"('{b['condition'].get('title')}').")


def check_ssh_firewalls(findings, project):
    print("\n== SSH firewall scoping ==")
    rules = gcloud_json(["compute", "firewall-rules", "list", f"--project={project}"])
    if not rules:
        print("  (no firewall rules read)")
        return
    for r in rules:
        if r.get("direction") != "INGRESS" or r.get("disabled"):
            continue
        ports = set()
        for a in r.get("allowed", []):
            ports.update(a.get("ports", []) or [])
        sources = set(r.get("sourceRanges", []))
        if "22" in ports:
            if sources & BROAD_RANGES:
                add(findings, "HIGH", "SSH_BROAD",
                    f"Rule '{r.get('name')}' allows SSH from {sorted(sources & BROAD_RANGES)} "
                    f"— should be scoped to {IAP_TCP_FORWARDING_RANGE}.")
            elif IAP_TCP_FORWARDING_RANGE in sources:
                print(f"  OK: rule '{r.get('name')}' scopes SSH to the IAP range.")


def main():
    ap = argparse.ArgumentParser(description="Zero-trust guardrail/posture check (read-only gate).")
    ap.add_argument("--project", required=True)
    ap.add_argument("--policy", required=True, help="Access Context Manager policy ID")
    ap.add_argument("--backend-service", action="append", default=[],
                    help="IAP-protected backend service to check (repeatable)")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    have_gcloud()

    print(f"Zero-trust guardrail check (READ-ONLY) — project={args.project} policy={args.policy}\n")
    findings = []
    check_access_levels(findings, args.policy)
    check_iap_bindings(findings, args.project, args.backend_service)
    check_ssh_firewalls(findings, args.project)

    highs = [f for f in findings if f["severity"] == "HIGH"]
    print("\n== Result ==")
    print(f"  findings: {len(findings)} total, {len(highs)} HIGH")
    verdict = "FAIL (block VPN retirement)" if highs else "PASS (guardrail clean)"
    print(f"  verdict: {verdict}")
    if args.json:
        print("\nJSON:\n" + json.dumps({"findings": findings, "high": len(highs)}, indent=2))
    return 1 if highs else 0


if __name__ == "__main__":
    sys.exit(main())
