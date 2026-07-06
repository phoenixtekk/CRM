#!/usr/bin/env python3
# integration_contract_validator.py — validate the target-model interface contract & vendor output
#
# PURPOSE: Validate an integration interface-contract file (target model, entities, required
#          fields, identifier/reference rules), and optionally validate vendor output against
#          it. Read-only: it inspects files and reports, it never modifies data. This is the
#          Gate B tool.
# HOW TO RUN: python integration_contract_validator.py --contract contract.json
#             [--data vendor_output.json]   (Python 3.10+; see --help)
# EXPECTED RESULTS: "CONTRACT OK" plus, when --data is given, a per-entity conformance report
#          ending in "GATE B: PASS" or "GATE B: FAIL" with the specific violations listed.
"""Integration contract validator.

The contract is expressed against the declared target model (FHIR / OMOP / native). Vendor
output must be shaped to the contract by the data-out adapter BEFORE it reaches here — this
tool checks the contract itself is well-formed and that output conforms; it does not adapt.
Standard-library only; no PHI required (validate against synthetic output only).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ALLOWED_TYPES = {"string", "integer", "number", "boolean", "date", "datetime"}


def load_json(path: str):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except FileNotFoundError:
        sys.exit(f"ERROR: file not found: {path}")
    except json.JSONDecodeError as exc:
        sys.exit(f"ERROR: invalid JSON in {path}: {exc}")


def validate_contract(contract: dict) -> list[str]:
    """Structural checks on the contract file itself."""
    errs: list[str] = []
    if contract.get("target_model") not in {"FHIR", "OMOP", "native"}:
        errs.append("target_model must be one of FHIR | OMOP | native")
    entities = contract.get("entities")
    if not isinstance(entities, dict) or not entities:
        errs.append("contract must declare a non-empty 'entities' object")
        return errs
    for ename, edef in entities.items():
        fields = edef.get("fields")
        if not isinstance(fields, dict) or not fields:
            errs.append(f"entity '{ename}' must declare 'fields'")
            continue
        for fname, fdef in fields.items():
            ftype = fdef.get("type")
            if ftype not in ALLOWED_TYPES:
                errs.append(f"{ename}.{fname}: type '{ftype}' not in {sorted(ALLOWED_TYPES)}")
        for ref in edef.get("references", []):
            if ref.get("entity") not in entities:
                errs.append(f"{ename}: reference to unknown entity '{ref.get('entity')}'")
    return errs


def _type_ok(value, ftype: str) -> bool:
    if value is None:
        return True  # presence is checked separately; null is a type-neutral absence
    if ftype == "string":
        return isinstance(value, str)
    if ftype == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if ftype == "number":
        return isinstance(value, (int, float)) and not isinstance(value, bool)
    if ftype == "boolean":
        return isinstance(value, bool)
    if ftype in ("date", "datetime"):
        return isinstance(value, str)  # ISO strings; format detail deferred to the pipeline
    return False


def validate_output(contract: dict, data: dict) -> list[str]:
    """Check vendor output (target-model-shaped) against the contract."""
    viol: list[str] = []
    entities = contract["entities"]
    for ename, edef in entities.items():
        rows = data.get(ename)
        if rows is None:
            viol.append(f"missing required entity '{ename}' in output")
            continue
        if not isinstance(rows, list):
            viol.append(f"entity '{ename}' must be a list of records")
            continue
        req = [f for f, d in edef["fields"].items() if d.get("required")]
        keyset = {r.get(edef.get("primary_key")) for r in rows} if edef.get("primary_key") else set()
        for idx, row in enumerate(rows):
            for f in req:
                if row.get(f) in (None, ""):
                    viol.append(f"{ename}[{idx}]: missing required field '{f}'")
            for f, fdef in edef["fields"].items():
                if f in row and not _type_ok(row[f], fdef["type"]):
                    viol.append(f"{ename}[{idx}].{f}: expected {fdef['type']}")
        # reference (foreign-key) integrity
        for ref in edef.get("references", []):
            target = ref["entity"]
            tkey = entities[target].get("primary_key")
            tvals = {r.get(tkey) for r in data.get(target, [])}
            for idx, row in enumerate(rows):
                fk = row.get(ref["field"])
                if fk is not None and fk not in tvals:
                    viol.append(f"{ename}[{idx}].{ref['field']}={fk!r} has no matching {target}.{tkey}")
    return viol


def main() -> int:
    ap = argparse.ArgumentParser(description="Validate the integration contract and (optionally) vendor output.")
    ap.add_argument("--contract", required=True, help="Interface-contract JSON file.")
    ap.add_argument("--data", help="Optional vendor-output JSON (target-model-shaped) to validate.")
    args = ap.parse_args()

    contract = load_json(args.contract)
    cerrs = validate_contract(contract)
    if cerrs:
        print("CONTRACT INVALID:")
        for e in cerrs:
            print(f"  - {e}")
        return 2
    print(f"CONTRACT OK  (target_model={contract['target_model']}, entities={len(contract['entities'])})")

    if not args.data:
        print("(no --data given: contract-only validation complete)")
        return 0

    viol = validate_output(contract, load_json(args.data))
    print("\nGate B — Contract conformance")
    print("-" * 40)
    if viol:
        for v in viol:
            print(f"  VIOLATION: {v}")
        print(f"\nGATE B: FAIL ({len(viol)} violation(s)) — fix in the data-out adapter and re-run.")
        return 1
    print("  all required entities/fields present; references resolve; types conform")
    print("\nGATE B: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
