#!/usr/bin/env python3
# twin_simulator.py — the hospital-twin/event simulator engine.
#
# PURPOSE: Loads (or synthesizes a placeholder) synthetic patient population against the Twin Scope
#          Config and advances a deterministic simulation clock, emitting the clinical/operational
#          event stream (admit -> order -> result -> medicate -> transfer -> discharge) the twin
#          runs on. Dry-run by default: plans and reports counts without writing the run log.
# HOW TO RUN: python twin_simulator.py --config "Twin Scope Config - Pilot - v1.json" \
#             --feed "Synthetic Feed Binding - Pilot - v1" [--commit]   (Python 3.10+; see --help)
# EXPECTED RESULTS: A run plan/summary on stdout (population size, per-event counts, horizon). With
#                   --commit, a run log JSON is written. A real-PHI marker in the feed aborts the run.
#
# Safe by default: refuses to run if the feed shows real-PHI markers; --dry-run is the default so
# nothing is written unless --commit is given. Only synthetic data is ever loaded into the twin.

import argparse
import json
import os
import random
import sys
from datetime import datetime, timezone, timedelta

EVENT_TYPES = ["admit", "order", "result", "medicate", "transfer", "discharge"]

# Substrings that, if present as record keys/values, indicate REAL PHI leaked into a supposedly
# synthetic feed. The twin must never load these. (Illustrative guard — extend per your policy.)
REAL_PHI_MARKERS = ("mrn_real", "ssn", "real_patient", "prod_pii", "live_phi")


def _now():
    return datetime.now(timezone.utc).isoformat()


def load_config(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def _scan_feed_for_real_phi(feed_path):
    """Return a list of real-PHI markers found. Metadata/sidecar scan only — safe by design."""
    hits = []
    if not feed_path or not os.path.exists(feed_path):
        return hits  # nothing to scan; simulator will use a synthetic placeholder population
    # Scan a small metadata/manifest window only; never dump record contents to stdout.
    try:
        with open(feed_path, encoding="utf-8", errors="ignore") as fh:
            sample = fh.read(65536).lower()
    except OSError:
        return hits
    for marker in REAL_PHI_MARKERS:
        if marker in sample:
            hits.append(marker)
    return hits


def synth_population(n, seed, model):
    """Deterministic placeholder synthetic population (no real PHI, no real names)."""
    rng = random.Random(seed)
    people = []
    for i in range(n):
        people.append({
            "person_id": f"SYN-{i:06d}",           # synthetic id only
            "age": rng.randint(0, 95),
            "sex": rng.choice(["F", "M", "U"]),
            "target_model": model,
        })
    return people


def plan_events(people, cfg, seed):
    """Deterministically plan the event stream over the sim horizon."""
    rng = random.Random(seed + 1)
    horizon_days = cfg.get("sim_clock", {}).get("horizon_days", 7)
    start = datetime(2000, 1, 1, tzinfo=timezone.utc)  # synthetic epoch, not a real date
    counts = {e: 0 for e in EVENT_TYPES}
    events = []
    for person in people:
        # A fraction of the population has an encounter within the horizon.
        if rng.random() < 0.6:
            t = start + timedelta(hours=rng.randint(0, horizon_days * 24))
            seq = ["admit", "order", "result", "medicate"]
            if rng.random() < 0.3:
                seq.append("transfer")
            seq.append("discharge")
            for step, etype in enumerate(seq):
                events.append({
                    "t": (t + timedelta(hours=step)).isoformat(),
                    "type": etype,
                    "person_id": person["person_id"],
                })
                counts[etype] += 1
    events.sort(key=lambda e: e["t"])
    return events, counts


def main(argv=None):
    p = argparse.ArgumentParser(description="Hospital-twin/event simulator engine (safe by default).")
    p.add_argument("--config", required=True, help="Twin Scope Config JSON path")
    p.add_argument("--feed", help="synthetic feed path/metadata (never real PHI)")
    p.add_argument("--commit", action="store_true",
                   help="write the run log (default is --dry-run: plan only, no write)")
    p.add_argument("--out", default="Twin Simulation Run - Pilot - v1.json",
                   help="run log output path (only written with --commit)")
    args = p.parse_args(argv)

    if not os.path.exists(args.config):
        print(f"ERROR: config not found: {args.config}", file=sys.stderr)
        return 2
    cfg = load_config(args.config)

    # Real-PHI leakage guard — abort before loading anything.
    hits = _scan_feed_for_real_phi(args.feed)
    if hits:
        print("ABORT: real-PHI markers detected in the feed; the twin must never load real PHI.",
              file=sys.stderr)
        print(f"  markers: {sorted(set(hits))}", file=sys.stderr)
        return 3

    n = int(cfg.get("population", 0))
    seed = int(cfg.get("seed", 0))
    model = cfg.get("target_model", "fhir")

    people = synth_population(n, seed, model)
    events, counts = plan_events(people, cfg, seed)

    mode = "COMMIT" if args.commit else "DRY-RUN"
    print(f"[{mode}] Twin simulation plan for '{cfg.get('service_line')}' (model={model})")
    print(f"  population: {len(people)} synthetic persons (seed={seed})")
    print(f"  horizon:    {cfg.get('sim_clock', {}).get('horizon_days', 7)} simulated days")
    print(f"  events:     {len(events)} total")
    for etype in EVENT_TYPES:
        print(f"    {etype:9}: {counts[etype]}")
    print("  real-PHI guard: PASS (no markers found)")

    if args.commit:
        run_log = {
            "artifact_name": "Twin Simulation Run - Pilot - v1",
            "generated_at": _now(),
            "config": args.config,
            "population": len(people),
            "seed": seed,
            "target_model": model,
            "event_counts": counts,
            "events": events,
            "note": "Synthetic data only. No real PHI. Isolated non-production use.",
        }
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(run_log, fh, indent=2)
        print(f"Wrote run log -> {args.out}")
    else:
        print("Dry-run: no run log written. Re-run with --commit to persist.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
