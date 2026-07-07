#!/usr/bin/env python3
# gcpnet_vpcsc_perimeter_build.py — build a VPC Service Controls perimeter DRY-RUN first (safe default)
#
# PURPOSE: Compose and (optionally) create a VPC-SC service perimeter in DRY-RUN mode, and read back
#          its dry-run violation logs. SAFE BY DEFAULT: prints the intended dry-run perimeter spec and
#          the exact gcloud command; only creates it (still in DRY-RUN) with --apply. It NEVER enforces
#          a perimeter — enforcement is a deliberate manual step (see Implementation Stage 5).
# HOW TO RUN: python gcpnet_vpcsc_perimeter_build.py --policy POLICY_ID --title "Perimeter – Prod – v1" \
#             --resource-project-number 111111111111 \
#             --restricted-services storage.googleapis.com bigquery.googleapis.com [--apply]
#             python gcpnet_vpcsc_perimeter_build.py --policy POLICY_ID --show-dry-run-violations
#             (Python 3.10+, gcloud auth / ADC; needs accesscontextmanager.policyEditor.)
# EXPECTED RESULTS: the dry-run perimeter plan (or, with --show-dry-run-violations, the would-deny
#          VPC-SC entries from Cloud Logging). No service is ever enforced by this tool.

import argparse
import re
import shutil
import subprocess
import sys


def _name_from_title(title):
    """Derive a gcloud-safe perimeter id from a human title."""
    return re.sub(r"[^a-z0-9_]", "", title.lower().replace(" ", "_").replace("-", "_")) or "perimeter"


def run_gcloud(args, apply):
    exe = shutil.which("gcloud")
    if not exe:
        print("ERROR: gcloud not found on PATH.", file=sys.stderr)
        sys.exit(2)
    cmd = [exe] + args
    if not apply:
        print("  DRY-RUN (tool) would run:\n    " + " ".join(cmd))
        return 0
    print("  RUNNING:\n    " + " ".join(cmd))
    res = subprocess.run(cmd, capture_output=True, text=True)
    sys.stdout.write(res.stdout)
    if res.returncode != 0:
        sys.stderr.write(res.stderr)
    return res.returncode


def build(args):
    name = _name_from_title(args.title)
    resources = ",".join(f"projects/{n}" for n in args.resource_project_number)
    services = ",".join(args.restricted_services)
    print("=" * 68)
    print("VPC-SC PERIMETER PLAN (DRY-RUN mode — logs, does not block)")
    print("=" * 68)
    print(f"  perimeter id:        {name}")
    print(f"  title:               {args.title}")
    print(f"  policy:              {args.policy}")
    print(f"  resources:           {resources}")
    print(f"  restricted services: {services}")
    print("  NOTE: verify CURRENT VPC-SC coverage for each service in your organization; support"
          " status (supported/preview/unsupported) changes over time.")
    print("-" * 68)
    gargs = ["access-context-manager", "perimeters", "dry-run", "create", name,
             f"--policy={args.policy}", f"--title={args.title}",
             "--perimeter-type=regular", f"--resources={resources}",
             f"--restricted-services={services}"]
    rc = run_gcloud(gargs, args.apply)
    if not args.apply:
        print("-" * 68)
        print("This was a DRY-RUN of the tool. Re-run with --apply to CREATE the perimeter — it will "
              "still be created in VPC-SC DRY-RUN (audit) mode and block nothing.")
        print("After creation, let it run 1–2 weeks, then: --show-dry-run-violations, add ingress/"
              "egress rules for legitimate flows, and only then enforce (manual step).")
    return rc


def show_violations(args):
    # Query Cloud Logging for VPC-SC dry-run (would-deny) violations.
    log_filter = (
        'protoPayload.metadata."@type"='
        '"type.googleapis.com/google.cloud.audit.VpcServiceControlAuditMetadata" '
        'AND protoPayload.metadata.dryRun=true'
    )
    exe = shutil.which("gcloud")
    if not exe:
        print("ERROR: gcloud not found on PATH.", file=sys.stderr)
        sys.exit(2)
    cmd = [exe, "logging", "read", log_filter, "--limit", str(args.limit),
           "--format=value(protoPayload.metadata.violationReason,"
           "protoPayload.resourceName,protoPayload.requestMetadata.callerIp)"]
    if args.project:
        cmd += [f"--project={args.project}"]
    print("Reading VPC-SC DRY-RUN (would-deny) violations from Cloud Logging...")
    print("  " + " ".join(cmd[:4]) + " <filter> ...")
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"WARN: could not read logs: {res.stderr.strip()}", file=sys.stderr)
        print("Ensure Data Access audit logs are enabled for the protected services (Requirement 7).")
        return 1
    lines = [ln for ln in res.stdout.splitlines() if ln.strip()]
    if not lines:
        print("No dry-run violations found (either none occurred yet, or logging is not capturing "
              "them). Generate a test cross-boundary request, then re-check.")
        return 0
    print(f"Found {len(lines)} would-deny violation(s):")
    for ln in lines:
        print("  - " + ln)
    print("Classify each: legitimate flow => add an ingress/egress rule referencing your access "
          "level; intended exfiltration => leave to be blocked at enforcement.")
    return 0


def main():
    ap = argparse.ArgumentParser(description="Build a VPC-SC perimeter DRY-RUN first (safe default).")
    ap.add_argument("--policy", required=True, help="Access Context Manager policy ID.")
    ap.add_argument("--title", help="Human perimeter title, e.g. 'Perimeter – Prod – v1'.")
    ap.add_argument("--resource-project-number", nargs="*", default=[],
                    help="One or more in-scope project NUMBERS (not IDs).")
    ap.add_argument("--restricted-services", nargs="*", default=[],
                    help="Service API names to restrict, e.g. storage.googleapis.com.")
    ap.add_argument("--show-dry-run-violations", action="store_true",
                    help="Instead of building, read the dry-run would-deny violation logs.")
    ap.add_argument("--project", help="Project to scope the log read to (with --show-dry-run-violations).")
    ap.add_argument("--limit", type=int, default=50, help="Max violation log entries to show.")
    ap.add_argument("--apply", action="store_true",
                    help="Create the perimeter (still in VPC-SC DRY-RUN mode). Omit for a plan only.")
    args = ap.parse_args()

    if args.show_dry_run_violations:
        sys.exit(show_violations(args))

    if not args.title or not args.resource_project_number or not args.restricted_services:
        ap.error("--title, --resource-project-number, and --restricted-services are required to build.")
    sys.exit(build(args))


if __name__ == "__main__":
    main()
