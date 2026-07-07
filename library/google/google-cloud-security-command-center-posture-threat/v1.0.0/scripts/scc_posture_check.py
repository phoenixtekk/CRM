#!/usr/bin/env python3
# scc_posture_check.py — check live SCC posture against Posture Baseline - Corp - v1 (read-only guardrail).
#
# PURPOSE: Compares the Organization's live posture findings and mute state against the agreed
#          Posture Baseline - Corp - v1 (approved mute exceptions + expected detector categories),
#          reporting DRIFT: un-approved mutes, missing/expired exceptions, and unexpected active
#          categories. READ-ONLY: it changes nothing. Exits non-zero on drift (CI-friendly).
# HOW TO RUN: python scc_posture_check.py --organization ORG_ID --baseline baseline.yaml \
#              [--out drift.json]   (Python 3.10+, gcloud auth / ADC; see --help)
# EXPECTED RESULTS: A printed drift summary and optional JSON. Exit 0 = compliant, 1 = drift found.
#
# NOTE: SCC editions/detectors are version-dependent — the baseline lists the categories YOUR
#       edition surfaces; verify them in Console/Settings. Uses `gcloud` (no keys in code, ADC).

import argparse
import json
import subprocess
import sys

try:
    import yaml
except ImportError:
    yaml = None


def run_gcloud_json(args):
    cmd = ["gcloud"] + args + ["--format=json"]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    except FileNotFoundError:
        print("ERROR: gcloud not found on PATH.", file=sys.stderr)
        sys.exit(2)
    if proc.returncode != 0:
        print(f"WARN: gcloud returned {proc.returncode}: {proc.stderr.strip()}", file=sys.stderr)
        return []
    try:
        return json.loads(proc.stdout or "[]")
    except json.JSONDecodeError:
        return []


def load_baseline(path):
    if yaml is None:
        print("ERROR: PyYAML required for --baseline (pip install pyyaml).", file=sys.stderr)
        sys.exit(2)
    with open(path, encoding="utf-8") as fh:
        data = yaml.safe_load(fh) or {}
    return {
        # Mute config IDs that are approved exceptions.
        "approved_mutes": set(data.get("approved_mutes", [])),
        # Categories the baseline expects to be actively monitored (not permanently muted).
        "expected_categories": set(data.get("expected_categories", [])),
    }


def list_mute_configs(org):
    # Verify the mute-config list subcommand for your edition.
    return run_gcloud_json(["scc", "muteconfigs", "list", f"--organization={org}"])


def list_active_categories(org):
    findings = run_gcloud_json(["scc", "findings", "list", org, "--filter", 'state="ACTIVE"'])
    cats = set()
    for item in findings:
        finding = item.get("finding", item) if isinstance(item, dict) else {}
        cats.add(finding.get("category", "UNSPECIFIED"))
    return cats


def main():
    ap = argparse.ArgumentParser(description="Read-only SCC posture-baseline drift check.")
    ap.add_argument("--organization", required=True, help="Organization ID (numeric).")
    ap.add_argument("--baseline", required=True,
                    help="YAML baseline: approved_mutes + expected_categories (Posture Baseline - Corp - v1).")
    ap.add_argument("--out", help="Optional path to write the drift JSON.")
    args = ap.parse_args()

    org = args.organization.split("/")[-1]
    baseline = load_baseline(args.baseline)

    mute_configs = list_mute_configs(org)
    live_mute_ids = {m.get("name", "").split("/")[-1] for m in mute_configs if m.get("name")}
    active_categories = list_active_categories(org)

    unapproved_mutes = sorted(live_mute_ids - baseline["approved_mutes"])
    missing_approved = sorted(baseline["approved_mutes"] - live_mute_ids)
    # Expected categories that have NO active findings could mean the detector is off/muted — flag.
    silent_expected = sorted(baseline["expected_categories"] - active_categories) \
        if baseline["expected_categories"] else []

    drift = {
        "organization": org,
        "unapproved_mutes": unapproved_mutes,          # mutes live but NOT in the baseline
        "missing_approved_mutes": missing_approved,     # baseline exceptions not present
        "expected_categories_with_no_active_findings": silent_expected,
        "note": "SCC editions/detectors are version-dependent; verify expected_categories for your edition.",
    }
    has_drift = bool(unapproved_mutes or missing_approved or silent_expected)

    print(f"SCC posture check — org {org} vs Posture Baseline - Corp - v1")
    print(f"  Unapproved mutes (live, not in baseline): {len(unapproved_mutes)}")
    for m in unapproved_mutes:
        print(f"    ! {m}")
    print(f"  Missing approved mutes (baseline, not live): {len(missing_approved)}")
    for m in missing_approved:
        print(f"    ? {m}")
    print(f"  Expected categories with no active findings (verify detector on): {len(silent_expected)}")
    for c in silent_expected:
        print(f"    - {c}")

    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(drift, fh, indent=2)
        print(f"  Wrote {args.out}")

    print("  RESULT:", "DRIFT" if has_drift else "COMPLIANT")
    sys.exit(1 if has_drift else 0)


if __name__ == "__main__":
    main()
