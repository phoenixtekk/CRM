#!/usr/bin/env python3
# kpi_rollup_generator.py — aggregate raw KPI observations into a dashboard feed
#
# PURPOSE: Reads a flat observations file (kpi, period, value) of AGGREGATE, PHI-free metrics and
#          rolls it up per KPI per period (mean/median/sum per the KPI's aggregation) into a portable
#          dashboard feed. Safe by default: dry-run prints the feed; writing requires --out.
# HOW TO RUN: python kpi_rollup_generator.py --observations obs.csv [--out feed.csv|feed.json]
#             (Python 3.10+; run --emit-sample for the expected input shape; see --help)
# EXPECTED RESULTS: A per-KPI, per-period feed on stdout (dry-run). With --out it also writes the
#                   feed. Exit 0 = rollup produced; exit 1 = input problems (e.g. a suspected-PHI
#                   column) that block the rollup.

import argparse
import csv
import io
import json
import statistics
import sys

# Column names that suggest patient-level / PHI content — these must NOT appear in a KPI feed.
SUSPECT_PHI_COLUMNS = {
    "patient", "patient_id", "mrn", "ssn", "name", "first_name", "last_name", "dob",
    "date_of_birth", "address", "phone", "email", "diagnosis_text", "note", "clinical_note",
}
AGGREGATIONS = {"mean", "median", "sum", "min", "max", "last"}


def sample_observations_csv() -> str:
    rows = [
        ["kpi", "period", "value", "aggregation"],
        ["Delivery cycle time", "2026-W23", "6.0", "median"],
        ["Delivery cycle time", "2026-W23", "4.0", "median"],
        ["Delivery cycle time", "2026-W24", "5.0", "median"],
        ["Defect escape rate", "2026-W23", "0.06", "mean"],
        ["Defect escape rate", "2026-W24", "0.04", "mean"],
        ["Privacy-gate first-pass rate", "2026-W23", "0.95", "mean"],
        ["Privacy-gate first-pass rate", "2026-W24", "0.97", "mean"],
    ]
    buf = io.StringIO()
    csv.writer(buf).writerows(rows)
    return buf.getvalue()


def aggregate(values, how: str) -> float:
    if not values:
        return float("nan")
    if how == "mean":
        return statistics.fmean(values)
    if how == "median":
        return statistics.median(values)
    if how == "sum":
        return sum(values)
    if how == "min":
        return min(values)
    if how == "max":
        return max(values)
    if how == "last":
        return values[-1]
    return statistics.fmean(values)


def load_rows(path):
    with open(path, "r", newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description="Roll up KPI observations into a dashboard feed.")
    p.add_argument("--observations", help="Path to observations CSV. If omitted, sample is used.")
    p.add_argument("--out", help="Write the feed here (.csv or .json). Omit for dry-run.")
    p.add_argument("--emit-sample", action="store_true",
                   help="Print a sample observations CSV to stdout and exit.")
    args = p.parse_args(argv)

    if args.emit_sample:
        sys.stdout.write(sample_observations_csv())
        return 0

    if args.observations:
        try:
            rows = load_rows(args.observations)
        except OSError as e:
            print(f"ERROR: could not read observations: {e}", file=sys.stderr)
            return 2
    else:
        print("NOTE: no --observations given; using built-in sample.", file=sys.stderr)
        rows = list(csv.DictReader(io.StringIO(sample_observations_csv())))

    if not rows:
        print("ERROR: no observation rows.", file=sys.stderr)
        return 2

    # Privacy guard: reject any suspected-PHI column outright.
    cols = {c.strip().lower() for c in rows[0].keys()}
    phi_hits = sorted(cols & SUSPECT_PHI_COLUMNS)
    if phi_hits:
        print(f"ERROR: suspected-PHI column(s) present: {', '.join(phi_hits)}. "
              f"A KPI feed must contain only aggregate, PHI-free metrics. Aborting.",
              file=sys.stderr)
        return 1

    # Group values by (kpi, period), remembering the aggregation.
    grouped = {}
    aggs = {}
    for r in rows:
        kpi = (r.get("kpi") or "").strip()
        period = (r.get("period") or "").strip()
        if not kpi or not period:
            continue
        try:
            val = float(r.get("value"))
        except (TypeError, ValueError):
            print(f"WARN: skipping non-numeric value for {kpi}/{period}: {r.get('value')!r}",
                  file=sys.stderr)
            continue
        how = (r.get("aggregation") or "mean").strip().lower()
        if how not in AGGREGATIONS:
            how = "mean"
        grouped.setdefault((kpi, period), []).append(val)
        aggs[(kpi, period)] = how

    feed = []
    for (kpi, period), vals in sorted(grouped.items()):
        how = aggs[(kpi, period)]
        feed.append({
            "kpi": kpi, "period": period, "value": round(aggregate(vals, how), 4),
            "n": len(vals), "aggregation": how,
        })

    # Dry-run print.
    print("KPI Dashboard Feed (dry-run preview)")
    print("-" * 60)
    print(f"{'kpi':<32}{'period':<10}{'value':>10}{'n':>5}")
    for f in feed:
        print(f"{f['kpi'][:31]:<32}{f['period']:<10}{f['value']:>10}{f['n']:>5}")
    print("-" * 60)
    print(f"{len(feed)} feed rows across "
          f"{len({f['kpi'] for f in feed})} KPIs.")

    if args.out:
        try:
            if args.out.lower().endswith(".json"):
                with open(args.out, "w", encoding="utf-8") as fh:
                    json.dump(feed, fh, indent=2)
            else:
                with open(args.out, "w", newline="", encoding="utf-8") as fh:
                    w = csv.DictWriter(fh, fieldnames=["kpi", "period", "value", "n",
                                                       "aggregation"])
                    w.writeheader()
                    w.writerows(feed)
            print(f"Wrote feed to {args.out}")
        except OSError as e:
            print(f"ERROR: could not write --out: {e}", file=sys.stderr)
            return 2
    else:
        print("(dry-run: pass --out feed.csv or feed.json to write the feed)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
