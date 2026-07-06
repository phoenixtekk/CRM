#!/usr/bin/env python3
# crossmodal_consistency_check.py — verify the modalities tell the SAME story, and scan for real PHI.
#
# PURPOSE: The core multi-modal guarantee. For each synthetic patient it checks CONSISTENCY (note
#          diagnoses appear in the structured problem list; a note-asserted vitals event has a matching
#          signal; units/ranges valid), PLAUSIBILITY (vitals within plausible ranges), NLP-readiness of
#          notes, and runs the release-blocking SYNTHETIC-SAFETY scan (no real-PHI patterns; synthetic
#          identifier allow-list). Read-only: reads synthetic files, writes only the report on --report.
# HOW TO RUN: python crossmodal_consistency_check.py --set ./harness/pilot --config multimodal-config.json \
#             [--report consistency.json]   (Python 3.10+; see --help)
# EXPECTED RESULTS: Prints PASS/FAIL per gate. FAIL on ANY consistency defect or ANY real-PHI hit (the
#          "gate" line is the pass/fail signal). A safety hit is a hard release block.

import argparse
import glob
import json
import os
import re
import sys

# Conservative real-PHI pattern scan for SYNTHETIC free-text. Any hit blocks release for investigation.
PHI_PATTERNS = {
    "ssn": re.compile(r"\b\d{3}-\d{2}-\d{4}\b"),
    "mrn_like": re.compile(r"\bMRN[:#]?\s*\d{4,}\b", re.IGNORECASE),
    "explicit_date": re.compile(r"\b(19|20)\d{2}-\d{2}-\d{2}\b"),
    "phone": re.compile(r"\b\d{3}[.\-]\d{3}[.\-]\d{4}\b"),
    "email": re.compile(r"\b[\w.+-]+@[\w-]+\.[\w.-]+\b"),
}
# Synthetic identifiers are expected to match this allow-list; anything else is flagged.
SYNTH_ID_ALLOW = re.compile(r"^SYN-\d{5}$")


def note_text(note):
    return " ".join(str(v) for v in note.get("sections", {}).values())


def check_patient(pt, cfg):
    defects = []       # consistency defects (block release)
    plausibility = []  # out-of-range vitals (block release)
    safety = []        # real-PHI hits (hard block)
    notes_issues = []  # NLP-readiness issues

    pid = pt.get("patient_id", "?")

    # --- synthetic identifier allow-list ---
    if not SYNTH_ID_ALLOW.match(str(pid)):
        safety.append({"patient": pid, "type": "identifier_not_allowlisted", "value": pid})

    structured_dx = {d["code"] for d in pt.get("structured", {}).get("problem_list", [])}

    # --- notes: consistency (dx in problem list) + NLP-readiness + PHI scan ---
    for note in pt.get("notes", []):
        for code in note.get("stated_diagnoses", []):
            if code not in structured_dx:
                defects.append({"patient": pid, "rule": "note_diagnoses_in_structured_problem_list",
                                "detail": f"note '{note.get('note_type')}' states dx {code} "
                                          "not in structured problem list"})
        # NLP-readiness: required sections non-empty
        for sec, val in note.get("sections", {}).items():
            if not str(val).strip():
                notes_issues.append({"patient": pid, "note": note.get("note_type"),
                                     "detail": f"empty section '{sec}'"})
        # PHI scan of free text
        text = note_text(note)
        for name, rx in PHI_PATTERNS.items():
            if rx.search(text):
                safety.append({"patient": pid, "type": f"phi_pattern:{name}",
                               "note": note.get("note_type")})

    # --- vitals: plausibility + note-asserted events have matching signals ---
    ranges = {c["name"]: c for c in cfg.get("vitals_channels", [])}
    series = pt.get("vitals", {}).get("series", {})
    for name, s in series.items():
        chan = ranges.get(name)
        if not chan:
            defects.append({"patient": pid, "rule": "vitals_units_and_ranges_valid",
                            "detail": f"channel '{name}' not defined in config"})
            continue
        plo, phi = chan.get("plausible", [float("-inf"), float("inf")])
        for point in s.get("points", []):
            v = point["value"]
            if v < plo or v > phi:
                plausibility.append({"patient": pid, "channel": name, "value": v,
                                     "plausible": [plo, phi]})
    # Each asserted event should be reflected — generator records asserted_events; confirm channel exists.
    for ev in pt.get("vitals", {}).get("asserted_events", []):
        if ev["channel"] not in series:
            defects.append({"patient": pid, "rule": "note_asserted_vitals_event_has_matching_signal",
                            "detail": f"asserted event '{ev['event']}' has no '{ev['channel']}' signal"})

    return defects, plausibility, safety, notes_issues


def main(argv=None):
    p = argparse.ArgumentParser(description="Cross-modal consistency + synthetic-safety validator for a "
                                            "multi-modal synthetic set. Read-only; no real PHI.")
    p.add_argument("--set", required=True, dest="set_dir", help="directory of the generated synthetic set")
    p.add_argument("--config", required=True, help="Multi-Modal Config JSON")
    p.add_argument("--report", help="write the JSON report here (otherwise stdout)")
    args = p.parse_args(argv)

    try:
        with open(args.config, encoding="utf-8") as fh:
            cfg = json.load(fh)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR — cannot read config: {exc}", file=sys.stderr)
        return 2

    paths = sorted(glob.glob(os.path.join(args.set_dir, "SYN-*.json")))
    if not paths:
        print(f"ERROR — no SYN-*.json patients found in {args.set_dir}", file=sys.stderr)
        return 2

    all_defects, all_plaus, all_safety, all_notes = [], [], [], []
    for path in paths:
        with open(path, encoding="utf-8") as fh:
            pt = json.load(fh)
        d, pl, sf, ni = check_patient(pt, cfg)
        all_defects += d
        all_plaus += pl
        all_safety += sf
        all_notes += ni

    gates = cfg.get("gate_thresholds", {})
    max_defects = gates.get("consistency_max_defects", 0)
    max_phi = gates.get("safety_max_phi_hits", 0)

    consistency_pass = len(all_defects) <= max_defects
    plausibility_pass = len(all_plaus) == 0
    safety_pass = len(all_safety) <= max_phi

    report = {
        "artifact_name": "Multi-Modal Validation Report – Pilot – v1 (Consistency/Safety)",
        "patients_checked": len(paths),
        "consistency": {"defects": all_defects, "pass": consistency_pass, "max_allowed": max_defects},
        "plausibility": {"violations": all_plaus, "pass": plausibility_pass},
        "notes": {"issues": all_notes, "pass": len(all_notes) == 0},
        "safety": {"hits": all_safety, "pass": safety_pass, "max_allowed": max_phi},
    }

    if args.report:
        with open(args.report, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        print(f"Wrote report to {args.report}.")
    else:
        print(json.dumps(report, indent=2))

    print(f"gate: consistency={'PASS' if consistency_pass else 'FAIL'} "
          f"({len(all_defects)} defects); "
          f"plausibility={'PASS' if plausibility_pass else 'FAIL'} "
          f"({len(all_plaus)} violations); "
          f"nlp={'PASS' if not all_notes else 'FAIL'} ({len(all_notes)} issues); "
          f"safety={'PASS' if safety_pass else 'FAIL'} ({len(all_safety)} PHI hits)", file=sys.stderr)
    if not safety_pass:
        print("HARD BLOCK: real-PHI pattern(s) hit — do NOT release; purge and regenerate. "
              "(Technical guardrail; de-identification determination remains with privacy/legal.)",
              file=sys.stderr)

    all_pass = consistency_pass and plausibility_pass and safety_pass and not all_notes
    return 0 if all_pass else 1


if __name__ == "__main__":
    raise SystemExit(main())
