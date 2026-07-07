#!/usr/bin/env python3
# bce_iap_enable_helper.py — enable Identity-Aware Proxy for a web app or a VM (SSH), dry-run by default
#
# PURPOSE: Check prerequisites and print the exact gcloud/console steps to put IAP in front of a pilot
#          resource — a web backend service (HTTPS load balancer) or a VM via IAP TCP forwarding,
#          including the 35.235.240.0/20 firewall requirement and the context-aware IAM binding form.
#          SAFE BY DEFAULT: prints the plan and never changes anything unless --apply is passed.
# HOW TO RUN: python bce_iap_enable_helper.py --project <P> --resource-type {web|ssh}
#             [--backend-service <BES> | --instance <VM> --zone <ZONE>]
#             [--member group:...] [--access-level <NAME>] [--apply]
#             (Python 3.10+, gcloud on PATH, ADC/`gcloud auth`; see --help)
# EXPECTED RESULTS: In dry-run (default) an ordered, copy-pasteable plan + prerequisite check results.
#          With --apply it executes the enable + binding commands and prints their output.

import argparse
import shutil
import subprocess
import sys

IAP_TCP_FORWARDING_RANGE = "35.235.240.0/20"


def have_gcloud():
    if not shutil.which("gcloud"):
        print("ERROR: gcloud CLI not found on PATH. Install the Google Cloud SDK.", file=sys.stderr)
        sys.exit(2)


def api_enabled(project, api):
    """Read-only check: is an API enabled on the project?"""
    out = subprocess.run(
        ["gcloud", "services", "list", "--enabled", f"--project={project}",
         f"--filter=config.name={api}", "--format=value(config.name)"],
        capture_output=True, text=True)
    return api in (out.stdout or "")


def emit_or_run(cmd, apply):
    """Print a command; run it only when apply=True."""
    printable = " ".join(cmd)
    if not apply:
        print(f"  [dry-run] {printable}")
        return
    print(f"  [apply]   {printable}")
    res = subprocess.run(cmd, capture_output=True, text=True)
    sys.stdout.write(res.stdout)
    if res.returncode != 0:
        sys.stderr.write(res.stderr)
        print(f"  -> command exited {res.returncode}", file=sys.stderr)


def condition_arg(access_level):
    if not access_level:
        print("  WARNING: no --access-level given. A binding WITHOUT an access-level condition enforces")
        print("           identity only, NOT context — that is not zero trust. Provide --access-level.")
        return None
    # NOTE: the exact expression syntax for access-level conditions is version-dependent.
    # Verify the current form for your gcloud version; this is the documented shape.
    expr = (f'"accessPolicies/POLICY_ID/accessLevels/{access_level}" in '
            f'request.auth.access_levels')
    return f"expression={expr},title={access_level}"


def plan_web(args):
    print("== IAP for a WEB app (HTTPS load-balancer backend service) ==")
    print("Prerequisites:")
    print(f"  - iap.googleapis.com enabled: "
          f"{'YES' if api_enabled(args.project, 'iap.googleapis.com') else 'NO — enable it first'}")
    print("  - OAuth consent/brand configured for IAP (first-run, version-dependent — verify in console)")
    if not args.backend_service:
        print("  ERROR: --backend-service is required for --resource-type web.", file=sys.stderr)
        sys.exit(2)
    print("\nStep 1 — enable IAP on the backend service:")
    emit_or_run(["gcloud", "compute", "backend-services", "update", args.backend_service,
                 f"--project={args.project}", "--global", "--iap=enabled"], args.apply)
    print("\nStep 2 — grant context-aware web access to the pilot group:")
    cond = condition_arg(args.access_level)
    cmd = ["gcloud", "iap", "web", "add-iam-policy-binding",
           f"--project={args.project}", "--resource-type=backend-services",
           f"--service={args.backend_service}",
           f"--member={args.member or 'group:REPLACE_WITH_PILOT_GROUP'}",
           "--role=roles/iap.httpsResourceAccessor"]
    if cond:
        cmd.append(f"--condition={cond}")
    emit_or_run(cmd, args.apply)


def plan_ssh(args):
    print("== IAP TCP forwarding for a VM (SSH) ==")
    if not args.instance:
        print("  ERROR: --instance is required for --resource-type ssh.", file=sys.stderr)
        sys.exit(2)
    print("Prerequisites:")
    print(f"  - iap.googleapis.com enabled: "
          f"{'YES' if api_enabled(args.project, 'iap.googleapis.com') else 'NO — enable it first'}")
    print(f"  - firewall must allow SSH (tcp:22) INGRESS only from {IAP_TCP_FORWARDING_RANGE}")
    print("    and NOT from 0.0.0.0/0 or the broad VPN range.")
    print("\nStep 1 — ensure the IAP-scoped SSH firewall rule exists:")
    emit_or_run(["gcloud", "compute", "firewall-rules", "create", "allow-ssh-from-iap",
                 f"--project={args.project}", "--direction=INGRESS", "--action=ALLOW",
                 "--rules=tcp:22", f"--source-ranges={IAP_TCP_FORWARDING_RANGE}"], args.apply)
    print("\nStep 2 — grant the context-aware tunnel accessor role:")
    cond = condition_arg(args.access_level)
    cmd = ["gcloud", "iap", "tcp", "add-iam-policy-binding",
           f"--project={args.project}",
           f"--member={args.member or 'group:REPLACE_WITH_PILOT_GROUP'}",
           "--role=roles/iap.tunnelResourceAccessor"]
    if cond:
        cmd.append(f"--condition={cond}")
    emit_or_run(cmd, args.apply)
    print("\nStep 3 — connect (test) through IAP only:")
    zone = args.zone or "<ZONE>"
    print(f"  gcloud compute ssh {args.instance} --tunnel-through-iap --zone {zone} "
          f"--project={args.project}")


def main():
    ap = argparse.ArgumentParser(description="Enable IAP for a web app or VM (dry-run by default).")
    ap.add_argument("--project", required=True)
    ap.add_argument("--resource-type", required=True, choices=["web", "ssh"])
    ap.add_argument("--backend-service", help="Backend service name (web)")
    ap.add_argument("--instance", help="VM instance name (ssh)")
    ap.add_argument("--zone", help="Instance zone (ssh)")
    ap.add_argument("--member", help="IAM member, e.g. group:zero-trust-pilot@domain")
    ap.add_argument("--access-level", help="Access level name to condition the binding on")
    ap.add_argument("--dry-run", action="store_true",
                    help="Explicit dry-run (default behavior; provided for clarity)")
    ap.add_argument("--apply", action="store_true",
                    help="Actually execute the commands (writes). Omit to only print the plan.")
    args = ap.parse_args()

    have_gcloud()
    if args.dry_run and args.apply:
        print("ERROR: pass either --dry-run or --apply, not both.", file=sys.stderr)
        sys.exit(2)
    mode = "APPLY (writes)" if args.apply else "DRY-RUN (no changes)"
    print(f"bce_iap_enable_helper — mode: {mode}\n")
    if args.resource_type == "web":
        plan_web(args)
    else:
        plan_ssh(args)
    if not args.apply:
        print("\n(No changes made. Re-run with --apply after review to execute.)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
