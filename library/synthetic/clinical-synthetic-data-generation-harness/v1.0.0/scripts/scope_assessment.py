#!/usr/bin/env python3
# scope_assessment.py — profile target model, in-scope domains, reference coverage, and out-dir safety
#
# PURPOSE: Assess a synthetic-EHR build BEFORE generating: resolve the target model (FHIR/OMOP/native),
#          confirm the reference stats cover every in-scope domain, and verify the isolated output
#          directory is safe (isolated, empty of PHI signals). Read-only; writes only an optional report.
# HOW TO RUN: python scope_assessment.py --target-model fhir --profile target-profile.json \
#             --reference reference-stats.json --out-dir /isolated/synthetic-ehr [--report scope.json]
#             (Python 3.10+; see --help)
# EXPECTED RESULTS: A scope summary on stdout and 0 BLOCK issues when the build is ready to proceed;
#                   any BLOCK must be resolved before Stage 2 (Design). Exit code 0 = ready, 1 = blocked.

import argparse
import json
import os
import re
import sys

TARGET_MODELS = {"fhir", "omop", "native"}
DEFAULT_DOMAINS = ["patients", "encounters", "conditions", "medications", "labs", "vitals"]

# Substrings that suggest a path is NOT an isolated synthetic location (safety heuristic, not exhaustive).
PHI_PATH_SIGNALS = ("prod", "production", "phi", "ehr-live", "clinical-live", "patients-real")


def load_json(path):
    if not path or not os.path.isfile(path):
        return None
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"  ! could not read {path}: {exc}")
        return None


def assess_out_dir(out_dir):
    findings = []
    low = out_dir.replace("\\", "/").lower()
    if any(sig in low for sig in PHI_PATH_SIGNALS):
        findings.append(("BLOCK", f"out-dir '{out_dir}' matches a PHI/production signal — refuse to target it"))
    if not os.path.isabs(out_dir):
        findings.append(("WARN", "out-dir is not an absolute path — prefer an absolute isolated path"))
    if os.path.isdir(out_dir):
        try:
            entries = os.listdir(out_dir)
            if entries:
                findings.append(("WARN", f"out-dir is not empty ({len(entries)} entries) — confirm no real data present"))
        except OSError:
            findings.append(("WARN", "out-dir exists but is not listable — check permissions"))
    else:
        findings.append(("INFO", "out-dir does not exist yet — it will be created at --apply time"))
    return findings


def assess_reference(reference, domains):
    findings = []
    if reference is None:
        findings.append(("BLOCK", "no reference stats provided — plausibility cannot be graded (Requirement R2)"))
        return findings
    covered = set(reference.get("domains", {}).keys()) if isinstance(reference.get("domains"), dict) else set()
    for dom in domains:
        if dom in covered:
            findings.append(("INFO", f"reference covers domain '{dom}'"))
        else:
            findings.append(("BLOCK", f"reference has no distribution for domain '{dom}' (Requirement R2)"))
    return findings


def assess_profile(profile, target_model, domains):
    findings = []
    if profile is None:
        findings.append(("BLOCK", "no target profile provided — schema/fields undefined (Requirement R1)"))
        return findings
    pm = str(profile.get("target_model", "")).lower()
    if pm and pm != target_model:
        findings.append(("WARN", f"profile target_model '{pm}' != --target-model '{target_model}'"))
    prof_domains = profile.get("domains", {})
    for dom in domains:
        if dom in prof_domains:
            fields = prof_domains[dom].get("fields", [])
            findings.append(("INFO", f"profile defines domain '{dom}' with {len(fields)} field(s)"))
        else:
            findings.append(("BLOCK", f"profile does not define domain '{dom}' (Requirement R1)"))
    return findings


def main():
    ap = argparse.ArgumentParser(description="Assess a synthetic-EHR build before generation (read-only).")
    ap.add_argument("--target-model", required=True, choices=sorted(TARGET_MODELS),
                    help="target clinical data model: fhir | omop | native")
    ap.add_argument("--profile", help="path to the target-profile JSON (Requirement R1)")
    ap.add_argument("--reference", help="path to the reference-stats JSON (Requirement R2)")
    ap.add_argument("--out-dir", required=True, help="the isolated output directory the harness will write to (R3)")
    ap.add_argument("--domains", default=",".join(DEFAULT_DOMAINS),
                    help="comma-separated in-scope domains (default: %(default)s)")
    ap.add_argument("--report", help="optional path to write the scope report JSON")
    args = ap.parse_args()

    domains = [d.strip() for d in args.domains.split(",") if d.strip()]
    profile = load_json(args.profile)
    reference = load_json(args.reference)

    findings = []
    findings.append(("INFO", f"target model: {args.target_model}"))
    findings.append(("INFO", f"in-scope domains: {', '.join(domains)}"))
    findings += assess_profile(profile, args.target_model, domains)
    findings += assess_reference(reference, domains)
    findings += assess_out_dir(args.out_dir)

    print("=== Synthetic EHR – Scope – Pilot : assessment ===")
    for level, msg in findings:
        print(f"  [{level:5}] {msg}")

    blocks = [m for lvl, m in findings if lvl == "BLOCK"]
    warns = [m for lvl, m in findings if lvl == "WARN"]
    print("\n--- summary ---")
    print(f"  blocking issues : {len(blocks)}")
    print(f"  warnings        : {len(warns)}")
    ready = len(blocks) == 0
    print(f"  ready to design : {'YES' if ready else 'NO — resolve BLOCK issues first'}")

    if args.report:
        report = {
            "artifact": "Synthetic EHR – Scope – Pilot",
            "target_model": args.target_model,
            "domains": domains,
            "out_dir": args.out_dir,
            "blocking": blocks,
            "warnings": warns,
            "ready": ready,
        }
        try:
            with open(args.report, "w", encoding="utf-8") as fh:
                json.dump(report, fh, indent=2)
            print(f"  report written  : {args.report}")
        except OSError as exc:
            print(f"  ! could not write report: {exc}")

    return 0 if ready else 1


if __name__ == "__main__":
    sys.exit(main())
