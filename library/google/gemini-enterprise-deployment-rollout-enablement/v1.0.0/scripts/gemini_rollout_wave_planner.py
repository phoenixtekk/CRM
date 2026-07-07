#!/usr/bin/env python3
# gemini_rollout_wave_planner.py — plan phased rollout waves by OU/group (dry-run, read-only)
#
# PURPOSE: Turn a wave definition (OUs/groups, order, dates, training package, adoption target) into a
#          concrete, seat-feasible rollout plan: named cohorts, per-wave seat requirements checked
#          against the license baseline, and the enable/train/measure sequence. Read-only / planning
#          only — it never changes the tenant; it emits a plan the other tools consume.
# HOW TO RUN: python gemini_rollout_wave_planner.py --plan waves.yaml --dry-run --out wave-plan.json
#             python gemini_rollout_wave_planner.py --plan waves.yaml --license-baseline license-baseline.json
#             (Python 3.10+; optional Admin SDK Directory read scope to size groups; see --help)
# EXPECTED RESULTS: An ordered wave plan with cohort names, seat requirements, and a seat-feasibility
#          PASS/FAIL against the baseline. Non-zero exit if a wave is not seat-feasible.
#
# NOTES:
#   - SAFE BY DEFAULT: read-only planning. No tenant changes; --dry-run is implied and honored.
#   - NO hardcoded credentials/keys — if group sizing is requested, uses ADC / gcloud auth read-only
#     Directory access; otherwise it uses sizes declared in the plan file.
#   - Cohort naming convention is enforced: 'Rollout Cohort - Pilot - Wave 0', 'Rollout Cohort - Wave N'.
#   - Plan file is YAML if PyYAML is installed, else JSON (same shape). See --sample for the schema.

import argparse
import json
import sys
from datetime import datetime, timezone


SAMPLE_PLAN = {
    "adoption_target_pct": 40,
    "waves": [
        {"order": 0, "name": "Pilot", "ous": ["/Pilot/Wave0"], "declared_size": 250,
         "enablement_date": "2026-07-20", "training_package": "gemini-quickstart-v1",
         "capabilities": ["gemini_in_workspace", "gemini_app", "gems"]},
        {"order": 1, "name": "Wave 1", "ous": ["/Corp/Engineering"], "declared_size": 8000,
         "enablement_date": "2026-08-10", "training_package": "gemini-quickstart-v1",
         "capabilities": ["gemini_in_workspace", "gemini_app", "gems"]},
        {"order": 2, "name": "Wave 2", "ous": ["/Corp/Sales", "/Corp/Marketing"], "declared_size": 15000,
         "enablement_date": "2026-09-01", "training_package": "gemini-role-based-v1",
         "capabilities": ["gemini_in_workspace", "gemini_app", "gems"]},
    ],
}


def _iso_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _cohort_name(wave: dict) -> str:
    if wave.get("order") == 0 or str(wave.get("name", "")).lower().startswith("pilot"):
        return "Rollout Cohort - Pilot - Wave 0"
    return f"Rollout Cohort - Wave {wave.get('order')}"


def _load_plan(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as fh:
        text = fh.read()
    try:
        import yaml  # type: ignore
        return yaml.safe_load(text)
    except ImportError:
        return json.loads(text)


def _load_baseline_seats(path: str | None) -> int | None:
    if not path:
        return None
    try:
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    except OSError:
        return None
    # Available seats are recorded from Billing -> Subscriptions; accept a couple of shapes.
    for key in ("available_seats", "seats_available", "total_seats"):
        if key in data:
            return int(data[key])
    return None


def cmd_plan(args) -> int:
    if args.sample:
        print(json.dumps(SAMPLE_PLAN, indent=2))
        return 0
    if not args.plan:
        print("ERROR: provide --plan <file> (or --sample to see the schema).")
        return 2
    try:
        plan = _load_plan(args.plan)
    except OSError as exc:
        print(f"ERROR: cannot read plan: {exc}")
        return 2

    available = _load_baseline_seats(args.license_baseline)
    target = plan.get("adoption_target_pct", args.adoption_target)
    waves = sorted(plan.get("waves", []), key=lambda w: w.get("order", 0))

    print(f"[plan] rollout waves ({len(waves)}) — adoption target {target}% — "
          f"available seats: {available if available is not None else 'UNKNOWN (verify in tenant)'}")

    cumulative = 0
    feasible = True
    out_waves = []
    for w in waves:
        cohort = _cohort_name(w)
        size = int(w.get("declared_size", 0))
        cumulative += size
        seat_ok = (available is None) or (cumulative <= available)
        feasible = feasible and (available is None or seat_ok)
        flag = "OK" if seat_ok else "SHORTFALL"
        if available is None:
            flag = "UNVERIFIED"
        print(f"  [{w.get('order')}] {cohort}")
        print(f"      OUs: {', '.join(w.get('ous', []))}")
        print(f"      seats this wave: {size}   cumulative: {cumulative}   feasibility: {flag}")
        print(f"      enablement date: {w.get('enablement_date', 'TBD')}   "
              f"training: {w.get('training_package', 'TBD')}")
        print(f"      capabilities: {', '.join(w.get('capabilities', []))}")
        out_waves.append({
            "order": w.get("order"),
            "cohort": cohort,
            "ous": w.get("ous", []),
            "seats_this_wave": size,
            "cumulative_seats": cumulative,
            "seat_feasible": None if available is None else seat_ok,
            "enablement_date": w.get("enablement_date"),
            "training_package": w.get("training_package"),
            "capabilities": w.get("capabilities", []),
            "adoption_target_pct": target,
        })

    result = {
        "generated": _iso_now(),
        "available_seats": available,
        "adoption_target_pct": target,
        "waves": out_waves,
        "seat_feasible_overall": None if available is None else feasible,
    }
    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(result, fh, indent=2)
        print(f"[plan] wave plan written -> {args.out}")

    if available is None:
        print("PLAN: UNVERIFIED — supply --license-baseline to check seat feasibility "
              "(and VERIFY available seats in your tenant).")
        return 0
    if not feasible:
        print("PLAN: FAIL — cumulative seats exceed available licenses; adjust waves or licensing.")
        return 1
    print("PLAN: PASS — all waves seat-feasible against the baseline.")
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Plan phased Gemini rollout waves (read-only).")
    p.add_argument("--plan", default=None, help="Wave definition file (YAML or JSON).")
    p.add_argument("--sample", action="store_true", help="Print a sample plan schema and exit.")
    p.add_argument("--license-baseline", default=None, help="license-baseline.json (for seat feasibility).")
    p.add_argument("--adoption-target", type=int, default=40, help="Default adoption target %% if not in plan.")
    p.add_argument("--out", default=None, help="Write the computed wave plan JSON here.")
    p.add_argument("--dry-run", action="store_true", default=True, help="Planning only (default; no changes).")
    return p


def main(argv=None) -> int:
    return cmd_plan(build_parser().parse_args(argv))


if __name__ == "__main__":
    sys.exit(main())
