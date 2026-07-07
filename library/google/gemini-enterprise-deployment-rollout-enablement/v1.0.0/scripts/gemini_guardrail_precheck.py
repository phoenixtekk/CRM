#!/usr/bin/env python3
# gemini_guardrail_precheck.py — verify governance guardrails before enabling Gemini (read-only)
#
# PURPOSE: Read-only guardrail gate (Gate G0). Before enabling Gemini for a scope, confirm the
#          governance baseline owned by the SEPARATE governance solution is present for that OU/group
#          — DLP posture, data-region/residency, model-usage/admin-security policy. This tool checks
#          for the presence of those controls; it does NOT create or modify any guardrail (that is the
#          governance solution's job).
# HOW TO RUN: python gemini_guardrail_precheck.py --ou "/Pilot/Wave0" --dry-run
#             python gemini_guardrail_precheck.py --ou "/Pilot/Wave0" --expect guardrail-baseline.json
#             (Python 3.10+, gcloud auth / ADC; read-only Admin/DLP inspect scopes; see --help)
# EXPECTED RESULTS: A per-control present/absent list and 'GATE G0: PASS/FAIL'. Non-zero exit on a
#          missing guardrail (do not enable Gemini on an ungoverned scope).
#
# NOTES:
#   - SAFE BY DEFAULT: read-only. No --apply; this tool never changes a guardrail.
#   - NO hardcoded credentials/keys — ADC / gcloud auth or an authorized service account from the
#     environment only. No key in code.
#   - SCOPE BOUNDARY: this tool asserts the governance baseline EXISTS; it does not configure it. The
#     exact guardrail controls/labels are owned by the governance solution and are version-dependent —
#     VERIFY IN YOUR TENANT and express the expected baseline via --expect <baseline.json>.

import argparse
import json
import sys
from datetime import datetime, timezone


# The guardrails this deployment REQUIRES to be present (configured by the governance solution).
# Presence checks are intentionally conservative — a control we cannot confirm is reported UNKNOWN,
# never silently PASS.
REQUIRED_GUARDRAILS = [
    {"key": "dlp_posture", "desc": "DLP rules applicable to Gemini-reachable content for the scope"},
    {"key": "data_region", "desc": "Data-region / residency setting appropriate for the scope"},
    {"key": "model_usage_policy", "desc": "Model-usage / generative-AI admin policy in effect"},
    {"key": "admin_security_policy", "desc": "Admin-security baseline (access, logging) for the scope"},
]


def _iso_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _load_expected(path: str | None) -> dict:
    """Expected baseline: {guardrail_key: true} the governance owner asserts is deployed."""
    if not path:
        return {}
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return json.load(fh)
    except OSError as exc:
        print(f"  WARNING: cannot read expected baseline {path}: {exc}")
        return {}


def cmd_precheck(args) -> int:
    print(f"[gate G0] guardrail pre-check for OU '{args.ou}' (governance baseline must be present)")
    expected = _load_expected(args.expect)
    if not expected:
        print("  No --expect baseline supplied. This tool cannot INVENT guardrail state.")
        print("  VERIFY IN YOUR TENANT with the governance owner that the baseline is deployed for")
        print("  this scope, then express it as guardrail-baseline.json:")
        print('    { "dlp_posture": true, "data_region": true, "model_usage_policy": true,')
        print('      "admin_security_policy": true }')

    all_present = True
    any_unknown = False
    results = []
    for g in REQUIRED_GUARDRAILS:
        state = expected.get(g["key"])
        if state is True:
            status = "PRESENT"
        elif state is False:
            status = "MISSING"
            all_present = False
        else:
            status = "UNKNOWN"
            any_unknown = True
        print(f"  - {g['key']:22s} {status:8s} — {g['desc']}")
        results.append({"guardrail": g["key"], "status": status})

    report = {"generated": _iso_now(), "ou": args.ou, "results": results}
    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        print(f"  report written -> {args.out}")

    if not all_present:
        print("GATE G0: FAIL — a required guardrail is MISSING. Do NOT enable Gemini on this scope;")
        print("  complete the Gemini governance solution for this scope first.")
        return 1
    if any_unknown:
        print("GATE G0: INDETERMINATE — one or more guardrails UNKNOWN. VERIFY IN YOUR TENANT with the")
        print("  governance owner and supply a complete --expect baseline. Not treating UNKNOWN as PASS.")
        return 2
    print("GATE G0: PASS — required governance guardrails present for this scope.")
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Verify Gemini governance guardrails before enablement (read-only).")
    p.add_argument("--ou", required=True, help="Target OU path or group (e.g. /Pilot/Wave0).")
    p.add_argument("--expect", default=None, help="guardrail-baseline.json asserting deployed guardrails.")
    p.add_argument("--out", default=None, help="Write the pre-check report JSON here.")
    p.add_argument("--dry-run", action="store_true", default=True, help="Read-only (default; always).")
    return p


def main(argv=None) -> int:
    return cmd_precheck(build_parser().parse_args(argv))


if __name__ == "__main__":
    sys.exit(main())
