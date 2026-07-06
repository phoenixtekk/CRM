#!/usr/bin/env python3
# modality_scope_assess.py — profile which modalities each AI/QA use case needs (structured/notes/vitals).
#
# PURPOSE: Read the AI/QA use cases and produce the Modality Scope – Pilot – v1 record: per use case,
#          which modalities are required, the target model, note types, and vitals channels implied.
#          Read-only assessment; writes a scope file only on explicit --out. No real PHI is read or written.
# HOW TO RUN: python modality_scope_assess.py --use-cases use-cases.json [--out scope.json]  (Python 3.10+)
# EXPECTED RESULTS: A per-use-case table of required modalities and an aggregated scope; the operator sees
#          which modalities the pilot must generate. Warns if any use case declares no modality.

import argparse
import json
import sys

# Keyword hints mapping a use case's model type / description to the modalities it implies.
MODALITY_HINTS = {
    "notes": ["nlp", "note", "document", "text", "ner", "summariz", "coding", "phenotyp", "narrative"],
    "vitals": ["vitals", "signal", "time-series", "timeseries", "sequence", "waveform", "deterioration",
               "sepsis", "monitor", "trajectory"],
    "structured": ["tabular", "structured", "risk score", "cohort", "eligibility", "classif", "regression"],
}

SAMPLE_USE_CASES = {
    "use_cases": [
        {"id": "uc-note-ner", "description": "Clinical NLP entity extraction from discharge summaries",
         "model_type": "document/NLP"},
        {"id": "uc-deterioration", "description": "Early deterioration from vitals time-series",
         "model_type": "signal/sequence"},
        {"id": "uc-fusion", "description": "Note + vitals fusion for sepsis risk",
         "model_type": "multimodal"},
    ],
    "target_model": "FHIR",
}


def infer_modalities(uc):
    text = (uc.get("description", "") + " " + uc.get("model_type", "")).lower()
    found = set()
    for modality, keywords in MODALITY_HINTS.items():
        if any(k in text for k in keywords):
            found.add(modality)
    # A multimodal/fusion use case implies at least notes + vitals + structured backbone.
    if "multimodal" in text or "fusion" in text:
        found |= {"structured", "notes", "vitals"}
    # Any explicit override wins.
    if uc.get("modalities"):
        found = set(uc["modalities"])
    # Structured backbone is always needed as the source of truth.
    found.add("structured")
    return sorted(found)


def assess(doc):
    ucs = doc.get("use_cases", [])
    target_model = doc.get("target_model", "unspecified")
    rows = []
    aggregate = set()
    warnings = []
    for uc in ucs:
        mods = infer_modalities(uc)
        aggregate |= set(mods)
        rows.append({"id": uc.get("id", "?"), "modalities": mods,
                     "model_type": uc.get("model_type", ""),})
        declared = [m for m in mods if m != "structured"]
        if not declared:
            warnings.append(f"use case '{uc.get('id','?')}' implies no notes/vitals modality "
                            "(structured-only) — confirm this is intended")
    note_types = sorted({nt for uc in ucs for nt in uc.get("note_types", [])}) or \
        (["admission_note", "progress_note", "discharge_summary"] if "notes" in aggregate else [])
    vitals_channels = sorted({c for uc in ucs for c in uc.get("vitals_channels", [])}) or \
        (["heart_rate", "systolic_bp", "respiratory_rate", "temperature_c", "spo2"]
         if "vitals" in aggregate else [])
    return {
        "artifact_name": "Modality Scope – Pilot – v1",
        "target_model": target_model,
        "per_use_case": rows,
        "aggregate_modalities": sorted(aggregate),
        "implied_note_types": note_types,
        "implied_vitals_channels": vitals_channels,
        "warnings": warnings,
    }


def main(argv=None):
    p = argparse.ArgumentParser(description="Assess which modalities each AI/QA use case needs. "
                                            "Read-only; writes only on --out; no real PHI.")
    p.add_argument("--use-cases", help="path to use-cases JSON ({use_cases:[...], target_model})")
    p.add_argument("--out", help="write the Modality Scope record here (otherwise stdout)")
    p.add_argument("--sample", action="store_true", help="print a sample use-cases input and exit")
    args = p.parse_args(argv)

    if args.sample:
        print(json.dumps(SAMPLE_USE_CASES, indent=2))
        return 0

    if not args.use_cases:
        p.error("--use-cases is required (or use --sample to see the expected input)")

    try:
        with open(args.use_cases, encoding="utf-8") as fh:
            doc = json.load(fh)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR — cannot read use-cases: {exc}", file=sys.stderr)
        return 2

    result = assess(doc)
    text = json.dumps(result, indent=2)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(text + "\n")
        print(f"Wrote {result['artifact_name']} to {args.out}.")
    else:
        print(text)
        print("\n[dry-run] No file written. Re-run with --out <path> to save.", file=sys.stderr)

    for w in result["warnings"]:
        print(f"WARNING: {w}", file=sys.stderr)
    print(f"Aggregate modalities in scope: {', '.join(result['aggregate_modalities'])}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
