#!/usr/bin/env python3
# twin_fidelity_report.py — fidelity/behavior report for the hospital twin.
#
# PURPOSE: Compares the twin's synthetic population and event distributions against an agreed
#          reference profile (published or governed real-stats), scoring each metric's distance vs.
#          its threshold, and summarizes scenario coverage. Emits an HTML report. Read-only.
# HOW TO RUN: python twin_fidelity_report.py --config "Twin Scope Config - Pilot - v1.json" \
#             --reference "Twin Reference Profile - Pilot - v1.json" \
#             --out "Twin Fidelity Report - Pilot - v1.html"          (Python 3.10+; see --help)
# EXPECTED RESULTS: Per-metric PASS/FAIL (distance within threshold?) and an overall fidelity verdict,
#                   plus scenario coverage. Any metric over threshold = the fidelity gate is NOT met.
#
# Safe by default: reads only synthetic run summaries and the agreed reference profile; writes only
# the report. No real PHI is read or written; fidelity claims are only as strong as the reference.

import argparse
import html
import json
import os
import sys
from datetime import datetime, timezone


def _now():
    return datetime.now(timezone.utc).isoformat()


def load_json(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def _distribution_from_run(run_log):
    """Derive simple observed distributions from a Twin Simulation Run log (synthetic)."""
    dist = {"event_counts": run_log.get("event_counts", {}),
            "population": run_log.get("population", 0)}
    return dist


def compare_metrics(observed, reference):
    """
    reference: {"metrics": [{"name","expected","observed_key","threshold"}...],
                "covered_use_cases": [...]}
    Compares observed value (looked up by observed_key path) to expected within threshold.
    Distance is normalized absolute difference; PASS when distance <= threshold.
    """
    rows = []
    for m in reference.get("metrics", []):
        name = m["name"]
        expected = float(m["expected"])
        threshold = float(m.get("threshold", 0.1))
        obs_val = _lookup(observed, m.get("observed_key", ""))
        if obs_val is None:
            rows.append({"metric": name, "expected": expected, "observed": None,
                         "distance": None, "threshold": threshold, "pass": False,
                         "note": "observed value not found"})
            continue
        obs_val = float(obs_val)
        denom = abs(expected) if expected != 0 else 1.0
        distance = abs(obs_val - expected) / denom
        rows.append({"metric": name, "expected": expected, "observed": obs_val,
                     "distance": round(distance, 4), "threshold": threshold,
                     "pass": distance <= threshold, "note": ""})
    return rows


def _lookup(d, dotted):
    cur = d
    for part in [p for p in dotted.split(".") if p]:
        if isinstance(cur, dict) and part in cur:
            cur = cur[part]
        else:
            return None
    return cur if isinstance(cur, (int, float)) else None


def coverage(reference, scenario_dir):
    covered = set(reference.get("covered_use_cases", []))
    present = set()
    if scenario_dir and os.path.isdir(scenario_dir):
        for f in os.listdir(scenario_dir):
            if f.endswith(".json"):
                try:
                    present.add(load_json(os.path.join(scenario_dir, f)).get("use_case", f[:-5]))
                except (OSError, json.JSONDecodeError):
                    pass
    return {"required": sorted(covered), "present": sorted(present),
            "uncovered": sorted(covered - present)}


def render_html(cfg_path, rows, cov, verdict):
    def cell(x):
        return html.escape("" if x is None else str(x))
    metric_rows = "".join(
        f"<tr class='{'ok' if r['pass'] else 'bad'}'>"
        f"<td>{cell(r['metric'])}</td><td>{cell(r['expected'])}</td>"
        f"<td>{cell(r['observed'])}</td><td>{cell(r['distance'])}</td>"
        f"<td>{cell(r['threshold'])}</td>"
        f"<td>{'PASS' if r['pass'] else 'FAIL'}</td><td>{cell(r['note'])}</td></tr>"
        for r in rows)
    return f"""<!doctype html><html><head><meta charset="utf-8">
<title>Twin Fidelity Report - Pilot - v1</title>
<style>
body{{font-family:system-ui,Arial,sans-serif;margin:2rem;color:#111}}
table{{border-collapse:collapse;width:100%;margin:1rem 0}}
th,td{{border:1px solid #ccc;padding:.4rem .6rem;text-align:left;font-size:.9rem}}
th{{background:#f2f2f2}}
tr.ok td:nth-child(6){{color:#137333;font-weight:600}}
tr.bad td:nth-child(6){{color:#a50e0e;font-weight:600}}
.verdict{{font-size:1.1rem;font-weight:700}}
.note{{color:#555;font-size:.85rem}}
</style></head><body>
<h1>Twin Fidelity Report &ndash; Pilot &ndash; v1</h1>
<p class="note">Config: {html.escape(cfg_path)} &middot; generated {html.escape(_now())}</p>
<p class="verdict">Fidelity gate: {html.escape(verdict)}</p>
<h2>Per-metric fidelity (distance vs. threshold)</h2>
<table><tr><th>Metric</th><th>Expected</th><th>Observed</th><th>Distance</th>
<th>Threshold</th><th>Result</th><th>Note</th></tr>{metric_rows}</table>
<h2>Scenario coverage</h2>
<p>Required use cases: {html.escape(", ".join(cov['required']) or "(none)")}<br>
Present: {html.escape(", ".join(cov['present']) or "(none)")}<br>
<b>Uncovered: {html.escape(", ".join(cov['uncovered']) or "(none)")}</b></p>
<p class="note">Fidelity claims are only as strong as the reference profile. Real PHI is never used
in the twin. Disclosure-risk and de-identification determinations are deferred to the privacy office.</p>
</body></html>"""


def main(argv=None):
    p = argparse.ArgumentParser(description="Hospital-twin fidelity/coverage report (read-only).")
    p.add_argument("--config", required=True, help="Twin Scope Config JSON path")
    p.add_argument("--reference", required=True, help="Twin Reference Profile JSON path")
    p.add_argument("--run-log", help="Twin Simulation Run JSON (observed distributions)")
    p.add_argument("--scenario-dir", help="scenario directory for coverage check")
    p.add_argument("--out", default="Twin Fidelity Report - Pilot - v1.html",
                   help="HTML report output path")
    args = p.parse_args(argv)

    for path in (args.config, args.reference):
        if not os.path.exists(path):
            print(f"ERROR: not found: {path}", file=sys.stderr)
            return 2

    reference = load_json(args.reference)
    observed = _distribution_from_run(load_json(args.run_log)) if args.run_log and \
        os.path.exists(args.run_log) else {}
    rows = compare_metrics(observed, reference)
    cov = coverage(reference, args.scenario_dir)

    all_pass = all(r["pass"] for r in rows) and not cov["uncovered"]
    verdict = "MET" if all_pass else "NOT MET"

    print(f"Twin fidelity: gate {verdict}")
    for r in rows:
        print(f"  [{'PASS' if r['pass'] else 'FAIL'}] {r['metric']}: "
              f"observed={r['observed']} expected={r['expected']} "
              f"distance={r['distance']} threshold={r['threshold']} {r['note']}")
    if cov["uncovered"]:
        print(f"  [FAIL] uncovered use cases: {', '.join(cov['uncovered'])}")
    else:
        print("  [PASS] all required use cases covered")

    with open(args.out, "w", encoding="utf-8") as fh:
        fh.write(render_html(args.config, rows, cov, verdict))
    print(f"Wrote fidelity report -> {args.out}")
    return 0 if all_pass else 1


if __name__ == "__main__":
    sys.exit(main())
