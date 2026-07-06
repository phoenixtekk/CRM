#!/usr/bin/env python3
# kpi_variance_reporter.py — report target-vs-actual variance, direction-aware
#
# PURPOSE: Joins a KPI dashboard feed (kpi, period, value) to a catalog of targets+directions and
#          reports actual vs target with a direction-aware status (a lower-is-better KPI is never
#          "good" when it rises). Read-only; writes only with --out.
# HOW TO RUN: python kpi_variance_reporter.py --feed feed.csv --catalog kpi_catalog.json
#             [--period 2026-W24] [--out variance.csv]  (Python 3.10+; --emit-sample for shapes)
# EXPECTED RESULTS: A variance table (actual, target, variance, status) on stdout. Exit 0 = report
#                   produced; exit 1 = any KPI off-target beyond tolerance (the attention signal).

import argparse
import csv
import io
import json
import sys

DEFAULT_TOLERANCE = 0.0  # fraction of target allowed before a miss is flagged (0 = strict)


def sample_feed_csv() -> str:
    rows = [
        ["kpi", "period", "value", "n", "aggregation"],
        ["Delivery cycle time", "2026-W24", "6.0", "3", "median"],
        ["Defect escape rate", "2026-W24", "0.03", "5", "mean"],
        ["Privacy-gate first-pass rate", "2026-W24", "0.90", "4", "mean"],
    ]
    buf = io.StringIO()
    csv.writer(buf).writerows(rows)
    return buf.getvalue()


def sample_catalog() -> dict:
    return {
        "program": "Program",
        "kpis": [
            {"name": "Delivery cycle time", "target": 5.0, "direction": "lower_is_better"},
            {"name": "Defect escape rate", "target": 0.05, "direction": "lower_is_better"},
            {"name": "Privacy-gate first-pass rate", "target": 0.95,
             "direction": "higher_is_better"},
        ],
    }


def status_for(actual, target, direction, tol) -> tuple[str, float]:
    """Return (status, signed_variance). variance = actual - target."""
    variance = actual - target
    margin = abs(target) * tol
    if direction == "lower_is_better":
        # good when actual <= target (+ tolerance)
        if actual <= target + margin:
            return "on_or_better", variance
        return "off_target", variance
    else:  # higher_is_better
        if actual >= target - margin:
            return "on_or_better", variance
        return "off_target", variance


def load_feed(path):
    with open(path, "r", newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description="Report direction-aware target-vs-actual KPI variance.")
    p.add_argument("--feed", help="Path to dashboard feed CSV. If omitted, sample is used.")
    p.add_argument("--catalog", help="Path to KPI catalog JSON (targets+directions). "
                   "If omitted, sample is used.")
    p.add_argument("--period", help="Only report this period (e.g. 2026-W24). "
                   "Default: latest period present.")
    p.add_argument("--tolerance", type=float, default=DEFAULT_TOLERANCE,
                   help="Fraction of target tolerated before flagging a miss (default 0.0).")
    p.add_argument("--out", help="Optional CSV path to write the variance report.")
    p.add_argument("--emit-sample", action="store_true",
                   help="Print sample feed CSV and catalog JSON, then exit.")
    args = p.parse_args(argv)

    if args.emit_sample:
        print("# --- sample feed.csv ---")
        sys.stdout.write(sample_feed_csv())
        print("# --- sample kpi_catalog.json ---")
        print(json.dumps(sample_catalog(), indent=2))
        return 0

    # Load feed.
    if args.feed:
        try:
            feed_rows = load_feed(args.feed)
        except OSError as e:
            print(f"ERROR: could not read feed: {e}", file=sys.stderr)
            return 2
    else:
        print("NOTE: no --feed given; using built-in sample.", file=sys.stderr)
        feed_rows = list(csv.DictReader(io.StringIO(sample_feed_csv())))

    # Load catalog.
    if args.catalog:
        try:
            with open(args.catalog, "r", encoding="utf-8") as fh:
                cat = json.load(fh)
        except (OSError, json.JSONDecodeError) as e:
            print(f"ERROR: could not read catalog: {e}", file=sys.stderr)
            return 2
    else:
        print("NOTE: no --catalog given; using built-in sample.", file=sys.stderr)
        cat = sample_catalog()

    targets = {k["name"]: k for k in cat.get("kpis", [])}
    if not feed_rows:
        print("ERROR: empty feed.", file=sys.stderr)
        return 2

    # Choose period.
    periods = sorted({r.get("period", "") for r in feed_rows if r.get("period")})
    period = args.period or (periods[-1] if periods else "")
    if not period:
        print("ERROR: no period found in feed.", file=sys.stderr)
        return 2

    print(f"KPI target-vs-actual variance — period {period} "
          f"(tolerance {args.tolerance:.0%})")
    print("-" * 78)
    print(f"{'kpi':<32}{'actual':>10}{'target':>10}{'variance':>12}{'status':>14}")

    any_off = False
    report = []
    for r in feed_rows:
        if r.get("period") != period:
            continue
        name = r.get("kpi")
        meta = targets.get(name)
        if not meta:
            print(f"{name[:31]:<32}{'--':>10}{'(no target)':>10}")
            continue
        try:
            actual = float(r.get("value"))
        except (TypeError, ValueError):
            continue
        target = float(meta.get("target"))
        direction = meta.get("direction", "higher_is_better")
        status, variance = status_for(actual, target, direction, args.tolerance)
        if status == "off_target":
            any_off = True
        print(f"{name[:31]:<32}{actual:>10.4g}{target:>10.4g}"
              f"{variance:>+12.4g}{status:>14}")
        report.append({"kpi": name, "period": period, "actual": actual, "target": target,
                       "direction": direction, "variance": round(variance, 4), "status": status})

    print("-" * 78)

    if args.out and report:
        try:
            with open(args.out, "w", newline="", encoding="utf-8") as fh:
                w = csv.DictWriter(fh, fieldnames=["kpi", "period", "actual", "target",
                                                   "direction", "variance", "status"])
                w.writeheader()
                w.writerows(report)
            print(f"Wrote variance report to {args.out}")
        except OSError as e:
            print(f"ERROR: could not write --out: {e}", file=sys.stderr)
            return 2

    if any_off:
        print("RESULT: ATTENTION — one or more KPIs are off target (feed the cadence review).")
        return 1
    print("RESULT: OK — all reported KPIs are on or better than target.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
