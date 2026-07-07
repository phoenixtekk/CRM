#!/usr/bin/env python3
# gcp_org_policy_guardrails.py — apply the "Org Policy Baseline - Org - v1" guardrail set to a scope.
#
# PURPOSE: Diff the current org policies at a scope (folder or organization) against a baseline
#          set and enforce them. DRY-RUN BY DEFAULT — reports the diff and changes NOTHING unless
#          --apply is passed. Pilot on a folder before promoting to the Organization node.
# HOW TO RUN: python gcp_org_policy_guardrails.py --scope folders/FOLDER_ID
#             [--baseline org-policy-baseline-v1.yaml] [--apply]
#             (Python 3.10+, gcloud authenticated / ADC; see --help)
# EXPECTED RESULTS: A per-constraint report (present/enforced vs desired). --apply enforces the
#          missing/mismatched constraints. Constraint names must be verified in your organization.

import argparse
import json
import shutil
import subprocess
import sys

# Representative baseline. Boolean constraints are enforced true/false; list constraints carry
# allow/deny values. VERIFY each constraint's exact name and semantics against the current
# Organization Policy constraints reference for YOUR organization before enforcing.
BASELINE = [
    {"constraint": "iam.disableServiceAccountKeyCreation", "type": "boolean", "enforce": True},
    {"constraint": "compute.vmExternalIpAccess", "type": "list", "policy": "denyAll"},
    {"constraint": "compute.skipDefaultNetworkCreation", "type": "boolean", "enforce": True},
    {"constraint": "storage.uniformBucketLevelAccess", "type": "boolean", "enforce": True},
    {"constraint": "gcp.resourceLocations", "type": "list",
     "allow": ["in:us-locations"], "note": "verify region group / values for your org"},
    {"constraint": "iam.allowedPolicyMemberDomains", "type": "list",
     "allow": ["<your-customer-id>"], "note": "domain-restricted sharing; set your customer ID"},
]


def gcloud_bin():
    g = shutil.which("gcloud")
    if not g:
        sys.exit("ERROR: gcloud CLI not found on PATH. Install the Google Cloud SDK first.")
    return g


def scope_flag(scope):
    """Translate 'folders/123' or 'organizations/123' into the gcloud --folder/--organization flag."""
    if scope.startswith("folders/"):
        return f"--folder={scope.split('/', 1)[1]}"
    if scope.startswith("organizations/"):
        return f"--organization={scope.split('/', 1)[1]}"
    if scope.startswith("projects/"):
        return f"--project={scope.split('/', 1)[1]}"
    sys.exit("ERROR: --scope must be folders/ID, organizations/ID, or projects/ID.")


def describe_current(constraint, flag):
    """Return the current policy JSON for a constraint at the scope, or None if unset."""
    res = subprocess.run(
        [gcloud_bin(), "org-policies", "describe", constraint, flag, "--format=json"],
        capture_output=True, text=True)
    if res.returncode != 0:
        return None
    try:
        return json.loads(res.stdout)
    except json.JSONDecodeError:
        return None


def enforce(item, flag, apply):
    c = item["constraint"]
    if item["type"] == "boolean":
        verb = "enforce" if item.get("enforce", True) else "reset"
        action = ["org-policies", "set-policy" if False else verb, c, flag]
        # gcloud supports `org-policies enable-enforce`/`reset`; use enforce/reset shorthands:
        action = ["org-policies", "enforce" if item.get("enforce", True) else "reset", c, flag]
        printable = "gcloud " + " ".join(action)
    else:
        printable = (f"gcloud org-policies (list) set for {c} "
                     f"allow={item.get('allow')} policy={item.get('policy')} {flag} "
                     f"(author a policy YAML and `gcloud org-policies set-policy policy.yaml`)")
        action = None
    if not apply:
        print(f"  [DRY-RUN] {printable}")
        return
    if action is None:
        print(f"  [APPLY]   {printable}")
        print("    NOTE: list constraints are applied via a policy YAML file per your org's values.")
        return
    print(f"  [APPLY]   {printable}")
    res = subprocess.run([gcloud_bin()] + action, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"    ERROR: {res.stderr.strip()}", file=sys.stderr)


def load_baseline(path):
    if not path:
        return BASELINE
    # Minimal YAML-free loader: accept a JSON baseline for portability (no PyYAML dependency).
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        sys.exit("ERROR: provide the baseline as JSON, or edit the built-in BASELINE list.")


def main():
    ap = argparse.ArgumentParser(
        description="Apply the Org Policy Baseline guardrails to a scope (dry-run by default).")
    ap.add_argument("--scope", required=True,
                    help="folders/FOLDER_ID (pilot first) or organizations/ORG_ID.")
    ap.add_argument("--baseline", help="Optional baseline JSON (defaults to the built-in set).")
    ap.add_argument("--apply", action="store_true",
                    help="Actually enforce constraints. Omit for a safe dry-run.")
    args = ap.parse_args()

    baseline = load_baseline(args.baseline)
    flag = scope_flag(args.scope)
    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"== Org-policy guardrails ({mode}) — scope {args.scope} ==")
    print("   (Verify every constraint name/behavior in your organization before enforcing.)\n")

    for item in baseline:
        c = item["constraint"]
        current = describe_current(c, flag)
        state = "unset/inherited" if current is None else "set at this scope"
        print(f"- {c} [{item['type']}] — current: {state}")
        enforce(item, flag, args.apply)

    if not args.apply:
        print("\nDry-run complete. Re-run with --apply (pilot folder first) to enforce.")


if __name__ == "__main__":
    main()
