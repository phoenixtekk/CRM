#!/usr/bin/env python3
# generate_harness.py — seeded, reproducible synthetic-EHR generator (dry-run by default)
#
# PURPOSE: Generate clinically plausible, privacy-conscious synthetic EHR records (patients, encounters,
#          conditions, medications, labs, vitals) in the target model's shape. Deterministic from --seed +
#          config. SAFE BY DEFAULT: writes nothing unless --apply, and only ever under --out-dir (refuses
#          production/PHI-signal paths). No real PHI is ever read or written.
# HOW TO RUN: python generate_harness.py --config harness-config.json --seed 20260706 --patients 500 \
#             --out-dir /isolated/synthetic-ehr --dataset-name synthetic-ehr-pilot-v1 [--apply]
#             (Python 3.10+; see --help)
# EXPECTED RESULTS: Dry-run prints the generation plan and writes nothing. With --apply, the dataset plus a
#                   run manifest (seed, config hash, tool version, record counts) are written under --out-dir.

import argparse
import hashlib
import json
import os
import random
import sys
from datetime import date, timedelta

TOOL_VERSION = "1.0.0"
PHI_PATH_SIGNALS = ("prod", "production", "phi", "ehr-live", "clinical-live", "patients-real")

# Small, illustrative reference vocabularies. Real builds bind these to the target profile's value sets /
# vocabularies (verify against your FHIR version or OMOP vocabulary release — see docs).
CONDITIONS = [  # (display, illustrative code)
    ("Type 2 diabetes mellitus", "E11"),
    ("Essential hypertension", "I10"),
    ("Asthma", "J45"),
    ("Acute upper respiratory infection", "J06"),
    ("Hyperlipidemia", "E78"),
]
MEDS_BY_CONDITION = {
    "E11": ["Metformin", "Insulin glargine"],
    "I10": ["Lisinopril", "Amlodipine"],
    "J45": ["Albuterol", "Fluticasone"],
    "J06": ["Acetaminophen"],
    "E78": ["Atorvastatin"],
}
LABS = [  # (name, low, high, unit) — illustrative adult reference ranges; confirm against your reference
    ("HbA1c", 4.5, 9.5, "%"),
    ("Glucose", 70, 180, "mg/dL"),
    ("LDL", 50, 190, "mg/dL"),
    ("Creatinine", 0.6, 1.3, "mg/dL"),
]


def guard_out_dir(out_dir):
    low = out_dir.replace("\\", "/").lower()
    for sig in PHI_PATH_SIGNALS:
        if sig in low:
            raise SystemExit(
                f"REFUSED: out-dir '{out_dir}' matches PHI/production signal '{sig}'. "
                "Point --out-dir at an isolated non-production location (Requirement R3)."
            )


def config_hash(config):
    blob = json.dumps(config, sort_keys=True).encode("utf-8")
    return hashlib.sha256(blob).hexdigest()[:16]


def gen_patient(rng, idx):
    sex = rng.choice(["male", "female"])
    age = int(max(0, min(100, rng.gauss(48, 20))))
    birth = date.today() - timedelta(days=age * 365 + rng.randint(0, 364))
    return {
        # Clearly-synthetic identifier from a synthetic namespace — never a real MRN.
        "id": f"SYN-{idx:07d}",
        "sex": sex,
        "birth_date": birth.isoformat(),
        "age": age,
    }


def gen_vitals(rng):
    systolic = int(rng.gauss(124, 14))
    diastolic = int(rng.gauss(78, 9))
    # Clinical invariant: systolic must exceed diastolic.
    if diastolic >= systolic:
        diastolic = systolic - rng.randint(20, 40)
    return {
        "systolic_mmHg": max(80, systolic),
        "diastolic_mmHg": max(40, diastolic),
        "heart_rate_bpm": int(rng.gauss(74, 11)),
        "temp_C": round(rng.gauss(36.8, 0.4), 1),
    }


def gen_record(rng, idx, domains):
    patient = gen_patient(rng, idx)
    rec = {"patient": patient}
    n_cond = rng.randint(0, 3)
    conds = rng.sample(CONDITIONS, min(n_cond, len(CONDITIONS)))
    if "encounters" in domains:
        rec["encounters"] = [{"type": rng.choice(["outpatient", "inpatient", "emergency"]),
                              "date": (date.today() - timedelta(days=rng.randint(0, 730))).isoformat()}]
    if "conditions" in domains:
        rec["conditions"] = [{"display": d, "code": c} for d, c in conds]
    if "medications" in domains:
        meds = []
        for _, code in conds:
            for m in MEDS_BY_CONDITION.get(code, []):
                if rng.random() < 0.7:  # meds plausibly linked to a condition
                    meds.append({"name": m, "for_code": code})
        rec["medications"] = meds
    if "labs" in domains:
        rec["labs"] = [{"name": n, "value": round(rng.uniform(lo, hi), 1), "unit": u}
                       for (n, lo, hi, u) in rng.sample(LABS, rng.randint(1, len(LABS)))]
    if "vitals" in domains:
        rec["vitals"] = gen_vitals(rng)
    return rec


def main():
    ap = argparse.ArgumentParser(description="Seeded synthetic-EHR generator (safe by default).")
    ap.add_argument("--config", required=True, help="harness config JSON (from scenario_config.py)")
    ap.add_argument("--seed", type=int, required=True, help="random seed — same seed + config => same dataset")
    ap.add_argument("--patients", type=int, default=100, help="number of synthetic patients (default 100)")
    ap.add_argument("--out-dir", required=True, help="ISOLATED output directory (R3); PHI/prod paths refused")
    ap.add_argument("--dataset-name", default="synthetic-ehr-pilot-v1", help="dataset artifact name")
    ap.add_argument("--apply", action="store_true", help="actually write; without it this is a dry-run")
    args = ap.parse_args()

    guard_out_dir(args.out_dir)

    if not os.path.isfile(args.config):
        raise SystemExit(f"config not found: {args.config} (create it with scenario_config.py)")
    with open(args.config, "r", encoding="utf-8") as fh:
        config = json.load(fh)

    target_model = str(config.get("target_model", "native")).lower()
    domains = config.get("domains", ["patients", "encounters", "conditions", "medications", "labs", "vitals"])
    cfg_hash = config_hash(config)

    print(f"=== {args.dataset_name} : generation plan ===")
    print(f"  target model : {target_model}")
    print(f"  domains      : {', '.join(domains)}")
    print(f"  patients     : {args.patients}")
    print(f"  seed         : {args.seed}")
    print(f"  config hash  : {cfg_hash}")
    print(f"  out-dir      : {args.out_dir}")

    rng = random.Random(args.seed)  # deterministic: seed fully controls output
    records = [gen_record(rng, i, domains) for i in range(args.patients)]

    counts = {"patients": len(records)}
    for dom in ("encounters", "conditions", "medications", "labs"):
        if dom in domains:
            counts[dom] = sum(len(r.get(dom, [])) for r in records)
    if "vitals" in domains:
        counts["vitals"] = sum(1 for r in records if r.get("vitals"))

    print("  record counts:")
    for k, v in counts.items():
        print(f"    - {k}: {v}")

    if not args.apply:
        print("\nDRY-RUN: nothing written. Re-run with --apply to write into the isolated out-dir.")
        return 0

    os.makedirs(args.out_dir, exist_ok=True)
    ds_dir = os.path.join(args.out_dir, args.dataset_name)
    os.makedirs(ds_dir, exist_ok=True)

    data_path = os.path.join(ds_dir, "records.json")
    with open(data_path, "w", encoding="utf-8") as fh:
        json.dump({"target_model": target_model, "records": records}, fh, indent=2)

    manifest = {
        "artifact": args.dataset_name,
        "tool_version": TOOL_VERSION,
        "seed": args.seed,
        "config_hash": cfg_hash,
        "target_model": target_model,
        "domains": domains,
        "record_counts": counts,
    }
    # content hash makes reproducibility checkable (Testing T4)
    manifest["content_hash"] = hashlib.sha256(
        json.dumps(manifest, sort_keys=True).encode("utf-8")).hexdigest()[:16]
    with open(os.path.join(ds_dir, "run-manifest.json"), "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=2)

    print(f"\nWROTE dataset -> {data_path}")
    print(f"WROTE manifest (content_hash={manifest['content_hash']}) -> {ds_dir}/run-manifest.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())
