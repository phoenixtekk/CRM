#!/usr/bin/env python3
# control_compliance_check.py — governance gate coverage + control-map evidence view
#
# PURPOSE: Two read-only checks over the JSON governance registers. `coverage` runs the governance
#          gates over the catalog + approval log (per asset: lineage / classification / approval-if-
#          consumed / access-aligned) with an overall pass/fail. `controls` maps the governance
#          controls this solution operates against the org's DECLARED control set, marking each
#          declared control in-place / partial / not-addressed with its evidence artifact. Emits
#          EVIDENCE for compliance to interpret -- it is NOT a compliance determination.
# HOW TO RUN: python control_compliance_check.py coverage --catalog catalog.json --log log.json [--pilot ID ...]   |   python control_compliance_check.py controls --control-set set.json --control-map map.json   (Python 3.10+; see --help)
# EXPECTED RESULTS: coverage prints a per-asset gate table and an overall PASS/FAIL (exit 0 pass, 1
#          fail). controls prints every declared control with a status + evidence; exit 1 if any
#          control is unresolved or claims 'in-place' without a backing evidence artifact.

import argparse
import json
import sys
from pathlib import Path


def load_json(path, what):
    p = Path(path)
    if not p.exists():
        sys.exit(f"ERROR: {what} not found: {path}")
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        sys.exit(f"ERROR: {what} is not valid JSON ({path}): {e}")


DISCLAIMER = ("\nNOTE: This output is EVIDENCE for your privacy/compliance/legal functions to "
              "interpret. It is NOT a HIPAA/HITRUST compliance determination, de-identification "
              "adequacy finding, or disclosure-risk acceptance.")


# ---------------- coverage (governance gates) ----------------

def approval_state(log, asset_id):
    apps = [a for a in log.get("approvals", []) if a.get("asset_id") == asset_id]
    if not apps:
        return "none"
    # latest decided wins; approved if any approved and none later rejected
    for a in reversed(apps):
        if a.get("status") in ("approved", "rejected"):
            return a["status"]
    return "requested"


def access_aligned(asset, log):
    # Evidence-level check: an asset consumed in a shared env must be approved for that env.
    if not asset.get("consumed_in_shared"):
        return True
    env = asset.get("environment")
    for a in log.get("approvals", []):
        if a.get("asset_id") == asset.get("id") and a.get("status") == "approved":
            if a.get("target_env") in (env, None) or env is None:
                return True
    return False


def cmd_coverage(args):
    catalog = load_json(args.catalog, "catalog")
    log = load_json(args.log, "log")
    assets = catalog.get("assets", [])
    if args.pilot:
        wanted = set(args.pilot)
        assets = [a for a in assets if a.get("id") in wanted]
    classifications = log.get("classifications", {})

    gate_fail = {"lineage": 0, "classification": 0, "approval": 0, "access": 0}
    rows = []
    for a in assets:
        aid = a.get("id")
        has_lineage = bool((a.get("generator") or a.get("source") or "").strip())
        cls = classifications.get(aid, {}).get("value") or a.get("classification")
        has_class = bool(cls)
        consumed = bool(a.get("consumed_in_shared"))
        appr = approval_state(log, aid)
        has_appr = (appr == "approved") if consumed else True
        aligned = access_aligned(a, log)

        for gate, ok in (("lineage", has_lineage), ("classification", has_class),
                         ("approval", has_appr), ("access", aligned)):
            if not ok:
                gate_fail[gate] += 1
        rows.append((aid, has_lineage, has_class, consumed, appr, has_appr, aligned))

    print("=== Governance coverage (gate G3/G4 evidence) ===")
    print(f"{'asset':<28} {'lineage':<8} {'class':<6} {'consumed':<9} {'approval':<10} {'access':<7}")
    for aid, lin, cl, cons, appr, hasa, al in rows:
        print(f"{aid:<28} {('PASS' if lin else 'FAIL'):<8} {('PASS' if cl else 'FAIL'):<6} "
              f"{('yes' if cons else 'no'):<9} {(appr if cons else 'n/a'):<10} "
              f"{('PASS' if al else 'FAIL'):<7}")
    overall_pass = all(v == 0 for v in gate_fail.values())
    print("\nGate summary (assets failing):")
    for g, n in gate_fail.items():
        print(f"  {g:<14}: {'PASS' if n == 0 else f'FAIL ({n})'}")
    print(f"\nOVERALL: {'PASS' if overall_pass else 'FAIL'}")
    print(DISCLAIMER)
    return 0 if overall_pass else 1


# ---------------- controls (declared control-set mapping) ----------------

def cmd_controls(args):
    control_set = load_json(args.control_set, "declared control set")
    control_map = load_json(args.control_map, "governance control map")

    declared = control_set.get("controls", control_set if isinstance(control_set, list) else [])
    mapping = {m.get("control_id"): m for m in control_map.get("mappings", control_map if isinstance(control_map, list) else [])}

    VALID = {"in-place", "partial", "not-addressed"}
    print("=== Control alignment evidence (declared control set) ===")
    print(f"Declared control set: {control_set.get('name', args.control_set)}")
    unresolved = 0
    unbacked = 0
    counts = {"in-place": 0, "partial": 0, "not-addressed": 0}
    for c in declared:
        cid = c.get("id") if isinstance(c, dict) else c
        statement = c.get("statement", "") if isinstance(c, dict) else ""
        m = mapping.get(cid)
        status = (m or {}).get("status")
        gov = (m or {}).get("governance_control", "-")
        evidence = (m or {}).get("evidence")

        if status not in VALID:
            status_disp = "UNRESOLVED"
            unresolved += 1
        else:
            counts[status] += 1
            status_disp = status
            if status == "in-place" and not evidence:
                status_disp = "in-place (NO-EVIDENCE)"
                unbacked += 1

        ev = evidence or ("none" if status == "not-addressed" else "MISSING")
        print(f"  {str(cid):<16} {status_disp:<24} gov='{gov}' evidence='{ev}'")
        if statement:
            print(f"      \"{statement[:80]}\"")

    print("\nSummary:")
    for k, v in counts.items():
        print(f"  {k:<14}: {v}")
    print(f"  unresolved    : {unresolved}")
    print(f"  in-place w/o evidence: {unbacked}")
    ok = (unresolved == 0 and unbacked == 0)
    print(f"\nEVIDENCE VIEW: {'complete & backed' if ok else 'INCOMPLETE -- fix before review'}")
    print(DISCLAIMER)
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser(description="Governance gate coverage + control-map evidence (read-only).")
    sub = ap.add_subparsers(dest="cmd", required=True)

    cov = sub.add_parser("coverage", help="Run governance gates over catalog + approval log.")
    cov.add_argument("--catalog", required=True)
    cov.add_argument("--log", required=True)
    cov.add_argument("--pilot", nargs="*", default=None, help="Restrict to these asset ids.")
    cov.set_defaults(func=cmd_coverage)

    con = sub.add_parser("controls", help="Map governance controls to the declared control set.")
    con.add_argument("--control-set", required=True, help="Declared Control Set - Enterprise - v1 JSON.")
    con.add_argument("--control-map", required=True, help="Governance Control Map - Enterprise - v1 JSON.")
    con.set_defaults(func=cmd_controls)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
