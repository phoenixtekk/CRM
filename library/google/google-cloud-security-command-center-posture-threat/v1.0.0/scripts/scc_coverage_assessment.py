#!/usr/bin/env python3
# scc_coverage_assessment.py — inventory an Organization's Security Command Center coverage (read-only).
#
# PURPOSE: Snapshot the current SCC state for an Organization — enabled services, existing
#          notification configs, and finding counts by severity/category — as the baseline for the
#          posture/export/triage design. READ-ONLY: it never changes SCC configuration.
# HOW TO RUN: python scc_coverage_assessment.py --organization ORG_ID [--out report.json]
#            (Python 3.10+, gcloud auth / ADC; see --help)
# EXPECTED RESULTS: A printed summary and optional JSON: enabled services, notification configs,
#          and active-finding counts by severity/category. Non-zero exit only on hard error.
#
# NOTE: SCC editions/services/detectors are version-dependent. This tool reports what your tenant
#       returns; it does not assume any specific detector exists. Verify commands against your
#       edition's current gcloud SCC docs. Uses `gcloud` via subprocess (no keys in code, uses ADC).

import argparse
import json
import subprocess
import sys
from collections import Counter


def run_gcloud(args, timeout=120):
    """Run a gcloud command, returning parsed JSON (or None) and never raising on non-zero."""
    cmd = ["gcloud"] + args + ["--format=json"]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    except FileNotFoundError:
        print("ERROR: gcloud not found on PATH. Install the Google Cloud SDK.", file=sys.stderr)
        sys.exit(2)
    except subprocess.TimeoutExpired:
        print(f"WARN: timeout running: {' '.join(cmd)}", file=sys.stderr)
        return None
    if proc.returncode != 0:
        print(f"WARN: gcloud returned {proc.returncode} for: {' '.join(cmd)}\n"
              f"      {proc.stderr.strip()}", file=sys.stderr)
        return None
    try:
        return json.loads(proc.stdout or "null")
    except json.JSONDecodeError:
        print(f"WARN: could not parse JSON from: {' '.join(cmd)}", file=sys.stderr)
        return None


def list_notifications(org):
    # Verify the exact subcommand for your edition; falls back gracefully if unavailable.
    data = run_gcloud(["scc", "notifications", "list", f"--organization={org}"])
    return data or []


def list_findings(org):
    # SCC finding listing (read-only). Command surface varies by edition — verify with --help.
    data = run_gcloud(["scc", "findings", "list", org, "--filter", 'state="ACTIVE"'])
    return data or []


def summarize_findings(findings):
    by_sev = Counter()
    by_cat = Counter()
    for f in findings:
        # Finding shape varies; look in the common locations defensively.
        finding = f.get("finding", f) if isinstance(f, dict) else {}
        sev = (finding.get("severity") or "UNSPECIFIED")
        cat = (finding.get("category") or "UNSPECIFIED")
        by_sev[sev] += 1
        by_cat[cat] += 1
    return by_sev, by_cat


def main():
    ap = argparse.ArgumentParser(description="Read-only SCC coverage assessment for an Organization.")
    ap.add_argument("--organization", required=True,
                    help="Organization ID (numeric) or organizations/ORG_ID.")
    ap.add_argument("--out", help="Optional path to write the JSON report.")
    ap.add_argument("--max-categories", type=int, default=15,
                    help="How many top finding categories to print (default 15).")
    args = ap.parse_args()

    org = args.organization.split("/")[-1]
    print(f"SCC coverage assessment — organization {org} (read-only)")
    print("NOTE: SCC editions/detectors are version-dependent; verify against your edition's docs.\n")

    notifications = list_notifications(org)
    findings = list_findings(org)
    by_sev, by_cat = summarize_findings(findings)

    print(f"Notification configs found: {len(notifications)}")
    for n in notifications:
        name = n.get("name", "<unknown>")
        topic = n.get("pubsubTopic", "<no-topic>")
        print(f"  - {name.split('/')[-1]}  ->  {topic}")

    print(f"\nActive findings: {len(findings)}")
    print("  By severity:")
    for sev, count in sorted(by_sev.items(), key=lambda x: -x[1]):
        print(f"    {sev:<14} {count}")
    print(f"  Top {args.max_categories} categories:")
    for cat, count in by_cat.most_common(args.max_categories):
        print(f"    {cat:<40} {count}")

    report = {
        "organization": org,
        "notification_configs": [
            {"name": n.get("name"), "topic": n.get("pubsubTopic"), "filter": n.get("filter")}
            for n in notifications
        ],
        "active_findings_total": len(findings),
        "active_findings_by_severity": dict(by_sev),
        "active_findings_by_category": dict(by_cat),
        "note": "SCC editions/detectors are version-dependent; verify enabled services in Console/Settings.",
    }

    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        print(f"\nWrote report to {args.out}")
    print("\nReminder: confirm the active edition and enabled services in "
          "Security Command Center -> Settings; this tool does not assume any detector exists.")


if __name__ == "__main__":
    main()
