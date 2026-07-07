#!/usr/bin/env python3
# GCPIAM-WIFSetup.py — Workload Identity Federation setup helper to retire exported SA keys (dry-run by default)
#
# PURPOSE: Plan and (with --apply) create a Workload Identity Pool + OIDC provider and the service-account
#          impersonation binding, so an external/federated workload (CI/CD, another cloud, on-prem) uses
#          short-lived federated credentials instead of a downloaded service-account key. Safe default:
#          plan only; nothing is created without --apply.
# HOW TO RUN: python GCPIAM-WIFSetup.py --project PID --pool-id wif-pool-pilot \
#             --provider-id github --issuer-uri https://token.actions.githubusercontent.com \
#             --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository" \
#             --service-account SA_EMAIL --allowed-attribute attribute.repository/org/repo [--apply]
#             (Python 3.10+, gcloud on PATH, ADC; needs roles/iam.workloadIdentityPoolAdmin to --apply)
# EXPECTED RESULTS: Dry-run prints the pool/provider/binding plan + the workload-side config, no changes.
#                   With --apply, the pool, OIDC provider, and impersonation binding are created.
#
# Uses the `gcloud` CLI via subprocess. No credentials/keys/secrets in code. Verify OIDC issuer/attribute
# details against your external IdP's documentation.

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


def project_number(project):
    out = run_gcloud(["projects", "describe", project])
    return out.get("projectNumber")


def main():
    p = argparse.ArgumentParser(description="Set up Workload Identity Federation to replace exported keys.")
    p.add_argument("--project", required=True, help="Project that hosts the WIF pool + target SA")
    p.add_argument("--pool-id", required=True, help="Workload identity pool ID, e.g. wif-pool-pilot")
    p.add_argument("--pool-name", default=None, help='Display name, e.g. "WIF Pool – Pilot – v1"')
    p.add_argument("--provider-id", required=True, help="Provider ID, e.g. github")
    p.add_argument("--issuer-uri", required=True, help="OIDC issuer URI of the external IdP")
    p.add_argument("--attribute-mapping", required=True,
                   help="Comma-separated google.subject=... ,attribute.X=... mappings")
    p.add_argument("--attribute-condition", default=None,
                   help="Optional CEL condition restricting which tokens are accepted")
    p.add_argument("--service-account", required=True, help="SA email the workload will impersonate")
    p.add_argument("--allowed-attribute", required=True,
                   help="Attribute value allowed to impersonate, e.g. attribute.repository/org/repo")
    p.add_argument("--location", default="global")
    g = p.add_mutually_exclusive_group()
    g.add_argument("--dry-run", action="store_true", default=True, help="(default) plan only")
    g.add_argument("--apply", action="store_true", help="Create pool, provider, and binding.")
    args = p.parse_args()

    proj_num = project_number(args.project)
    pool_res = f"projects/{proj_num}/locations/{args.location}/workloadIdentityPools/{args.pool_id}"
    principal = (f"principalSet://iam.googleapis.com/{pool_res}/{args.allowed_attribute}")

    print("# Workload Identity Federation plan")
    print(f"  pool            : {args.pool_id} ({args.pool_name or args.pool_id})")
    print(f"  provider (OIDC) : {args.provider_id}  issuer={args.issuer_uri}")
    print(f"  attr mapping    : {args.attribute_mapping}")
    if args.attribute_condition:
        print(f"  attr condition  : {args.attribute_condition}")
    print(f"  impersonates SA : {args.service_account}")
    print(f"  allowed member  : {principal}")
    print()

    if not args.apply:
        print("DRY-RUN: no changes made. Re-run with --apply to create the pool/provider/binding.")
        print("\nWorkload-side config the CI/workload will use (no key file):")
        print(json.dumps({
            "type": "external_account",
            "audience": f"//iam.googleapis.com/{pool_res}/providers/{args.provider_id}",
            "subject_token_type": "urn:ietf:params:oauth:token-type:jwt",
            "service_account_impersonation_url":
                f"https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/"
                f"{args.service_account}:generateAccessToken",
            "token_url": "https://sts.googleapis.com/v1/token",
        }, indent=2))
        sys.exit(0)

    # 1) pool
    run_gcloud(["iam", "workload-identity-pools", "create", args.pool_id,
                "--project", args.project, "--location", args.location,
                "--display-name", args.pool_name or args.pool_id], capture=False)
    # 2) OIDC provider
    prov_cmd = ["iam", "workload-identity-pools", "providers", "create-oidc", args.provider_id,
                "--project", args.project, "--location", args.location,
                "--workload-identity-pool", args.pool_id,
                "--issuer-uri", args.issuer_uri,
                "--attribute-mapping", args.attribute_mapping]
    if args.attribute_condition:
        prov_cmd += ["--attribute-condition", args.attribute_condition]
    run_gcloud(prov_cmd, capture=False)
    # 3) impersonation binding
    run_gcloud(["iam", "service-accounts", "add-iam-policy-binding", args.service_account,
                "--project", args.project,
                "--role", "roles/iam.workloadIdentityUser",
                "--member", principal], capture=False)

    print("APPLIED: WIF pool, OIDC provider, and impersonation binding created.")
    print("NEXT: point the workload at the config above, confirm it runs, then DELETE the exported key.")


if __name__ == "__main__":
    main()
