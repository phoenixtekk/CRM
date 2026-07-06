#!/usr/bin/env python3
# synfid_fidelity.py — measure statistical fidelity (and optional utility gap) synthetic vs reference
#
# PURPOSE: Fidelity & utility metric suite. Compares a synthetic dataset to an aggregate-only
#          Reference Profile: per-numeric-field distribution distance (histogram-based), per-
#          categorical-field frequency divergence (total variation), and correlation preservation.
#          Optionally reports a TSTR-style utility gap when a utility task is configured and a real
#          test-metric baseline is provided. Read-only: computes and reports, never writes datasets.
# HOW TO RUN: python synfid_fidelity.py --synthetic synth.csv --profile ref_profile.json --config validation_suite.json
#             (Python 3.10+, standard library only; see --help)
# EXPECTED RESULTS: A per-field metrics report plus PASS/FAIL against the config tolerances, and an
#                   overall fidelity verdict. Non-zero exit when any gated metric breaches tolerance.

import argparse
import csv
import json
import math
import sys
from collections import Counter, defaultdict


def load_json(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def read_columns(path):
    with open(path, newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        header = reader.fieldnames or []
        cols = defaultdict(list)
        for row in reader:
            for h in header:
                cols[h].append(row.get(h, ""))
    return header, cols


def _floats(values):
    out = []
    for v in values:
        if v in ("", None):
            continue
        try:
            out.append(float(v))
        except ValueError:
            continue
    return out


def hist_distance(syn_values, ref_field):
    """Normalized L1 distance between synthetic histogram and the reference histogram (0..1)."""
    lo, hi = ref_field["hist_range"]
    bins = ref_field["hist_bins"]
    ref_counts = ref_field["hist_counts"]
    ref_total = sum(ref_counts) or 1
    ref_p = [c / ref_total for c in ref_counts]
    width = (hi - lo) / bins if hi > lo else 1.0
    syn_counts = [0] * bins
    nums = _floats(syn_values)
    for x in nums:
        if hi > lo:
            idx = min(max(int((x - lo) / width), 0), bins - 1)
        else:
            idx = 0
        syn_counts[idx] += 1
    syn_total = sum(syn_counts) or 1
    syn_p = [c / syn_total for c in syn_counts]
    # total variation distance = 0.5 * sum|p-q|, in [0,1]
    return round(0.5 * sum(abs(a - b) for a, b in zip(ref_p, syn_p)), 6)


def category_divergence(syn_values, ref_field):
    """Total-variation distance between synthetic and reference category frequencies (0..1)."""
    ref_freq = ref_field.get("frequencies", {})
    present = [v for v in syn_values if v not in ("", None)]
    counts = Counter(present)
    total = sum(counts.values()) or 1
    syn_freq = {k: c / total for k, c in counts.items()}
    keys = set(ref_freq) | set(syn_freq)
    tv = 0.5 * sum(abs(ref_freq.get(k, 0.0) - syn_freq.get(k, 0.0)) for k in keys)
    return round(tv, 6)


def pearson(xs, ys):
    n = len(xs)
    if n < 2:
        return None
    mx, my = sum(xs) / n, sum(ys) / n
    dx = math.sqrt(sum((a - mx) ** 2 for a in xs))
    dy = math.sqrt(sum((b - my) ** 2 for b in ys))
    if dx == 0 or dy == 0:
        return None
    return sum((a - mx) * (b - my) for a, b in zip(xs, ys)) / (dx * dy)


def correlation_preservation(cols, profile):
    """1 - mean(|r_synth - r_ref|) over the pairs the reference tracked (higher is better)."""
    ref_corr = profile.get("correlations", {})
    if not ref_corr:
        return None, []
    deltas = []
    detail = []
    for pair, r_ref in ref_corr.items():
        a, b = pair.split("|", 1)
        xs, ys = [], []
        for va, vb in zip(cols.get(a, []), cols.get(b, [])):
            if va in ("", None) or vb in ("", None):
                continue
            try:
                xs.append(float(va))
                ys.append(float(vb))
            except ValueError:
                continue
        r_syn = pearson(xs, ys)
        if r_syn is None:
            continue
        d = abs(r_syn - r_ref)
        deltas.append(d)
        detail.append({"pair": pair, "ref_r": round(r_ref, 4),
                       "syn_r": round(r_syn, 4), "abs_delta": round(d, 4)})
    if not deltas:
        return None, []
    score = 1.0 - (sum(deltas) / len(deltas))
    return round(score, 6), detail


def main(argv=None):
    p = argparse.ArgumentParser(description="Fidelity & utility metric suite (synthetic vs reference profile).")
    p.add_argument("--synthetic", required=True, help="Synthetic dataset CSV under test.")
    p.add_argument("--profile", required=True, help="Aggregate-only Reference Profile JSON.")
    p.add_argument("--config", required=True, help="Validation Suite config JSON (tolerances).")
    p.add_argument("--real-test-metric", type=float, default=None,
                   help="Optional: real-trained model score on the real test set (for TSTR utility gap).")
    p.add_argument("--synth-test-metric", type=float, default=None,
                   help="Optional: synthetic-trained model score on the same real test set.")
    args = p.parse_args(argv)

    profile = load_json(args.profile)
    config = load_json(args.config)
    tol = config.get("tolerances", {})
    header, cols = read_columns(args.synthetic)

    report = {"fields": {}, "gates": {}, "verdict": "PASS"}
    failures = []

    max_dist = tol.get("max_distribution_distance", 0.10)
    max_div = tol.get("max_category_divergence", 0.10)

    for name, ref_field in profile.get("fields", {}).items():
        if ref_field.get("excluded"):
            continue
        if name not in cols:
            report["fields"][name] = {"status": "MISSING_IN_SYNTHETIC"}
            failures.append(f"{name}: absent from synthetic dataset")
            continue
        if ref_field.get("type") == "numeric":
            d = hist_distance(cols[name], ref_field)
            ok = d <= max_dist
            report["fields"][name] = {"type": "numeric", "distribution_distance": d,
                                      "tolerance": max_dist, "status": "PASS" if ok else "FAIL"}
            if not ok:
                failures.append(f"{name}: distribution_distance {d} > {max_dist}")
        else:
            dv = category_divergence(cols[name], ref_field)
            ok = dv <= max_div
            report["fields"][name] = {"type": "categorical", "category_divergence": dv,
                                      "tolerance": max_div, "status": "PASS" if ok else "FAIL"}
            if not ok:
                failures.append(f"{name}: category_divergence {dv} > {max_div}")

    corr_score, corr_detail = correlation_preservation(cols, profile)
    if corr_score is not None:
        min_corr = tol.get("min_correlation_preservation", 0.85)
        ok = corr_score >= min_corr
        report["gates"]["correlation_preservation"] = {
            "score": corr_score, "min": min_corr, "detail": corr_detail,
            "status": "PASS" if ok else "FAIL"}
        if not ok:
            failures.append(f"correlation_preservation {corr_score} < {min_corr}")

    # Optional TSTR-style utility gap
    if args.real_test_metric is not None and args.synth_test_metric is not None:
        gap = round(args.real_test_metric - args.synth_test_metric, 6)
        max_gap = tol.get("max_utility_gap", 0.05)
        ok = gap <= max_gap
        report["gates"]["utility_gap"] = {"gap": gap, "max": max_gap,
                                          "status": "PASS" if ok else "FAIL"}
        if not ok:
            failures.append(f"utility_gap {gap} > {max_gap}")
    elif config.get("utility_task", {}).get("in_scope"):
        report["gates"]["utility_gap"] = {"status": "NOT_MEASURED",
                                          "note": "utility in scope but no metrics supplied "
                                                  "(--real-test-metric/--synth-test-metric)"}
        failures.append("utility in scope but not measured")

    if failures:
        report["verdict"] = "FAIL"
        report["failures"] = failures

    print(json.dumps(report, indent=2))
    return 0 if report["verdict"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
