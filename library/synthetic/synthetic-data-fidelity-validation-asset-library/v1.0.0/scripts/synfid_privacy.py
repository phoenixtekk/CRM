#!/usr/bin/env python3
# synfid_privacy.py — report technical disclosure-risk SIGNALS on synthetic data (not a determination)
#
# PURPOSE: Privacy / disclosure-signal check. Reports technical signals only: the fraction of
#          synthetic quasi-identifier tuples that EXACTLY match a governed reference sample, and a
#          nearest-neighbor distance summary over the quasi-identifiers. These are inputs for the
#          privacy office. It is NOT a HIPAA/HITRUST de-identification determination and never makes
#          a legal call. Read-only; reference input should be minimized and governed.
# HOW TO RUN: python synfid_privacy.py --synthetic synth.csv --reference-sample ref_sample.csv --config validation_suite.json
#             (Python 3.10+, standard library only; see --help)
# EXPECTED RESULTS: A signals report (exact-match fraction, nearest-neighbor min/mean) with a
#                   technical-threshold PASS/FAIL for triage. The determination is deferred to
#                   privacy/compliance/legal (stated in the output). Non-zero exit on threshold breach.

import argparse
import csv
import json
import math
import sys


DISCLAIMER = ("SIGNALS ONLY. This is a technical disclosure-risk indicator for the privacy office. "
              "It is NOT a HIPAA/HITRUST de-identification determination. IRB/privacy-office sign-off "
              "and disclosure-risk acceptance are deferred to privacy/compliance/legal.")


def load_json(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def read_rows(path):
    with open(path, newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def qi_tuple(row, qis):
    return tuple(str(row.get(q, "")) for q in qis)


def numeric_qi_vector(row, qis):
    vec = []
    for q in qis:
        try:
            vec.append(float(row.get(q, "")))
        except (TypeError, ValueError):
            vec.append(None)
    return vec


def exact_match_fraction(syn_rows, ref_rows, qis):
    ref_set = {qi_tuple(r, qis) for r in ref_rows}
    if not syn_rows:
        return 0.0, 0
    matches = sum(1 for r in syn_rows if qi_tuple(r, qis) in ref_set)
    return round(matches / len(syn_rows), 6), matches


def nearest_neighbor_summary(syn_rows, ref_rows, qis, cap=2000):
    """Min/mean nearest-neighbor Euclidean distance over numeric QIs (capped for cost).
    Ranges are normalized per field so scales don't dominate. Rows with any non-numeric QI skipped."""
    ref_vecs = [numeric_qi_vector(r, qis) for r in ref_rows[:cap]]
    ref_vecs = [v for v in ref_vecs if all(x is not None for x in v)]
    syn_vecs = [numeric_qi_vector(r, qis) for r in syn_rows[:cap]]
    syn_vecs = [v for v in syn_vecs if all(x is not None for x in v)]
    if not ref_vecs or not syn_vecs:
        return None
    dim = len(qis)
    mins = [min(v[d] for v in ref_vecs + syn_vecs) for d in range(dim)]
    maxs = [max(v[d] for v in ref_vecs + syn_vecs) for d in range(dim)]
    spans = [(maxs[d] - mins[d]) or 1.0 for d in range(dim)]

    def norm(v):
        return [(v[d] - mins[d]) / spans[d] for d in range(dim)]

    ref_n = [norm(v) for v in ref_vecs]
    nn = []
    for sv in (norm(v) for v in syn_vecs):
        best = None
        for rv in ref_n:
            dist = math.sqrt(sum((a - b) ** 2 for a, b in zip(sv, rv)))
            if best is None or dist < best:
                best = dist
        nn.append(best)
    return {"min": round(min(nn), 6), "mean": round(sum(nn) / len(nn), 6),
            "n_compared": len(nn)}


def main(argv=None):
    p = argparse.ArgumentParser(description="Technical disclosure-risk SIGNALS (not a determination).")
    p.add_argument("--synthetic", required=True, help="Synthetic dataset CSV under test.")
    p.add_argument("--reference-sample", required=True,
                   help="Governed, minimized reference sample CSV (for match/NN signals).")
    p.add_argument("--config", required=True, help="Validation Suite config JSON (privacy block).")
    args = p.parse_args(argv)

    config = load_json(args.config)
    priv = config.get("privacy", {})
    qis = priv.get("quasi_identifiers", [])
    report = {"disclaimer": DISCLAIMER, "verdict": "PASS", "signals": {}}

    if not qis:
        report["verdict"] = "NOT_RUN"
        report["signals"]["note"] = "no quasi_identifiers configured; nothing to check"
        print(json.dumps(report, indent=2))
        return 0

    syn_rows = read_rows(args.synthetic)
    ref_rows = read_rows(args.reference_sample)

    frac, matches = exact_match_fraction(syn_rows, ref_rows, qis)
    max_exact = priv.get("max_exact_match_fraction", 0.0)
    exact_ok = frac <= max_exact
    report["signals"]["exact_match"] = {"fraction": frac, "matches": matches,
                                        "max_allowed": max_exact,
                                        "status": "PASS" if exact_ok else "FAIL"}

    nn = nearest_neighbor_summary(syn_rows, ref_rows, qis)
    nn_ok = True
    if nn is not None:
        min_nn = priv.get("min_nearest_neighbor_distance", 0.0)
        nn_ok = nn["min"] >= min_nn
        report["signals"]["nearest_neighbor"] = {**nn, "min_allowed": min_nn,
                                                 "status": "PASS" if nn_ok else "FAIL"}
    else:
        report["signals"]["nearest_neighbor"] = {"status": "NOT_MEASURED",
                                                 "note": "no fully-numeric QI rows to compare"}

    if not (exact_ok and nn_ok):
        report["verdict"] = "FAIL"
        report["action"] = "Escalate signals to the privacy office; determination remains with privacy/compliance/legal."

    print(json.dumps(report, indent=2))
    return 0 if report["verdict"] in ("PASS", "NOT_RUN") else 1


if __name__ == "__main__":
    sys.exit(main())
