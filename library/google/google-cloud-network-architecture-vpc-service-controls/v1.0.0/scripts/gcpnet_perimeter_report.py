#!/usr/bin/env python3
# gcpnet_perimeter_report.py — VPC-SC perimeter + private-access validation report (read-only)
#
# PURPOSE: Generate a go/no-go report for a VPC Service Controls perimeter: whether it exists, its
#          mode (DRY-RUN vs ENFORCED), restricted services, resources, referenced access levels, and a
#          summary of dry-run would-deny violations — the evidence for Gate G2 before enforcement.
#          READ-ONLY — makes no changes.
# HOW TO RUN: python gcpnet_perimeter_report.py --policy POLICY_ID --perimeter perimeter_prod_v1 \
#             [--json report.json] (Python 3.10+, gcloud auth / ADC; see --help.)
# EXPECTED RESULTS: A printed report with a clear READY-TO-ENFORCE / NOT-READY verdict and optional
#          JSON evidence artifact for the change record.

import argparse
import json
import shutil
import subprocess
import sys


def gcloud_json(args):
    exe = shutil.which("gcloud")
    if not exe:
        print("ERROR: gcloud not found on PATH.", file=sys.stderr)
        sys.exit(2)
    res = subprocess.run([exe] + args + ["--format=json"], capture_output=True, text=True, timeout=120)
    if res.returncode != 0:
        print(f"WARN: gcloud failed ({' '.join(args)}): {res.stderr.strip()}", file=sys.stderr)
        return None
    try:
        return json.loads(res.stdout or "null")
    except json.JSONDecodeError:
        return None


def count_dry_run_violations(project, limit):
    exe = shutil.which("gcloud")
    log_filter = (
        'protoPayload.metadata."@type"='
        '"type.googleapis.com/google.cloud.audit.VpcServiceControlAuditMetadata" '
        'AND protoPayload.metadata.dryRun=true'
    )
    cmd = [exe, "logging", "read", log_filter, "--limit", str(limit),
           "--format=value(protoPayload.resourceName)"]
    if project:
        cmd += [f"--project={project}"]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        return None
    return len([ln for ln in res.stdout.splitlines() if ln.strip()])


def main():
    ap = argparse.ArgumentParser(description="VPC-SC perimeter validation report (read-only).")
    ap.add_argument("--policy", required=True, help="Access Context Manager policy ID.")
    ap.add_argument("--perimeter", required=True, help="Perimeter id, e.g. perimeter_prod_v1.")
    ap.add_argument("--project", help="Project to scope the dry-run violation log count to.")
    ap.add_argument("--limit", type=int, default=200, help="Max violation entries to count.")
    ap.add_argument("--json", help="Write the report to this JSON file (change-record evidence).")
    args = ap.parse_args()

    per = gcloud_json(["access-context-manager", "perimeters", "describe", args.perimeter,
                       f"--policy={args.policy}"])
    report = {"policy": args.policy, "perimeter": args.perimeter, "exists": bool(per),
              "mode": None, "restricted_services": [], "resources": [], "access_levels": [],
              "dry_run_violations": None, "verdict": "NOT-READY"}

    print("=" * 68)
    print(f"VPC-SC PERIMETER REPORT — {args.perimeter}")
    print("=" * 68)
    if not per:
        print("Perimeter not found under this policy. Create it in DRY-RUN first (Implementation "
              "Stage 4).")
        _finish(report, args)
        sys.exit(1)

    status = per.get("status", {}) or {}
    spec = per.get("spec", {}) or {}
    use_explicit_dry_run = per.get("useExplicitDryRunSpec", False)
    # If a spec exists and differs from status / explicit dry-run is set, it is being run in dry-run.
    mode = "DRY-RUN" if (use_explicit_dry_run or spec) and not _enforced_equals_spec(status, spec) \
        else "ENFORCED"
    report["mode"] = mode
    active = spec if (use_explicit_dry_run or spec) else status
    report["restricted_services"] = active.get("restrictedServices", [])
    report["resources"] = active.get("resources", [])
    report["access_levels"] = active.get("accessLevels", [])

    print(f"  mode:                {mode}")
    print(f"  resources:           {len(report['resources'])} -> {report['resources']}")
    print(f"  restricted services: {report['restricted_services']}")
    print(f"  access levels:       {report['access_levels'] or '(none referenced)'}")

    v = count_dry_run_violations(args.project, args.limit)
    report["dry_run_violations"] = v
    if v is None:
        print("  dry-run violations:  (could not read logs — check audit logging / permissions)")
    else:
        print(f"  dry-run would-deny violations (sampled): {v}")

    # Verdict logic (advisory — a human still gates enforcement).
    ready = bool(report["restricted_services"]) and bool(report["resources"])
    if mode == "ENFORCED":
        report["verdict"] = "ALREADY-ENFORCED"
    elif ready:
        report["verdict"] = "READY-TO-ENFORCE (after confirming all listed dry-run violations are " \
                            "intended blocks)"
    print("-" * 68)
    print(f"VERDICT: {report['verdict']}")
    if mode == "DRY-RUN":
        print("Reminder: enforce only after every LEGITIMATE dry-run violation has an ingress/egress "
              "rule; keep the prior spec for rollback (Implementation Stage 5).")
    print("=" * 68)
    _finish(report, args)


def _enforced_equals_spec(status, spec):
    """Heuristic: if there is no separate spec, the perimeter is enforced via status only."""
    return not spec


def _finish(report, args):
    if args.json:
        with open(args.json, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        print(f"Wrote {args.json}")


if __name__ == "__main__":
    main()
