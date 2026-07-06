#!/usr/bin/env python3
# multimodal_generate.py — generate structured + notes + vitals for synthetic patients from ONE state.
#
# PURPOSE: For each synthetic patient, derive one clinical state and render three CONSISTENT modalities:
#          a structured record, template/pattern clinical notes (NLP-ready), and vitals/time-series.
#          Safe by default: DRY-RUN (no files written) unless --write is given; only synthetic data,
#          only to the isolated harness path you name. No real PHI is ever used or written.
# HOW TO RUN: python multimodal_generate.py --config multimodal-config.json --patients 25 \
#             [--out ./harness/pilot --write] [--seed 7]   (Python 3.10+; see --help)
# EXPECTED RESULTS: Dry-run prints a per-patient preview and counts; with --write, one JSON file per
#          patient under --out plus a manifest. Every patient has all in-scope modalities from one state.

import argparse
import json
import os
import random
import sys

SYNTH_FIRST = ["Alex", "Sam", "Jordan", "Casey", "Riley", "Morgan", "Taylor", "Jamie"]  # synthetic only
SYNTH_LAST = ["Synthetic", "Testcase", "Sample", "Placeholder", "Fixture"]  # obviously non-real

# Small synthetic clinical scenario bank. Each scenario keys notes AND vitals to the SAME facts.
SCENARIOS = [
    {
        "key": "sepsis_suspected",
        "primary_dx": {"code": "A41.9", "text": "Sepsis, unspecified organism"},
        "facts": {"febrile": True, "hypotensive_episode": True, "tachycardic": True},
        "note_phrases": {
            "hpi": "Presents with fever and malaise; concern for infection.",
            "assessment": "Suspected sepsis; febrile and tachycardic with a hypotensive episode.",
            "plan": "Cultures, IV fluids, empiric antibiotics per protocol; monitor closely.",
        },
    },
    {
        "key": "stable_observation",
        "primary_dx": {"code": "Z04.9", "text": "Observation, unspecified"},
        "facts": {"febrile": False, "hypotensive_episode": False, "tachycardic": False},
        "note_phrases": {
            "hpi": "Presents for observation; hemodynamically stable, afebrile.",
            "assessment": "Stable; vital signs within normal limits.",
            "plan": "Continue observation; discharge planning if stable overnight.",
        },
    },
    {
        "key": "resp_distress",
        "primary_dx": {"code": "J96.00", "text": "Acute respiratory failure"},
        "facts": {"febrile": False, "hypoxic": True, "tachypneic": True},
        "note_phrases": {
            "hpi": "Presents with shortness of breath and increased work of breathing.",
            "assessment": "Acute respiratory distress; hypoxic and tachypneic.",
            "plan": "Supplemental oxygen, monitor SpO2 and respiratory rate; escalate if worsening.",
        },
    },
]


def band(rng, low, high, ndigits=0):
    v = rng.uniform(low, high)
    return round(v, ndigits) if ndigits else int(round(v))


def channel_target(name, facts):
    """Return (baseline_low, baseline_high) for a channel given the scenario facts."""
    base = {
        "heart_rate": (65, 90), "systolic_bp": (105, 120), "respiratory_rate": (13, 18),
        "temperature_c": (36.4, 37.0), "spo2": (96, 99),
    }.get(name, (0, 1))
    if name == "temperature_c" and facts.get("febrile"):
        return (38.3, 39.4)
    if name == "heart_rate" and facts.get("tachycardic"):
        return (105, 125)
    if name == "systolic_bp" and facts.get("hypotensive_episode"):
        return (80, 92)
    if name == "respiratory_rate" and facts.get("tachypneic"):
        return (24, 32)
    if name == "spo2" and facts.get("hypoxic"):
        return (86, 92)
    return base


def gen_vitals(rng, cfg, facts, hours=24):
    cadence = cfg.get("vitals_cadence_minutes", 60)
    steps = max(1, int(hours * 60 / cadence))
    series = {}
    events = []
    for ch in cfg.get("vitals_channels", []):
        name = ch["name"]
        lo, hi = channel_target(name, facts)
        ndig = 1 if name == "temperature_c" else 0
        pts = []
        for t in range(steps):
            minute = t * cadence
            pts.append({"t_min": minute, "value": band(rng, lo, hi, ndig)})
        series[name] = {"unit": ch.get("unit", ""), "points": pts}
    # Record which asserted events the vitals actually reflect (used by the consistency validator).
    if facts.get("febrile"):
        events.append({"channel": "temperature_c", "event": "fever"})
    if facts.get("tachycardic"):
        events.append({"channel": "heart_rate", "event": "tachycardia"})
    if facts.get("hypotensive_episode"):
        events.append({"channel": "systolic_bp", "event": "hypotension"})
    if facts.get("tachypneic"):
        events.append({"channel": "respiratory_rate", "event": "tachypnea"})
    if facts.get("hypoxic"):
        events.append({"channel": "spo2", "event": "hypoxia"})
    return series, events


def render_note(note_type_cfg, scenario, pid):
    """Slot-fill a template. No real note text — pattern phrases keyed to the scenario facts."""
    phrases = scenario["note_phrases"]
    sections = {}
    for sec in note_type_cfg.get("sections", []):
        if sec in ("hpi", "subjective", "course"):
            sections[sec] = phrases.get("hpi", "Synthetic clinical narrative.")
        elif sec in ("assessment", "diagnoses"):
            sections[sec] = phrases.get("assessment", "Assessment.") + \
                f" Primary: {scenario['primary_dx']['text']} ({scenario['primary_dx']['code']})."
        elif sec in ("plan", "followup", "medications"):
            sections[sec] = phrases.get("plan", "Plan.")
        elif sec == "objective":
            sections[sec] = "Vitals as recorded in the paired time-series."
        else:
            sections[sec] = "Synthetic content."
    return {
        "note_type": note_type_cfg["type"],
        "patient_ref": pid,
        "sections": sections,
        "stated_diagnoses": [scenario["primary_dx"]["code"]],
    }


def make_patient(rng, cfg, idx):
    pid = f"SYN-{idx:05d}"  # synthetic identifier, allow-listed by design
    scenario = rng.choice(SCENARIOS)
    facts = scenario["facts"]
    structured = {
        "id": pid,
        "name": {"given": rng.choice(SYNTH_FIRST), "family": rng.choice(SYNTH_LAST)},
        "target_model": cfg.get("target_model", "FHIR"),
        "problem_list": [scenario["primary_dx"]],
        "encounter": {"class": "inpatient", "length_hours": 24},
    }
    patient = {"patient_id": pid, "scenario": scenario["key"], "clinical_state_facts": facts}
    mods = set(cfg.get("modalities", ["structured", "notes", "vitals"]))
    if "structured" in mods:
        patient["structured"] = structured
    if "notes" in mods:
        patient["notes"] = [render_note(nt, scenario, pid) for nt in cfg.get("note_types", [])]
    if "vitals" in mods:
        series, events = gen_vitals(rng, cfg, facts, hours=structured["encounter"]["length_hours"])
        patient["vitals"] = {"series": series, "asserted_events": events}
    return patient


def main(argv=None):
    p = argparse.ArgumentParser(description="Generate consistent multi-modal synthetic patients from one "
                                            "shared clinical state. Dry-run by default; --write to save "
                                            "synthetic data to the isolated harness. Never real PHI.")
    p.add_argument("--config", required=True, help="Multi-Modal Config JSON (see scope_config_helper.py)")
    p.add_argument("--patients", type=int, default=10, help="pilot cohort size (default 10)")
    p.add_argument("--out", help="output directory (required with --write)")
    p.add_argument("--write", action="store_true",
                   help="OPT-IN: actually write synthetic files to --out (default is dry-run)")
    p.add_argument("--seed", type=int, default=1234, help="RNG seed for reproducibility")
    args = p.parse_args(argv)

    try:
        with open(args.config, encoding="utf-8") as fh:
            cfg = json.load(fh)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR — cannot read config: {exc}", file=sys.stderr)
        return 2

    if args.write and not args.out:
        p.error("--write requires --out <isolated-harness-dir>")

    rng = random.Random(args.seed)
    patients = [make_patient(rng, cfg, i + 1) for i in range(max(1, args.patients))]

    mods = cfg.get("modalities", [])
    print(f"Generated {len(patients)} synthetic patients; modalities per patient: {', '.join(mods)}")
    sample = patients[0]
    print("Preview (patient 1): scenario=%s, notes=%d, vitals_channels=%d, asserted_events=%s" % (
        sample.get("scenario"),
        len(sample.get("notes", [])),
        len(sample.get("vitals", {}).get("series", {})),
        [e["event"] for e in sample.get("vitals", {}).get("asserted_events", [])],
    ))

    if not args.write:
        print("\n[dry-run] No files written. Re-run with --out <dir> --write to save to the isolated "
              "harness.", file=sys.stderr)
        return 0

    os.makedirs(args.out, exist_ok=True)
    manifest = {"artifact_name": "Multi-Modal Synthetic Set – Pilot – v1",
                "target_model": cfg.get("target_model"), "count": len(patients),
                "modalities": mods, "patients": []}
    for pt in patients:
        fname = f"{pt['patient_id']}.json"
        with open(os.path.join(args.out, fname), "w", encoding="utf-8") as fh:
            json.dump(pt, fh, indent=2)
        manifest["patients"].append(fname)
    with open(os.path.join(args.out, "manifest.json"), "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=2)
    print(f"Wrote {len(patients)} synthetic patient files + manifest.json to {args.out} "
          f"({manifest['artifact_name']}).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
