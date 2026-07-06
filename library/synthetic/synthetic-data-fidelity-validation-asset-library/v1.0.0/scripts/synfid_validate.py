#!/usr/bin/env python3
# synfid_validate.py — run the full Validation Suite and emit a PASS/FAIL Evidence Report
#
# PURPOSE: Reusable validation-suite runner. Orchestrates fidelity, coverage, and privacy-signal
#          checks under one Validation Suite config and produces a machine-readable + human-readable
#          Evidence Report with an overall PASS/FAIL against every gate. This is what makes each
#          synthetic dataset ship with evidence. Safe by default: prints the report unless --write.
# HOW TO RUN: python synfid_validate.py --synthetic synth.csv --profile ref_profile.json \
#               --config validation_suite.json [--reference-sample ref_sample.csv] \
#               [--real-test-metric R --synth-test-metric S] [--out evidence_report.json] [--write]
#             (Python 3.10+, standard library only; imports the sibling synfid_* modules; see --help)
# EXPECTED RESULTS: An Evidence Report (JSON + printed summary) with per-gate verdicts and an overall
#                   PASS/FAIL. Non-zero exit when the overall verdict is FAIL (drives the release gate).

import argparse
import json
import os
import sys
from datetime import datetime, timezone

# Import sibling tools so the runner reuses their exact metric logic.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import synfid_fidelity  # noqa: E402
import synfid_coverage  # noqa: E402
import synfid_privacy   # noqa: E402


def load_json(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def run_fidelity(args, config, profile):
    header, cols = synfid_fidelity.read_columns(args.synthetic)
    tol = config.get("tolerances", {})
    result = {"fields": {}, "gates": {}, "verdict": "PASS", "failures": []}
    max_dist = tol.get("max_distribution_distance", 0.10)
    max_div = tol.get("max_category_divergence", 0.10)
    for name, ref_field in profile.get("fields", {}).items():
        if ref_field.get("excluded"):
            continue
        if name not in cols:
            result["fields"][name] = {"status": "MISSING_IN_SYNTHETIC"}
            result["failures"].append(f"{name}: absent from synthetic dataset")
            continue
        if ref_field.get("type") == "numeric":
            d = synfid_fidelity.hist_distance(cols[name], ref_field)
            ok = d <= max_dist
            result["fields"][name] = {"type": "numeric", "distribution_distance": d,
                                      "tolerance": max_dist, "status": "PASS" if ok else "FAIL"}
            if not ok:
                result["failures"].append(f"{name}: distribution_distance {d} > {max_dist}")
        else:
            dv = synfid_fidelity.category_divergence(cols[name], ref_field)
            ok = dv <= max_div
            result["fields"][name] = {"type": "categorical", "category_divergence": dv,
                                      "tolerance": max_div, "status": "PASS" if ok else "FAIL"}
            if not ok:
                result["failures"].append(f"{name}: category_divergence {dv} > {max_div}")
    score, detail = synfid_fidelity.correlation_preservation(cols, profile)
    if score is not None:
        min_corr = tol.get("min_correlation_preservation", 0.85)
        ok = score >= min_corr
        result["gates"]["correlation_preservation"] = {"score": score, "min": min_corr,
                                                        "status": "PASS" if ok else "FAIL"}
        if not ok:
            result["failures"].append(f"correlation_preservation {score} < {min_corr}")
    if args.real_test_metric is not None and args.synth_test_metric is not None:
        gap = round(args.real_test_metric - args.synth_test_metric, 6)
        max_gap = tol.get("max_utility_gap", 0.05)
        ok = gap <= max_gap
        result["gates"]["utility_gap"] = {"gap": gap, "max": max_gap,
                                          "status": "PASS" if ok else "FAIL"}
        if not ok:
            result["failures"].append(f"utility_gap {gap} > {max_gap}")
    elif config.get("utility_task", {}).get("in_scope"):
        result["gates"]["utility_gap"] = {"status": "NOT_MEASURED"}
        result["failures"].append("utility in scope but not measured")
    if result["failures"]:
        result["verdict"] = "FAIL"
    return result


def run_coverage(args, config):
    targets = config.get("coverage_targets", [])
    rows = synfid_coverage.read_rows(args.synthetic)
    n = len(rows) or 1
    result = {"targets": [], "verdict": "PASS", "gaps": []}
    for t in targets:
        try:
            preds = synfid_coverage.parse_rule(t["rule"])
        except ValueError as e:
            result["targets"].append({"name": t.get("name"), "status": "RULE_ERROR", "error": str(e)})
            result["gaps"].append(f"{t.get('name')}: {e}")
            continue
        matched = sum(1 for r in rows if synfid_coverage.row_matches(r, preds))
        frac = round(matched / n, 6)
        min_frac = t.get("min_fraction", 0.0)
        ok = frac >= min_frac
        result["targets"].append({"name": t.get("name"), "observed_fraction": frac,
                                  "min_fraction": min_frac, "status": "PASS" if ok else "FAIL"})
        if not ok:
            result["gaps"].append(f"{t.get('name')}: observed {frac} < required {min_frac}")
    if result["gaps"]:
        result["verdict"] = "FAIL"
    return result


def run_privacy(args, config):
    priv = config.get("privacy", {})
    qis = priv.get("quasi_identifiers", [])
    if not qis:
        return {"verdict": "NOT_RUN", "note": "no quasi_identifiers configured"}
    if not args.reference_sample:
        return {"verdict": "NOT_RUN", "note": "privacy configured but no --reference-sample supplied"}
    syn_rows = synfid_privacy.read_rows(args.synthetic)
    ref_rows = synfid_privacy.read_rows(args.reference_sample)
    frac, matches = synfid_privacy.exact_match_fraction(syn_rows, ref_rows, qis)
    max_exact = priv.get("max_exact_match_fraction", 0.0)
    exact_ok = frac <= max_exact
    result = {"disclaimer": synfid_privacy.DISCLAIMER, "verdict": "PASS",
              "exact_match": {"fraction": frac, "matches": matches, "max_allowed": max_exact,
                              "status": "PASS" if exact_ok else "FAIL"}}
    nn = synfid_privacy.nearest_neighbor_summary(syn_rows, ref_rows, qis)
    nn_ok = True
    if nn is not None:
        min_nn = priv.get("min_nearest_neighbor_distance", 0.0)
        nn_ok = nn["min"] >= min_nn
        result["nearest_neighbor"] = {**nn, "min_allowed": min_nn,
                                      "status": "PASS" if nn_ok else "FAIL"}
    if not (exact_ok and nn_ok):
        result["verdict"] = "FAIL"
    return result


def main(argv=None):
    p = argparse.ArgumentParser(description="Run the full Validation Suite and emit an Evidence Report.")
    p.add_argument("--synthetic", required=True, help="Synthetic dataset CSV under test.")
    p.add_argument("--profile", required=True, help="Aggregate-only Reference Profile JSON.")
    p.add_argument("--config", required=True, help="Validation Suite config JSON.")
    p.add_argument("--reference-sample", help="Governed minimized reference sample CSV (privacy signals).")
    p.add_argument("--real-test-metric", type=float, default=None, help="TSTR: real-trained score.")
    p.add_argument("--synth-test-metric", type=float, default=None, help="TSTR: synthetic-trained score.")
    p.add_argument("--out", help="Output path for the Evidence Report (used with --write).")
    p.add_argument("--write", action="store_true", help="Write to --out (default: print only).")
    args = p.parse_args(argv)

    config = load_json(args.config)
    profile = load_json(args.profile)

    fidelity = run_fidelity(args, config, profile)
    coverage = run_coverage(args, config)
    privacy = run_privacy(args, config)

    gate_verdicts = {"fidelity": fidelity["verdict"], "coverage": coverage["verdict"],
                     "privacy": privacy["verdict"]}
    # Overall PASS only when no gate is FAIL. NOT_RUN/NOT_MEASURED do not pass silently for privacy
    # if it was configured; run_privacy already downgrades to NOT_RUN only when truly unconfigured.
    overall = "PASS"
    if any(v == "FAIL" for v in gate_verdicts.values()):
        overall = "FAIL"

    report = {
        "asset_name": config.get("asset_name", "Validation Suite"),
        "evidence_report": "Evidence Report",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "reference_profile_hash": profile.get("_hash"),
        "overall_verdict": overall,
        "gate_verdicts": gate_verdicts,
        "fidelity": fidelity,
        "coverage": coverage,
        "privacy": privacy,
        "note": "Privacy results are SIGNALS ONLY; de-identification determination is deferred to "
                "the organization's privacy/compliance/legal functions.",
    }

    out = json.dumps(report, indent=2)
    if args.write and args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(out + "\n")
        print(f"[written] Evidence Report -> {args.out}")
    # human-readable summary always printed
    print(f"=== Evidence Report: {report['asset_name']} ===")
    print(f"overall: {overall}   fidelity={gate_verdicts['fidelity']} "
          f"coverage={gate_verdicts['coverage']} privacy={gate_verdicts['privacy']}")
    if overall == "FAIL":
        for section in ("fidelity", "coverage"):
            for f in report[section].get("failures", []) or report[section].get("gaps", []):
                print(f"  - {section}: {f}")
        if privacy.get("verdict") == "FAIL":
            print("  - privacy: disclosure signal breached threshold (escalate to privacy office)")
    if not (args.write and args.out):
        print("# dry-run: pass --write --out <file> to save the full JSON Evidence Report.")
    return 0 if overall == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
