#!/usr/bin/env python3
# app-access-validation.py — validate the three OAuth governance gates + emit the review packet
#
# PURPOSE: Validation / report generator, READ-ONLY. Checks the three governance gates against the
#          inventory + classification + policy state:
#            Gate A: restricted/sensitive scopes are only held by Trusted apps
#            Gate B: unverified/unconfigured apps are blocked (or blocked from sensitive scopes)
#            Gate C: Marketplace install policy is allowlist-only and matches "Trusted Apps - Org-Wide
#                    - v1"
#          Emits a PASS/FAIL report and the approver review packet. Makes NO changes.
# HOW TO RUN: python app-access-validation.py --inventory app-inventory.json --plan classification.json
#             [--policy policy-state.json] [--scope pilot-ou|org] [--report validation.json]
#             (Python 3.10+; policy-state captures the current tenant settings you recorded)
# EXPECTED RESULTS: gate_a/gate_b/gate_c each PASS or FAIL with the offending apps listed, an overall
#                   result, and a human-readable review packet for the approver. Exit code 0 if all
#                   gates PASS, 1 otherwise (useful in CI / change-control checks).

import argparse
import json
import sys

SENSITIVE_TIERS = {"restricted", "sensitive"}


def load_json(path, default=None):
    if not path:
        return default
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def gate_a(apps, trusted_ids):
    """Restricted/sensitive scopes only held by Trusted apps."""
    offenders = []
    for a in apps:
        tiers = set(a.get("scope_tiers", {}).values())
        if tiers & SENSITIVE_TIERS and a["client_id"] not in trusted_ids:
            offenders.append({"client_id": a["client_id"], "display": a.get("display", ""),
                              "risk": a.get("risk"), "reason": "sensitive/restricted scope, not Trusted"})
    return ("PASS" if not offenders else "FAIL", offenders)


def gate_b(policy):
    """Unconfigured/unverified apps blocked, or at least blocked from sensitive+restricted scopes."""
    setting = (policy or {}).get("unconfigured_apps_policy", "unknown")
    ok = setting in {"blocked", "block_sensitive_and_restricted"}
    detail = {"unconfigured_apps_policy": setting}
    return ("PASS" if ok else "FAIL", detail)


def gate_c(policy, trusted_ids):
    """Marketplace allowlist-only and allowlist == Trusted list."""
    mkt = (policy or {}).get("marketplace", {})
    allowlist_only = mkt.get("install_policy") == "allowlist_only"
    allowlist_ids = set(mkt.get("allowlist", []))
    matches_trusted = allowlist_ids == set(trusted_ids)
    ok = allowlist_only and matches_trusted
    detail = {"install_policy": mkt.get("install_policy", "unknown"),
              "allowlist_matches_trusted": matches_trusted,
              "only_in_allowlist": sorted(allowlist_ids - set(trusted_ids)),
              "trusted_not_allowlisted": sorted(set(trusted_ids) - allowlist_ids)}
    return ("PASS" if ok else "FAIL", detail)


def main():
    ap = argparse.ArgumentParser(description="Validate the three OAuth app-access governance gates.")
    ap.add_argument("--inventory", required=True, help="app-inventory.json.")
    ap.add_argument("--plan", required=True, help="classification.json (Trusted/Limited/Blocked).")
    ap.add_argument("--policy", help="policy-state.json: recorded tenant settings (unconfigured/marketplace).")
    ap.add_argument("--scope", default="org", help="Scope label recorded in the report.")
    ap.add_argument("--report", default="validation.json")
    args = ap.parse_args()

    apps = load_json(args.inventory, {}).get("apps", [])
    plan = load_json(args.plan, {})
    policy = load_json(args.policy, {}) or {}
    trusted_ids = {e["client_id"] for e in plan.get("apps", []) if e.get("level") == "Trusted"}

    a_res, a_off = gate_a(apps, trusted_ids)
    b_res, b_det = gate_b(policy)
    c_res, c_det = gate_c(policy, trusted_ids)
    overall = "PASS" if a_res == b_res == c_res == "PASS" else "FAIL"

    report = {
        "artifact": "App-Access Validation Report",
        "scope": args.scope,
        "overall": overall,
        "gate_a": {"name": "High-risk scopes only held by Trusted apps", "result": a_res, "offenders": a_off},
        "gate_b": {"name": "Unverified/unconfigured apps blocked", "result": b_res, "detail": b_det},
        "gate_c": {"name": "Marketplace allowlist-only == Trusted list", "result": c_res, "detail": c_det},
        "review_packet": {
            "trusted_count": len(trusted_ids),
            "high_risk_apps": [a["display"] or a["client_id"] for a in apps if a.get("risk") == "HIGH"],
            "unknown_scope_apps": [a["display"] or a["client_id"] for a in apps if a.get("risk") == "UNKNOWN"],
        },
    }
    with open(args.report, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2)

    print(f"Validation  scope={args.scope}  OVERALL={overall}")
    print(f"  Gate A (high-risk scopes -> Trusted only): {a_res}  ({len(a_off)} offenders)")
    print(f"  Gate B (unverified apps blocked):          {b_res}  ({b_det})")
    print(f"  Gate C (Marketplace allowlist-only):       {c_res}")
    print(f"\nReport + approver review packet written to {args.report}")
    if overall != "PASS":
        print("One or more gates FAILED — remediate and re-validate before expanding scope.")
    sys.exit(0 if overall == "PASS" else 1)


if __name__ == "__main__":
    main()
