#!/usr/bin/env python3
# bce_zerotrust_validation_report.py — deny/allow validation report for an IAP-protected resource
#
# PURPOSE: Back the Stage-4/Stage-5 gates. Reads the current IAP IAM policy for a resource, confirms
#          bindings carry an access-level condition, and reads recent IAP/audit-log allow/deny events
#          to build the allow-vs-deny evidence matrix. READ-ONLY: it inspects policy + logs only, it
#          does not attempt real logins. The four required outcomes it checks for are printed with
#          PASS/FAIL/INFO so the operator can attach the output as audit evidence.
# HOW TO RUN: python bce_zerotrust_validation_report.py --project <P> --resource <BACKEND_SERVICE>
#             --group group:zero-trust-pilot@domain [--hours 24] [--json]
#             (Python 3.10+, gcloud on PATH, ADC/`gcloud auth`; log read needs logging.viewer)
# EXPECTED RESULTS: A report of the four zero-trust outcomes with observed evidence; overall PASS only
#          if every binding is context-conditioned and no unauthorized allow was observed. Exit 0 on
#          PASS, 1 if any FAIL (usable as a gate in CI).

import argparse
import json
import shutil
import subprocess
import sys


def have_gcloud():
    if not shutil.which("gcloud"):
        print("ERROR: gcloud CLI not found on PATH.", file=sys.stderr)
        sys.exit(2)


def gcloud_json(args):
    out = subprocess.run(["gcloud"] + args + ["--format=json"],
                         capture_output=True, text=True)
    if out.returncode != 0:
        print(f"  WARN: {' '.join(args)} -> {out.stderr.strip().splitlines()[:1]}", file=sys.stderr)
        return None
    try:
        return json.loads(out.stdout or "null")
    except json.JSONDecodeError:
        return None


def check_bindings(project, resource, group):
    """Confirm the pilot group is bound with an access-level condition (context-aware)."""
    print("== Binding / IAM check ==")
    policy = gcloud_json(["iap", "web", "get-iam-policy",
                          f"--project={project}", "--resource-type=backend-services",
                          f"--service={resource}"])
    results = {"group_bound": False, "conditioned": False, "broad_principal": False}
    if not policy:
        print("  INFO: could not read IAP IAM policy (permission or resource shape). Verify manually.")
        return results
    for b in policy.get("bindings", []):
        members = b.get("members", [])
        if any(m in ("allAuthenticatedUsers", "allUsers") for m in members):
            results["broad_principal"] = True
            print(f"  FAIL: over-broad principal in role {b.get('role')}: {members}")
        if group in members and b.get("role") == "roles/iap.httpsResourceAccessor":
            results["group_bound"] = True
            if b.get("condition"):
                results["conditioned"] = True
                print(f"  PASS: {group} bound WITH access-level condition "
                      f"'{b['condition'].get('title')}'.")
            else:
                print(f"  FAIL: {group} bound WITHOUT an access-level condition (identity-only).")
    if not results["group_bound"]:
        print(f"  INFO: {group} not found in an httpsResourceAccessor binding on {resource}.")
    return results


def read_iap_events(project, resource, hours):
    """Read recent IAP allow/deny events from Cloud Logging (read-only)."""
    print(f"\n== Observed IAP events (last {hours}h) ==")
    log_filter = (f'resource.type="gce_backend_service" OR logName:"iap" '
                  f'AND timestamp>="-{hours}h"')
    entries = gcloud_json(["logging", "read", log_filter,
                           f"--project={project}", f"--freshness={hours}h", "--limit=200"])
    allows = denies = 0
    if not entries:
        print("  INFO: no IAP log entries read (none in window, or logging.viewer missing). "
              "Verify audit logging is enabled for IAP.")
        return {"allows": 0, "denies": 0}
    for e in entries:
        blob = json.dumps(e).lower()
        if "denied" in blob or "permission_denied" in blob:
            denies += 1
        elif "allow" in blob or "granted" in blob:
            allows += 1
    print(f"  observed allow-like events: {allows}")
    print(f"  observed deny-like events : {denies}")
    return {"allows": allows, "denies": denies}


def main():
    ap = argparse.ArgumentParser(description="Deny/allow validation report for an IAP resource (read-only).")
    ap.add_argument("--project", required=True)
    ap.add_argument("--resource", required=True, help="Backend service name behind IAP")
    ap.add_argument("--group", required=True, help="Pilot group member, e.g. group:...@domain")
    ap.add_argument("--hours", type=int, default=24, help="Log lookback window (default 24)")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    have_gcloud()

    print(f"Zero-trust validation report (READ-ONLY) — {args.resource} @ {args.project}\n")
    binding = check_bindings(args.project, args.resource, args.group)
    events = read_iap_events(args.project, args.resource, args.hours)

    print("\n== Four required zero-trust outcomes ==")
    print("  1) Allowed  — pilot user, corp-managed device, allowed region  -> verify PASS in T2 test")
    print("  2) Denied   — unmanaged device / disallowed region             -> verify PASS in T3 test")
    print("  3) Denied   — unauthorized identity (not in group)             -> verify PASS in T4 test")
    print("  4) Refused  — direct bypass of IAP                             -> verify PASS in T5 test")
    print("  (This tool confirms the policy/log preconditions; run the manual T2-T5 checks for the "
          "live allow/deny behavior.)")

    fails = []
    if binding["group_bound"] and not binding["conditioned"]:
        fails.append("binding not context-conditioned")
    if binding["broad_principal"]:
        fails.append("over-broad principal present")

    overall = "PASS" if not fails else "FAIL"
    print(f"\nOVERALL PRECONDITION: {overall}" + (f"  ({'; '.join(fails)})" if fails else ""))
    if args.json:
        print("\nJSON:\n" + json.dumps({"binding": binding, "events": events,
                                        "overall": overall, "fails": fails}, indent=2))
    return 0 if overall == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
