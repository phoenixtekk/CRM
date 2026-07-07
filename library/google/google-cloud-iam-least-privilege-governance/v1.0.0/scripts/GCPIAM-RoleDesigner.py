#!/usr/bin/env python3
# GCPIAM-RoleDesigner.py — design/validate a least-privilege custom IAM role and apply it (dry-run by default)
#
# PURPOSE: Validate a proposed Organization-level custom role's permissions and print the plan (dry-run).
#          Creates or updates the custom role only when --apply is passed. Safe default: no write without
#          --apply. Helps you trim a predefined role down to exactly the permissions a job needs.
# HOW TO RUN: python GCPIAM-RoleDesigner.py --organization ORG_ID --role-id customAppDeployer \
#             --title "Custom App Deployer – Org – v1" --permissions p1,p2,p3 [--stage GA] [--apply]
#             (Python 3.10+, gcloud on PATH, ADC; needs roles/iam.organizationRoleAdmin to --apply)
# EXPECTED RESULTS: Dry-run prints the role definition + a testable-permissions check and exits without
#                   changing anything. With --apply, the custom role is created/updated and printed.
#
# Uses the `gcloud` CLI via subprocess. No credentials/keys/secrets in code — auth is ADC/gcloud.

import argparse
import json
import subprocess
import sys


def run_gcloud(args, capture=True):
    cmd = ["gcloud", *args]
    if capture:
        cmd.append("--format=json")
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)
    except FileNotFoundError:
        sys.exit("ERROR: 'gcloud' not found on PATH. Install the Google Cloud SDK and retry.")
    except subprocess.CalledProcessError as exc:
        sys.exit(f"ERROR running: {' '.join(cmd)}\n{exc.stderr.strip()}")
    return json.loads(proc.stdout) if capture and proc.stdout.strip() else proc.stdout


def role_exists(org, role_id):
    out = run_gcloud(["iam", "roles", "list", "--organization", org, "--filter",
                      f"name:organizations/{org}/roles/{role_id}"])
    return bool(out)


def main():
    p = argparse.ArgumentParser(description="Design/validate/apply a least-privilege custom IAM role.")
    p.add_argument("--organization", required=True, help="Organization ID (custom roles live here for reuse)")
    p.add_argument("--role-id", required=True, help="Custom role ID, e.g. customAppDeployer")
    p.add_argument("--title", required=True, help='Display title, e.g. "Custom App Deployer – Org – v1"')
    p.add_argument("--permissions", required=True,
                   help="Comma-separated IAM permissions the role should grant.")
    p.add_argument("--description", default="Least-privilege custom role (designed via GCPIAM-RoleDesigner).")
    p.add_argument("--stage", default="GA", choices=["ALPHA", "BETA", "GA", "DISABLED"])
    g = p.add_mutually_exclusive_group()
    g.add_argument("--dry-run", action="store_true", default=True, help="(default) validate + plan only")
    g.add_argument("--apply", action="store_true", help="Create/update the custom role.")
    args = p.parse_args()

    perms = [x.strip() for x in args.permissions.split(",") if x.strip()]
    if not perms:
        sys.exit("ERROR: --permissions must list at least one permission.")

    exists = role_exists(args.organization, args.role_id)
    action = "UPDATE" if exists else "CREATE"

    print(f"# Custom role plan: {action} organizations/{args.organization}/roles/{args.role_id}")
    print(f"  title       : {args.title}")
    print(f"  stage       : {args.stage}")
    print(f"  permissions : {len(perms)}")
    for perm in perms:
        print(f"     - {perm}")
    print()

    if not args.apply:
        print("DRY-RUN: no changes made. Re-run with --apply to create/update the role.")
        print("TIP: verify each permission is testable with:")
        print(f"     gcloud iam roles list --organization {args.organization}  # confirm no clash")
        sys.exit(0)

    verb = "update" if exists else "create"
    cmd = ["iam", "roles", verb, args.role_id, "--organization", args.organization,
           "--title", args.title, "--description", args.description,
           "--permissions", ",".join(perms), "--stage", args.stage]
    result = run_gcloud(cmd)
    print(f"APPLIED ({action}):")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
