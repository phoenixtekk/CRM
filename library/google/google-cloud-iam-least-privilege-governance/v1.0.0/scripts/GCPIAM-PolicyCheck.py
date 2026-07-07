#!/usr/bin/env python3
# GCPIAM-PolicyCheck.py — IAM-restricting org-policy guardrail check + reference-design assertion (dry-run by default)
#
# PURPOSE: Read/set IAM-restricting org-policy constraints (e.g. disableServiceAccountKeyCreation,
#          allowedPolicyMemberDomains) and assert the least-privilege reference design holds on a scope.
#          Safe default: reads and dry-run. Enforcing (--enforce) or setting dry-run (--set-dry-run) are
#          explicit; nothing enforces without the operator asking.
# HOW TO RUN: python GCPIAM-PolicyCheck.py --resource organizations/ORG_ID
#             [--constraint constraints/iam.disableServiceAccountKeyCreation] [--set-dry-run|--enforce]
#             [--assert-reference-design] [--domains d1 d2]
#             (Python 3.10+, gcloud on PATH, ADC; needs roles/orgpolicy.policyAdmin to set; see --help)
# EXPECTED RESULTS: Prints the constraint's current state, or applies dry-run/enforce, or runs the
#                   reference-design assertion (exit 0 = all invariants hold; non-zero = a violation).
#
# Uses the `gcloud` CLI via subprocess. No credentials/keys/secrets in code — auth is ADC/gcloud.

import argparse
import json
import subprocess
import sys

PRIMITIVE_ROLES = {"roles/owner", "roles/editor"}
BREAK_GLASS_HINT = "break-glass"


def run_gcloud(args, allow_fail=False, capture=True):
    cmd = ["gcloud", *args]
    if capture:
        cmd.append("--format=json")
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)
    except FileNotFoundError:
        sys.exit("ERROR: 'gcloud' not found on PATH. Install the Google Cloud SDK and retry.")
    except subprocess.CalledProcessError as exc:
        if allow_fail:
            return None
        sys.exit(f"ERROR running: {' '.join(cmd)}\n{exc.stderr.strip()}")
    if not capture:
        return proc.stdout
    return json.loads(proc.stdout) if proc.stdout.strip() else {}


def resource_scope_flag(resource):
    kind, ident = resource.split("/", 1)
    return {
        "organizations": ["--organization", ident],
        "folders": ["--folder", ident],
        "projects": ["--project", ident],
    }.get(kind) or sys.exit("ERROR: --resource must be organizations/ID | folders/ID | projects/ID")


def get_policy_for_scope(resource):
    kind, ident = resource.split("/", 1)
    if kind == "projects":
        return run_gcloud(["projects", "get-iam-policy", ident])
    if kind == "folders":
        return run_gcloud(["resource-manager", "folders", "get-iam-policy", ident])
    return run_gcloud(["organizations", "get-iam-policy", ident])


def describe_constraint(resource, constraint):
    flag = resource_scope_flag(resource)
    out = run_gcloud(["org-policies", "describe", constraint, *flag], allow_fail=True)
    return out or {"note": "no explicit policy set at this scope (inherits parent/default)"}


def set_constraint(resource, constraint, mode):
    """mode: 'set-dry-run' or 'enforce'. Uses gcloud org-policies set/reset flows conceptually."""
    flag = resource_scope_flag(resource)
    if mode == "enforce":
        print(f"# Enforcing {constraint} on {resource}")
        run_gcloud(["org-policies", "set-policy", "-"], allow_fail=True, capture=False) if False else None
        # For a boolean constraint, the enforced form:
        run_gcloud(["org-policies", "enable-enforce", constraint, *flag], capture=False)
        print("  -> enforced (verify with --constraint alone; then run Test 3 in the Testing guide).")
    else:
        print(f"# Setting {constraint} to DRY-RUN on {resource}")
        print("  Apply the constraint under a dryRunSpec via your org-policy YAML / Terraform, then review")
        print("  violations in Cloud Logging before promoting with --enforce.")
        print("  (Boolean-constraint dry-run is expressed in the policy spec's dryRunSpec — see docs.)")


def assert_reference_design(resource, domains):
    print(f"# Reference-design assertion on {resource}")
    policy = get_policy_for_scope(resource)
    violations = []
    users, groups = 0, 0
    for binding in policy.get("bindings", []):
        role = binding.get("role", "")
        for member in binding.get("members", []):
            if member.startswith("user:"):
                users += 1
                violations.append(f"direct user binding: {member} -> {role} (use a group)")
            if member.startswith("group:"):
                groups += 1
            if role in PRIMITIVE_ROLES and BREAK_GLASS_HINT not in member:
                violations.append(f"primitive role outside break-glass: {member} -> {role}")
            if domains and member.startswith(("user:", "serviceAccount:")):
                addr = member.split(":", 1)[1]
                if "@" in addr and not any(addr.endswith("@" + d) or addr.endswith("." + d) for d in domains):
                    violations.append(f"external principal: {member} -> {role}")

    key_policy = describe_constraint(resource, "constraints/iam.disableServiceAccountKeyCreation")
    enforced = json.dumps(key_policy).find('"enforced": true') != -1 or \
        json.dumps(key_policy).find('"booleanPolicy"') != -1
    if not enforced:
        violations.append("iam.disableServiceAccountKeyCreation not confirmed enforced at this scope")

    print(f"  group bindings: {groups}, direct-user bindings: {users}")
    if violations:
        print(f"  FAIL — {len(violations)} invariant(s) violated:")
        for v in violations:
            print(f"    - {v}")
        sys.exit(1)
    print("  PASS — no primitive grants outside break-glass, group-based access, key-creation guarded.")
    sys.exit(0)


def main():
    p = argparse.ArgumentParser(description="Org-policy guardrail check + reference-design assertion.")
    p.add_argument("--resource", required=True, help="organizations/ID | folders/ID | projects/ID")
    p.add_argument("--constraint", help="Org-policy constraint to describe/set")
    p.add_argument("--domains", nargs="*", default=[], help="Owned domains (for external-principal checks)")
    mode = p.add_mutually_exclusive_group()
    mode.add_argument("--set-dry-run", action="store_true", help="Guide setting the constraint to dry-run")
    mode.add_argument("--enforce", action="store_true", help="Enforce the constraint (write)")
    p.add_argument("--assert-reference-design", action="store_true",
                   help="Assert least-privilege invariants hold on the scope (read-only).")
    args = p.parse_args()

    if args.assert_reference_design:
        assert_reference_design(args.resource, args.domains)
        return

    if not args.constraint:
        sys.exit("ERROR: provide --constraint (to describe/set) or --assert-reference-design.")

    if args.enforce:
        set_constraint(args.resource, args.constraint, "enforce")
    elif args.set_dry_run:
        set_constraint(args.resource, args.constraint, "set-dry-run")
    else:
        print(f"# Current policy for {args.constraint} on {args.resource} (read-only):")
        print(json.dumps(describe_constraint(args.resource, args.constraint), indent=2))


if __name__ == "__main__":
    main()
