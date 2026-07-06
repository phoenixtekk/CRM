#!/usr/bin/env python3
# deid_config_helper.py — build/validate the de-identification pipeline config; assemble the evidence record
#
# PURPOSE: Scope/config helper. From a reviewed field classification and a target (k, l), generate a
#          starting "De-Identification Pipeline – Pilot – v1" config (suppress direct identifiers,
#          generalize quasi-identifiers, pass through the rest). Also VALIDATES an existing config, and
#          (--assemble-evidence) composes the Privacy Evidence Record from the classification, pipeline,
#          risk, and fidelity outputs. Never writes real data; only JSON config / a Markdown record.
# HOW TO RUN: python deid_config_helper.py --classification field-classification-pilot-v1.json --k 5 --l 2 --out deid-pipeline-pilot-v1.json
#             python deid_config_helper.py --validate --config deid-pipeline-pilot-v1.json
#             python deid_config_helper.py --assemble-evidence --classification c.json --pipeline p.json --risk r.json --fidelity f.json --out evidence.md
# EXPECTED RESULTS: A versioned pipeline config JSON, a PASS/FAIL validation summary, or a Markdown
#          Privacy Evidence Record assembled from the four inputs.
#
# Standard-library only. No network, no secrets, no PHI. The key-custody decision (S4) is surfaced as a
# TODO in the config so the operator records where any pseudonymization key is held (outside the test env).

import argparse
import json
import sys
from datetime import date

# Default per-classification transformation policy.
DEFAULT_POLICY = {
    "direct_identifier": {"action": "suppress"},
    "quasi_identifier": {"action": "generalize"},
    "sensitive_attribute": {"action": "keep"},
    "non_identifying": {"action": "keep"},
}

# Generalization defaults keyed by common quasi-identifier shapes (operator can override per field).
GENERALIZE_DEFAULTS = {
    "age": {"method": "band", "width": 10},
    "zip": {"method": "truncate", "keep_prefix": 3},
    "postal": {"method": "truncate", "keep_prefix": 3},
    "date": {"method": "date_shift_coarsen", "granularity": "month"},
    "dob": {"method": "date_shift_coarsen", "granularity": "year"},
}


def _load(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def _generalize_default_for(field_name):
    key = field_name.lower()
    for hint, cfg in GENERALIZE_DEFAULTS.items():
        if hint in key:
            return dict(cfg)
    return {"method": "coarsen", "note": "review generalization for this field"}


def cmd_generate(args):
    cls_doc = _load(args.classification)
    fields = cls_doc.get("fields", cls_doc)
    field_rules = {}
    for name, info in fields.items():
        classification = info.get("classification", "non_identifying") if isinstance(info, dict) else info
        rule = dict(DEFAULT_POLICY.get(classification, {"action": "keep"}))
        rule["classification"] = classification
        if rule["action"] == "generalize":
            rule["generalize"] = _generalize_default_for(name)
        if rule["action"] == "suppress":
            rule["key_custody_TODO"] = ("suppress by default; if pseudonymize is required, record WHERE "
                                        "the key is held — it MUST stay outside the test environment (S4).")
        field_rules[name] = rule
    config = {
        "artifact": "De-Identification Pipeline – Pilot – v1",
        "generated": date.today().isoformat(),
        "target_threshold": {"k": args.k, "l": args.l, "max_disclosure_risk": args.max_dr},
        "route": args.route,
        "field_rules": field_rules,
        "note": "Starting config. Review generalization vs. AI/QA utility before running the pipeline.",
    }
    _emit_json(config, args.out)
    print(f"Generated pipeline config for {len(field_rules)} fields "
          f"(target k={args.k}, l={args.l}, max_disclosure_risk={args.max_dr}).")
    return 0


def cmd_validate(args):
    cfg = _load(args.config)
    problems = []
    rules = cfg.get("field_rules", {})
    if not rules:
        problems.append("no field_rules present")
    thr = cfg.get("target_threshold", {})
    if not thr.get("k"):
        problems.append("target_threshold.k missing (release gate undefined)")
    for name, rule in rules.items():
        if rule.get("action") == "pseudonymize" and "key_location" not in rule:
            problems.append(f"field '{name}': pseudonymize without documented key_location (S4 violation risk)")
        if rule.get("action") == "generalize" and "generalize" not in rule:
            problems.append(f"field '{name}': generalize action without a generalize spec")
    result = {"artifact": "Pipeline Config Validation", "config": args.config,
              "pass": not problems, "problems": problems}
    _emit_json(result, args.out)
    if problems:
        print("FAIL: config validation found issues:")
        for pr in problems:
            print(f"  - {pr}")
        return 1
    print("PASS: pipeline config is internally consistent.")
    return 0


def cmd_assemble_evidence(args):
    cls_doc = _load(args.classification)
    pipe = _load(args.pipeline)
    risk = _load(args.risk)
    fid = _load(args.fidelity) if args.fidelity else {}
    lines = []
    a = lines.append
    a("# Privacy Evidence Record – Pilot – v1\n")
    a(f"_Assembled {date.today().isoformat()}._\n")
    a("> Technical evidence only. The regulatory/legal DETERMINATION (de-identification status, "
      "residual-risk acceptance, IRB/privacy sign-off) is deferred to privacy/compliance/legal.\n")
    a("## 1. Field classification\n")
    for name, info in cls_doc.get("fields", cls_doc).items():
        c = info.get("classification") if isinstance(info, dict) else info
        a(f"- `{name}` — **{c}**")
    a("\n## 2. Transformations applied\n")
    for name, rule in pipe.get("field_rules", {}).items():
        a(f"- `{name}` — {rule.get('action')}"
          + (f" ({rule.get('generalize', {}).get('method')})" if rule.get("action") == "generalize" else ""))
    thr = pipe.get("target_threshold", {})
    a("\n## 3. Re-identification-risk metrics vs. threshold\n")
    a(f"- Threshold: k≥{thr.get('k')}, l≥{thr.get('l')}, disclosure-risk≤{thr.get('max_disclosure_risk')}")
    for key in ("k_anonymity", "l_diversity", "disclosure_risk", "unique_record_share"):
        if key in risk:
            a(f"- Measured {key}: {risk[key]}")
    a(f"- **Overall risk gate: {'PASS' if risk.get('pass') else 'FAIL'}**")
    if fid:
        a("\n## 4. Fidelity / coverage\n")
        a(f"- Fidelity gate: {'PASS' if fid.get('pass') else 'FAIL'} "
          f"(score {fid.get('overall_score', 'n/a')})")
    a("\n## 5. Release decision (to be completed by privacy/compliance/legal)\n")
    a("- [ ] Determination recorded by: __________  Date: __________")
    a("- [ ] Residual risk accepted / not accepted")
    text = "\n".join(lines) + "\n"
    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(text)
        print(f"[written] {args.out}")
    else:
        sys.stdout.write(text)
    return 0


def _emit_json(obj, out_path):
    text = json.dumps(obj, indent=2)
    if out_path:
        with open(out_path, "w", encoding="utf-8") as fh:
            fh.write(text)
        print(f"[written] {out_path}")
    else:
        print(text)


def main(argv=None):
    p = argparse.ArgumentParser(description="Build/validate the de-identification pipeline config and assemble the privacy evidence record.")
    p.add_argument("--classification", help="Reviewed field classification JSON.")
    p.add_argument("--config", help="Existing pipeline config (for --validate).")
    p.add_argument("--pipeline", help="Pipeline config (for --assemble-evidence).")
    p.add_argument("--risk", help="Re-ID risk output JSON (for --assemble-evidence).")
    p.add_argument("--fidelity", help="Fidelity output JSON (for --assemble-evidence).")
    p.add_argument("--k", type=int, default=5, help="Target minimum k (default 5).")
    p.add_argument("--l", type=int, default=2, help="Target minimum l-diversity (default 2).")
    p.add_argument("--max-dr", type=float, default=0.05, dest="max_dr",
                   help="Max acceptable disclosure-risk proportion (default 0.05).")
    p.add_argument("--route", choices=["deidentify", "synthesize"], default="deidentify")
    p.add_argument("--validate", action="store_true", help="Validate an existing --config.")
    p.add_argument("--assemble-evidence", action="store_true",
                   help="Assemble the Privacy Evidence Record from the four inputs.")
    p.add_argument("--out", help="Write output here; default stdout.")
    args = p.parse_args(argv)

    if args.assemble_evidence:
        if not (args.classification and args.pipeline and args.risk):
            p.error("--assemble-evidence needs --classification, --pipeline, and --risk")
        return cmd_assemble_evidence(args)
    if args.validate:
        if not args.config:
            p.error("--validate needs --config")
        return cmd_validate(args)
    if not args.classification:
        p.error("generate mode needs --classification")
    return cmd_generate(args)


if __name__ == "__main__":
    sys.exit(main())
