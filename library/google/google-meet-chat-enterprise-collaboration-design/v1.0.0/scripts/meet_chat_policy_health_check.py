#!/usr/bin/env python3
# meet_chat_policy_health_check.py — scored Meet & Chat governance health / drift check (read-only).
#
# PURPOSE: Score the Meet/Chat governance posture against a set of best-practice checks (external
#          scoped, recording storage governed, history/retention present, app allowlist enforced,
#          OUs not silently inherited) and flag drift by severity. READ-ONLY: evaluates captured/
#          observed state only; changes nothing. Meant to run on a schedule to catch drift.
# HOW TO RUN: python meet_chat_policy_health_check.py --domain your-domain.com --state design.json \
#             --out health.json   (Python 3.10+; if --state omitted, prints the check catalog only)
# EXPECTED RESULTS: writes health.json and prints a health score + per-check status; exit 0 when no
#          HIGH-severity finding, exit 1 when any HIGH finding exists. No tenant change.

import argparse
import json
import sys
from datetime import datetime, timezone

# Each check: key, description, severity, and how to derive PASS from the observed state dict.
# Observed state comes from design.json's per-scope "observed" values (captured from console/tools).
CHECKS = [
    ("external_scoped", "External Meet/Chat restricted or allowlisted (not open)", "HIGH",
     lambda o: str(o.get("chat_external", "")).lower() in {"blocked", "allowlist", "allowlist-only"}
               and str(o.get("meet_external", "")).lower() not in {"open", "anyone", ""}),
    ("recording_governed", "Recordings stored in governed Shared Drive", "HIGH",
     lambda o: str(o.get("meet_recording_storage", "")).lower() in {"shared_drive", "shared drive", "governed"}),
    ("history_defined", "Chat history default explicitly set (on or off per policy)", "MEDIUM",
     lambda o: str(o.get("chat_history_default", "")).lower() in {"on", "off"}),
    ("retention_present", "Vault Chat retention rule present", "HIGH",
     lambda o: bool(o.get("vault_chat_retention"))),
    ("app_allowlist", "Chat app installation restricted to allowlist", "MEDIUM",
     lambda o: str(o.get("chat_app_installation", "")).lower() in {"allowlist", "restricted", "allowlist-only"}),
    ("warn_external", "External-participant warning enabled", "LOW",
     lambda o: str(o.get("meet_warn_external", "")).lower() in {"on", "true", "enabled"}),
    ("not_inherited", "Scope has explicit overrides (not silently inherited)", "MEDIUM",
     lambda o: str(o.get("inheritance", "")).lower() != "inherited"),
]

SEVERITY_WEIGHT = {"HIGH": 3, "MEDIUM": 2, "LOW": 1}


def load_state(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def run_checks(scope_name, observed):
    findings = []
    for key, desc, severity, predicate in CHECKS:
        try:
            ok = bool(predicate(observed))
        except Exception:  # noqa: BLE001 - a malformed observed value counts as a failing check
            ok = False
        findings.append({
            "scope": scope_name, "check": key, "description": desc,
            "severity": severity, "status": "PASS" if ok else "FAIL", "ok": ok,
        })
    return findings


def main():
    ap = argparse.ArgumentParser(description="Meet & Chat governance health/drift check (read-only).")
    ap.add_argument("--domain", required=True)
    ap.add_argument("--state", help="design.json with per-scope 'observed' values.")
    ap.add_argument("--out", default="health.json")
    args = ap.parse_args()

    if not args.state:
        print("Check catalog (provide --state design.json to evaluate):")
        for key, desc, severity, _ in CHECKS:
            print(f"  [{severity:>6}] {key}: {desc}")
        return 0

    state = load_state(args.state)
    all_findings = []
    for scope_name, scope_cfg in state.get("scopes", {}).items():
        observed = scope_cfg.get("observed", {})
        all_findings.extend(run_checks(scope_name, observed))

    max_score = sum(SEVERITY_WEIGHT[f["severity"]] for f in all_findings) or 1
    earned = sum(SEVERITY_WEIGHT[f["severity"]] for f in all_findings if f["ok"])
    high_fails = [f for f in all_findings if not f["ok"] and f["severity"] == "HIGH"]
    score_pct = round(100 * earned / max_score)

    report = {
        "artifact": "Meet+Chat Health - Enterprise - Validate",
        "domain": args.domain,
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "read_only": True,
        "health_score_pct": score_pct,
        "high_severity_failures": len(high_fails),
        "findings": all_findings,
    }
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2)

    print(f"Meet/Chat governance health — {args.domain}: {score_pct}%")
    for f in all_findings:
        if not f["ok"]:
            print(f"  [{f['severity']:>6}] FAIL  {f['scope']:<16} {f['description']}")
    print(f"\nHIGH-severity failures: {len(high_fails)}. Report: {args.out}")
    return 1 if high_fails else 0


if __name__ == "__main__":
    sys.exit(main())
