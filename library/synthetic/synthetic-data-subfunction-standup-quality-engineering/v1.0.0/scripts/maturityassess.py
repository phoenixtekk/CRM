#!/usr/bin/env python3
# maturityassess.py — capability & maturity self-assessment for the synthetic-data sub-function
#
# PURPOSE: Score the synthetic-data sub-function across five dimensions (operating model, engineering,
#          validation/quality, privacy/governance, adoption), compute an overall maturity level, and
#          emit the "Maturity Baseline - Sub-Function - v1" artifact. Read-only / assessment tool: it
#          only WRITES a baseline JSON when you explicitly pass --out (safe default: print only).
# HOW TO RUN: python maturityassess.py --scores scores.json [--target 3] [--out baseline.json]
#             (Python 3.10+; standard library only; see --help). With no --scores it runs a built-in
#             interactive-free example so you can see the output shape.
# EXPECTED RESULTS: A per-dimension level (1-5), an overall level, gap-to-target per dimension, and a
#                   PASS/BELOW-TARGET signal. Nothing is written unless --out is given.

import argparse
import json
import sys
from datetime import datetime, timezone

ARTIFACT_NAME = "Maturity Baseline - Sub-Function - v1"

# The five maturity dimensions and what each level roughly means (1=ad-hoc .. 5=optimized).
DIMENSIONS = {
    "operating_model": "Pods, single intake, RACI, charter",
    "engineering": "Engine-agnostic pipeline, reproducibility, config-as-data",
    "validation_quality": "Fidelity/coverage/privacy gates, validation records",
    "privacy_governance": "Isolation boundary, privacy screens, deferral discipline",
    "adoption": "Programs served, request throughput, sponsor engagement",
}

LEVEL_NAMES = {1: "Ad-hoc", 2: "Emerging", 3: "Defined", 4: "Managed", 5: "Optimized"}

EXAMPLE_SCORES = {
    "operating_model": 2,
    "engineering": 2,
    "validation_quality": 1,
    "privacy_governance": 3,
    "adoption": 1,
}


def load_scores(path):
    if path is None:
        print("[info] no --scores given; using built-in EXAMPLE_SCORES for demonstration.",
              file=sys.stderr)
        return dict(EXAMPLE_SCORES)
    with open(path, "r", encoding="utf-8") as fh:
        data = json.load(fh)
    return data


def validate_scores(scores):
    errors = []
    for dim in DIMENSIONS:
        if dim not in scores:
            errors.append(f"missing dimension: {dim}")
            continue
        v = scores[dim]
        if not isinstance(v, int) or not (1 <= v <= 5):
            errors.append(f"dimension {dim} must be an integer 1-5 (got {v!r})")
    extra = set(scores) - set(DIMENSIONS)
    for e in sorted(extra):
        errors.append(f"unknown dimension ignored: {e}")
    return errors


def overall_level(scores):
    # Overall maturity is the floor of the mean, but capped by the weakest gate-critical dimension:
    # a sub-function cannot be "Defined" overall while validation/quality or privacy is still ad-hoc.
    vals = [scores[d] for d in DIMENSIONS]
    mean_level = int(sum(vals) / len(vals))  # floor via int()
    gate_critical = min(scores["validation_quality"], scores["privacy_governance"])
    capped = min(mean_level, gate_critical + 1)
    return max(1, capped)


def main(argv=None):
    p = argparse.ArgumentParser(
        description="Capability & maturity self-assessment for the synthetic-data sub-function.")
    p.add_argument("--scores", help="JSON file mapping each dimension to an integer level 1-5.")
    p.add_argument("--target", type=int, default=3,
                   help="Target maturity level for the next review (default: 3 = Defined).")
    p.add_argument("--out", help="Optional path to WRITE the baseline JSON (safe default: no write).")
    args = p.parse_args(argv)

    scores = load_scores(args.scores)
    errors = validate_scores(scores)
    fatal = [e for e in errors if not e.startswith("unknown dimension")]
    for e in errors:
        print(f"[warn] {e}", file=sys.stderr)
    if fatal:
        print("[FAIL] score validation failed; fix the above before baselining.", file=sys.stderr)
        return 2

    scores = {d: scores[d] for d in DIMENSIONS}  # normalized order
    overall = overall_level(scores)

    print(f"\n=== {ARTIFACT_NAME} ===")
    print(f"{'dimension':<22}{'level':<8}{'name':<12}{'gap-to-target'}")
    below = []
    for dim in DIMENSIONS:
        lvl = scores[dim]
        gap = max(0, args.target - lvl)
        if gap > 0:
            below.append(dim)
        print(f"{dim:<22}{lvl:<8}{LEVEL_NAMES[lvl]:<12}{gap}")
    print("-" * 54)
    print(f"{'OVERALL':<22}{overall:<8}{LEVEL_NAMES[overall]:<12}"
          f"{max(0, args.target - overall)}")

    signal = "PASS" if overall >= args.target and not below else "BELOW-TARGET"
    print(f"\nTarget level: {args.target} ({LEVEL_NAMES.get(args.target, '?')})   Signal: {signal}")
    if below:
        print("Dimensions below target (prioritize in the Expansion Plan): " + ", ".join(below))

    baseline = {
        "artifact": ARTIFACT_NAME,
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "dimensions": scores,
        "overall_level": overall,
        "target_level": args.target,
        "below_target": below,
        "signal": signal,
    }

    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(baseline, fh, indent=2)
        print(f"\n[written] baseline saved to {args.out}")
    else:
        print("\n[dry-run] no file written (pass --out to save the baseline).")

    return 0 if signal == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
