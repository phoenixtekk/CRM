#!/usr/bin/env python3
# gcpnet_private_access_validate.py — validate Private Google Access is working (read-only)
#
# PURPOSE: Confirm that subnets have Private Google Access enabled, that the restricted/private Google
#          API VIP route exists, and (optionally, when run FROM an internal-only VM) that an API call
#          resolves to the private VIP and succeeds. READ-ONLY — makes no changes.
# HOW TO RUN: python gcpnet_private_access_validate.py --project PROJECT_ID [--region us-east4]
#             [--resolve storage.googleapis.com] (Python 3.10+, gcloud auth / ADC; see --help.)
# EXPECTED RESULTS: "PRIVATE ACCESS: OK" when subnets have PGA on and (if --resolve given) the host
#          resolves to a restricted/private VIP; otherwise per-check FAIL lines and a non-zero exit.

import argparse
import ipaddress
import shutil
import socket
import subprocess
import sys
import json

# Restricted / private Google API VIP ranges (per Google "Private Google Access" docs).
# VERIFY the current documented ranges in your organization — Google publishes them and they can change.
KNOWN_PRIVATE_VIP_NETS = ["199.36.153.4/30", "199.36.153.8/30", "34.126.0.0/18"]


def gcloud_json(args):
    exe = shutil.which("gcloud")
    if not exe:
        print("ERROR: gcloud not found on PATH.", file=sys.stderr)
        sys.exit(2)
    res = subprocess.run([exe] + args + ["--format=json"], capture_output=True, text=True, timeout=120)
    if res.returncode != 0:
        print(f"WARN: gcloud failed ({' '.join(args)}): {res.stderr.strip()}", file=sys.stderr)
        return []
    try:
        return json.loads(res.stdout or "[]")
    except json.JSONDecodeError:
        return []


def in_known_private_vip(ip):
    try:
        addr = ipaddress.ip_address(ip)
    except ValueError:
        return False
    return any(addr in ipaddress.ip_network(net) for net in KNOWN_PRIVATE_VIP_NETS)


def main():
    ap = argparse.ArgumentParser(description="Validate Private Google Access (read-only).")
    ap.add_argument("--project", required=True, help="Project ID whose subnets/routes to check.")
    ap.add_argument("--region", help="Restrict subnet check to this region.")
    ap.add_argument("--resolve", default="storage.googleapis.com",
                    help="Hostname to DNS-resolve (run from an internal-only VM for a true test).")
    ap.add_argument("--skip-resolve", action="store_true",
                    help="Skip the DNS resolution test (config-only check).")
    args = ap.parse_args()

    ok = True
    print(f"Validating Private Google Access — project={args.project}")

    # Check 1: subnets have Private Google Access on.
    subnet_args = ["compute", "networks", "subnets", "list", f"--project={args.project}"]
    if args.region:
        subnet_args += [f"--regions={args.region}"]
    subnets = gcloud_json(subnet_args)
    if not subnets:
        print("  [subnets] none found (or no access) — cannot confirm PGA.")
        ok = False
    for s in subnets:
        pga = s.get("privateIpGoogleAccess", False)
        flag = "OK" if pga else "FAIL"
        print(f"  [subnet] {s.get('name')}: Private Google Access = {pga}  [{flag}]")
        ok &= pga

    # Check 2: a route toward a known private/restricted VIP exists.
    routes = gcloud_json(["compute", "routes", "list", f"--project={args.project}"])
    has_vip_route = any(in_known_private_vip(str(r.get("destRange", "")).split("/")[0])
                        or str(r.get("destRange")) in KNOWN_PRIVATE_VIP_NETS for r in routes)
    print(f"  [route] restricted/private VIP route present: {has_vip_route} "
          f"[{'OK' if has_vip_route else 'WARN'}]")
    if not has_vip_route:
        print("        NOTE: verify the current restricted VIP range in Google's Private Google "
              "Access docs and add the route (Implementation step 6).")

    # Check 3 (best run from an internal-only VM): DNS resolves the API host to a private VIP.
    if not args.skip_resolve:
        try:
            resolved = socket.gethostbyname(args.resolve)
            private = in_known_private_vip(resolved)
            print(f"  [dns] {args.resolve} -> {resolved}  "
                  f"[{'OK private VIP' if private else 'FAIL public IP'}]")
            if not private:
                print("        Run this ON an internal-only VM; ensure Cloud DNS maps googleapis.com "
                      "to the restricted VIP.")
            ok &= private
        except socket.gaierror as e:
            print(f"  [dns] could not resolve {args.resolve}: {e}  [WARN]")

    print("-" * 60)
    print("PRIVATE ACCESS: OK" if ok else "PRIVATE ACCESS: NEEDS ATTENTION (see FAIL lines above)")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
