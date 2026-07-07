#!/usr/bin/env python3
# gcpnet_shared_vpc_provision.py — provision the Shared VPC host + private-access subnet (dry-run default)
#
# PURPOSE: Stand up the Shared VPC building blocks — enable Shared VPC on the host project, create the
#          custom-mode VPC, and create a regional subnet with Private Google Access ON. SAFE BY
#          DEFAULT: prints the exact gcloud plan and changes NOTHING unless --apply is passed.
# HOW TO RUN: python gcpnet_shared_vpc_provision.py --host-project HOST --network vpc-prod-shared \
#             --region us-east4 --subnet sn-prod-use4 --range 10.20.0.0/20 [--apply]
#             (Python 3.10+, gcloud auth / ADC; requires compute.networkAdmin + compute.xpnAdmin.)
# EXPECTED RESULTS: In dry-run, the ordered commands it WOULD run. With --apply, each command runs and
#          its result is printed; already-existing resources are reported and skipped (idempotent-ish).

import argparse
import shutil
import subprocess
import sys


def gcloud(args, apply):
    exe = shutil.which("gcloud")
    if not exe:
        print("ERROR: gcloud not found on PATH.", file=sys.stderr)
        sys.exit(2)
    cmd = [exe] + args
    if not apply:
        print("  DRY-RUN would run: " + " ".join(cmd))
        return True
    print("  RUNNING: " + " ".join(cmd))
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        err = res.stderr.strip()
        if "already exists" in err.lower():
            print("    (already exists — skipping)")
            return True
        print(f"    FAILED: {err}", file=sys.stderr)
        return False
    print("    OK")
    return True


def main():
    ap = argparse.ArgumentParser(
        description="Provision Shared VPC host + private-access subnet (dry-run by default).")
    ap.add_argument("--host-project", required=True, help="Shared VPC host project ID.")
    ap.add_argument("--network", required=True, help="VPC network name, e.g. vpc-prod-shared.")
    ap.add_argument("--region", required=True, help="Subnet region, e.g. us-east4.")
    ap.add_argument("--subnet", required=True, help="Subnet name, e.g. sn-prod-use4.")
    ap.add_argument("--range", required=True, help="Primary CIDR, e.g. 10.20.0.0/20.")
    ap.add_argument("--pods-range", help="Optional GKE Pods secondary range CIDR.")
    ap.add_argument("--services-range", help="Optional GKE Services secondary range CIDR.")
    ap.add_argument("--apply", action="store_true",
                    help="Actually perform the changes. Omit for a safe dry-run.")
    args = ap.parse_args()

    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"[{mode}] Shared VPC provisioning for host project '{args.host_project}'")
    print(f"        network={args.network} region={args.region} subnet={args.subnet} range={args.range}")

    ok = True
    print("Step 1/3 — enable Shared VPC on host project:")
    ok &= gcloud(["compute", "shared-vpc", "enable", args.host_project], args.apply)

    print("Step 2/3 — create custom-mode VPC network:")
    ok &= gcloud(["compute", "networks", "create", args.network,
                  f"--project={args.host_project}", "--subnet-mode=custom"], args.apply)

    print("Step 3/3 — create subnet WITH Private Google Access + flow logs:")
    subnet_cmd = ["compute", "networks", "subnets", "create", args.subnet,
                  f"--project={args.host_project}", f"--network={args.network}",
                  f"--region={args.region}", f"--range={args.range}",
                  "--enable-private-ip-google-access", "--enable-flow-logs"]
    if args.pods_range and args.services_range:
        subnet_cmd.append(f"--secondary-range=pods={args.pods_range},services={args.services_range}")
    ok &= gcloud(subnet_cmd, args.apply)

    print("-" * 60)
    if not args.apply:
        print("DRY-RUN complete. Review the plan above, then re-run with --apply.")
        print("Reminder: add the restricted-VIP route + Cloud DNS private zone (see Implementation "
              "step 6) so private API access resolves correctly.")
    else:
        print("APPLY complete." if ok else "APPLY finished WITH ERRORS — see messages above.")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
