#!/usr/bin/env python3
# reid_risk_assessor.py — assess re-identification risk (k-anonymity / l-diversity / disclosure risk)
#
# PURPOSE: The core release-gate tool. Over the quasi-identifiers it computes k-ANONYMITY (smallest
#          equivalence-class size), l-DIVERSITY (distinct sensitive values per class), the DISCLOSURE-RISK
#          proportion (share of records in classes < k), and a simple MEMBERSHIP/ATTRIBUTE-INFERENCE
#          signal (unique-record share). It reports PASS/FAIL vs. a supplied threshold — it does NOT make
#          the regulatory determination.
# HOW TO RUN: python reid_risk_assessor.py --input deidentified-pilot-v1.csv --classification field-classification-pilot-v1.json --k 5 --l 2 --out reid-risk-pilot-v1.json
# EXPECTED RESULTS: JSON + stdout with k, l, disclosure-risk, unique-record-share and an overall
#          PASS/FAIL. FAIL (nonzero exit) means DO NOT RELEASE — generalize/suppress further and re-run.
#
# Standard-library only (no pandas needed). Read-only on the input; writes only the risk report JSON.
# No network, no secrets, no PHI beyond the already-de-identified candidate it is auditing.

import argparse
import csv
import json
import sys
from collections import Counter, defaultdict


def _load_json(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def _roles(classification_doc):
    fields = classification_doc.get("fields", classification_doc)
    quasi, sensitive = [], []
    for name, info in fields.items():
        c = info.get("classification") if isinstance(info, dict) else info
        if c == "quasi_identifier":
            quasi.append(name)
        elif c == "sensitive_attribute":
            sensitive.append(name)
    return quasi, sensitive


def _read(path):
    with open(path, newline="", encoding="utf-8-sig") as fh:
        return list(csv.DictReader(fh))


def assess(rows, quasi, sensitive):
    n = len(rows)
    if n == 0:
        raise SystemExit("ERROR: input has no data rows.")
    if not quasi:
        raise SystemExit("ERROR: classification lists no quasi-identifiers — cannot compute k-anonymity.")

    classes = defaultdict(list)
    for i, row in enumerate(rows):
        key = tuple(row.get(q, "") for q in quasi)
        classes[key].append(i)

    sizes = [len(idx) for idx in classes.values()]
    k = min(sizes)
    unique = sum(1 for s in sizes if s == 1)
    below = defaultdict(int)  # populated per requested k at report time

    # l-diversity: min distinct sensitive values across classes (worst-case over sensitive attrs).
    if sensitive:
        l_per_attr = {}
        for attr in sensitive:
            worst = None
            for idx in classes.values():
                distinct = len({rows[i].get(attr, "") for i in idx})
                worst = distinct if worst is None else min(worst, distinct)
            l_per_attr[attr] = worst
        l_min = min(l_per_attr.values()) if l_per_attr else None
    else:
        l_per_attr, l_min = {}, None

    return {
        "records": n,
        "equivalence_classes": len(classes),
        "quasi_identifiers": quasi,
        "sensitive_attributes": sensitive,
        "k_anonymity": k,
        "l_diversity": l_min,
        "l_diversity_per_attribute": l_per_attr,
        "unique_record_share": round(unique / n, 4),
        "_class_sizes": sizes,
    }


def main(argv=None):
    p = argparse.ArgumentParser(description="Assess re-identification risk (k-anonymity / l-diversity / disclosure risk) vs. a threshold.")
    p.add_argument("--input", required=True, help="Candidate de-identified/synthetic CSV (read-only).")
    p.add_argument("--classification", required=True, help="Reviewed field classification JSON.")
    p.add_argument("--k", type=int, default=5, help="Minimum acceptable k (default 5).")
    p.add_argument("--l", type=int, default=2, help="Minimum acceptable l-diversity (default 2).")
    p.add_argument("--max-dr", type=float, default=0.05, dest="max_dr",
                   help="Max acceptable disclosure-risk proportion (default 0.05).")
    p.add_argument("--out", help="Write JSON report here; default stdout.")
    args = p.parse_args(argv)

    quasi, sensitive = _roles(_load_json(args.classification))
    metrics = assess(_read(args.input), quasi, sensitive)

    sizes = metrics.pop("_class_sizes")
    disclosure_risk = round(sum(s for s in sizes if s < args.k) / metrics["records"], 4)
    metrics["disclosure_risk"] = disclosure_risk

    gates = {
        "k": {"measured": metrics["k_anonymity"], "threshold": args.k,
              "pass": metrics["k_anonymity"] >= args.k},
        "l": {"measured": metrics["l_diversity"], "threshold": args.l,
              "pass": (metrics["l_diversity"] is None) or (metrics["l_diversity"] >= args.l)},
        "disclosure_risk": {"measured": disclosure_risk, "threshold": args.max_dr,
                            "pass": disclosure_risk <= args.max_dr},
    }
    overall = all(g["pass"] for g in gates.values())
    report = {
        "artifact": "Re-ID Risk Assessment – Pilot – v1",
        "input_file": args.input,
        **metrics,
        "gates": gates,
        "pass": overall,
        "note": "Technical signal only. The de-identification/residual-risk DETERMINATION is deferred "
                "to privacy/compliance/legal.",
    }

    text = json.dumps(report, indent=2)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(text)
        print(f"[written] {args.out}")

    print(f"Records: {metrics['records']}  classes: {metrics['equivalence_classes']}")
    print(f"  k-anonymity     : {metrics['k_anonymity']:>6}  (>= {args.k}?)   "
          f"{'PASS' if gates['k']['pass'] else 'FAIL'}")
    print(f"  l-diversity     : {str(metrics['l_diversity']):>6}  (>= {args.l}?)   "
          f"{'PASS' if gates['l']['pass'] else 'FAIL'}")
    print(f"  disclosure-risk : {disclosure_risk:>6}  (<= {args.max_dr}?) "
          f"{'PASS' if gates['disclosure_risk']['pass'] else 'FAIL'}")
    print(f"  unique-record % : {metrics['unique_record_share']:>6}  (membership-inference signal)")
    print(f"\nOVERALL: {'PASS — releasable pending privacy/legal sign-off' if overall else 'FAIL — DO NOT RELEASE; tighten and re-run'}")
    return 0 if overall else 1


if __name__ == "__main__":
    sys.exit(main())
