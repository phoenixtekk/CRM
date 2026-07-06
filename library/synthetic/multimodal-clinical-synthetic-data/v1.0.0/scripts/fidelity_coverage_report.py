#!/usr/bin/env python3
# fidelity_coverage_report.py — measure modality coverage and fidelity of a multi-modal synthetic set.
#
# PURPOSE: Load a generated Multi-Modal Synthetic Set and report (a) COVERAGE — is every in-scope
#          modality present for every patient — and (b) FIDELITY — do vitals distributions match a
#          reference within the configured threshold. Read-only: reads synthetic files, writes only the
#          report on --report. No real PHI is read or written.
# HOW TO RUN: python fidelity_coverage_report.py --set ./harness/pilot --config multimodal-config.json \
#             [--reference reference-stats.json] [--report fidelity-coverage.json]   (Python 3.10+)
# EXPECTED RESULTS: Prints PASS/FAIL for coverage and fidelity gates and a summary; the pass/fail signal
#          is the "gate" line. Coverage FAILs if any patient is missing an in-scope modality.

import argparse
import glob
import json
import os
import statistics
import sys


def load_patients(set_dir):
    patients = []
    for path in sorted(glob.glob(os.path.join(set_dir, "SYN-*.json"))):
        with open(path, encoding="utf-8") as fh:
            patients.append(json.load(fh))
    return patients


def coverage(patients, modalities):
    total = len(patients)
    present = {m: 0 for m in modalities}
    missing = []
    for pt in patients:
        for m in modalities:
            if m == "vitals":
                ok = bool(pt.get("vitals", {}).get("series"))
            elif m == "notes":
                ok = bool(pt.get("notes"))
            else:
                ok = bool(pt.get(m))
            if ok:
                present[m] += 1
            else:
                missing.append({"patient": pt.get("patient_id"), "modality": m})
    pct = {m: (100.0 * present[m] / total if total else 0.0) for m in modalities}
    return {"total_patients": total, "present": present, "pct": pct, "missing": missing}


def fidelity(patients, cfg, reference):
    """Compare mean of each vitals channel to a reference mean; distance = normalized abs diff."""
    channels = [c["name"] for c in cfg.get("vitals_channels", [])]
    result = {}
    for name in channels:
        vals = []
        for pt in patients:
            series = pt.get("vitals", {}).get("series", {}).get(name)
            if series:
                vals.extend(pt_pt["value"] for pt_pt in series["points"])
        if not vals:
            continue
        synth_mean = statistics.fmean(vals)
        ref = (reference or {}).get(name, {})
        ref_mean = ref.get("mean")
        entry = {"synthetic_mean": round(synth_mean, 2), "n": len(vals)}
        if ref_mean is not None and ref_mean != 0:
            dist = abs(synth_mean - ref_mean) / abs(ref_mean)
            entry.update({"reference_mean": ref_mean, "distance": round(dist, 4)})
        else:
            entry["distance"] = None  # no reference -> cannot score (see global req #6)
        result[name] = entry
    return result


def main(argv=None):
    p = argparse.ArgumentParser(description="Coverage + fidelity report for a multi-modal synthetic set. "
                                            "Read-only; no real PHI.")
    p.add_argument("--set", required=True, dest="set_dir", help="directory of the generated synthetic set")
    p.add_argument("--config", required=True, help="Multi-Modal Config JSON")
    p.add_argument("--reference", help="reference stats JSON: {channel: {mean: X}} (global req #6)")
    p.add_argument("--report", help="write the JSON report here (otherwise stdout)")
    args = p.parse_args(argv)

    try:
        with open(args.config, encoding="utf-8") as fh:
            cfg = json.load(fh)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR — cannot read config: {exc}", file=sys.stderr)
        return 2

    reference = None
    if args.reference:
        try:
            with open(args.reference, encoding="utf-8") as fh:
                reference = json.load(fh)
        except (OSError, json.JSONDecodeError) as exc:
            print(f"ERROR — cannot read reference: {exc}", file=sys.stderr)
            return 2

    patients = load_patients(args.set_dir)
    if not patients:
        print(f"ERROR — no SYN-*.json patients found in {args.set_dir}", file=sys.stderr)
        return 2

    modalities = cfg.get("modalities", ["structured", "notes", "vitals"])
    gates = cfg.get("gate_thresholds", {})
    cov = coverage(patients, modalities)
    fid = fidelity(patients, cfg, reference)

    cov_min = gates.get("coverage_min_pct", 100.0)
    cov_pass = all(pct >= cov_min for pct in cov["pct"].values())

    fid_max = gates.get("fidelity_max_distance", 0.15)
    scored = [v["distance"] for v in fid.values() if v.get("distance") is not None]
    fid_scored = bool(scored)
    fid_pass = all(d <= fid_max for d in scored) if scored else None  # None => not scored (no reference)

    report = {
        "artifact_name": "Multi-Modal Validation Report – Pilot – v1 (Fidelity/Coverage)",
        "coverage": cov, "fidelity": fid,
        "gates": {"coverage_min_pct": cov_min, "coverage_pass": cov_pass,
                  "fidelity_max_distance": fid_max, "fidelity_pass": fid_pass, "fidelity_scored": fid_scored},
    }

    if args.report:
        with open(args.report, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        print(f"Wrote report to {args.report}.")
    else:
        print(json.dumps(report, indent=2))

    print(f"gate: coverage={'PASS' if cov_pass else 'FAIL'} "
          f"(min {cov_min}%); "
          f"fidelity={'PASS' if fid_pass else ('FAIL' if fid_pass is False else 'NOT-SCORED')} "
          f"(max distance {fid_max})", file=sys.stderr)
    if fid_pass is None:
        print("NOTE: fidelity not scored — provide --reference to score (global requirement #6).",
              file=sys.stderr)

    # Non-zero exit if a scored gate fails, so CI can gate on it.
    if not cov_pass or fid_pass is False:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
