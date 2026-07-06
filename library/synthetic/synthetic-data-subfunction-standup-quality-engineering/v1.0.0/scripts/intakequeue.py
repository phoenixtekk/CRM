#!/usr/bin/env python3
# intakequeue.py — intake-queue analyzer & pod-capacity helper for the synthetic-data sub-function
#
# PURPOSE: Validate an intake queue against the intake schema, apply the value/urgency/effort/risk
#          prioritization scoring model, rank requests, and (with --capacity) model demand against pod
#          FTE to flag over-commitment. Read-only analysis: it never writes unless you pass --out.
# HOW TO RUN: python intakequeue.py --input queue.csv [--capacity capacity.json] [--ceiling 0.85]
#             [--out ranked.csv]   (Python 3.10+; standard library only; see --help). With no --input
#             it runs a built-in example queue so you can see the output shape.
# EXPECTED RESULTS: A ranked queue (highest priority first) with per-request scores, a count of
#                   rejected rows (missing required fields), and — with --capacity — per-pod
#                   utilization vs. the ceiling with an OK / OVER-COMMITTED signal.

import argparse
import csv
import io
import json
import sys
from datetime import datetime, timezone

REQUIRED_FIELDS = ["request_id", "program", "use_case", "target_model",
                   "value", "urgency", "effort", "risk", "pod"]

# Prioritization weights (agree with the sponsor; these are sane defaults).
WEIGHTS = {"value": 0.40, "urgency": 0.25, "effort": 0.20, "risk": 0.15}

# Effort in "pod-days" per request by a coarse effort band (1..5); used for the capacity model.
EFFORT_DAYS = {1: 1, 2: 3, 3: 5, 4: 10, 5: 20}

EXAMPLE_CSV = """request_id,program,use_case,target_model,value,urgency,effort,risk,pod
REQ-001,Cardiology AI,readmission model test data,FHIR,5,4,3,2,generation
REQ-002,Radiology QA,edge-case scenario suite,OMOP,3,2,2,4,generation
REQ-003,Pharmacy AI,med-interaction fixtures,FHIR,4,5,4,3,generation
REQ-004,Platform,reference-arch validation set,native,2,1,1,1,platform
"""


def _score(row):
    # value/urgency higher-is-better; effort/risk lower-is-better -> invert on a 1..5 scale.
    value = row["value"]
    urgency = row["urgency"]
    effort_inv = 6 - row["effort"]
    risk_inv = 6 - row["risk"]
    raw = (WEIGHTS["value"] * value + WEIGHTS["urgency"] * urgency
           + WEIGHTS["effort"] * effort_inv + WEIGHTS["risk"] * risk_inv)
    return round(raw, 3)


def parse_queue(text):
    reader = csv.DictReader(io.StringIO(text))
    accepted, rejected = [], []
    for i, raw in enumerate(reader, start=1):
        missing = [f for f in REQUIRED_FIELDS if not (raw.get(f) or "").strip()]
        if missing:
            rejected.append((i, raw.get("request_id", f"row{i}"), missing))
            continue
        try:
            for f in ("value", "urgency", "effort", "risk"):
                v = int(raw[f])
                if not (1 <= v <= 5):
                    raise ValueError(f"{f}={v} out of range 1-5")
                raw[f] = v
        except ValueError as e:
            rejected.append((i, raw.get("request_id", f"row{i}"), [str(e)]))
            continue
        raw["priority_score"] = _score(raw)
        accepted.append(raw)
    accepted.sort(key=lambda r: r["priority_score"], reverse=True)
    for rank, r in enumerate(accepted, start=1):
        r["rank"] = rank
    return accepted, rejected


def capacity_model(accepted, capacity, ceiling):
    # capacity: {"pod": {"fte": float, "days_per_period": int}}
    demand = {}
    for r in accepted:
        pod = r["pod"]
        demand[pod] = demand.get(pod, 0) + EFFORT_DAYS[r["effort"]]
    rows = []
    over = False
    for pod, cap in capacity.items():
        avail = cap.get("fte", 0) * cap.get("days_per_period", 0)
        need = demand.get(pod, 0)
        util = (need / avail) if avail else float("inf")
        flag = "OVER-COMMITTED" if util > ceiling else "OK"
        if util > ceiling:
            over = True
        rows.append((pod, need, round(avail, 1), round(util, 3), flag))
    # pods with demand but no capacity entry
    for pod, need in demand.items():
        if pod not in capacity:
            rows.append((pod, need, 0.0, float("inf"), "NO-CAPACITY"))
            over = True
    return rows, over


def main(argv=None):
    p = argparse.ArgumentParser(
        description="Intake-queue analyzer & pod-capacity helper for the synthetic-data sub-function.")
    p.add_argument("--input", help="CSV intake queue (see REQUIRED_FIELDS). Omit for a built-in example.")
    p.add_argument("--capacity", help="JSON pod capacity map: {pod: {fte, days_per_period}}.")
    p.add_argument("--ceiling", type=float, default=0.85,
                   help="Max acceptable pod utilization before OVER-COMMITTED (default 0.85).")
    p.add_argument("--out", help="Optional path to WRITE the ranked queue as CSV (safe default: no write).")
    args = p.parse_args(argv)

    if args.input:
        with open(args.input, "r", encoding="utf-8") as fh:
            text = fh.read()
    else:
        print("[info] no --input given; using built-in EXAMPLE queue.", file=sys.stderr)
        text = EXAMPLE_CSV

    accepted, rejected = parse_queue(text)

    print("\n=== Intake Scheme - Sub-Function - v1 : ranked queue ===")
    print(f"{'rank':<6}{'request_id':<12}{'pod':<12}{'score':<8}{'program'}")
    for r in accepted:
        print(f"{r['rank']:<6}{r['request_id']:<12}{r['pod']:<12}{r['priority_score']:<8}{r['program']}")
    print(f"\naccepted: {len(accepted)}   rejected: {len(rejected)}")
    for i, rid, why in rejected:
        print(f"  [reject] row {i} ({rid}): {', '.join(why)}", file=sys.stderr)

    exit_code = 0 if not rejected else 1

    if args.capacity:
        with open(args.capacity, "r", encoding="utf-8") as fh:
            cap = json.load(fh)
        rows, over = capacity_model(accepted, cap, args.ceiling)
        print(f"\n=== Pod capacity vs. demand (ceiling {args.ceiling:.0%}) ===")
        print(f"{'pod':<12}{'demand_d':<10}{'avail_d':<10}{'util':<10}{'flag'}")
        for pod, need, avail, util, flag in rows:
            util_s = "inf" if util == float("inf") else f"{util:.0%}"
            print(f"{pod:<12}{need:<10}{avail:<10}{util_s:<10}{flag}")
        print(f"\nCapacity signal: {'OVER-COMMITTED' if over else 'OK'}")
        if over:
            exit_code = 1

    if args.out:
        cols = ["rank", "request_id", "program", "pod", "priority_score",
                "value", "urgency", "effort", "risk", "use_case", "target_model"]
        with open(args.out, "w", newline="", encoding="utf-8") as fh:
            w = csv.DictWriter(fh, fieldnames=cols, extrasaction="ignore")
            w.writeheader()
            w.writerows(accepted)
        print(f"\n[written] ranked queue saved to {args.out}")
    else:
        print("\n[dry-run] no file written (pass --out to save the ranked queue).")

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
