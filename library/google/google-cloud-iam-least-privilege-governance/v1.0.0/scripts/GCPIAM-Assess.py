#!/usr/bin/env python3
# GCPIAM-Assess.py — read-only Cloud IAM posture assessment (primitive roles, SA keys, external principals, role sprawl)
#
# PURPOSE: Inventory the current IAM posture at an Organization, folder, or project scope. Read-only:
#          it never modifies IAM. Flags primitive-role grants, user-managed (exportable) service-account
#          keys, external principals, and direct user (non-group) bindings, and writes a baseline JSON
#          used for rollback and validation.
# HOW TO RUN: python GCPIAM-Assess.py --organization ORG_ID [--folder FID] [--project PID]
#             [--only primitive-roles|user-bindings|keys|external] [--out iam-baseline.json]
#             (Python 3.10+, gcloud on PATH, ADC via `gcloud auth application-default login`; see --help)
# EXPECTED RESULTS: A printed summary plus (optionally) a JSON baseline. Pass = the findings you expect;
#                   any primitive grant / user-managed key / external principal is a finding to remediate.
#
# Uses the `gcloud` CLI via subprocess (no extra pip installs). No credentials, keys, or secrets in code —
# authentication is whatever ADC / gcloud is logged in as.

import argparse
import json
import subprocess
import sys

PRIMITIVE_ROLES = {"roles/owner", "roles/editor"}


def run_gcloud(args):
    """Run a gcloud command and return parsed JSON stdout, or exit with a clear message."""
    cmd = ["gcloud", *args, "--format=json"]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)
    except FileNotFoundError:
        sys.exit("ERROR: 'gcloud' not found on PATH. Install the Google Cloud SDK and retry.")
    except subprocess.CalledProcessError as exc:
        sys.exit(f"ERROR running: {' '.join(cmd)}\n{exc.stderr.strip()}")
    return json.loads(proc.stdout or "[]")


def resource_flag(args):
    if args.project:
        return ("projects", args.project, ["projects", "get-iam-policy", args.project])
    if args.folder:
        return ("folders", args.folder, ["resource-manager", "folders", "get-iam-policy", args.folder])
    return ("organizations", args.organization,
            ["organizations", "get-iam-policy", args.organization])


def analyze_policy(policy, domains):
    findings = {"primitive_roles": [], "external_principals": [], "user_bindings": []}
    for binding in policy.get("bindings", []):
        role = binding.get("role", "")
        for member in binding.get("members", []):
            if role in PRIMITIVE_ROLES:
                findings["primitive_roles"].append({"member": member, "role": role})
            if member.startswith("user:"):
                findings["user_bindings"].append({"member": member, "role": role})
                addr = member.split(":", 1)[1]
                if domains and not any(addr.endswith("@" + d) or addr.endswith("." + d) for d in domains):
                    findings["external_principals"].append({"member": member, "role": role})
    return findings


def enumerate_keys(project):
    """List user-managed (exportable) SA keys for all service accounts in a project."""
    if not project:
        return []
    keys = []
    accounts = run_gcloud(["iam", "service-accounts", "list", "--project", project])
    for acct in accounts:
        email = acct.get("email")
        acct_keys = run_gcloud(["iam", "service-accounts", "keys", "list",
                                "--iam-account", email, "--managed-by", "user"])
        for k in acct_keys:
            keys.append({"service_account": email, "key": k.get("name"),
                         "valid_after": k.get("validAfterTime")})
    return keys


def main():
    p = argparse.ArgumentParser(description="Read-only Cloud IAM posture assessment.")
    scope = p.add_mutually_exclusive_group(required=True)
    scope.add_argument("--organization", help="Organization ID")
    scope.add_argument("--folder", help="Folder ID")
    scope.add_argument("--project", help="Project ID")
    p.add_argument("--domains", nargs="*", default=[],
                   help="Your owned domains; principals outside them are flagged external.")
    p.add_argument("--only", choices=["primitive-roles", "user-bindings", "keys", "external"],
                   help="Report only this finding class.")
    p.add_argument("--out", help="Write the full baseline JSON to this path.")
    args = p.parse_args()

    kind, ident, policy_cmd = resource_flag(args)
    print(f"# Assessing {kind}/{ident} (read-only)\n")

    policy = run_gcloud(policy_cmd)
    findings = analyze_policy(policy, args.domains)
    findings["keys"] = enumerate_keys(args.project) if args.project else []

    show = {
        "primitive-roles": ["primitive_roles"],
        "user-bindings": ["user_bindings"],
        "external": ["external_principals"],
        "keys": ["keys"],
    }.get(args.only, ["primitive_roles", "user_bindings", "external_principals", "keys"])

    for section in show:
        rows = findings.get(section, [])
        print(f"## {section} — {len(rows)} finding(s)")
        for r in rows:
            print(f"   {json.dumps(r, sort_keys=True)}")
        print()

    if args.project and "keys" in show and not findings["keys"]:
        print("   (no user-managed keys — good: no exportable keys on this project)\n")

    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump({"scope": f"{kind}/{ident}", "findings": findings}, fh, indent=2)
        print(f"# Baseline written to {args.out} (keep for rollback + validation)")

    total = sum(len(findings.get(s, [])) for s in ("primitive_roles", "external_principals", "keys"))
    sys.exit(1 if total else 0)  # non-zero = findings present, for CI gating


if __name__ == "__main__":
    main()
