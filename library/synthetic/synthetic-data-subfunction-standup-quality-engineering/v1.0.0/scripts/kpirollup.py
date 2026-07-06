#!/usr/bin/env python3
# kpirollup.py — KPI computation & rollup + reference-architecture config validator
#
# PURPOSE: Compute the sub-function's delivery-quality and engineering-productivity KPIs from intake +
#          validation records (default mode); OR (with --refarch) validate a reference-architecture
#          config for the required tiers, engine interface, gate stage, and the no-real-PHI isolation
#          boundary. Read-only: prints results; writes a JSON report only with --out.
# HOW TO RUN: python kpirollup.py --records records.json [--out kpi.json]
#             python kpirollup.py --refarch --config arch.json
#             (Python 3.10+; standard library only; see --help). No args = KPI demo on built-in data.
# EXPECTED RESULTS: KPI mode -> each delivery-quality & productivity KPI as a number vs. its target,
#                   with an ON-TARGET / OFF-TARGET signal. Refarch mode -> exit 0 and "no ERROR
#                   findings" when the architecture is valid; nonzero with ERROR findings otherwise.

import argparse
import json
import statistics
import sys
from datetime import datetime, timezone

# ---------------------------------------------------------------------------
# KPI mode
# ---------------------------------------------------------------------------
# Each record = one released (or attempted) request with timestamps + validation outcome.
EXAMPLE_RECORDS = [
    {"request_id": "REQ-001", "accepted_h": 0, "released_h": 40, "active_h": 24,
     "first_pass": True, "cycles": 1, "gate_h": 6, "consumer_issues": 0, "internal_issues": 2},
    {"request_id": "REQ-002", "accepted_h": 0, "released_h": 90, "active_h": 30,
     "first_pass": False, "cycles": 2, "gate_h": 10, "consumer_issues": 1, "internal_issues": 3},
    {"request_id": "REQ-003", "accepted_h": 0, "released_h": 55, "active_h": 40,
     "first_pass": True, "cycles": 1, "gate_h": 8, "consumer_issues": 0, "internal_issues": 1},
]

# KPI targets (agree with the sponsor; sane defaults). "dir" = better direction.
KPI_TARGETS = {
    "validation_pass_rate": {"target": 0.80, "dir": "high"},
    "defect_escape_rate": {"target": 0.15, "dir": "low"},
    "rework_rate": {"target": 0.25, "dir": "low"},
    "gate_cycle_time_median_h": {"target": 12.0, "dir": "low"},
    "lead_time_median_h": {"target": 72.0, "dir": "low"},
    "lead_time_p85_h": {"target": 120.0, "dir": "low"},
    "throughput": {"target": 3, "dir": "high"},
    "flow_efficiency": {"target": 0.40, "dir": "high"},
}


def _p85(values):
    if not values:
        return 0.0
    s = sorted(values)
    idx = min(len(s) - 1, int(round(0.85 * (len(s) - 1))))
    return float(s[idx])


def compute_kpis(records):
    n = len(records)
    if n == 0:
        return {}, {}
    lead_times = [r["released_h"] - r["accepted_h"] for r in records]
    first_pass = sum(1 for r in records if r.get("first_pass"))
    reworked = sum(1 for r in records if r.get("cycles", 1) > 1)
    consumer = sum(r.get("consumer_issues", 0) for r in records)
    internal = sum(r.get("internal_issues", 0) for r in records)
    total_issues = consumer + internal
    active = sum(r.get("active_h", 0) for r in records)
    total_lead = sum(lead_times)

    kpis = {
        "validation_pass_rate": round(first_pass / n, 3),
        "defect_escape_rate": round((consumer / total_issues), 3) if total_issues else 0.0,
        "rework_rate": round(reworked / n, 3),
        "gate_cycle_time_median_h": round(statistics.median(r.get("gate_h", 0) for r in records), 2),
        "lead_time_median_h": round(statistics.median(lead_times), 2),
        "lead_time_p85_h": round(_p85(lead_times), 2),
        "throughput": n,
        "flow_efficiency": round(active / total_lead, 3) if total_lead else 0.0,
    }
    signals = {}
    for k, v in kpis.items():
        spec = KPI_TARGETS[k]
        on = v >= spec["target"] if spec["dir"] == "high" else v <= spec["target"]
        signals[k] = "ON-TARGET" if on else "OFF-TARGET"
    return kpis, signals


def run_kpi(args):
    if args.records:
        with open(args.records, "r", encoding="utf-8") as fh:
            records = json.load(fh)
    else:
        print("[info] no --records; using built-in demo records.", file=sys.stderr)
        records = EXAMPLE_RECORDS

    kpis, signals = compute_kpis(records)
    print("\n=== KPI Framework - Sub-Function - v1 : rollup ===")
    print(f"{'kpi':<28}{'value':<12}{'target':<12}{'signal'}")
    off = 0
    for k, v in kpis.items():
        tgt = KPI_TARGETS[k]["target"]
        if signals[k] == "OFF-TARGET":
            off += 1
        print(f"{k:<28}{str(v):<12}{str(tgt):<12}{signals[k]}")
    overall = "ON-TARGET" if off == 0 else f"{off} KPI(s) OFF-TARGET"
    print(f"\nOverall: {overall}   (records={len(records)})")

    report = {"artifact": "KPI Framework - Sub-Function - v1",
              "generated_utc": datetime.now(timezone.utc).isoformat(),
              "kpis": kpis, "signals": signals, "records": len(records)}
    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        print(f"[written] KPI rollup saved to {args.out}")
    else:
        print("[dry-run] no file written (pass --out to save the rollup).")
    return 0 if off == 0 else 1


# ---------------------------------------------------------------------------
# Reference-architecture validator mode
# ---------------------------------------------------------------------------
REQUIRED_TIERS = ["isolated_nonprod"]
EXAMPLE_ARCH = {
    "tiers": ["isolated_nonprod"],
    "engine_interface": {"defined": True, "engines": ["synthea", "commercial_platform"]},
    "storage": {"access_control": True},
    "gate_stage": {"present": True, "gates": ["fidelity", "coverage", "privacy"]},
    "isolation_boundary": {"no_real_phi_in_shared_harness": True,
                           "connected_to_prod_phi": False},
}


def validate_refarch(cfg):
    findings = []

    def err(msg):
        findings.append(("ERROR", msg))

    def warn(msg):
        findings.append(("WARN", msg))

    tiers = cfg.get("tiers", [])
    for t in REQUIRED_TIERS:
        if t not in tiers:
            err(f"missing required tier: {t}")

    ei = cfg.get("engine_interface", {})
    if not ei.get("defined"):
        err("engine_interface.defined must be true (engines must be swappable behind an interface)")
    if not ei.get("engines"):
        warn("no engines listed behind the engine interface")

    if not cfg.get("storage", {}).get("access_control"):
        err("storage.access_control must be true")

    gate = cfg.get("gate_stage", {})
    if not gate.get("present"):
        err("gate_stage.present must be true (a fixed validation/gate stage is required)")
    else:
        for g in ("fidelity", "coverage", "privacy"):
            if g not in gate.get("gates", []):
                warn(f"gate stage does not list '{g}' gate")

    iso = cfg.get("isolation_boundary", {})
    if not iso.get("no_real_phi_in_shared_harness"):
        err("isolation_boundary.no_real_phi_in_shared_harness must be asserted true")
    if iso.get("connected_to_prod_phi"):
        err("isolation_boundary.connected_to_prod_phi must be false (no link to production PHI)")

    return findings


def run_refarch(args):
    if args.config:
        with open(args.config, "r", encoding="utf-8") as fh:
            cfg = json.load(fh)
    else:
        print("[info] no --config; validating built-in EXAMPLE_ARCH.", file=sys.stderr)
        cfg = EXAMPLE_ARCH

    findings = validate_refarch(cfg)
    print("\n=== Reference Architecture - Sub-Function - v1 : validation ===")
    errors = [f for f in findings if f[0] == "ERROR"]
    for level, msg in findings:
        print(f"  [{level}] {msg}")
    if not findings:
        print("  (no findings)")
    signal = "PASS" if not errors else "FAIL"
    print(f"\nRefarch signal: {signal}  (errors={len(errors)}, "
          f"warnings={len(findings) - len(errors)})")
    return 0 if not errors else 2


def main(argv=None):
    p = argparse.ArgumentParser(
        description="KPI rollup + reference-architecture validator for the synthetic-data sub-function.")
    p.add_argument("--refarch", action="store_true",
                   help="Run in reference-architecture validator mode instead of KPI mode.")
    p.add_argument("--records", help="JSON list of request records (KPI mode). Omit for demo.")
    p.add_argument("--config", help="JSON reference-architecture config (refarch mode). Omit for demo.")
    p.add_argument("--out", help="Optional path to WRITE the KPI JSON report (KPI mode; default: none).")
    args = p.parse_args(argv)

    if args.refarch:
        return run_refarch(args)
    return run_kpi(args)


if __name__ == "__main__":
    sys.exit(main())
