#!/usr/bin/env python3
# scope_config_helper.py — initialize and validate the single Multi-Modal Config that drives everything.
#
# PURPOSE: Create ("init") and check ("validate") the Multi-Modal Config – Pilot – v1 that encodes the
#          scope, note types, vitals channels/ranges, cross-modal consistency rules, and pass/fail gate
#          thresholds. Read/emit-only: it writes a config file only on explicit --out, never real PHI.
# HOW TO RUN: python scope_config_helper.py init --out multimodal-config.json   (Python 3.10+; see --help)
#             python scope_config_helper.py validate --config multimodal-config.json
# EXPECTED RESULTS: "init" prints/writes a well-formed config skeleton; "validate" prints PASS with no
#          issues, or FAIL and a list of problems (missing sections, ranges, or gate thresholds).

import argparse
import json
import sys

# A safe, synthetic-only default config. All values are examples to be tuned per solution — no real data.
DEFAULT_CONFIG = {
    "artifact_name": "Multi-Modal Config – Pilot – v1",
    "target_model": "FHIR",  # or "OMOP" or a native schema name
    "modalities": ["structured", "notes", "vitals"],
    "note_types": [
        {"type": "admission_note", "sections": ["hpi", "assessment", "plan"]},
        {"type": "progress_note", "sections": ["subjective", "objective", "assessment", "plan"]},
        {"type": "discharge_summary", "sections": ["course", "diagnoses", "medications", "followup"]},
    ],
    "vitals_channels": [
        {"name": "heart_rate", "unit": "bpm", "normal": [60, 100], "plausible": [30, 220]},
        {"name": "systolic_bp", "unit": "mmHg", "normal": [90, 120], "plausible": [50, 250]},
        {"name": "respiratory_rate", "unit": "breaths/min", "normal": [12, 20], "plausible": [4, 60]},
        {"name": "temperature_c", "unit": "C", "normal": [36.1, 37.2], "plausible": [30.0, 43.0]},
        {"name": "spo2", "unit": "%", "normal": [95, 100], "plausible": [50, 100]},
    ],
    "vitals_cadence_minutes": 60,
    "consistency_rules": [
        "note_diagnoses_in_structured_problem_list",
        "note_asserted_vitals_event_has_matching_signal",
        "vitals_units_and_ranges_valid",
    ],
    "gate_thresholds": {
        "coverage_min_pct": 100.0,
        "fidelity_max_distance": 0.15,
        "consistency_max_defects": 0,
        "safety_max_phi_hits": 0,
    },
    "reference_note": "Fidelity is measured only against the reference recorded here (global req. #6).",
    "safety_note": "Synthetic only. No real PHI in the shared harness. Regulatory determination deferred "
                   "to privacy/compliance/legal.",
}

REQUIRED_TOP_KEYS = [
    "target_model", "modalities", "note_types", "vitals_channels",
    "vitals_cadence_minutes", "consistency_rules", "gate_thresholds",
]
REQUIRED_GATES = ["coverage_min_pct", "fidelity_max_distance", "consistency_max_defects", "safety_max_phi_hits"]
VALID_MODALITIES = {"structured", "notes", "vitals"}


def cmd_init(args):
    cfg = json.loads(json.dumps(DEFAULT_CONFIG))  # deep copy
    if args.scope:
        cfg["scope_ref"] = args.scope
    text = json.dumps(cfg, indent=2)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(text + "\n")
        print(f"Wrote config skeleton to {args.out} ({cfg['artifact_name']}).")
        print("Next: tune values, then run: python scope_config_helper.py validate --config " + args.out)
    else:
        print(text)
        print("\n[dry-run] No file written. Re-run with --out <path> to save.", file=sys.stderr)
    return 0


def validate_config(cfg):
    issues = []
    for key in REQUIRED_TOP_KEYS:
        if key not in cfg:
            issues.append(f"missing required key: {key}")
    mods = cfg.get("modalities", [])
    if not mods:
        issues.append("modalities is empty")
    for m in mods:
        if m not in VALID_MODALITIES:
            issues.append(f"unknown modality: {m}")
    for ch in cfg.get("vitals_channels", []):
        name = ch.get("name", "?")
        for band in ("normal", "plausible"):
            b = ch.get(band)
            if not (isinstance(b, list) and len(b) == 2 and b[0] < b[1]):
                issues.append(f"vitals channel '{name}': {band} must be [low, high] with low<high")
        if ch.get("normal") and ch.get("plausible"):
            n, p = ch["normal"], ch["plausible"]
            if len(n) == 2 and len(p) == 2 and (n[0] < p[0] or n[1] > p[1]):
                issues.append(f"vitals channel '{name}': normal range must sit within plausible range")
    gates = cfg.get("gate_thresholds", {})
    for g in REQUIRED_GATES:
        if g not in gates:
            issues.append(f"gate_thresholds missing: {g}")
    if not cfg.get("note_types"):
        issues.append("note_types is empty (no notes to synthesize)")
    if not cfg.get("consistency_rules"):
        issues.append("consistency_rules is empty (nothing to gate consistency on)")
    return issues


def cmd_validate(args):
    try:
        with open(args.config, encoding="utf-8") as fh:
            cfg = json.load(fh)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"FAIL — cannot read config: {exc}")
        return 2
    issues = validate_config(cfg)
    if issues:
        print(f"FAIL — {len(issues)} issue(s) in {args.config}:")
        for i in issues:
            print(f"  - {i}")
        return 1
    print(f"PASS — {args.config} is a well-formed Multi-Modal Config.")
    print(f"  target_model={cfg.get('target_model')}  modalities={cfg.get('modalities')}  "
          f"channels={len(cfg.get('vitals_channels', []))}  note_types={len(cfg.get('note_types', []))}")
    return 0


def build_parser():
    p = argparse.ArgumentParser(description="Init/validate the Multi-Modal Config that drives generation "
                                            "and validation. Safe: writes only on --out; no real PHI.")
    sub = p.add_subparsers(dest="command", required=True)

    pi = sub.add_parser("init", help="emit a config skeleton (stdout unless --out)")
    pi.add_argument("--out", help="write the config to this path (otherwise stdout / dry-run)")
    pi.add_argument("--scope", help="name of the Modality Scope record to reference")
    pi.set_defaults(func=cmd_init)

    pv = sub.add_parser("validate", help="check a config for required sections and valid ranges")
    pv.add_argument("--config", required=True, help="path to the config JSON to validate")
    pv.set_defaults(func=cmd_validate)
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
