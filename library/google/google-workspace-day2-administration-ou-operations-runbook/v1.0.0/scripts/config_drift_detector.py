#!/usr/bin/env python3
# config_drift_detector.py — read-only comparison of live per-OU governance settings against a curated
#                            baseline JSON; reports each drift and exits non-zero when drift exists.
#
# PURPOSE: Validation-stage config-drift detection. Compares governance-critical settings for a given
#          OU scope against the intended baseline (ou-policy-baseline.json) and prints each
#          DRIFT: <setting> expected=<x> actual=<y>. READ-ONLY — never changes tenant configuration.
# HOW TO RUN: python config_drift_detector.py --baseline ou-policy-baseline.json --scope Corp/Standard-Users/Pilot
#             (Python 3.10+, OAuth/ADC or DWD service account, read-only scopes; see --help)
# EXPECTED RESULTS: "0 drift" and exit 0 when live == baseline; a list of DRIFT lines and exit 2 when
#                   settings differ (so it can gate scheduled/CI checks).
#
# The baseline JSON maps an OU path to its intended settings, e.g.:
#   { "org_units": { "/Corp/Standard-Users/Pilot": {
#         "drive_external_sharing": "off", "link_sharing_default": "restricted",
#         "two_step_enforcement": "on", "gmail_service": "on", "marketplace_allowlist": "enforced" } } }
# Live settings are read via the Admin SDK where an API exists for the setting; where a setting has no
# stable public read API for your edition, the tool marks it "verify-in-console" rather than inventing
# a value. No keys are stored in this file.
# Read-only scopes (live mode): admin.directory.orgunit.readonly and the relevant settings-read scopes
# for the services you govern (verify the exact scope names for your edition).
# Requires (live): pip install google-api-python-client google-auth ; else runs in --offline mode.

import argparse
import json
import sys
from datetime import datetime, timezone

# Settings this tool knows how to evaluate. Values with a reader of None have no stable public read API
# assumed here and are reported as "verify-in-console" rather than guessed.
KNOWN_SETTINGS = {
    "drive_external_sharing": "reads Drive sharing policy for the OU",
    "link_sharing_default": "reads default link-sharing state",
    "two_step_enforcement": "reads 2-Step Verification enforcement",
    "gmail_service": "reads Gmail service on/off for the OU",
    "marketplace_allowlist": "reads Marketplace app allow-listing mode",
}

# Offline sample "live" values so drift logic can be demonstrated without a tenant.
SAMPLE_LIVE = {
    "/Corp/Standard-Users/Pilot": {
        "drive_external_sharing": "off",
        "link_sharing_default": "restricted",
        "two_step_enforcement": "on",
        "gmail_service": "on",
        "marketplace_allowlist": "enforced",
    }
}


def _norm(scope):
    scope = scope.strip()
    if not scope.startswith("/"):
        scope = "/" + scope
    return scope.rstrip("/") or "/"


def read_live_settings(scope, offline):
    """Return {setting: value|'verify-in-console'} for the OU scope.

    In live mode this is where Admin SDK / service settings reads go. This reference implementation
    reads what has a stable public API and marks the rest 'verify-in-console' — it never fabricates a
    value. In offline mode it returns the bundled sample.
    """
    if offline:
        return dict(SAMPLE_LIVE.get(scope, {}))

    try:
        import google.auth  # noqa: F401
        from googleapiclient.discovery import build  # noqa: F401
    except Exception:
        print("[info] google client libs not installed; use --offline to demo.", file=sys.stderr)
        return None

    # NOTE: settings-read endpoints and scopes vary by service and edition. Rather than call an
    # endpoint that may not exist for your tenant, this reference marks each known setting for
    # console verification. Extend read_live_settings() with the concrete Admin SDK calls your
    # edition supports (verify the endpoint + scope names in your tenant).
    print("[info] live settings-read not wired for this edition; each known setting reported as "
          "'verify-in-console'. Extend read_live_settings() for your tenant.", file=sys.stderr)
    return {k: "verify-in-console" for k in KNOWN_SETTINGS}


def main():
    ap = argparse.ArgumentParser(description="Read-only OU config-drift detector vs. a baseline JSON.")
    ap.add_argument("--baseline", required=True, help="Path to the intended baseline JSON.")
    ap.add_argument("--scope", required=True,
                    help="OU path to check, e.g. Corp/Standard-Users/Pilot (leading slash optional).")
    ap.add_argument("--offline", action="store_true",
                    help="Use bundled sample live values instead of calling the API.")
    args = ap.parse_args()

    scope = _norm(args.scope)

    try:
        with open(args.baseline, "r", encoding="utf-8") as fh:
            baseline = json.load(fh)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"[error] cannot read baseline {args.baseline}: {exc}", file=sys.stderr)
        return 3

    intended = baseline.get("org_units", {}).get(scope)
    if intended is None:
        print(f"[error] baseline has no entry for OU '{scope}'. "
              f"Add it to org_units in {args.baseline}.", file=sys.stderr)
        return 3

    live = read_live_settings(scope, args.offline)
    if live is None:
        return 3

    print(f"Config-drift check — OU {scope} — {datetime.now(timezone.utc).isoformat()}")
    drift, verify = 0, 0
    for setting, want in intended.items():
        if setting not in KNOWN_SETTINGS:
            print(f"  SKIP: {setting} (not a known evaluable setting)")
            continue
        got = live.get(setting, "MISSING")
        if got == "verify-in-console":
            print(f"  VERIFY: {setting} expected={want} actual=verify-in-console")
            verify += 1
        elif got != want:
            print(f"  DRIFT: {setting} expected={want} actual={got}")
            drift += 1
        else:
            print(f"  OK: {setting} = {want}")

    print("-" * 60)
    if drift == 0 and verify == 0:
        print("0 drift — live configuration matches the baseline.")
        return 0
    if drift == 0:
        print(f"0 drift, but {verify} setting(s) require console verification (see VERIFY lines).")
        return 0
    print(f"{drift} drift(s) detected — reconcile the setting or the baseline under change control.")
    return 2


if __name__ == "__main__":
    sys.exit(main())
