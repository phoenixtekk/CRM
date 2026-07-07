#!/usr/bin/env python3
# gcp_naming_label_helper.py — emit and validate the landing-zone naming/labeling standard.
#
# PURPOSE: Emit the "<Purpose> - <Scope> - <Stage>" name grammar and the required label key set,
#          and validate candidate names/labels (or scan an Organization's live resources) against
#          it. READ-ONLY — it reports conformance, it never changes resources.
# HOW TO RUN: python gcp_naming_label_helper.py --emit-standard [--output naming-standard.json]
#             python gcp_naming_label_helper.py --validate --check-name "Logging - Common - Prod"
#             python gcp_naming_label_helper.py --validate --scan-organization ORG_ID
#             (Python 3.10+; --scan-organization needs gcloud authenticated / ADC; see --help)
# EXPECTED RESULTS: The standard as JSON, or a per-resource CONFORMS/VIOLATION list with the
#          expected form. Non-zero exit if any scanned resource violates the standard.

import argparse
import json
import re
import shutil
import subprocess
import sys

# Name grammar: "<Purpose> - <Scope> - <Stage>". Stage is a closed set; Purpose/Scope are
# free tokens (letters, digits, spaces, hyphen, slash) with single " - " separators.
NAME_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 /]*"
                     r" - [A-Za-z0-9][A-Za-z0-9 /-]*"
                     r" - (Prod|Non-Prod|Pilot|Dev|Test|Shared)$")
REQUIRED_LABEL_KEYS = ["env", "owner", "cost-center", "data-class"]
ALLOWED_ENV_VALUES = ["prod", "non-prod", "dev", "test", "shared", "pilot"]


def standard():
    return {
        "name_grammar": "<Purpose> - <Scope> - <Stage>",
        "name_regex": NAME_RE.pattern,
        "allowed_stages": ["Prod", "Non-Prod", "Pilot", "Dev", "Test", "Shared"],
        "examples": [
            "Logging - Common - Prod",
            "Networking-Host - Shared-VPC - Prod",
            "Landing Zone - Pilot",  # short form for the pilot scope
            "Bootstrap - Seed - Prod",
        ],
        "required_label_keys": REQUIRED_LABEL_KEYS,
        "allowed_env_values": ALLOWED_ENV_VALUES,
        "notes": "Human-facing display names use the grammar; project IDs use the lowercase/"
                 "hyphen form gcloud requires. Labels are machine-queryable attribution.",
    }


def validate_name(name):
    # The pilot short form "Landing Zone - Pilot" is explicitly allowed.
    if name == "Landing Zone - Pilot":
        return True, "ok (pilot short form)"
    if NAME_RE.match(name):
        return True, "ok"
    return False, "expected '<Purpose> - <Scope> - <Stage>' with Stage in " \
                  "{Prod,Non-Prod,Pilot,Dev,Test,Shared}"


def validate_labels(labels):
    labels = labels or {}
    missing = [k for k in REQUIRED_LABEL_KEYS if k not in labels]
    problems = []
    if missing:
        problems.append(f"missing label keys: {missing}")
    env = labels.get("env")
    if env is not None and env not in ALLOWED_ENV_VALUES:
        problems.append(f"env='{env}' not in {ALLOWED_ENV_VALUES}")
    return (not problems), ("ok" if not problems else "; ".join(problems))


def scan_org(org_id):
    g = shutil.which("gcloud")
    if not g:
        sys.exit("ERROR: gcloud CLI not found on PATH for --scan-organization.")
    res = subprocess.run(
        [g, "projects", "list", f"--filter=parent.type=folder OR parent.id={org_id}",
         "--format=json"], capture_output=True, text=True)
    if res.returncode != 0:
        sys.exit(f"ERROR: could not list projects: {res.stderr.strip()}")
    try:
        projects = json.loads(res.stdout) if res.stdout.strip() else []
    except json.JSONDecodeError:
        projects = []
    violations = 0
    print(f"== Naming/label scan — org {org_id}, {len(projects)} project(s) ==")
    for p in projects:
        name = p.get("name", p.get("projectId", ""))
        labels = p.get("labels", {})
        nok, ndetail = validate_name(name)
        lok, ldetail = validate_labels(labels)
        status = "CONFORMS" if (nok and lok) else "VIOLATION"
        if status == "VIOLATION":
            violations += 1
        print(f"  [{status}] {p.get('projectId')} name='{name}': {ndetail} | labels: {ldetail}")
    print(f"\n{violations} violation(s).")
    return violations


def main():
    ap = argparse.ArgumentParser(description="Landing-zone naming/label standard helper (read-only).")
    ap.add_argument("--emit-standard", action="store_true", help="Print the standard as JSON.")
    ap.add_argument("--output", help="Write the emitted standard to this path.")
    ap.add_argument("--validate", action="store_true", help="Run validation mode.")
    ap.add_argument("--check-name", help="Validate a single candidate name.")
    ap.add_argument("--check-labels", help="Validate a labels JSON string, e.g. '{\"env\":\"prod\"}'.")
    ap.add_argument("--scan-organization", help="Scan an Organization's projects for conformance.")
    args = ap.parse_args()

    if args.emit_standard:
        js = json.dumps(standard(), indent=2)
        if args.output:
            with open(args.output, "w", encoding="utf-8") as fh:
                fh.write(js)
            print(f"Standard written to {args.output}")
        else:
            print(js)
        return

    if args.validate:
        rc = 0
        if args.check_name:
            ok, detail = validate_name(args.check_name)
            print(f"name '{args.check_name}': {'CONFORMS' if ok else 'VIOLATION'} — {detail}")
            rc = rc or (0 if ok else 1)
        if args.check_labels:
            ok, detail = validate_labels(json.loads(args.check_labels))
            print(f"labels: {'CONFORMS' if ok else 'VIOLATION'} — {detail}")
            rc = rc or (0 if ok else 1)
        if args.scan_organization:
            rc = rc or (1 if scan_org(args.scan_organization) else 0)
        if not (args.check_name or args.check_labels or args.scan_organization):
            ap.error("--validate needs one of --check-name / --check-labels / --scan-organization")
        sys.exit(rc)

    ap.error("choose --emit-standard or --validate (see --help)")


if __name__ == "__main__":
    main()
