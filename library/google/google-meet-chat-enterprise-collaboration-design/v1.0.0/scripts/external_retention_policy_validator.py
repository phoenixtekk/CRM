#!/usr/bin/env python3
# external_retention_policy_validator.py — validate external-access & retention posture vs. design (read-only).
#
# PURPOSE: Compare the intended Meet/Chat external-access and Chat retention design (design.json,
#          with observed values captured from the console/assessment) against what the tool can
#          confirm, and report DRIFT with a pass/fail per control. READ-ONLY: performs no writes.
#          Validates the "Chat External Policy - Allowlisted Domains - Enforce" and
#          "Vault Retention - Chat 3yr - Enforce" artifacts among others.
# HOW TO RUN: python external_retention_policy_validator.py --domain your-domain.com \
#             --config design.json --out validation.json   (Python 3.10+, OAuth/ADC; see --help)
# EXPECTED RESULTS: writes validation.json and prints PASS/FAIL per control; overall exit 0 when all
#          validated controls pass, exit 1 when any drift/fail is found (read-only either way).

import argparse
import json
import sys
from datetime import datetime, timezone

# Controls this validator checks. 'source' notes whether the observed value comes from the design's
# captured console observation or (where available) an API read the operator wired in.
CONTROLS = [
    ("meet_external", "Meet external participant posture", "console"),
    ("chat_external", "Chat external policy (blocked/allowlist)", "console"),
    ("chat_allowlisted_domains", "Chat allowlisted domains match approved list", "console"),
    ("meet_recording_storage", "Recording storage = governed Shared Drive", "console"),
    ("chat_history_default", "Chat history default matches policy", "console"),
    ("vault_chat_retention", "Vault Chat retention rule present + scoped + period", "console"),
]


def load_config(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def compare(intended, observed):
    """Normalized comparison; lists are compared as sets so domain-order does not cause false drift."""
    if isinstance(intended, list) or isinstance(observed, list):
        return set(intended or []) == set(observed or [])
    return str(intended).strip().lower() == str(observed).strip().lower()


def validate_scope(scope_name, scope_cfg):
    results = []
    intended = scope_cfg.get("intended", {})
    observed = scope_cfg.get("observed", {})
    for key, label, source in CONTROLS:
        if key not in intended:
            continue  # control not in scope for this design
        want = intended.get(key)
        got = observed.get(key, None)
        if got is None:
            status = "UNVERIFIED"  # observed value not captured yet -> treat as fail for the gate
            ok = False
        else:
            ok = compare(want, got)
            status = "PASS" if ok else "FAIL (drift)"
        results.append({
            "scope": scope_name, "control": key, "label": label, "source": source,
            "intended": want, "observed": got, "status": status, "ok": ok,
        })
    return results


def main():
    ap = argparse.ArgumentParser(description="Validate external-access & retention posture vs design (read-only).")
    ap.add_argument("--domain", required=True)
    ap.add_argument("--config", required=True, help="design.json with intended + observed values.")
    ap.add_argument("--out", default="validation.json")
    args = ap.parse_args()

    config = load_config(args.config)
    all_results = []
    for scope_name, scope_cfg in config.get("scopes", {}).items():
        all_results.extend(validate_scope(scope_name, scope_cfg))

    passed = [r for r in all_results if r["ok"]]
    failed = [r for r in all_results if not r["ok"]]

    report = {
        "artifact": "Meet+Chat Validation - Pilot - Validate",
        "domain": args.domain,
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "read_only": True,
        "summary": {"checked": len(all_results), "passed": len(passed), "failed": len(failed)},
        "results": all_results,
    }
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2)

    print(f"External/retention validation — {args.domain}")
    for r in all_results:
        print(f"  [{r['status']:>12}] {r['scope']:<16} {r['label']}")
    print(f"\n{len(passed)}/{len(all_results)} controls PASS. Report: {args.out}")
    if failed:
        print("Drift/unverified found — remediate before expanding.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
