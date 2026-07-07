#!/usr/bin/env python3
# GCPIAM-Review.py — access-review report generator (read-only): bindings + IAM Recommender over-grant flags
#
# PURPOSE: Produce a per-binding access-review report for owner attestation. Read-only: it never modifies
#          IAM. Lists every principal/role binding on a scope and, where available, annotates it with
#          IAM Recommender "unused / over-granted role" findings so reviewers can trim to least privilege.
# HOW TO RUN: python GCPIAM-Review.py --organization ORG_ID --scope projects/PID [--out review.csv]
#             (Python 3.10+, gcloud on PATH, ADC; needs viewer + recommender.iamViewer roles; see --help)
# EXPECTED RESULTS: A CSV (and stdout summary) of bindings with a recommender flag column, ready for the
#                   quarterly access review. Empty/errored output usually means the Recommender API is
#                   disabled or the caller lacks the viewer role.
#
# Uses the `gcloud` CLI via subprocess. No credentials/keys/secrets in code — auth is ADC/gcloud.

import argparse
import csv
import json
import subprocess
import sys


def run_gcloud(args, allow_fail=False):
    cmd = ["gcloud", *args, "--format=json"]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)
    except FileNotFoundError:
        sys.exit("ERROR: 'gcloud' not found on PATH. Install the Google Cloud SDK and retry.")
    except subprocess.CalledProcessError as exc:
        if allow_fail:
            return None
        sys.exit(f"ERROR running: {' '.join(cmd)}\n{exc.stderr.strip()}")
    return json.loads(proc.stdout or "[]")


def get_policy(scope):
    kind, ident = scope.split("/", 1)
    if kind == "projects":
        return run_gcloud(["projects", "get-iam-policy", ident])
    if kind == "folders":
        return run_gcloud(["resource-manager", "folders", "get-iam-policy", ident])
    if kind == "organizations":
        return run_gcloud(["organizations", "get-iam-policy", ident])
    sys.exit("ERROR: --scope must be projects/ID, folders/ID, or organizations/ID")


def get_recommendations(scope):
    """Best-effort IAM Recommender pull for over-granted/unused roles (project scope only)."""
    kind, ident = scope.split("/", 1)
    if kind != "projects":
        return {}
    recs = run_gcloud(["recommender", "recommendations", "list",
                       "--project", ident, "--location", "global",
                       "--recommender", "google.iam.policy.Recommender"], allow_fail=True)
    flagged = {}
    for rec in recs or []:
        subtype = rec.get("recommenderSubtype", "")
        for op_group in rec.get("content", {}).get("operationGroups", []):
            for op in op_group.get("operations", []):
                member = op.get("pathFilters", {}).get("/iamPolicy/bindings/*/members/*")
                role = op.get("pathFilters", {}).get("/iamPolicy/bindings/*/role")
                if member and role:
                    flagged[(member, role)] = subtype or "REPLACE_ROLE"
    return flagged


def main():
    p = argparse.ArgumentParser(description="Generate an access-review report (read-only).")
    p.add_argument("--organization", required=True, help="Organization ID (context)")
    p.add_argument("--scope", required=True, help="projects/ID | folders/ID | organizations/ID")
    p.add_argument("--out", help="CSV output path (default: stdout only)")
    args = p.parse_args()

    policy = get_policy(args.scope)
    flags = get_recommendations(args.scope)

    rows = []
    for binding in policy.get("bindings", []):
        role = binding.get("role", "")
        cond = binding.get("condition", {}).get("title", "")
        for member in binding.get("members", []):
            rows.append({
                "scope": args.scope,
                "member": member,
                "role": role,
                "member_type": member.split(":", 1)[0],
                "condition": cond,
                "recommender_flag": flags.get((member, role), ""),
                "attestation": "",  # reviewer fills: KEEP / REMOVE / TRIM
            })

    print(f"# Access review — {args.scope} — {len(rows)} binding(s)")
    over = [r for r in rows if r["recommender_flag"]]
    print(f"  IAM Recommender flagged {len(over)} binding(s) as over-granted/unused.")
    direct_users = [r for r in rows if r["member_type"] == "user"]
    print(f"  {len(direct_users)} direct user binding(s) (prefer groups).\n")

    fields = ["scope", "member", "member_type", "role", "condition", "recommender_flag", "attestation"]
    if args.out:
        with open(args.out, "w", newline="", encoding="utf-8") as fh:
            w = csv.DictWriter(fh, fieldnames=fields)
            w.writeheader()
            w.writerows(rows)
        print(f"# Wrote {args.out} — send to binding owners for attestation (KEEP/REMOVE/TRIM).")
    else:
        w = csv.DictWriter(sys.stdout, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)


if __name__ == "__main__":
    main()
